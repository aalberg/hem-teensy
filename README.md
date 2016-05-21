# hem-teensy
Hardware enhanced melee using a teensy 3.x and python 2.7.

Game state data can be streamed from the console to a computer in real time.

Created by [Alex Alberg](https://github.com/aalberg), based on prior work by [JLaferri](https://github.com/JLaferri)

## Parts Required

* A teensy 3.1 or 3.2 ($20 from PJRC)
* A Uart<->Usb cable ($10 from Adafruit)
* A memory card breakout board (board files included in this repo)
* A breadboard or another way to prototype a circuit
* Some wires

Other helpful things:
* Headers (to solder to the breakout board)
* A few LEDs
* A few resistors
* The shell of a memory card (circuit board removed)

## Getting Started

### Setting up the Console

There are several methods of setting the console up to run the appropriate assembly code in the game.
The most straightforward method is to use the [gecko code](wii/hem_gecko.txt).
Guides for using gecko codes on a console already exist, so the process will not be documented here.

The second method is to create an .iso file with the assembly already injected into the game. See
[this Smashboards post](http://smashboards.com/threads/the-dol-mod-topic.326347/page-5#post-16623011) for more info.

### Setting up the Circuit
![Circuit diagram](images/circuit.png)

The above image shows the the wiring of the entire circuit. The pinout for the Uart and SPI pins on the teensy can be found
[here](https://forum.pjrc.com/attachment.php?attachmentid=1847&d=1398128869)

Note that the 5V wire on the Uart<->Usb cable is not used. The Teensy is powered by the microUsb cable instead. The LEDs are not necessary, but are helpful for figuring out what state the program is in the event something goes wrong.

![Circuit diagram](images/memcard_breakout.png)

The pinout of the relevant pins on the breakout board. These pins are the only ones that need to be wired for this project. A description of every pin on the board can be found
[here](http://forums.modretro.com/index.php?threads/gamecube-memory-card-sd-gecko-diagrams.7994/)

The memory card breakout board should be inserted into the second memory card slot on the console. This might be possible without a memory card shell, but would probably fit better with one. The breakout I have was created by taking the circuit board out of the style of memory card pictured below, cutting a hole in the back of the card, and filing pieces down until the breakout board fit in the shell with the screws in.

![Memory card](images/memcard.jpg)

### Setting up the Teensy
A prebuilt binary for the Teensy is located in `firmware/bin/stable`

The firmware can be loaded onto the teensy using `util/teensy.exe`.
Press the button on the teensy to put it in reset mode, open `hem-teensy.hex` with the util program, click program, and click reboot.
The teensy should reboot and start running the firmware.

### Setting up the Python script
The python demo script requires [Python 2.7](https://www.python.org/download/releases/2.7/) and
[pyserial](https://github.com/pyserial/pyserial) to run.

The script should be run after the teensy is connected to the computer, but before a match is started. The serial port specified in main.py may need to be changed to the actual serial port the Teensy is connected to. On Windows the port can be found through the Device Manager Serial Ports.

If the script does not connect, check the Uart speed in the firmware (main.c) and python script (memcard_driver.py)

## Making Modifications
### Ditching the microUSB cable
Note: I haven't tried this personally, but there isn't any reason why it shouldn't work. Attempt at your own risk.

Once the firmware is loaded and unchanging, the microUSB cable is only used to power the Teensy. The Uart<->Usb cable has a 5V wire that isn't used in the current setup, but the microUSB cable could be disconnected and the 5V from the Uart<->Usb cable could be connected to the Vin pin on the Teensy to power it.

### Rebuilding the Firmware
Quick note: This guide assumes Windows, but most of the steps probably work on a Linux distribution (make would already be installed, and there is a different installer for Teensyduino, but the toolchain should end up in the same place)

Building the code for the Teensy requires the
[Teensyduino](https://www.pjrc.com/teensy/td_download.html) toolchain and
[Make for Windows](http://gnuwin32.sourceforge.net/packages/make.htm)

Once both are installed, edit the Makefile TOOLPATH (line 36) to point to:

`<Arduino install dir>/hardware/tools/arm/bin`

To build the firmware, run `make` from the command line in the `firmware` directory.
`hem-teensy.elf` and `hem-teensy.hex` should appear in `firmware/bin`

### Changing the data transfered

Changing the data written out the memory card slot is possible, but requires changing a bunch of pieces of the system:
* The asm must be updated to write the new data
* The gecko code must be regenerated from the asm, possibly with the injection point changed (WiiRd works for this)
* The firmware must be updated with the new packet sizes and packet types
* The python must be updated with the same packet sizes and types, and the struct unpacking strings must also be updated

A future update will add the ability to add new packet types in one place, but probably not for a while.

## Prior Work

hem-teensy is based on the [Hardware Enhanced Melee](https://github.com/JLaferri/HardwareEnhancedMelee) project by JLaferri.

More info about his project:
[1](http://www.meleeitonme.com/statistics-in-melee-p1/)
[2](http://www.meleeitonme.com/statistics-in-melee-p2/)