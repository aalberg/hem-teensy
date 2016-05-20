// Simple SPI driver. SPI init initializes two interrupts that must be
// implemented by the user: INT_SPI0 and INT_PORTC (pin C6, chip select).

#ifndef __SPI_H__
#define __SPI_H__

#include "arm_cm4.h"

void SpiSlaveInit();

#endif  // __SPI_H__