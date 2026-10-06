#!/bin/bash
# presentation-validator.sh -- validate an o1prsnt slide source file against
# the rules the MBASIC program (src/O1PRSNT.BAS) actually parses, then write
# it out as a CRLF file (CONTENT.TXT) suitable for a CP/M diskette image.
#
# Usage:
#   ./presentation-validator.sh SOURCE DEST
#
#   SOURCE   your presentation text (LF or CRLF, e.g. a markdown-like draft)
#   DEST     output file, written with CRLF line endings (e.g. CONTENT.TXT)
#
# Exit status: 0 = valid (warnings allowed), 1 = errors found (DEST not written).
#
# Rules checked (mirroring the parser):
#   - line 12 is the presentation title (>40 chars is truncated by the program)
#   - slides are delimited by '---' on a line by itself, in pairs
#   - first line after an opening '---' is the start row (integer 1-22)
#   - content lines: first char is a format code L C R I B or T, then a space
#   - 'T MM:SS' (or bare 'T M') = countdown timer line; one per slide
#   - content must fit rows (start row + lines - 1 <= 22) and 52 columns

set -uo pipefail

[ $# -eq 2 ] || { sed -n '2,20p' "$0" >&2; exit 1; }
SRC="$1"; DST="$2"
[ -f "$SRC" ] || { echo "error: no such source file: $SRC" >&2; exit 1; }

python3 - "$SRC" "$DST" <<'PYEOF'
import sys, re

src, dst = sys.argv[1], sys.argv[2]
raw = open(src, 'rb').read()
if b'\0' in raw:
    print("error: NUL byte in source file"); sys.exit(1)
crlf_in = b'\r\n' in raw
text = raw.decode('ascii', errors='replace')
# normalise to LF for analysis
lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
if lines and lines[-1] == '':
    lines.pop()

errors, warnings = [], []

def err(msg):  errors.append(msg)
def warn(msg): warnings.append(msg)

# --- header / title ------------------------------------------------------------
if len(lines) < 13:
    err(f"file has {len(lines)} lines; the program skips 11 header lines and "
        f"reads the title from line 12 -- need at least 13 lines")
else:
    title = lines[11]
    if len(title) > 40:
        warn(f"line 12 title is {len(title)} chars; program truncates to 40: "
             f"'{title[:40]}'")

# --- slide structure -------------------------------------------------------------
seps = [i for i, l in enumerate(lines) if l == '---']
if not seps:
    err("no '---' slide separators found")
if len(seps) % 2 != 0:
    err(f"odd number of '---' separators ({len(seps)}); slides must start AND end with ---")

codes = set('LCRIBT')
slide_no = 0
i = 0
n = len(lines)
while i < n:
    if lines[i] != '---':
        i += 1
        continue
    # opening separator
    slide_no += 1
    if i + 1 >= n:
        err(f"slide {slide_no}: missing start-row line after '---' (line {i+1})")
        break
    fl_line = lines[i + 1]
    m = re.match(r'^\s*(\d+)', fl_line)
    if not m:
        err(f"slide {slide_no}: start-row line '{fl_line}' is not a number")
        fl = 1
    else:
        fl = int(m.group(1))
        if not 1 <= fl <= 22:
            err(f"slide {slide_no}: start row {fl} out of range 1-22")
    # content until closing separator
    j = i + 2
    content = []
    while j < n and lines[j] != '---':
        content.append((j + 1, lines[j]))
        j += 1
    if j >= n:
        err(f"slide {slide_no}: no closing '---'")
        break
    # validate content lines
    timers = 0
    for lno, cl in content:
        if len(cl) > 255:
            err(f"slide {slide_no} line {lno}: longer than 255 chars (MBASIC line limit)")
        if len(cl) > 52:
            warn(f"slide {slide_no} line {lno}: {len(cl)} chars > 52, will be truncated")
        if len(cl) < 2:
            continue  # blank-ish line, program renders empty
        c1 = cl[0]
        if c1 not in codes:
            err(f"slide {slide_no} line {lno}: unknown format code '{c1}' "
                f"(expected one of L C R I B T; lowercase is NOT recognised)")
        elif len(cl) > 1 and cl[1] != ' ':
            err(f"slide {slide_no} line {lno}: code '{c1}' must be followed by a space "
                f"(the program drops the second character)")
        if c1 == 'T' and len(cl) > 1:
            timers += 1
            tm = re.match(r'^T (\d+)(?::([0-9]{1,2}))?$', cl)
            if not tm:
                err(f"slide {slide_no} line {lno}: malformed timer '{cl}' "
                    f"(want 'T MM:SS' or bare minutes 'T M')")
            else:
                mm = int(tm.group(1)); ss = int(tm.group(2) or 0)
                if ss >= 60:
                    err(f"slide {slide_no} line {lno}: seconds {ss} >= 60")
                if mm * 60 + ss < 1:
                    err(f"slide {slide_no} line {lno}: timer must be at least 0:01")
                if mm > 99:
                    warn(f"slide {slide_no} line {lno}: {mm} minutes is a long countdown...")
    if timers > 1:
        warn(f"slide {slide_no}: {timers} timer lines; the program uses the LAST one")
    last_row = fl + len(content) - 1
    if last_row > 22:
        warn(f"slide {slide_no}: content reaches row {last_row}; rows past 22 are "
             f"never displayed")
    if not content:
        warn(f"slide {slide_no}: no content lines")
    i = j + 1

print(f"slides: {slide_no}")
print(f"input line endings: {'CRLF' if crlf_in else 'LF'} (output will be CRLF)")
for w in warnings: print("warning:", w)
for e in errors:   print("error:", e)
if errors:
    print(f"INVALID: {len(errors)} error(s), {len(warnings)} warning(s); {dst} not written")
    sys.exit(1)

# --- write CRLF output -------------------------------------------------------------
with open(dst, 'wb') as f:
    f.write(('\r\n'.join(lines) + '\r\n').encode('ascii'))
print(f"OK: wrote {dst} ({len(lines)} lines, CRLF, {len(warnings)} warning(s))")
PYEOF
