# Headless Testing Harness for the Osborne 1

Drive and observe an emulated Osborne 1 from Lua scripts -- no display, no
keyboard, fully scriptable. Built for testing `o1prsnt`, but usable for any
CP/M-era Osborne 1 software.

The harness is a small Lua library (`o1harness.lua`) that MAME runs via its
`-autoboot_script` option. It gives you two superpowers:

- **Keyboard injection** through MAME's "natural keyboard" device
- **Screen reading** straight from video RAM (`0xF000`, 128 bytes/row), so you
  can assert on what the machine is *displaying*, not what you hope it is doing

## Prerequisites

- macOS with Homebrew
- `brew install mame`
- Osborne 1 ROMs in `~/Documents/Osborne1/roms/` (either as `osborne1.zip` or
  an `osborne1/` directory; see `docs/emulating-the-osborne-1.md`)
- A bootable CP/M floppy image (`.imd`) to test with

## Running a test

```bash
./run-test.sh examples/countdown-timer.lua ~/Documents/Osborne1/floppies/o1prsnt.imd 240
```

`run-test.sh` concatenates `o1harness.lua` with your test file and launches:

```
SDL_VIDEODRIVER=dummy mame osborne1 -flop1 IMAGE -video none -sound none \
  -nothrottle -autoboot_script RUN.lua -seconds_to_run BUDGET -rompath ROMS
```

What the flags do and why:

| Flag | Why |
|---|---|
| `SDL_VIDEODRIVER=dummy` | SDL cannot init video from a pure terminal session on macOS; without this MAME aborts with "Could not initialize SDL". |
| `-video none -sound none` | No window, no audio. The emulated screen still renders into VRAM, which is all we read. |
| `-nothrottle` | Run the 4 MHz Z80 as fast as the host allows (~20-25x here). Timing inside the emulation is unaffected -- `-seconds_to_run` and `emu.wait()` count *emulated* seconds. |
| `-seconds_to_run N` | Hard stop after N emulated seconds. Make it generous; a well-behaved test calls `os.exit(0)` long before. (Letting MAME hit the budget often ends in a harmless macOS teardown segfault.) |
| `-autoboot_script` | Runs your Lua after machine start, with `emu.wait()` available. |

Set `O1_ROMPATH` if your ROMs live somewhere other than `~/Documents/Osborne1/roms`.

## Writing a test

Start from this skeleton:

```lua
H.boot_cpm() or H.finish(1)          -- presses RETURN at the BIOS prompt, waits for A>

H.type_line("mbasic o1prsnt")        -- CCP uppercases the command tail for you
H.wait_for("Press any key", 90)      -- MBASIC load + indexing takes a while
H.send("x")                          -- dismiss the splash screen

H.wait_for("1 / 5", 20)              -- footer of slide 1 visible
H.send("N")                          -- next slide
H.wait_for("2 / 5", 20)              -- slide 2 visible
H.dump("slide 2")                    -- print all non-blank screen rows

H.finish(0)                          -- clean exit
```

### Library reference

| Function | Purpose |
|---|---|
| `H.boot_cpm()` | RETURN at the "Insert disk..." BIOS prompt, wait for `A>`. |
| `H.run_mbasic(name)` | Type `mbasic NAME` at the prompt. |
| `H.type_line(text)` | Post text + CR, paced to not outrun the guest keyboard. |
| `H.send(text)` | Raw keyboard post (no CR). For single-key navigation. |
| `H.wait_for(pat, timeout)` | Poll the screen until `pat` (plain text) appears. Dumps the screen on timeout. |
| `H.find(pat)` | Boolean: is `pat` anywhere in video RAM right now? |
| `H.dump(tag)` | Print all non-blank screen rows with row numbers. |
| `H.screen_text()` | Whole VRAM buffer as one string (32 rows x 128 cols). |
| `H.ok_count()` / `H.wait_new_ok(prev, timeout)` | Fresh-`Ok` detection for MBASIC direct mode (see gotchas). |
| `H.time()` | Emulated seconds since boot -- use for timing measurements. |
| `H.finish(code)` | `os.exit` -- avoids MAME's messy headless teardown. |
| `H.space` | CPU program space; `H.space:read_u8(addr)` reads guest memory. |

Constants for hardware poking: `H.VRAM_BASE`, `H.VRAM_STRIDE`,
`H.ACIA_STATUS` (DCD/CTS foot-switch bits), `H.BEEPER_PORT`.

## Gotchas (learned the hard way)

These cost real debugging time. Respect them and your tests will be solid:

1. **Never send keys into disk I/O.** MBASIC flushes the console input buffer
   around program LOADs, so keystrokes posted while a program loads or indexes
   files simply vanish. Always `wait_for` the expected prompt/banner first.
   (Symptom: you typed five keys, the program saw none or one.)

2. **Pace your typing.** `natkeyboard:post()` drops characters when a second
   post arrives while the first is still being typed. `H.type_line()` waits
   ~0.15s/character; for anything critical, verify via the command's echo or
   MBASIC's `list` output before relying on it.

3. **Stale `Ok` prompts.** MBASIC direct mode prints `Ok` after every command
   and old ones stay on screen (and scroll). `wait_for("Ok")` can match a
   leftover. Use `H.ok_count()` before the command and `H.wait_new_ok(prev)`
   after.

4. **MBASIC `LOAD"name.bas"` is case-sensitive** (the file must be upper case:
   `LOAD"O1PRSNT.BAS"`), but the CP/M command line is not (the CCP uppercases
   the command tail, so `mbasic o1prsnt` works fine).

5. **Video RAM is a ring buffer.** The Osborne 1 scrolls by rotating a hardware
   start register, not by moving memory, so after any scroll the VRAM row of a
   given screen line shifts. Write assertions as full-buffer substring searches,
   not fixed-row reads. (See DISCOVERY.md for how this bit us.)

6. **`emu.wait()` uses emulated seconds.** With `-nothrottle`, 240 emulated
   seconds complete in ~10 real seconds. All timing measurements you take with
   `H.time()` are valid 4 MHz Z80 timings and transfer to real hardware.

## Directory layout

```
headless-testing-harness/
  o1harness.lua                  the library (prepended to every test)
  run-test.sh                    runner: lib + test -> mame
  template.lua                   copy this to start a new test
  examples/
    countdown-timer.lua          end-to-end test of the 'T' timer slide
  DISCOVERY.md                   how the Osborne 1 interaction patterns
                                 were reverse-engineered (the fun part)
```
