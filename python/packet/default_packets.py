# Default packet classes for storing the data from the Wii.
# There are three types of packets:
# START: sent on the first frame of a match.
# UPDATE: sent on all unpaused frames during a match.
# END: send at the end of a match.
# As of 5/19/16, packet formats are documented at:
# http://www.meleeitonme.com/statistics-in-melee-p2/
# Packet size and checksum are prepended to each packet by the Teensy.

import binascii
import struct
import sys

import packet

# START packet
# 2 bytes stage id
# 4 bytes repeated player params
class StartPacket(packet.Packet):
  HEADER_SIZE = 3
  UNPACK_STRING = ">hb"

  def VerifySize(self, size):
    return size > PlayerParams.SIZE and size % PlayerParams.SIZE == StartPacket.HEADER_SIZE

  def UnpackData(self, data):
    # Extract stage.
    (self.stage, self.num_params) = struct.unpack(StartPacket.UNPACK_STRING,
                                                  data[0:StartPacket.HEADER_SIZE])

    # Extract player params.
    offset = StartPacket.HEADER_SIZE
    num_param_bytes = len(data) - offset
    if not num_param_bytes == PlayerParams.SIZE * self.num_params:
      print "Invalid number of bytes for player params", num_param_bytes, PlayerParams.SIZE
      return False
    self.player_params = []
    for i in xrange(0, self.num_params):
      params = PlayerParams(data[offset + PlayerParams.SIZE*i:
                                 offset + PlayerParams.SIZE*(i+1)])
      if params.valid:
        self.player_params.append(params)
      else:
        print "Unpacking Player Params failed"
        return False
    return True

  def __str__(self):
    if self.type == packet.PacketType.START:
      return "Start " + str((self.stage, self.player_params))
    return packet.Packet.__str__(self)

# Class to hold player parameters.
class PlayerParams:
  SIZE = 4
  UNPACK_STRING = ">bbbb"

  def __init__(self, bytes = ''):
    if not len(bytes) == PlayerParams.SIZE:
      self.valid = False
    else:
      self.valid = True
      (self.port_id, self.char_id, self.player_type, self.costume_id) = \
          struct.unpack(PlayerParams.UNPACK_STRING, bytes)

  def __str__(self):
    return str((self.port_id, self.char_id, self.player_type, self.costume_id))

  def __repr__(self):
    return self.__str__()

# UPDATE packet
# 4 bytes frame count
# 4 bytes rng seed
# 57 bytes repeated player update
class UpdatePacket(packet.Packet):
  HEADER_SIZE = 9
  UNPACK_STRING = ">iIb"

  def VerifySize(self, size):
    return size > PlayerUpdate.SIZE and size % PlayerUpdate.SIZE == UpdatePacket.HEADER_SIZE

  def UnpackData(self, data):
    # Extract frame count and rng seed.
    (self.frame_count, self.rng_seed, self.num_updates) = \
        struct.unpack(UpdatePacket.UNPACK_STRING, data[0:UpdatePacket.HEADER_SIZE])

    # Extract player params.
    offset = UpdatePacket.HEADER_SIZE
    num_update_bytes = len(data) - offset
    if not num_update_bytes == PlayerUpdate.SIZE * self.num_updates:
      print "Invalid number of bytes for player updates", num_update_bytes, PlayerUpdate.SIZE
      return False
    self.player_updates = []
    for i in xrange(0, self.num_updates):
      update = PlayerUpdate(data[offset + PlayerUpdate.SIZE*i:
                                 offset + PlayerUpdate.SIZE*(i+1)])
      if update.valid:
        self.player_updates.append(update)
      else:
        print "Unpacking Player Update failed"
        return False
    return True

  def __str__(self):
    if self.type == packet.PacketType.UPDATE:
      return "Update" + str((self.frame_count, self.rng_seed, self.player_updates))
    return packet.Packet.__str__(self)

# Class to hold player update structure.
class PlayerUpdate:
  SIZE = 57
  UNPACK_STRING = ">bhfffffffIffbbbbHff"

  def __init__(self, bytes = ''):
    if not len(bytes) == PlayerUpdate.SIZE:
      self.valid = False
    else:
      self.valid = True
      (self.char_id, self.action_state, self.xpos, self.ypos, self.jx, self.jy,
       self.cx, self.cy, self.trigger, self.buttons, self.percent, \
       self.shield_size, self.last_move_connected, self.combo_count,\
       self.last_hit_by, self.stocks, self.phy_buttons, self.l, self.r) = \
        struct.unpack(PlayerUpdate.UNPACK_STRING, bytes)

  def __str__(self):
    return "PlayerUpdate " + str((self.char_id, self.xpos, self.ypos))

  def __repr__(self):
    return self.__str__()

# END packet
# 1 byte win condition
class EndPacket(packet.Packet):
  HEADER_SIZE = 1
  UNPACK_STRING = ">b"

  def VerifySize(self, size):
    return size == EndPacket.HEADER_SIZE

  def UnpackData(self, data):
    self.win_condition = struct.unpack(EndPacket.UNPACK_STRING, data)[0]
    return True

  def __str__(self):
    if self.type == packet.PacketType.END:
      return "End " + str(self.win_condition)
    return packet.Packet.__str__(self)