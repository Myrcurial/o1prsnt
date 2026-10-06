# Discovery: how the Osborne 1 interaction patterns were learned

This documents how each piece of "tribal knowledge" baked into the harness was
actually discovered, so the next person can extend the techniques instead of
re-deriving them. Roughly in the order it happened.

## 1. The hardware truth lives in the MAME driver source

Question: does the Osborne 1 have a beeper, and how do you control the screen?

`src/mame/osborne/osborne1.cpp` in the MAME tree answered both:

- **Memory map** (from the driver's header comment): bank 2 holds I/O at
  `2A00-2A01` (serial ACIA), `2C00-2C03` (video PIA), etc. This confirmed the
  addresses the BASIC program already used (`PEEK/POKE 10752` = 0x2A00).
- **Beeper**: the driver instantiates a `SPEAKER` device, and
  `video_pia_port_b_w()` drives it from **bit 5 of the video PIA port B**
  (0x2C02 = decimal 11266), gated to be active 4 out of every 10 scanlines --
  which is what makes it an audible buzz rather than a DC level. The same
  register's low 5 bits are the vertical scroll offset, hence the
  `PEEK ... OR 32 / AND 223` dance to preserve them.

Lesson: when documentation is thin, the emulator *is* the documentation. MAME
drivers are written from schematics and ROM dumps, and cite them.

## 2. terminfo is a time machine

Question: what console control codes does the Osborne 1 BIOS understand?

`infocmp osborne1` on macOS returned a real terminfo entry:

```
clear=^Z, cup=\E=%p1%' '%+%c%p2%' '%+%c, ...
```

That single line confirmed: clear screen = `CHR$(26)` (already in use), and
cursor addressing = `ESC` `=` row col with row/col offset by 32 (space) --
the ADM-3A convention. Termcap/terminfo entries were written by people who
had the hardware manual in hand; for CP/M-era machines they are often the
most accessible surviving spec of console behaviour.

## 3. Seeing the screen without a screen: VRAM dumping

The first harness dump (`read_u8` over `0xF000-0xFFFF`, 128-byte stride,
printable chars only) immediately showed the BIOS banner:

```
r05|                   OSBORNE 1
r07|              Rev 1.44 (c) 1983 OCC
r11|    Insert disk in Drive A and press RETURN.
```

Three discoveries in one shot:

- **The layout**: 128-byte rows, character codes directly readable. The 9th
  bit per cell (attributes) lives in a separate bank and can be ignored for
  text testing.
- **The BIOS waits for RETURN** before booting CP/M. Any automated test must
  press it first.
- The machine was genuinely running our code headless.

## 4. What the boot disk actually does

Booting the real test floppy showed a directory listing ending in `A>` rather
than the presentation auto-starting: the stock `AUTOST.COM` on that image runs
XDIR, not MBASIC. So tests must type `mbasic o1prsnt` -- and the harness got
`H.run_mbasic()`. (Later this also motivated building a *custom* autost.com.)

## 5. The keyboard lies if you talk over it

Early scripted runs sent `mbasic o1prsnt\r` too early after boot and the
keystrokes were silently eaten (screen showed `A>mbxNNNN` -- fragments of
later posts). And keystrokes sent while MBASIC was still loading/indexing
vanished too (input buffer flush). Worse: re-posting while `natkeyboard` was
still typing dropped characters *mid-line*, which once turned a line of BASIC
into garbage that only surfaced as `Syntax error in 1`.

Pattern that emerged: **wait for the prompt, pace the typing, verify the
echo**. That is exactly what `wait_for`, `type_line`, and
`ok_count`/`wait_new_ok` encode.

Case-sensitivity asymmetry found the same way: `mbasic o1prsnt` works because
the CCP uppercases the command tail, but inside MBASIC, `LOAD"o1prsnt.bas"`
fails with `File not found` -- MBASIC passes the string to BDOS verbatim, and
the CP/M directory is upper case.

## 6. The VRAM is a ring buffer (the "walking countdown" bug)

The countdown timer's in-place update used `ESC=` to print a full 52-char line
every second. On hardware it "walked": one row, next row, back again. The
harness made it visible and measurable:

```
tick+1:  r07=0:10  r08=0:10
tick+5:  r08 -> 0:09      (r07 stale)
tick+8:  r09 -> 0:08
tick+11: r08 -> 0:07      (r09 stale)
```

Two defects, both confirmed by typing small isolated test programs into MBASIC
via the harness:

- **Row off-by-one**: with this BIOS (v1.44) in the program's post-footer
  scroll state, the byte that lands the cursor on the painted row is
  `30 + row`, not the ADM-3A textbook `31 + row`. The screen is a ring buffer
  with a hardware scroll register, so "absolute" cursor addressing is relative
  to the current window -- which is why harness assertions search the whole
  buffer instead of fixed rows.
- **The walk**: printing 52 characters fills the last column, which trips the
  console's auto-wrap state; the next cursor-addressed print then lands one
  row off. Printing a short fixed-width window (14 chars centred at column 19)
  never touches column 52 and is perfectly stable.

The generalised lesson: **replicate the failing output byte-stream in a small
typed program, dump VRAM between steps, and let the machine tell you the
rule.** Three short experiments replaced hours of manual-guessing.

## 7. Timing without a clock chip

The Osborne 1 has no RTC, so the countdown uses a calibrated delay loop.
The harness measured it: with `DL% = 300`, a "1 second" tick took ~3.2
emulated seconds (`emu.time()`), so the calibrated value is `DL% ~= 95`.
Because MAME runs the Z80 at its true 4 MHz even under `-nothrottle`, a value
calibrated in the emulator transfers to real hardware.

## 8. macOS headless specifics

- `SDL_VIDEODRIVER=dummy` is mandatory from a pure terminal session.
- Ending the script with `os.exit(0)` avoids a harmless but noisy MAME
  segfault during headless teardown.
- Windowed runs for humans: MAME forces fullscreen; LEFT Option + Return
  toggles out of it (see `docs/emulating-the-osborne-1.md`).

## References

- MAME osborne1 driver: https://github.com/mamedev/mame/blob/master/src/mame/osborne/osborne1.cpp
- Osborne 1 User's Reference Guide (bitsavers, linked in README)
- system terminfo entry for `osborne1` (`infocmp osborne1`)
