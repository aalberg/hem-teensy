# Packet classes for storing the data from the Wii.

import binascii
import struct
import sys

# Enum for packet type
class PacketType:
  INVALID = 0
  START = 0x37
  UPDATE = 0x38
  END = 0x39

  # Static functions for verifying the size of a packet is valid for the packet type.
  @staticmethod
  def CheckStartSize(size):
    return size > 4 and size % 4 == 2
  @staticmethod
  def CheckUpdateSize(size):
    return size > 57 and size % 57 == 8
  @staticmethod
  def CheckEndSize(size):
    return size == 0x1

  SIZES = {
    START: CheckStartSize,
    UPDATE: CheckUpdateSize,
    END: CheckEndSize,
  }

# Class to hold player parameters.
class PlayerParams:
  HEADER_SIZE = 2
  SIZE = 4
  def __init__(self, bytes = ''):
    if not len(bytes) == PlayerParams.SIZE:
      self.valid = False
    else:
      self.valid = True
      (self.port_id, self.char_id, self.player_type, self.costume_id) = \
          struct.unpack(Packet.format_strings["player_params"], bytes)

  def __str__(self):
    return str((self.port_id, self.char_id, self.player_type, self.costume_id))

  def __repr__(self):
    return self.__str__()

# Class to hold player update structure.
class PlayerUpdate:
  HEADER_SIZE = 8
  SIZE = 57
  def __init__(self, bytes = ''):
    if not len(bytes) == PlayerUpdate.SIZE:
      self.valid = False
    else:
      self.valid = True
      (self.char_id, self.action_state, self.xpos, self.ypos, self.stocks, \
       self.percent, self.shield_size, self.last_move_connected, \
       self.combo_count, self.last_hit_by, self.jx, self.jy, self.cx, self.cy, \
       self.trigger, self.buttons, self.phy_buttons, self.l, self.r) = \
        struct.unpack(Packet.format_strings["player_update"], bytes)

  def __str__(self):
    return "PlayerUpdate " + str((self.char_id, self.xpos, self.ypos))

  def __repr__(self):
    return self.__str__()

# Class to hold a packet from the wii. There are three types of packets:
# START: sent on the first frame of a match.
# UPDATE: sent on all unpaused frames during a match.
# END: send at the end of a match.
# As of 5/19/16, packet formats are documented at:
# http://www.meleeitonme.com/statistics-in-melee-p2/
# Packet size and checksum are prepended to each packet by the Teensy.
class Packet:
  HEADER_SIZE = 4
  format_strings = {
    # All packets.
    "packet_header": "<hBB",

    # START packet.
    "start": ">h",
    "player_params": ">bbbb",

    # UPDATE packet.
    "update": ">iI",
    "player_update": ">bhffbffbbbfffffIHff",

    # END packet.
    "end": ">b",
  }

  def __init__(self, packet_type, size, checksum, data):
    self.type = packet_type
    self.size = size
    self.checksum = checksum
    if not self.CheckChecksum(data):
      self.type = PacketType.INVALID
      return
    if not self.ParseData(data):
      self.type = PacketType.INVALID

  # Unpack the packet header into a tuple.
  @staticmethod
  def UnpackHeader(data):
    return struct.unpack(Packet.format_strings["packet_header"], data)

  # Use the PacketType enum to verify the reported type and size of the packet.
  @staticmethod
  def VerifyPacketType(packet_type, size):
    if packet_type not in PacketType.SIZES:
      return False
    return PacketType.SIZES[packet_type].__func__(size)

  # Check simple checksum.
  def CheckChecksum(self, data):
    s = self.type
    for c in data:
      s += ord(c)
    if self.checksum == (s % 256):
      return True
    print "Checksum mismatch. Expected", self.checksum, "calculated", s
    print len(data)
    return False

  # Parse a packet.
  # Packets are expanded into tuples using the strings in Packet.format_strings
  # and are appended to the queue.
  def ParseData(self, data):
    # START packet
    # 2 bytes stage id
    # 4 bytes repeated player params
    if self.type == PacketType.START:
      # Extract stage.
      self.stage = struct.unpack(Packet.format_strings["start"], data[0:PlayerParams.HEADER_SIZE])[0]

      # Extract player params.
      num_param_bytes = len(data) - PlayerParams.HEADER_SIZE
      if not num_param_bytes % PlayerParams.SIZE == 0:
        print "Invalid number of bytes for player params", num_param_bytes, PlayerParams.SIZE
        return False
      self.player_params = []
      for i in xrange(0, int(num_param_bytes / PlayerParams.SIZE)):
        params = PlayerParams(data[PlayerParams.HEADER_SIZE + PlayerParams.SIZE*i:
                                   PlayerParams.HEADER_SIZE + PlayerParams.SIZE*(i+1)])
        if params.valid:
          self.player_params.append(params)
        else:
          print "Player Params invalid"
          return False
    # UPDATE packet
    # 4 bytes frame count
    # 4 bytes rng seed
    # 57 bytes repeated player update
    elif self.type == PacketType.UPDATE:
      # Extract frame count and rng seed.
      (self.frame_count, self.rng_seed) = \
          struct.unpack(Packet.format_strings["update"], data[0:PlayerUpdate.HEADER_SIZE])

      # Extract player updates.
      num_update_bytes = len(data) - PlayerUpdate.HEADER_SIZE
      if not num_update_bytes % PlayerUpdate.SIZE == 0:
        print "Invalid number of bytes for player updates", num_update_bytes, PlayerUpdate.SIZE
        return False
      self.player_updates = []
      for i in xrange(0, int(num_update_bytes / PlayerUpdate.SIZE)):
        update = PlayerUpdate(data[PlayerUpdate.HEADER_SIZE + PlayerUpdate.SIZE*i:
                                   PlayerUpdate.HEADER_SIZE + PlayerUpdate.SIZE*(i+1)])
        if update.valid:
          self.player_updates.append(update)
        else:
          print "Player Update invalid"
          return False
    # END packet
    # 1 byte win condition
    elif self.type == PacketType.END:
      self.win_condition = struct.unpack(Packet.format_strings["end"], data)[0]

    return True

  # Simple string representations.
  def __str__(self):
    if self.type == PacketType.INVALID:
      return "Invalid"
    elif self.type == PacketType.START:
      return "Start " + str((self.stage, self.player_params))
    elif self.type == PacketType.UPDATE:
      return "Update" + str((self.frame_count, self.rng_seed, self.player_updates))
    elif self.type == PacketType.END:
      return "End " + str(self.win_condition)
    else:
      return "Unknown type"

  def __repr__(self):
    return self.__str__()

