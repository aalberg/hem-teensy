# Packet Factory class that takes in raw data and generates packet instances.

import packet.packet as packet
import packet.default_packets as default_packets

class PacketFactory:
  factories = {
    packet.PacketType.START: default_packets.StartPacket,
    packet.PacketType.UPDATE: default_packets.UpdatePacket,
    packet.PacketType.END: default_packets.EndPacket,
  }
  
  @staticmethod
  def AddFactory(id, type):
    if not PacketFactory.factories.has_key(id):
      PacketFactory.factories[id] = type
  
  @staticmethod
  def Create(header, data):
    if not PacketFactory.factories.has_key(header.type):
      return None
    return PacketFactory.factories[header.type](header, data)