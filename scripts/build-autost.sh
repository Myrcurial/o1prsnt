#!/bin/bash
# build-autost.sh -- assemble autost.asm into autost.com using the authentic
# CP/M toolchain (ASM.COM + LOAD.COM) running on the emulated Osborne 1, via
# the headless testing harness approach (MAME -autoboot_script, VRAM reading).
#
# Usage:
#   ./build-autost.sh [--asm-src FILE] [--system-image FILE] [--out FILE]
#                     [--test-image FILE] [--skip-test]
#
# Defaults:
#   --asm-src       <repo>/scripts/autost.asm
#   --system-image  ~/Documents/Osborne1/floppies/cpm-system.imd  (has ASM.COM
#                   and LOAD.COM)
#   --out           <repo>/src/autost.com
#   --test-image    first of ~/Documents/Osborne1/floppies/o1prsnt.imd or
#                   <repo>/assets/disks/o1prsnt.imd
#
# The build is verified by booting a test floppy in the emulator and watching
# for the o1prsnt splash screen with NO keyboard input -- proof that the new
# AUTOST.COM chain-loads "MBASIC O1PRSNT.BAS" at cold boot.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
O1DIR="${O1DIR:-$HOME/Documents/Osborne1}"
ASM_SRC="$REPO_ROOT/scripts/autost.asm"
SYSTEM_IMAGE="$O1DIR/floppies/cpm-system.imd"
OUT="$REPO_ROOT/src/autost.com"
TEST_IMAGE=""
SKIP_TEST=0

while [ $# -gt 0 ]; do
  case "$1" in
    --asm-src)      ASM_SRC="$2"; shift 2;;
    --system-image) SYSTEM_IMAGE="$2"; shift 2;;
    --out)          OUT="$2"; shift 2;;
    --test-image)   TEST_IMAGE="$2"; shift 2;;
    --skip-test)    SKIP_TEST=1; shift;;
    -h|--help)      sed -n '2,22p' "$0"; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

if [ -z "$TEST_IMAGE" ]; then
  for c in "$O1DIR/floppies/o1prsnt.imd" "$REPO_ROOT/assets/disks/o1prsnt.imd"; do
    [ -f "$c" ] && TEST_IMAGE="$c" && break
  done
fi

# --- prerequisites -----------------------------------------------------------
for tool in mame cpmcp cpmrm cpmls; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found (brew install mame cpmtools)" >&2; exit 1; }
done
[ -f "$ASM_SRC" ]      || { echo "error: no assembler source: $ASM_SRC" >&2; exit 1; }
[ -f "$SYSTEM_IMAGE" ] || { echo "error: no CP/M system image: $SYSTEM_IMAGE" >&2; exit 1; }
cpmls -f osborne1 "$SYSTEM_IMAGE" | grep -q "asm.com"  || { echo "error: ASM.COM not on $SYSTEM_IMAGE" >&2; exit 1; }
cpmls -f osborne1 "$SYSTEM_IMAGE" | grep -q "load.com" || { echo "error: LOAD.COM not on $SYSTEM_IMAGE" >&2; exit 1; }
echo "build-autost: source=$ASM_SRC"
echo "build-autost: system image=$SYSTEM_IMAGE"

# run MAME from a neutral directory so its cfg/snap litter doesn't land in the repo
cd "$O1DIR"

WORK="$(mktemp -d /tmp/o1autost.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# --- put the source on a scratch copy of the system image --------------------
cp "$SYSTEM_IMAGE" "$WORK/build.imd"
for f in AUTOST.ASM AUTOST.HEX AUTOST.PRN AUTOST.COM; do
  cpmrm -f osborne1 "$WORK/build.imd" "0:$f" 2>/dev/null || true
done
cpmcp -f osborne1 "$WORK/build.imd" "$ASM_SRC" 0:AUTOST.ASM
echo "build-autost: AUTOST.ASM placed on build image"

# --- compose the build's Lua script ------------------------------------------
# Prefer the shared harness library when it is checked out next to us; fall
# back to a minimal embedded prelude so this script also works standalone.
HARNESS_LIB="$REPO_ROOT/utilities/headless-testing-harness/o1harness.lua"
BUILD_LUA="$WORK/build.lua"
if [ -f "$HARNESS_LIB" ]; then
  cat "$HARNESS_LIB" > "$BUILD_LUA"
else
  cat > "$BUILD_LUA" << 'LUAEOF'
