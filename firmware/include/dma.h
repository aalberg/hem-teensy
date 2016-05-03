#ifndef __DMA_H__
#define __DMA_H__

#include "arm_cm4.h"

void DmaChannelInit(int channel, void *source_ptr, void *dest_ptr, int size, int source,
                    int source_inc, int dest_inc);
void SpiSlaveInitDma();
void InitSpiAndDma(void *source_ptr, void *dest_ptr, int size);
//void UartDmaInit(void *source_ptr, void *dest_ptr, int size);

#endif  // __DMA_H__