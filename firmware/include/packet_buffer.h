// Library for manipulating a Buffer of packets. Buffers are implemented as
// circular queues of Packets. For speed no dynamic allocation is used, and
// push and pop operations are split avoid copying data.
//
// Buffers are not safe to read from multiple contexts or write from multiple
// contexts, but a single context can read a Buffer while a different context
// writes to it.

#include "arm_cm4.h"

#define BUFFER_SIZE (16)
#define PACKET_HEADER_SIZE (6)
#define MAX_PACKET_DATA (506)

// The order of this struct is used for the packet format. Do not change it
// Unless you know what you're doing. Size: 256 bytes.
typedef struct {
  char marker[2];
  int16 size;
  uint8_t checksum;
  // Type MUST come directly before data.
  char type; 
  char data[MAX_PACKET_DATA];
} Packet;
 
typedef struct {
  Packet buffer[BUFFER_SIZE];
  volatile int buffer_start;
  volatile int buffer_end;
} Buffer;

void InitBuffer(Buffer *buffer_ptr);
int BufferFull(Buffer *buffer_ptr);
int BufferEmpty(Buffer *buffer_ptr);

// Pushes work as follows: BufferStartPush is called for a particular Buffer,
// and a pointer to a Packet in that Buffer is returned. The Packet is filled
// with data, type, and size information and BufferFinishPush is called. The
// Packet is put in the Buffer and becomes visible to the pop functions.
int BufferStartPush(Buffer *buffer_ptr, Packet** packet_ptr);
int BufferFinishPush(Buffer *buffer_ptr);

// Pops work as follows: BufferStartPop is called for a particular Buffer, and
// a pointer to the first Packet in that buffer is returned. The Packet is used
// for whatever it is needed for, and BufferFinishPop is called. The Packet is
// removed from the Buffer and the space is freed for another 
int BufferStartPop(Buffer *buffer_ptr, Packet** packet_ptr);
int BufferFinishPop(Buffer *buffer_ptr);
uint8 ComputerChecksum(Packet* packet_ptr);