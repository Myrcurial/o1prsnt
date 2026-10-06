#!/bin/bash
# diskette-writer.sh -- build a bootable o1prsnt floppy image (.imd).
#
# Usage:
#   ./diskette-writer.sh [--autost] [--hdmi] [--strip] [--no-splash]
#                        [--src-image FILE] [--basic FILE] [--content FILE]
#                        [--out FILE]
#
# There is ONE stored BASIC master: src/O1PRSNT.BAS. Variants are generated
# on the fly from it (src/o1prsnt-hdmi.bas is no longer stored):
#
#   --hdmi       generate the HDMI-adapter variant: 21 display rows instead
#                of 22 (the 22nd row has overscan issues on composite->HDMI)
#   --autost     install autost.com so the presentation self-starts at boot,
#                AND generate the no-splash variant of the program (the
#                AUTOST.COM banner is already on screen -- no need to show
#                the splash twice)
#   --no-splash  generate the no-splash variant without installing autost
#   --strip      remove REM statements from the installed program (smaller
#                and faster to load; line numbers are preserved so MBASIC
#                error messages still map back to the master source)
#
#   --src-image  base floppy image containing MBASIC.COM
#                (default: ~/Documents/Osborne1/floppies/mbasic.imd,
#                 fallback: <repo>/assets/disks/mbasic.imd)
#   --basic FILE master BASIC source (default: <repo>/src/O1PRSNT.BAS)
#   --content FILE slide content (default: <repo>/examples/CONTENT.TXT)
#   --out FILE   output image (default: ~/Documents/Osborne1/floppies/o1prsnt.imd)
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
STRIP=0
NOSPLASH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --autost)    AUTOST=1; shift;;
    --hdmi)      HDMI=1; shift;;
    --strip)     STRIP=1; shift;;
    --no-splash) NOSPLASH=1; shift;;
    --src-image) SRC_IMAGE="$2"; shift 2;;
    --basic)     BASIC_FILE="$2"; shift 2;;
    --content)   CONTENT_FILE="$2"; shift 2;;
    --out)       OUT="$2"; shift 2;;
    -h|--help)   sed -n '2,34p' "$0"; exit 0;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1;;
  esac
done

# --autost implies the no-splash program variant (AUTOST shows the banner)
[ "$AUTOST" -eq 1 ] && NOSPLASH=1

[ -z "$BASIC_FILE" ] && BASIC_FILE="$REPO_ROOT/src/O1PRSNT.BAS"
if [ -z "$SRC_IMAGE" ]; then
  for c in "$O1DIR/floppies/mbasic.imd" "$REPO_ROOT/assets/disks/mbasic.imd"; do
    [ -f "$c" ] && SRC_IMAGE="$c" && break
  done
fi

for t in cpmcp cpmrm cpmls python3; do
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

file "$BASIC_FILE"   | grep -q CRLF || { echo "error: $BASIC_FILE is not CRLF line-terminated (MBASIC requirement)" >&2; exit 1; }
file "$CONTENT_FILE" | grep -q CRLF || echo "warning: $CONTENT_FILE is not CRLF; MBASIC may misread it (run presentation-validator.sh first)" >&2

WORK="$(mktemp -d /tmp/o1writer.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# --- generate the BASIC variant from the single stored master -------------------
GEN="$WORK/O1PRSNT.BAS"
GENFLAGS=()
[ "$HDMI" -eq 1 ] && GENFLAGS+=(--hdmi)
[ "$NOSPLASH" -eq 1 ] && GENFLAGS+=(--no-splash)
[ "$STRIP" -eq 1 ] && GENFLAGS+=(--strip)

python3 - "$BASIC_FILE" "$GEN" ${GENFLAGS[@]+"${GENFLAGS[@]}"} << 'PYEOF'
import sys, re

src, dst = sys.argv[1], sys.argv[2]
flags = set(sys.argv[3:])
hdmi, nosplash, strip = '--hdmi' in flags, '--no-splash' in flags, '--strip' in flags

text = open(src, newline='').read()
lines = text.split('\r\n')
while lines and lines[-1] == '':
    lines.pop()

def num(line):
    m = re.match(r'^(\d+)[\s]', line)
    return int(m.group(1)) if m else None

def find(n):
    for i, l in enumerate(lines):
        if num(l) == n:
            return i
    raise SystemExit(f'error: line {n} not found in {src} -- master has drifted, update the generator')

def replace_exact(old, new):
    for i, l in enumerate(lines):
        if l == old:
            lines[i] = new
            return
    raise SystemExit('error: anchor not found (master has drifted): ' + old[:60])

def check_jumps():
    numset = {num(l) for l in lines if num(l) is not None}
    targets = {int(m.group(1)) for l in lines for m in re.finditer(r'\b(?:GOTO|GOSUB)\s+(\d+)', l)}
    missing = sorted(targets - numset)
    if missing:
        raise SystemExit(f'error: variant would have dangling jump targets: {missing}')

