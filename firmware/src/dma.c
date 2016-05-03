#include "dma.h"
#include "common.h"

void DmaModuleInit() {
  // Enable clocks for DMA module.
  SIM_SCGC6 |= SIM_SCGC6_DMAMUX_MASK;
  SIM_SCGC7 |= SIM_SCGC7_DMA_MASK;
}

void DmaChannelInit(int channel, void *source_ptr, void *dest_ptr, int size, int source,
                    int source_inc, int dest_inc) {
  // Configure mux.
  // Disable channel and clear everything.
  DMAMUX_CHCFG(channel) = 0x00;
  
  // Select source.
  DMAMUX_CHCFG(channel) |= DMAMUX_CHCFG_SOURCE(source);
  
  // Configure channel.
  // Set up source and dest addresses.
  DMA_SADDR(channel) = (int)source_ptr;
  DMA_DADDR(channel) = (int)dest_ptr;

  // Set soruce and dest address increment.
  DMA_SOFF(channel) = source_inc;
  DMA_DOFF(channel) = dest_inc;

  // Set size of transfer 0x00 = 1 byte.
  DMA_ATTR(channel) = DMA_ATTR_SSIZE(0) | DMA_ATTR_DSIZE(0);
  // Set bytes per minor loop.
  DMA_NBYTES_MLNO(channel) = 0x01;
  
  // Set number of minor loops.
  DMA_CITER_ELINKNO(channel) = DMA_CITER_ELINKNO_CITER(size);
  DMA_BITER_ELINKNO(channel) = DMA_BITER_ELINKNO_BITER(size);

  // Adjustment applied after major loop finishes
  DMA_SLAST(channel) = -(size * source_inc);  // Source address adjustment.
  DMA_DLAST_SGA(channel) = -(size * dest_inc);  // Destination address adjustment.
  
  // Set to disable on completion.
  DMA_CSR(0) |= DMA_CSR_DREQ_MASK;
  
  // Enable DMA request for channel.
  DMA_ERQ |= (1 << channel);
  
  // Enable mux.
  DMAMUX_CHCFG(channel) |= DMAMUX_CHCFG_ENBL_MASK;
}

void SpiSlaveInitDma() {
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
  
  // Set send and receive to generate DMA requests
	SPI0_RSER = SPI_RSER_RFDF_RE_MASK | SPI_RSER_RFDF_DIRS_MASK | SPI_RSER_TFFF_RE_MASK | SPI_RSER_TFFF_DIRS_MASK;
  
  // Enable the right pins. (SCK, MOSI, MISO, CS0)
  PORTC_PCR5 = PORT_PCR_MUX(2);
  PORTC_PCR6 = PORT_PCR_DSE_MASK | PORT_PCR_MUX(2);
  PORTC_PCR7 = PORT_PCR_MUX(2);
  PORTC_PCR4 = PORT_PCR_MUX(2);
}

void InitSpiAndDma(void *source_ptr, void *dest_ptr, int size) {
  SpiSlaveInitDma();
  DmaChannelInit(0, (void *)SPI0_POPR, dest_ptr, size, 16, 0, 1);
  DmaChannelInit(1, source_ptr, (void *)SPI0_PUSHR_SLAVE, size, 17, 1, 0);
}

/*void EnableUart() {
  // configure TX pin
  SIM->SCGC5 |=  SIM_SCGC5_PORTE_MASK;
  PORTE->PCR[0] &= ~PORT_PCR_MUX_MASK;
  PORTE->PCR[0] |= PORT_PCR_MUX(GPIO_AF_ALT3);
 
  SIM->SCGC4 |= SIM_SCGC4_UART1_MASK;
 
  br_mpx = __UART_BRR(48000000, 9600);   // calculate baud rate mpx from desired clock
 
  // clear baud rate registers
  UART1->BDH &= ~(UART_BDH_SBR_MASK);   
  UART1->BDL = 0;
 
  // set baud rate
  UART1->BDH |= HI_BYTE(br_mpx);         
  UART1->BDL |= LO_BYTE(br_mpx);
 
  // Set baud rate
  UART1->C1  = 0;
 
  // Set FIFO water marks
  UART1->TWFIFO = UART_TWFIFO_TXWATER(1);
  UART1->RWFIFO = UART_RWFIFO_RXWATER(1);
 
  // Enable transmitter
  UART1->C2 = 0;
  UART1->C2 |= UART_C2_TE_MASK;
  UART1->S2 = 0;
  UART1->C3 = 0;
}

void UartDmaInit(void *source_ptr, void *dest_ptr, int size) {
  DmaChannelInit(2, 0x00, dest_ptr, size, 16, 0, 1);
  DmaChannelInit(3, source_ptr, 0x00, size, 16, 1, 0);
}*/