// Library for manipulating a Buffer of packets. See header for more
// information.

#include "common.h"
#include "arm_cm4.h"

#include "packet_buffer.h"

void InitBuffer(Buffer *buffer_ptr) {
  buffer_ptr->buffer_start = 0;
  buffer_ptr->buffer_end = 0;
  int i;
  for (i = 0; i < BUFFER_SIZE; i ++) {
    buffer_ptr->buffer[i].marker[0] = 0xAA;
    buffer_ptr->buffer[i].marker[1] = 0xAA;
  }
}

int BufferFull(Buffer *buffer_ptr) {
  int temp = buffer_ptr->buffer_end + 1;
  if (temp > BUFFER_SIZE) temp -= BUFFER_SIZE;
  return buffer_ptr->buffer_start == temp;
}

int BufferEmpty(Buffer *buffer_ptr) {
  return buffer_ptr->buffer_start == buffer_ptr->buffer_end;
}

int BufferStartPush(Buffer *buffer_ptr, Packet** packet_ptr) {
  if (BufferFull(buffer_ptr)) return -1;
  *packet_ptr = &(buffer_ptr->buffer[buffer_ptr->buffer_end]);
  return 0;
}

int BufferFinishPush(Buffer *buffer_ptr) {
  buffer_ptr->buffer_end++;
  if (buffer_ptr->buffer_end == BUFFER_SIZE) buffer_ptr->buffer_end = 0;
  return 0;
}

int BufferStartPop(Buffer *buffer_ptr, Packet** packet_ptr) {
  if (BufferEmpty(buffer_ptr)) return -1;
  *packet_ptr = &(buffer_ptr->buffer[buffer_ptr->buffer_start]);
  return 0;
}

int BufferFinishPop(Buffer *buffer_ptr) {
  buffer_ptr->buffer_start++;
  if (buffer_ptr->buffer_start == BUFFER_SIZE) buffer_ptr->buffer_start = 0;
  return 0;
}

uint8 ComputerChecksum(Packet* packet_ptr) {
  uint8 c = packet_ptr->type;
  int i;
  for (i = 0; i < packet_ptr->size; i ++) {
    c += packet_ptr->data[i];
  }
  packet_ptr->checksum = c;
  return c;
}