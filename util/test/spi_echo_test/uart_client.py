import binascii
import serial
import struct
import sys
import time

def main():
  #if len(sys.argv) < 2:
  #  print("Not enough args")

  # Open serial port
  try:
    ser = serial.Serial(
      port="COM3",#sys.argv[1],
      baudrate=921600,#230400,
      parity=serial.PARITY_NONE,
      stopbits=serial.STOPBITS_ONE,
      bytesize=serial.EIGHTBITS,
      timeout=None
    )
  except serial.SerialException as e:
    print(str(e), ser)
    return -1
    
  mode = 0
  last = -1
  start_time = time.time()
  count = 0
  print "starting test"
  while 1:
    b = ser.read(1)
    #print len(b), b, type(b), b[0], type(b[0])
    if b[0] == '\xfe':
      mode = 1
    elif b[0] == '\xff':
      mode = 0
    else:
      if mode == 0:
        cur = struct.unpack("<B", b[0])[0]
        #if not last == -1:
        #  if not (last + 1) % 250 == cur:
        #    print "data loss detected", cur, last
        last = cur
        #print binascii.hexlify(b)
      elif mode == 1:
        print(b)
    
    count += 1
    if count % 1000 == 0:
      print "Average bitrate =", count / (time.time() - start_time), "Bps"

if __name__ == "__main__":
  main()