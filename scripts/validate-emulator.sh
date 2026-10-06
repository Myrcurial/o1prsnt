#!/bin/bash
# validate-emulator.sh -- check that this Mac is ready for Osborne 1 emulation
# and development. macOS + Homebrew only.
#
# Usage: ./validate-emulator.sh
#
# Checks for: mame, cpmtools (cpmcp/cpmrm/cpmls), the Osborne 1 ROMs, and
# (optionally) disk-analyse for HFE conversion. Prints the preferred directory
# layout and what to install/change if anything is missing.

set -uo pipefail

O1DIR="${O1DIR:-$HOME/Documents/Osborne1}"
MISSING=0

pass() { echo "  ok    $1"; }
fail() { echo "  MISS  $1"; MISSING=1; }
warn() { echo "  warn  $1"; }

echo "== Osborne 1 emulator environment check =="
echo

# --- platform ----------------------------------------------------------------
if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: this setup is macOS-only; detected $(uname -s)" >&2
  exit 1
fi
if ! command -v brew >/dev/null; then
  echo "error: Homebrew not found -- see https://brew.sh" >&2
  exit 1
fi
pass "macOS + Homebrew"
echo

# --- required tools ------------------------------------------------------------
echo "-- tools --"
if command -v mame >/dev/null; then pass "mame ($(mame -version 2>/dev/null | head -1))"
else fail "mame -- install with: brew install mame"; fi

for t in cpmcp cpmrm cpmls; do
  if command -v "$t" >/dev/null; then pass "$t (cpmtools)"; else
    fail "$t -- install with: brew install cpmtools"; break
  fi
done

# --- ROMs ---------------------------------------------------------------------
echo "-- ROMs --"
ROM_OK=0
if [ -f "$O1DIR/roms/osborne1.zip" ]; then
  if unzip -l "$O1DIR/roms/osborne1.zip" 2>/dev/null | grep -q "3a10082-00rev-e.ud11"; then
    pass "osborne1.zip with BIOS v1.44 ROM"; ROM_OK=1
  else
    fail "osborne1.zip present but 3a10082-00rev-e.ud11 (BIOS v1.44) not inside"
  fi
elif [ -d "$O1DIR/roms/osborne1" ]; then
  if [ -f "$O1DIR/roms/osborne1/3a10082-00rev-e.ud11" ]; then
    pass "osborne1/ directory with BIOS v1.44 ROM"; ROM_OK=1
  else
    fail "osborne1/ directory exists but 3a10082-00rev-e.ud11 (BIOS v1.44) missing"
  fi
fi
if [ "$ROM_OK" -eq 0 ]; then
  cat >&2 <<'EOF'
  Get the ROMs from https://archive.org/details/osborne-1-roms and keep them
  zipped as ~/Documents/Osborne1/roms/osborne1.zip
EOF
fi

# --- optional tools -------------------------------------------------------------
echo "-- optional --"
if command -v disk-analyse >/dev/null; then
  pass "disk-analyse (HFE <-> IMD conversion)"
elif [ -x "$O1DIR/disk-utilities/disk-analyse" ]; then
  pass "disk-analyse (found in $O1DIR/disk-utilities, not on PATH)"
else
  warn "disk-analyse not found -- only needed for hardware floppy emulators (HFE)."
  warn "  build from https://github.com/keirf/disk-utilities (make; sudo make install)"
fi

# --- preferred layout -----------------------------------------------------------
echo
echo "Preferred directory layout:"
cat <<EOF
  ~/Documents/Osborne1/
    roms/          <- osborne1.zip (MAME ROMs)
    floppies/      <- .imd / .hfe disk images
    o1prsnt/       <- (optional) working copies
    presentations/ <- your slide source files
EOF

echo
if [ "$MISSING" -eq 0 ]; then
  echo "READY: emulator environment looks good."
  exit 0
else
  echo "NOT READY: fix the MISS items above." >&2
  exit 1
fi
