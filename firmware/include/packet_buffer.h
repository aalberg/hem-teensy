#include "arm_cm4.h"

#define BUFFER_SIZE (16)
#define PACKET_HEADER_SIZE (6)
#define MAX_PACKET_DATA (236)

// 244 bytes.
typedef struct {
  char marker[2];
  int16 size;
  uint8_t checksum;
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
int BufferStartPush(Buffer *buffer_ptr, Packet** packet_ptr);
int BufferFinishPush(Buffer *buffer_ptr);
int BufferStartPop(Buffer *buffer_ptr, Packet** packet_ptr);
int BufferFinishPop(Buffer *buffer_ptr);
uint8 ComputerChecksum(Packet* packet_ptr);