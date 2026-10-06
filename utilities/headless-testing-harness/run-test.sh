#!/bin/bash
# run-test.sh -- run a headless Osborne 1 test script under MAME.
#
# Usage:
#   ./run-test.sh TEST.lua [IMAGE.imd] [SECONDS]
#
#   TEST.lua   your test script; the harness library (o1harness.lua, same
#              directory as this script) is prepended automatically, so your
#              script can call H.boot_cpm(), H.wait_for(), etc. directly.
#   IMAGE.imd  floppy image for drive A
#              (default: ~/Documents/Osborne1/floppies/o1prsnt.imd)
#   SECONDS    emulated-seconds budget (default: 240). With -nothrottle this
#              runs much faster than real time; make it generous.
#
# Environment:
#   O1_ROMPATH  MAME ROM path (default: ~/Documents/Osborne1/roms)
#
# macOS notes: SDL_VIDEODRIVER=dummy is required when running from a pure
# terminal session, otherwise SDL video initialisation fails.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST="${1:?usage: run-test.sh TEST.lua [IMAGE.imd] [SECONDS]}"
IMAGE="${2:-$HOME/Documents/Osborne1/floppies/o1prsnt.imd}"
SECONDS_BUDGET="${3:-240}"
ROMPATH="${O1_ROMPATH:-$HOME/Documents/Osborne1/roms}"

[ -f "$TEST" ]  || { echo "error: no such test script: $TEST" >&2; exit 1; }
[ -f "$IMAGE" ] || { echo "error: no such floppy image: $IMAGE" >&2; exit 1; }
command -v mame >/dev/null || { echo "error: mame not found (brew install mame)" >&2; exit 1; }

RUN_LUA="/tmp/o1test.$$.lua"
trap 'rm -f "$RUN_LUA"' EXIT
cat "$HARNESS_DIR/o1harness.lua" "$TEST" > "$RUN_LUA"

SDL_VIDEODRIVER=dummy mame osborne1 \
  -flop1 "$IMAGE" \
  -video none -sound none -nothrottle \
  -autoboot_script "$RUN_LUA" \
  -seconds_to_run "$SECONDS_BUDGET" \
  -rompath "$ROMPATH"
