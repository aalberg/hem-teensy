# Driver to talk to the Teensy and read all of the packets it sends into a queue.
# Packet streaming is done in a separate thread.
# Written for Python 2.7, but may be possible to update to a newer version.

import serial
import threading
import Queue

import packet.packet as packet
import packet_factory

class MemCardDriver:
  def __init__(self, port = ''):
    self.queue = Queue.Queue()
    
    # Connect to serial.
    self.ser = None
    try:
      self.ser = serial.Serial(
        port=port,
        baudrate=921600,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        bytesize=serial.EIGHTBITS,
        timeout=None
      )
      print "Serial port opened"
    except serial.SerialException as e:
      print str(e), self.ser
      return
    
    # Start streaming thread.
    self.thread = threading.Thread(target = MemCardDriver.StreamingThread, args = (self,))
    self.thread.start()
  
  def Read(self, size):
    bytes = self.ser.read(size)
    #print packet.HexString(bytes)
    return bytes
  
  # Thread to stream packets from the serial port to a queue.
  # The start of a packet is indicated by two bytes of 0xAA. This should hopefully
  # let the driver connet after the teensy is already returning data, but this
  # hasn't been tested. The 0xAA bytes are discarded and are not passed to the Packet
  # class for parsing.
  def StreamingThread(self):
    while 1:
      # Read byte, compare to 0xAA
      b = self.Read(1)
      if not b == '\xAA':
        print 1, hex(ord(b))
        continue
      # Read byte, compare to 0xAA
      b = self.Read(1)
      if not b == '\xAA':
        print 2, hex(ord(b))
        continue
        
      # Read packet header
      header_raw = self.Read(packet.PacketHeader.SIZE)
      header = packet.PacketHeader(header_raw)
      
      # Read data, parse into packet
      data = self.Read(header.size)
      packet_inst = packet_factory.PacketFactory.Create(header, data)
      # Put in queue for higher level interface
      if not packet_inst == None and not packet_inst.type == packet.PacketType.INVALID:
        self.queue.put(packet_inst)
      else:
        print "Got an invalid packet"
  
  def Pop(self):
    return self.queue.get(block=True)
  
if __name__ == "__main__":
  print "run main.py"