if hdmi:
    # replicate the HDMI variant exactly (verified byte-identical to the
    # formerly stored src/o1prsnt-hdmi.bas)
    i = find(108)
    lines[i+1:i+1] = [
        "109 REM this is 52 characters, you'll want it",
        '110 REM 1234567890123456789012345678901234567890123456789012',
        '111 REM',
    ]
    replace_exact('333 PRINT "               Press any key to start presentation";',
                  '333 PRINT " "')
    replace_exact('334 PRINT " "',
                  '334 PRINT "               Press any key to start presentation";')
    replace_exact('435 FOR I% = 1 TO 22 : REM - Change this to 21 when using a composite to HDMI adapter',
                  '435 FOR I% = 1 TO 21')
    replace_exact('440   PRINT FSL$(I%) : REM - Now lightning fast as it formats an entire slide at once rather than the whole presentation',
                  '440   PRINT FSL$(I%) : REM  - Now lightning fast as it formats an entire slide at once rather than the whole presentation')
    replace_exact('460 REM These two or three lines are the footer - see line 471',
                  '460 REM These three lines are the footer')
    replace_exact('471 PRINT " " : REM - Remove this line if you\'re using a composite to HDMI adapter with overscan issues.',
                  '471 PRINT " "')
    print('variant: hdmi (21 display rows)')

if nosplash:
    # the splash is lines 310-335 (22 PRINTs + the INPUT$(1) wait); nothing
    # jumps into that range, and AUTOST has already shown the banner.
    first, last = find(310), find(335)
    if not lines[first].startswith('310 PRINT CHR$(26)'):
        raise SystemExit('error: splash block start moved; master drifted')
    if not lines[last].startswith('335 KEY$ = INPUT$(1)'):
        raise SystemExit('error: splash block end moved; master drifted')
    targets = {int(m.group(1)) for l in lines for m in re.finditer(r'\b(?:GOTO|GOSUB)\s+(\d+)', l)}
    doomed = {n for n in (num(l) for l in lines[first:last+1]) if n is not None}
    if targets & doomed:
        raise SystemExit(f'error: splash lines {sorted(targets & doomed)} are jump targets')
    del lines[first:last+1]
    print('variant: no-splash (lines 310-335 removed)')

if strip:
    targets = {int(m.group(1)) for l in lines for m in re.finditer(r'\b(?:GOTO|GOSUB)\s+(\d+)', l)}
    before = sum(len(l) + 2 for l in lines)
    out, removed, trimmed = [], 0, 0
    for l in lines:
        n = num(l)
        if n is not None and re.match(r'^\d+\s+REM(\s.*)?$', l):
            if n == 9999 or n in targets:
                out.append(l)   # keep the file-format sentinel and any jump targets
            else:
                removed += 1
            continue
        # strip a trailing ': REM ...' outside of string literals
        instr, cut = False, -1
        for i, ch in enumerate(l):
            if ch == '"':
                instr = not instr
            elif ch == ':' and not instr and re.match(r'\s*REM', l[i+1:]):
                cut = i
                break
        if cut >= 0 and not re.match(r'^\d+\s*$', l[:cut]):
            out.append(l[:cut].rstrip())
            trimmed += 1
        else:
            out.append(l)
    lines = out
    after = sum(len(l) + 2 for l in lines)
    print(f'variant: stripped ({removed} REM lines removed, {trimmed} trailing REMs trimmed, {before} -> {after} bytes)')

check_jumps()
with open(dst, 'w', newline='') as f:
    f.write('\r\n'.join(lines) + '\r\n')
PYEOF

# --- build the image -------------------------------------------------------------
mkdir -p "$(dirname "$OUT")"
cp "$SRC_IMAGE" "$OUT"
for f in O1PRSNT.BAS CONTENT.TXT AUTOST.COM; do
  cpmrm -f osborne1 "$OUT" "0:$f" 2>/dev/null || true
done
cpmcp -f osborne1 "$OUT" "$GEN" 0:O1PRSNT.BAS
cpmcp -f osborne1 "$OUT" "$CONTENT_FILE" 0:CONTENT.TXT
if [ "$AUTOST" -eq 1 ]; then
  cpmcp -f osborne1 "$OUT" "$AUTOST_FILE" 0:AUTOST.COM
fi

echo "diskette-writer: wrote $OUT"
echo "  master  : $BASIC_FILE"
echo "  content : $CONTENT_FILE"
echo "  autost  : $([ "$AUTOST" -eq 1 ] && echo "$AUTOST_FILE" || echo 'not installed')"
echo
echo "image contents:"
cpmls -f osborne1 "$OUT"
