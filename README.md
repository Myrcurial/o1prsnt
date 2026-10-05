# o1prsnt - Osborne 1 Presentation Software

```
314 PRINT "    ____       __                                 "
315 PRINT "   / __ \_____/ /_  ____  _________  ___          "
316 PRINT "  / / / / ___/ __ \/ __ \/ ___/ __ \/ _ \         "
317 PRINT " / /_/ (__  ) /_/ / /_/ / /  / / / /  __/         "
318 PRINT " \____/____/_.___/\____/_/  /_/ /_/\___/          "
319 PRINT "    / __ \________  ________  ____  / /____  _____"
320 PRINT "   / /_/ / ___/ _ \/ ___/ _ \/ __ \/ __/ _ \/ ___/"
321 PRINT "  / ____/ /  /  __(__  )  __/ / / / /_/  __/ /    "
322 PRINT " /_/   /_/   \___/____/\___/_/ /_/\__/\___/_/     "
```


A backport of modern presentation software concepts to the Osborne 1 personal computer (1981). This project enables slide-based presentations on the original hardware, complete with smooth viewport transitions and remote control capabilities.

## Project Overview

This software was created for a presentation at **NaClCon** where one of the speakers was **Lee Felsenstein**, the original designer of the Osborne 1. It demonstrates that the concepts of modern presentation software can be implemented on 45-year-old hardware.

## Features

- **Slide-based presentation** with markdown-like authoring format
- **Keyboard navigation** (Space=next, B=back, R=restart)
- **Memory management** slide content is loaded from diskette while running, hundreds of slides possible
- **Auto-start capability** via AUTOST.COM
- **Slide counter** display (nn/yy format)

## Technical Specifications

- **Target Hardware**: Osborne 1 (OCC1) with Double Density diskette upgrade
- **Operating System**: CP/M 2.2
- **Language**: MBASIC (Microsoft BASIC)
- **Display**: 52×24 character resolution (standard), extension to 80x24 and 104x24 modes with appropriate display expansion support
- **Storage**: 5.25" floppy disk (double density, dual drives)

## Project Structure

```
o1prsnt/
├── src/                    # Source code (MBASIC programs)
├─scripts/                # Utility scripts for development
├── docs/                   # Documentation
├── config/                 # Configuration files
├── assets/
│   └── disks/             # Disk images (.IMD files)
├── examples/              # Sample presentation content
└── README.md              # This file
```


## Development

### Repository Workflow

This project uses a branch-based workflow:
- All work is done in feature branches
- Changes are merged via pull requests
- All commits are GPG-signed
- Main branch is protected

### Utilities

- **Slide Processor**: Converts markdown-like format to optimized text file
- **REM Stripper**: Removes REM statements to minimize memory usage
- **CP/M Tools Scripts**: Simplify file transfer to/from disk images

## Hardware Requirements

No requirements beyond standard Osborne 1 configuration are necessary. If using a composite to HDMI adapter, limit your slides to only 21 lines.

## Testing

- **Emulator**: Primary development on MAME with OCC1 ROM v1.44
- **Hardware**: Periodic testing on actual Osborne 1 hardware
- **File Format**: Hard CR line endings required for CP/M compatibility

## Known Limitations

- Maximum slides limited to available floppy diskette space
- Text-only content (no graphics)
- 52×22 character display limit (on un-expanded hardware) content per slide

## Contributing

This is a historical preservation project. If you have suggestions or improvements, please:

1. Create a feature branch
2. Test on both emulator and hardware if possible
3. Submit a pull request with detailed description
4. Ensure all commits are signed

## License

This project is released for educational and historical preservation purposes.

## Acknowledgments

- Adam Osborne, Lee Felsenstein, and the original Osborne 1 team for creating the first commercially available portable computer and inspiring a lot of GenX kids in an entire career
- Conference organizers for the opportunity to present on this historic platform (who else provides AC outlets and "extra boot up time")
- The retrocomputing community for maintaining emulators, documentation, access to software archives, and advice.

## Resources

- [Osborne 1 User's Reference Guide](https://bitsavers.trailing-edge.com/pdf/osborne/osborne1/Osborne_1_Users_Reference_Guide_1981.pdf)
- [Osborne 1 Technical Manual](docs/Osborne1_Technical_Manual.pdf)
- [Osborne 1 Field Service Manual](docs/Osborne1_Service_Manual.pdf)
- [CP/M Operating System Documentation](https://www.cpm.z80.de/)

## Contact

For questions or collaboration, please open an issue on GitHub.

---

*"The Osborne 1 was the first portable computer, and 45 years later, it can still deliver presentations!"*
