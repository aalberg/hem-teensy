# Base class for packets and enum for packet types.

import struct

def HexString(str):
  return ' '.join(format(ord(n),'02x') for n in str)

# Enum for packet type
class PacketType:
  UNSET = 0
  INVALID = 1
  START = 0x37
  UPDATE = 0x38
  END = 0x39

# Class to store packet header information.
class PacketHeader:
  SIZE = 4
  UNPACK_STRING = "<hBB"

  def __init__(self, data):
    if not len(data) == PacketHeader.SIZE:
      self.valid = False
      self.size = 0
      return
    (self.size, self.checksum, self.type) = struct.unpack(PacketHeader.UNPACK_STRING, data)

  def __str__(self):
    return str((self.size, self.checksum, self.type))

  def __repr__(self):
    return self.__str__()

# Base Packet class. All other packet types must inherit from this.
class Packet:
  def __init__(self, header, data):
    self.type = PacketType.UNSET
    self.header = header
    if header == None or data == None:
      print "Null header or data."
      self.type = PacketType.INVALID
    elif not self.VerifySize(len(data)):
      print "Size verify failed."
      self.type = PacketType.INVALID
    elif not self.VerifyChecksum(header, data):
      self.type = PacketType.INVALID
    elif not self.UnpackData(data):
      print "Unpack failed."
      self.type = PacketType.INVALID
    else:
      self.type = header.type

  # Verify the length of the packet. Placeholder function. Must be overidden by child class.
  # Returns True if the size is a valid size for the packet, and False otherwise.
  def VerifySize(self, size):
    return self.header.size == size

  # Check simple checksum.
  # Returns True if the checksum in the header is correct, and False otherwise.
  def VerifyChecksum(self, header, data):
    s = header.type
    for c in data:
      s += ord(c)
    if header.checksum == (s % 256):
      return True
    print "Checksum mismatch. Expected", header.checksum, "calculated", s
    return False

  # Unpack the data into internal members. Placeholder function. Must be overidden by child class.
  # Returns True if the unpack operation succeeds, and False otherwise.
  def UnpackData(self, data):
    return False

  # Simple string representations.
  def __str__(self):
    if self.type == PacketType.INVALID:
      return "Invalid"
    else:
      return "Packet type: " + str(self.type)

  def __repr__(self):
    return self.__str__()