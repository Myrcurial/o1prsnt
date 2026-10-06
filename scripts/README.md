# scripts/

Development and build tooling for the o1prsnt project. Everything here runs on the host Mac (macOS + Homebrew); none of it goes onto the Osborne 1 itself.

| Script | What it does |
|---|---|
| `validate-emulator.sh` | Checks that this Mac is ready for Osborne 1 emulation and development — MAME, cpmtools, ROMs, and (optionally) disk-analyse for HFE↔IMD conversion. No arguments; prints a pass/fail checklist. |
| `build-autost.sh` | Assembles `autost.asm` into `src/autost.com` using the authentic CP/M toolchain (ASM.COM + LOAD.COM) running on the emulated Osborne 1, then boot-tests the result. |
| `diskette-writer.sh` | Builds a bootable o1prsnt floppy image (`.imd`) from a source MBASIC image, the master BASIC program, and a `CONTENT.TXT` slide deck. Generates program variants on the fly (`--hdmi`, `--no-splash`, `--strip`) and optionally installs `autost.com`. |
| `presentation-validator.sh` | Validates a slide source file against the rules the MBASIC parser actually enforces (positional line numbers, format codes, row/column limits), then writes it out as a CRLF `CONTENT.TXT` suitable for a CP/M diskette. |
| `diskette-converter.sh` | Converts Osborne 1 floppy images between the MAME emulator format (`.imd`) and the hardware floppy-emulator format (`.hfe`). Thin wrapper around `disk-analyse`. |
| `autost.asm` | 8080 assembler source for the AUTOST.COM boot stub — displays the splash banner and chain-loads `MBASIC O1PRSNT.BAS` at cold boot. Built by `build-autost.sh`. |

---

## `build-autost.sh`

```
./build-autost.sh [--asm-src FILE] [--system-image FILE] [--out FILE]
                  [--test-image FILE] [--skip-test]
```

| Flag | Default | Purpose |
|---|---|---|
| `--asm-src` | `scripts/autost.asm` | Assembler source to build |
| `--system-image` | `~/Documents/Osborne1/floppies/cpm-system.imd` | CP/M system disk containing `ASM.COM` and `LOAD.COM` |
| `--out` | `src/autost.com` | Where to write the built binary |
| `--test-image` | `~/Documents/Osborne1/floppies/o1prsnt.imd`, else `assets/disks/o1prsnt.imd` | Image to boot-test the new `autost.com` against |
| `--skip-test` | off | Skip the boot verification pass |

## `diskette-writer.sh`

```
./diskette-writer.sh [--autost] [--hdmi] [--hdmi-note] [--strip] [--no-splash]
                     [--src-image FILE] [--basic FILE] [--content FILE]
                     [--out FILE]
```

| Flag | Default | Purpose |
|---|---|---|
| `--autost` | off | Install `autost.com` so the presentation self-starts at boot; implies `--no-splash` |
| `--hdmi` | off | Generate the HDMI-adapter variant: 21 display rows instead of 22, content re-rowed one line lower, build fails if any slide would exceed row 21 |
| `--hdmi-note` | off | With `--hdmi`: instead of failing on an over-long slide, truncate the overflow (max 3 lines) and append a note slide at rows 17–21 in the rightmost 40 columns explaining the 21-line HDMI limit |
| `--strip` | off | Remove `REM` statements from the installed program (smaller and faster to load) |
| `--no-splash` | off | Generate the no-splash variant without installing `autost` |
| `--src-image` | `~/Documents/Osborne1/floppies/mbasic.imd`, else `assets/disks/mbasic.imd` | Base floppy image containing `MBASIC.COM` |
| `--basic` | `src/O1PRSNT.BAS` | Master BASIC source |
| `--content` | `examples/CONTENT.TXT` | Slide content |
| `--out` | `~/Documents/Osborne1/floppies/o1prsnt.imd` | Output image |

## `presentation-validator.sh`

```
./presentation-validator.sh SOURCE DEST
```

- `SOURCE` — your presentation text (LF or CRLF)
- `DEST` — output file, written with CRLF line endings (e.g. `CONTENT.TXT`)

Exit status: `0` = valid (warnings allowed), `1` = errors found (`DEST` not written).

## `diskette-converter.sh`

```
./diskette-converter.sh --imd2hfe INPUT.imd OUTPUT.hfe
./diskette-converter.sh --hfe2imd INPUT.hfe OUTPUT.imd
```

## `validate-emulator.sh`

```
./validate-emulator.sh
```

No arguments. Prints a checklist of required and optional tools and confirms the Osborne 1 ROMs are in place.