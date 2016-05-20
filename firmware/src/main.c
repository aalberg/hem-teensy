// Program to stream packets from SPI from a Wii to a computer over UART.
// Packets are read into a queue using the SPI interrupt, a checksum is added,
// And the packet is send over UART to the computer in the main thread.

// Libc includes.
#include <string.h>

// Common includes.
#include "common.h"
#include "arm_cm4.h"

// Module includes.
#include "dma.h"
#include "led.h"
#include "packet_buffer.h"
#include "spi.h"
#include "uart.h"

// Serial baud rate.
#define SERIAL_BAUD (921600)

// Packet ID codes for each type of packet.
#define EVENT_GAME_START 0x37
#define EVENT_UPDATE 0x38
#define EVENT_GAME_END 0x39
uint8 event_codes[256];

// Buffer and pointer to working packet.
Buffer buffer;
Packet *cur_packet = 0;

// Initialize everything that needs to be set up.
void Init(void) {
  // Enable the PIT clock.
  SIM_SCGC3 |= SIM_SCGC3_ADC1_MASK;
  SIM_SCGC6 |= SIM_SCGC6_PIT_MASK | SIM_SCGC6_ADC0_MASK;

  // Turn on PIT.
  PIT_MCR = 0x00;
  // Timer 1
  PIT_LDVAL1 = mcg_clk_hz /* 60;*/>> 2; // setup timer 1 for 4Hz.
  PIT_TCTRL1 = PIT_TCTRL_TIE_MASK; // enable Timer 1 interrupts
  PIT_TCTRL1 |= PIT_TCTRL_TEN_MASK; // start Timer 1

  // Enable interrupts.
  enable_irq(IRQ(INT_PIT1));
  ENABLE_INTERRUPTS;
  
  // Event code setup. These codes are used to verify the packet size is
  // is correct the packet type. These values could be replaced with functions
  // To allow packets of different sizes, such as data for a variable number of
  // players.
  event_codes[EVENT_GAME_START] = 0xA;
  event_codes[EVENT_UPDATE] = 0x7A;
  event_codes[EVENT_GAME_END] = 0x1;
}

int main(void) {
  Init();
  InitLeds();
  UARTInit(0, SERIAL_BAUD);
  SpiSlaveInit();
  InitBuffer(&buffer);

  Packet *send_packet = 0;
  while (1) {
    // Pop a packet from the buffer.
    int ret = BufferStartPop(&buffer, &send_packet);
    if (ret == 0) {
      // Verify the message has the correct length.
      if (send_packet->size == event_codes[(int)send_packet->type]) {
        ComputerChecksum(send_packet);
        UARTWrite((char *)send_packet, send_packet->size + PACKET_HEADER_SIZE);
        LedToggle(3);
      // A byte was dropped somewhere.
      } else {
        LedOn(4);
      }
      // Tell the buffer to free the space the packet was in.
      BufferFinishPop(&buffer);
    }
    // Failed to get a packet. Not necessarily an error case.
    else {
      LedToggle(5);
    }
  }
  return 0;
}

// SPI CS interrupt for indicating start/end of a packet.
void PORTC_IRQHandler() {
  // Verify the interrupt was on the right pin.
  if ((PORTC_ISFR & (1 << 4)) == 0) return;
  
  // Get the pin state.
  int pin_state = GPIOC_PDIR & (1 << 4);
  // Positive edge, SPI packet over. Finish pushing to the buffer.
  if (pin_state) {
    LedOff(1);
    BufferFinishPush(&buffer);
  // Negative edge, SPI packet starting. Reserve a packet at the end of the buffer.
  } else {
    LedOn(1);
    BufferStartPush(&buffer, &cur_packet);
    cur_packet->size = -1;
  }
  
  // Clear interrupt flag.
  PORTC_ISFR = 1 << 4;
}

// SPI interrupt handler for receiving data.
void SPI0_IRQHandler() {
  // Read a byte and put it in the packet.
  cur_packet->size ++;
  // A bit of a hack. The first thing the Wii writes is the packet type,
  // immediately followed by the data. Since type comes directly before the
  // data in the struct, use the pointer to type as the base address.
  *(&cur_packet->type + cur_packet->size) = SPI0_POPR;
  LedToggle(2);
  
  // Reset the interrupt flag.
  SPI0_SR |= SPI_SR_RFDF_MASK;
}

// Blink the onboard LED to indicate the teensy is running.
void PIT1_IRQHandler() {
  LedToggle(0);
  // Reset the interrupt flag.
  PIT_TFLG1 |= PIT_TFLG_TIF_MASK;
}