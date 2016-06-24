#!python3

# Main program to read data from the Teensy and prints it to a terminal.
# Demonstrates how to use the memcard driver.

import memcard_driver


def main():
    # Serial port may change each time the Teensy is plugged in.
    driver = memcard_driver.MemCardDriver('/dev/tty.usbserial')
    while 1:
        packet = driver.Pop()
        print(packet)

if __name__ == "__main__":
    main()
