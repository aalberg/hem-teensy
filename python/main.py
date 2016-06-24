# Main program to read data from the Teensy and print it to a terminal.
# Demonstrates how to use the memcard driver.

import memcard_driver

def main():
  # Serial port may change each time the Teensy is plugged in.
  driver = memcard_driver.MemCardDriver('COM3')
  
  while 1:
    packet = driver.Pop()
    print packet
  
if __name__ == "__main__":
  main()