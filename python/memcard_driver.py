import gnc_packet
import serial
import threading
import Queue

class MemCardDriver:
  def __init__(self, port = ''):
    self.queue = Queue.Queue()
    
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
      
    self.thread = threading.Thread(target = MemCardDriver.StreamingThread, args = (self,))
    self.thread.start()
    
  def StreamingThread(self):
    while 1:
      # Read byte, compare to 0xAA
      b = self.ser.read(1)
      if not b == '\xAA':
        print 1, hex(ord(b))
        continue
      # Read byte, compare to 0xAA
      b = self.ser.read(1)
      if not b == '\xAA':
        print 2, hex(ord(b))
        continue
        
      # Read size and type
      header = self.ser.read(gnc_packet.Packet.HEADER_SIZE)
      (size, checksum, type) = gnc_packet.Packet.UnpackHeader(header)
      if not gnc_packet.Packet.VerifyPacketType(type, size):
        continue
      
      # Read data, parse into packet
      data = self.ser.read(size)
      packet = gnc_packet.Packet(type, size, checksum, data)
      # Put in queue for higher level interface
      if not packet.type == gnc_packet.PacketType.INVALID:
        self.queue.put(packet)
      else:
        print "Got an invalid packet"
  
  def Pop(self):
    return self.queue.get(block=True)
  
if __name__ == "__main__":
  print "run main.py"