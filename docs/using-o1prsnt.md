# Quick Start

## Prerequisites

- MAME emulator with Osborne 1 configuration (ROM v1.44)
- CP/M tools installed (`cpmcp`, `cpmls`, `cpmrm`)
- MBASIC interpreter (included with Osborne 1)

## Running the Presentation

1. Download the latest release `.IMD` disk image -- or build your own with `../scripts/diskette-writer.sh` (validate your environment first with `../scripts/validate-emulator.sh`)
2. Load the disk image in your Osborne 1 emulator or transfer to physical media
3. Boot the Osborne 1 - optionally the presentation will auto-start via `AUTOST.COM`
4. Use keyboard controls:
   - **Advance to next slide**: N / n / <space> / <return>
   - **Go back to previous slide**: B / b
   - **Restart presentation**: R / r
   - **Quit presentation**: Q / q
   - **any number**: starts the "jump to slide" process

## Slide Format

The presentation source uses a simple markdown-like format. **Line numbers are positional** — the program reads them by absolute position in the file, so they cannot shift:

- **Lines 1–11** — header / comment block (skipped entirely by the program). Free text; `CONTENT.TXT` uses this space for its own usage notes and a 52-column ruler.
- **Line 12** — the presentation title. Truncated to the leftmost 40 characters and shown in the footer of every slide.
- **Line 13** — must be blank.
- **Line 14 onward** — the slides, each delimited by `---` on a line by itself:
  - the first line after an opening `---` is the slide's start row on screen (integer 1–22)
  - each content line's first character is a format code: `L` (left), `C` (centre), `R` (right), `I` (indent 4), `B` (bullet), or `T` (countdown timer, e.g. `T 0:10`)
  - content must fit the 52×22 window (start row + lines − 1 ≤ 22); lines longer than 52 characters are truncated
  - with the `--hdmi` build, content must fit rows 2–21 (21 lines max); see `scripts/diskette-writer.sh --hdmi-note`

## Countdown Timer Slides

A content line starting with `T` runs a countdown timer on that slide:

```
T 8:00
```

- The value is minutes:seconds (`T 8:00` = 8 minutes). A bare number (`T 5`) is treated as minutes.
- The remaining time is displayed centred on the screen row where the `T` line appears.
- The countdown starts as soon as the slide is displayed.
- Presenter controls (N/B/R/Q, jump-to-slide digits, and the DCD/CTS foot switch) stay live during the countdown and interrupt it.
- At 0:00 the Osborne 1 beeper sounds (~0.5s), the slide holds briefly, then the presentation advances automatically.
- One timer line per slide (if several are present, the last one wins). Minimum useful value is `0:01`.

### Calibrating the timer

The Osborne 1 has no real-time clock, so the countdown uses a calibrated delay
loop: line 155 of `src/O1PRSNT.BAS` sets `DL%`, the loop iterations per
nominal second.

**The correct value is machine-dependent — calibrate it on every machine you
present on.** MAME (osborne1, BIOS 1.44) ticks correctly at `DL% = 95`, but
real hardware runs the same loop at a different speed (on one machine a 1:00
countdown took 1:33, i.e. `DL%` ≈ 60), and the value may vary between
Osborne 1 hardware revisions.

Use the TICKCAL utility (`utilities/tickcal/TICKCAL.BAS`, see its README):
it ticks once per loop with a bell and a flashing block. Nudge with `n`/`b`
(±1) or `N`/`B` (±10) until the tick matches a real seconds hand, quit with
`q`, and copy the printed value into line 155. TICKCAL's delay loop performs
the same per-iteration work as the countdown loop in O1PRSNT.BAS, so the
calibrated value transfers directly.

### If the countdown row displays in the wrong place

By default (`CA% = 1`, line 157) the countdown digits are written directly to
video memory (0xF000), which is exact and flicker-free on any display path.
If you ever see a stale or doubled countdown, set `CA% = 0`: the whole slide
repaints once per second instead (expect a brief blink each second in this
mode).
   