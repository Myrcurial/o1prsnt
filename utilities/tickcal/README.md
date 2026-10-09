# TICKCAL — countdown tick calibration

`TICKCAL.BAS` is a tiny standalone MBASIC tool for calibrating `DL%`, the
delay-loop count that sets the countdown tick rate in `src/O1PRSNT.BAS`
(line 155).

## Why it exists

The countdown tick is a calibrated busy-wait, and its speed depends on the
machine: MAME running the Osborne 1 BIOS 1.44 ticks correctly around
`DL% = 95`, but real Osborne 1 hardware runs the same loop roughly 1.5x
slower (closer to `DL% = 60`). Rather than staring at a full-length
countdown with a stopwatch, run TICKCAL: it ticks once per "second" with
an audible bell and a flashing block, and you nudge the rate until it
matches a real seconds hand.

## Running it

Put `TICKCAL.BAS` on any bootable MBASIC diskette (or the ready-made
`tickcal.imd`), boot CP/M, then:

```
A>mbasic tickcal
```

## Controls

| Key | Effect |
|---|---|
| `n` | faster — `DL% - 1` |
| `N` | faster — `DL% - 10` |
| `b` | slower — `DL% + 1` |
| `B` | slower — `DL% + 10` |
| `q` | quit; prints the calibrated `DL%` |

The current `DL%` and tick count update on screen continuously (written
straight to video RAM, so no flicker).

## Important: the loop mirrors the real program

The delay loop in TICKCAL does exactly the same work per iteration as the
countdown loop in `O1PRSNT.BAS` (`INKEY$` plus an ACIA `PEEK`), so the
`DL%` you dial in here transfers directly to line 155 of the master
source. If you ever change the body of that countdown loop, change this
one to match.

## Known calibration points

| Machine | DL% |
|---|---|
| MAME osborne1 (BIOS 1.44), this repo's test harness | 95 |
| Real Osborne 1 hardware | ~60 (fine-tune ±3) |
