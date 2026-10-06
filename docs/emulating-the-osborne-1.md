# Using the Osborne 1 Emulator on macOS

## Install MAME

MAME is easiest to install if you just use homebrew

```
brew install mame
```
You'll need ROMs -- you can get them here: https://archive.org/details/osborne-1-roms
   - occ-7a3007-00-reva.rom
   - occ-v1.44.rom

Keep the ROM files in a zip archive named `osborne1.zip` inside the `roms` folder -- MAME loads machine ROMs from `<rompath>/<machine>.zip`, so the final location should be `~/Documents/Osborne1/roms/osborne1.zip`.

## Install Floppy Diskette Tools

To work with diskette images, I've settled on these two tools `cpmtools` and `disk-analyse` - mostly because I want to actually go back and forth between the kind of floppy image that MAME likes (IMD) and the kind of floppy image that works with my physical floppy diskette emulator (HFE).

```
brew install cpmtools
```

You're going to need the `disk-analyse` program from [Keirf's Disk Utilities](https://github.com/keirf/disk-utilities) and you're going to have to compile it... so make sure you've got the XCode Command Line Utilities installed. 

grab the [source tree](https://github.com/keirf/disk-utilities.git) and unzip it - from that directory:

```
make clean
make
sudo make install
```

## Your Osborne 1 Emulator Root Directory Structure

I like to use a stable directory structure because when you launch MAME from strange places, it creates default directories and files and just makes a mess. I've settled on: 

```
~/Documents
   |-Osborne1
   |   |-floppies
   |   |-o1prsnt
   |   |-presentations
   |   \-roms
```

that way, the stable commands are easy to copy and paste

## File Handling

copying a file onto the emulator floppy image (IMD)

`cpmcp -f osborne1 ~/Documents/Osborne1/floppies/o1prsnt.imd ~/Documents/Osborne1/presentations/mypresentation.txt 0:CONTENT.TXT`

removing a file from the emulator floppy image (IMD)

`cpmrm -f osborne1 ~/Documents/Osborne1/floppies/o1prsnt.imd 0:CONTENT.TXT`

listing the contents of the emulator floppy image (IMD)

`cpmls -f osborne1 ~/Documents/Osborne1/floppies/o1prsnt.imd`

converting an emulator floppy image (IMD) to a hardware floppy emulator image (HFE)

`disk-analyse ~/Documents/Osborne1/floppies/o1prsnt.imd ~/Documents/Osborne1/floppies/o1prsnt.hfe`

converting a hardware floppy emulator image (HFE) to an emulator floppy image (IMD)

`disk-analyse ~/Documents/Osborne1/floppies/o1prsnt.hfe ~/Documents/Osborne1/floppies/o1prsnt.imd`

## Launching MAME

`cd ~/Documents/Osborne1; mame osborne1 -flop1 ~/Documents/Osborne1/floppies/o1prsnt.imd`

## MAME weirdnesses... 

MAME puts itself into full screen mode whenever it launches. To get out of the full screen, use the LEFT Option key and Return. Once you've done that, hit the red circle to quit - the Cmd-Q is not honoured (despite what it says!)
