#!/bin/bash
# diskette-writer.sh -- build a bootable o1prsnt floppy image (.imd).
#
# Usage:
#   ./diskette-writer.sh [--autost] [--hdmi]
#                        [--src-image FILE] [--basic FILE] [--content FILE]
#                        [--out FILE]
#
# Options:
#   --autost       also install autost.com so the presentation self-starts at
#                  boot (default source: <repo>/src/autost.com)
#   --hdmi         install the HDMI-adapter BASIC variant
#                  (src/o1prsnt-hdmi.bas) as O1PRSNT.BAS
#   --src-image    base floppy image containing MBASIC.COM
#                  (default: ~/Documents/Osborne1/floppies/mbasic.imd,
#                   fallback: <repo>/assets/disks/mbasic.imd)
#   --basic FILE   BASIC program to install (default: <repo>/src/O1PRSNT.BAS)
#   --content FILE slide content to install (default: <repo>/examples/CONTENT.TXT)
#   --out FILE     output image (default: ~/Documents/Osborne1/floppies/o1prsnt.imd)
#
# The output image is a FRESH copy of the source image with O1PRSNT.BAS,
# CONTENT.TXT and optionally AUTOST.COM replaced/added. Requires cpmtools.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
O1DIR="${O1DIR:-$HOME/Documents/Osborne1}"
SRC_IMAGE=""
BASIC_FILE=""
CONTENT_FILE="$REPO_ROOT/examples/CONTENT.TXT"
OUT="$O1DIR/floppies/o1prsnt.imd"
AUTOST=0
HDMI=0

while [ $# -gt 0 ]; do
  case "$1" in
    --autost)    AUTOST=1; shift;;
    --hdmi)      HDMI=1; shift;;
    --src-image) SRC_IMAGE="$2"; shift 2;;
    --basic)     BASIC_FILE="$2"; shift 2;;
    --content)   CONTENT_FILE="$2"; shift 2;;
    --out)       OUT="$2"; shift 2;;
    -h|--help)   sed -n '2,24p' "$0"; exit 0;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1;;
  esac
done

[ "$HDMI" -eq 1 ] && [ -z "$BASIC_FILE" ] && BASIC_FILE="$REPO_ROOT/src/o1prsnt-hdmi.bas"
[ -z "$BASIC_FILE" ] && BASIC_FILE="$REPO_ROOT/src/O1PRSNT.BAS"
if [ -z "$SRC_IMAGE" ]; then
  for c in "$O1DIR/floppies/mbasic.imd" "$REPO_ROOT/assets/disks/mbasic.imd"; do
    [ -f "$c" ] && SRC_IMAGE="$c" && break
  done
fi

# --- prerequisites --------------------------------------------------------------
for t in cpmcp cpmrm cpmls; do
  command -v "$t" >/dev/null || { echo "error: $t not found (brew install cpmtools)" >&2; exit 1; }
done
[ -f "$SRC_IMAGE" ]    || { echo "error: no source image (looked for mbasic.imd; use --src-image)" >&2; exit 1; }
[ -f "$BASIC_FILE" ]   || { echo "error: no BASIC file: $BASIC_FILE" >&2; exit 1; }
[ -f "$CONTENT_FILE" ] || { echo "error: no content file: $CONTENT_FILE" >&2; exit 1; }
AUTOST_FILE="$REPO_ROOT/src/autost.com"
if [ "$AUTOST" -eq 1 ] && [ ! -f "$AUTOST_FILE" ]; then
  echo "error: --autost needs $AUTOST_FILE (build it with scripts/build-autost.sh)" >&2
  exit 1
fi
cpmls -f osborne1 "$SRC_IMAGE" | grep -q "mbasic.com" || {
  echo "error: $SRC_IMAGE does not contain mbasic.com" >&2; exit 1; }

# MBASIC needs CRLF text
file "$BASIC_FILE"   | grep -q CRLF || { echo "error: $BASIC_FILE is not CRLF line-terminated (MBASIC requirement)" >&2; exit 1; }
file "$CONTENT_FILE" | grep -q CRLF || echo "warning: $CONTENT_FILE is not CRLF; MBASIC may misread it (run presentation-validator.sh first)" >&2

# --- build the image --------------------------------------------------------------
mkdir -p "$(dirname "$OUT")"
cp "$SRC_IMAGE" "$OUT"
for f in O1PRSNT.BAS CONTENT.TXT AUTOST.COM; do
  cpmrm -f osborne1 "$OUT" "0:$f" 2>/dev/null || true
done
cpmcp -f osborne1 "$OUT" "$BASIC_FILE" 0:O1PRSNT.BAS
cpmcp -f osborne1 "$OUT" "$CONTENT_FILE" 0:CONTENT.TXT
if [ "$AUTOST" -eq 1 ]; then
  cpmcp -f osborne1 "$OUT" "$AUTOST_FILE" 0:AUTOST.COM
fi

echo "diskette-writer: wrote $OUT"
echo "  program : $BASIC_FILE ($([ "$HDMI" -eq 1 ] && echo hdmi || echo standard))"
echo "  content : $CONTENT_FILE"
echo "  autost  : $([ "$AUTOST" -eq 1 ] && echo "$AUTOST_FILE" || echo 'not installed')"
echo
echo "image contents:"
cpmls -f osborne1 "$OUT"
