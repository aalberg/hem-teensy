#include "common.h"
#include "arm_cm4.h"
#include "spi.h"

void SpiSlaveInit() {
  // Enable clock.
  SIM_SCGC6 |= SIM_SCGC6_SPI0_MASK;
  
  // Slave mode.
  SPI0_MCR = 0x00000000;
  
  // Set frame size.
  SPI0_CTAR0_SLAVE = 0;
  SPI0_CTAR0_SLAVE |= SPI_CTAR_FMSZ(7);
  
	// Set to (0, 0) mode.
  SPI0_CTAR0_SLAVE = SPI0_CTAR0_SLAVE & ~(SPI_CTAR_CPOL_MASK | SPI_CTAR_CPHA_MASK);
  
  // Clear all flags.
  SPI0_SR = 0xFF0F0000;
  
  // Set send and receive to generate ISR requests.
  SPI0_RSER = 0x00020000;
  
  // Enable the right pins. (SCK, MISO, MOSI, CS0)
  PORTC_PCR5 = PORT_PCR_MUX(2);
  PORTC_PCR6 = PORT_PCR_DSE_MASK | PORT_PCR_MUX(2);
  PORTC_PCR7 = PORT_PCR_MUX(2);
  PORTC_PCR4 = PORT_PCR_MUX(2);
  
  // Configure SS pin to generate interrupts on rising and falling edges.
  PORTC_PCR4 |= PORT_PCR_IRQC(0xB);
  PORTC_ISFR = 1 << 6;
  
  // Enable the interrupts.
  enable_irq(IRQ(INT_SPI0));
  enable_irq(IRQ(INT_PORTC));
}