-- minimal embedded harness prelude (fallback; the full library lives in
-- utilities/headless-testing-harness/o1harness.lua)
H = {}
H.kb = manager.machine.natkeyboard
H.space = manager.machine.devices[":maincpu"].spaces["program"]
function H.screen_text()
  local t = {}
  for row = 0, 31 do
    local s = ""
    for col = 0, 127 do
      local b = H.space:read_u8(0xF000 + row * 128 + col) % 128
      s = s .. ((b >= 32 and b < 127) and string.char(b) or " ")
    end
    t[#t + 1] = s
  end
  return table.concat(t, "\n")
end
function H.dump(tag)
  print("=== DUMP " .. tostring(tag) .. " ===")
  print(H.screen_text())
end
function H.wait_for(pat, timeout)
  local t = 0
  while t < timeout do
    if H.screen_text():find(pat, 1, true) then print("FOUND: " .. pat) return true end
    emu.wait(0.5) t = t + 0.5
  end
  print("TIMEOUT: " .. pat) H.dump("at timeout") return false
end
function H.send(text) H.kb:post(text) end
function H.type_line(text) H.kb:post(text .. "\r") emu.wait(#text * 0.15 + 1.5) end
function H.finish(code) os.exit(code or 0) end
LUAEOF
fi

cat >> "$BUILD_LUA" << 'LUAEOF'

-- build steps: assemble with ASM.COM, then hex->com with LOAD.COM
emu.wait(2)
H.send("\r")                                 -- BIOS: boot from drive A
if not H.wait_for("A>", 30) then H.finish(1) end
H.type_line("asm autost")                    -- AUTOST.ASM -> AUTOST.HEX (+ .PRN)
if not H.wait_for("USE FACTOR", 180) then H.finish(1) end
-- ASM.COM is still running when USE FACTOR appears; wait for it to fully
-- exit before typing, or the LOAD command's keystrokes get eaten.
if not H.wait_for("END OF ASSEMBLY", 60) then H.finish(1) end
emu.wait(2)
H.dump("after ASM")
if H.screen_text():find("ASSEMBLY ERROR", 1, true) then
  print("BUILD FAILED: assembly errors")
  H.finish(1)
end
H.type_line("load autost")                   -- AUTOST.HEX -> AUTOST.COM
if not H.wait_for("RECORDS WRITTEN", 60) then H.finish(1) end
H.dump("after LOAD")
print("BUILD OK")
-- NOTE: do NOT os.exit here. MAME flushes floppy-image writes only on a
-- clean emulation teardown, so we let the script end and -seconds_to_run
-- expire naturally; os.exit() would abandon the freshly written AUTOST.COM.
LUAEOF

# --- run the build in the emulator -------------------------------------------
SDL_VIDEODRIVER=dummy mame osborne1 \
  -flop1 "$WORK/build.imd" \
  -video none -sound none -nothrottle \
  -autoboot_script "$BUILD_LUA" \
  -seconds_to_run 300 \
  -rompath "$O1DIR/roms" | tee "$WORK/build.log" || true
# (mame's exit code is ignored: the macOS headless teardown segfaults
#  occasionally *after* the machine has cleanly shut down and flushed the
#  floppy image -- what matters is the artifacts, checked below.)

grep -q "BUILD OK" "$WORK/build.log" || { echo "error: emulator build failed; see log above" >&2; exit 1; }

# --- extract the product ------------------------------------------------------
cpmls -f osborne1 "$WORK/build.imd" | grep -q "autost.com" || { echo "error: AUTOST.COM not produced" >&2; exit 1; }
cpmcp -f osborne1 "$WORK/build.imd" 0:AUTOST.COM "$WORK/autost.com"
[ -s "$WORK/autost.com" ] || { echo "error: AUTOST.COM is empty" >&2; exit 1; }
grep -aq "Loading O1PRSNT" "$WORK/autost.com" || { echo "error: AUTOST.COM missing load message (bad build?)" >&2; exit 1; }
cp "$WORK/autost.com" "$OUT"
echo "build-autost: wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"

# --- boot test: prove the new AUTOST.COM chain-loads the presentation ---------
if [ "$SKIP_TEST" -eq 1 ]; then
  echo "build-autost: boot test skipped (--skip-test)"
  exit 0
fi
if [ -z "$TEST_IMAGE" ] || [ ! -f "$TEST_IMAGE" ]; then
  echo "build-autost: WARNING: no o1prsnt test image found; skipping boot test" >&2
  echo "build-autost: (pass --test-image PATH to enable it)" >&2
  exit 0
fi

cp "$TEST_IMAGE" "$WORK/test.imd"
cpmrm -f osborne1 "$WORK/test.imd" 0:AUTOST.COM 2>/dev/null || true
cpmcp -f osborne1 "$WORK/test.imd" "$OUT" 0:AUTOST.COM

TEST_LUA="$WORK/test.lua"
{
  if [ -f "$HARNESS_LIB" ]; then
    cat "$HARNESS_LIB"
  else
    # fallback: reuse the minimal prelude already written into BUILD_LUA
    sed -n '/^-- minimal embedded harness prelude/,/^function H.finish(code) os.exit(code or 0) end$/p' "$BUILD_LUA"
  fi
  cat << 'LUAEOF'
-- boot test: with NO keyboard input after the BIOS RETURN, AUTOST.COM must
-- print its message and chain-load "MBASIC O1PRSNT.BAS" to the splash screen
emu.wait(2)
H.send("\r")
if not H.wait_for("Loading O1PRSNT", 60) then
  print("TEST FAIL: AUTOST load message never appeared")
  H.finish(1)
end
if not H.wait_for("Press any key", 120) then
  print("TEST FAIL: splash screen never appeared")
  H.finish(1)
end
print("TEST PASS: AUTOST.COM booted straight into o1prsnt")
H.finish(0)
LUAEOF
} > "$TEST_LUA"

SDL_VIDEODRIVER=dummy mame osborne1 \
  -flop1 "$WORK/test.imd" \
  -video none -sound none -nothrottle \
  -autoboot_script "$TEST_LUA" \
  -seconds_to_run 240 \
  -rompath "$O1DIR/roms" | tee "$WORK/test.log" || true

grep -q "TEST PASS" "$WORK/test.log" || { echo "error: boot test failed; see log above" >&2; exit 1; }
echo "build-autost: done. $OUT assembled and boot-verified."
