#!/bin/bash
# diskette-converter.sh -- convert Osborne 1 floppy images between the MAME
# emulator format (.imd) and hardware floppy-emulator format (.hfe).
#
# Usage:
#   ./diskette-converter.sh --imd2hfe INPUT.imd OUTPUT.hfe
#   ./diskette-converter.sh --hfe2imd INPUT.hfe OUTPUT.imd
#
# Thin convenience wrapper around disk-analyse (from Keirf's Disk Utilities).
set -euo pipefail

O1DIR="${O1DIR:-$HOME/Documents/Osborne1}"

if [ $# -ne 3 ] || { [ "$1" != "--imd2hfe" ] && [ "$1" != "--hfe2imd" ]; }; then
  sed -n '2,10p' "$0" >&2
  exit 1
fi
MODE="$1"; IN="$2"; OUT="$3"

# locate disk-analyse: PATH first, then the usual build location
DA=""
if command -v disk-analyse >/dev/null; then
  DA="disk-analyse"
elif [ -x "$O1DIR/disk-utilities/disk-analyse" ]; then
  DA="$O1DIR/disk-utilities/disk-analyse"
else
  cat >&2 <<EOF
error: disk-analyse not found (checked PATH and $O1DIR/disk-utilities)
Build it from https://github.com/keirf/disk-utilities :
  git clone https://github.com/keirf/disk-utilities.git
  cd disk-utilities && make clean && make && sudo make install
EOF
  exit 1
fi

[ -f "$IN" ] || { echo "error: no such input file: $IN" >&2; exit 1; }
case "$MODE" in
  --imd2hfe) [ "${IN##*.}" = "imd" ] || echo "warning: $IN does not have .imd extension" >&2;;
  --hfe2imd) [ "${IN##*.}" = "hfe" ] || echo "warning: $IN does not have .hfe extension" >&2;;
esac

"$DA" "$IN" "$OUT"
echo "diskette-converter: $IN -> $OUT"
