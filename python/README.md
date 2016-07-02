# Adding packet types

## The new packet class

A new packet class can be created by inheriting from `packet.Packet`. The new class must implement
three functions:
* VerifySize
* UnpackData
* __str__

More documentation of these functions can be found in `packet.py`. The simplest example of a packet
is `EndPacket` in `default_packets.py`.

## Updating the PacketFactory

Once you have the new packet class, the PacketFactory needs to know it exists. Two modifications to
`packet_factory.py` are required.

1. Import the new packet class file.
2. Add a map entry to `PacketFactory.factories` that maps the id code of the new packet type to the class in the new file.