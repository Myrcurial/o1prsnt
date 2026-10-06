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
   - the first character of each line is justification (L,C,R), or indent (I), or bullet (B)
   