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

The presentation source uses a simple markdown-like format:
   - you must stay inside the constraint of 52x22 (or 80x22 / 104x22 if using the expanded modes) for content, lines longer will be truncated
   - each slide starts and ends with "---" on a line by itself
   - the first line of each slide contains the first on screen line to be utilized (skip until)
   - the first character of each line is justification (L,C,R), indent (I), bullet (B), or countdown timer (T)
   
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

The Osborne 1 has no real-time clock, so the countdown uses a calibrated delay loop.
Line 155 of `src/O1PRSNT.BAS` sets `DL%`, the loop count per second (initial guess 300).

To calibrate: add a test slide with `T 1:00`, time it with a stopwatch from the moment
the slide appears until the beep, then compute `DL% = 300 * 60 / measured_seconds`
and update line 155. MAME runs the Z80 at the true 4 MHz, so a value calibrated in
the emulator transfers to real hardware.

### If the countdown row displays in the wrong place

The in-place update uses the Osborne 1 console cursor-addressing sequence
(`ESC` `=` row column). If your display path (e.g. some composite/HDMI adapters)
misplaces the countdown, set `CA% = 0` on line 157: the whole slide will repaint
once per second instead (expect a brief blink each second in this mode).
   