# Below this line is tests. To run them run this file as main.
# ------------------------------------------------------------
if __name__ == "__main__":
  print "Running gnc_packet.py tests"
  # Test UnpackHeader
  (size, checksum, packet_type) = Packet.UnpackHeader('\x00\x0A\xFF\x37')
  if not (size == 10 and checksum == 255 and packet_type == 55):
    raise Exception("Test failed")

  # Test VerifyPacketType
  if Packet.VerifyPacketType(0x35, 0xA):
    raise Exception("Test failed")

  # Test VerifyPacketType
  if not Packet.VerifyPacketType(0x37, 0xA):
    raise Exception("Test failed")
  if not Packet.VerifyPacketType(0x37, 0x12):
    raise Exception("Test failed")
  if Packet.VerifyPacketType(0x37, 0x11):
    raise Exception("Test failed")

  # Test VerifyPacketType
  if not Packet.VerifyPacketType(0x38, 0x7A):
    raise Exception("Test failed")
  if not Packet.VerifyPacketType(0x38, 179):
    raise Exception("Test failed")
  if Packet.VerifyPacketType(0x38, 180):
    raise Exception("Test failed")

  # Test VerifyPacketType
  if not Packet.VerifyPacketType(0x39, 1):
    raise Exception("Test failed")
  if Packet.VerifyPacketType(0x39, 2):
    raise Exception("Test failed")
  if Packet.VerifyPacketType(0x39, 3):
    raise Exception("Test failed")

  # Test checksum calculation
  a = Packet(0x37, 0xA, 0xA6, '\x12\x00\x0A\x0B\x0C\x0D\x0A\x0B\x0C\x0D')
  print a
  if not (a.type == PacketType.INVALID):
    raise Exception("Test failed")

  # Test ParseData for START
  a = Packet(0x37, 0xA, 0xA5, '\x00\x12\x0A\x0B\x0C\x0D\x0A\x0B\x0C\x0D')
  print a
  if not (a.type == PacketType.START and a.stage == 0x12 and len(a.player_params) == 2):
    raise Exception("Test failed")
  for p in a.player_params:
    if not (p.port_id == 0xA and p.char_id == 0xB and p.player_type == 0xC and p.costume_id == 0xD):
      raise Exception("Test failed")

  # Test ParseData for END
  a = Packet(0x39, 0x1, 0x3A, '\x01')
  print a
  if not (a.type == PacketType.END and a.win_condition == 0x01):
    raise Exception("Test failed")

  # Test ParseData for UPDATE
  a = Packet(0x38, 0x1, 0xB2, '\x01'*0x7A)
  print a
  if not (a.type == PacketType.UPDATE):
    raise Exception("Test failed")

  print "All tests passed"
