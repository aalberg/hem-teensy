// Simple library for using LEDs through GPIO. Pins selected do not interfere
// with SPI pins.
// See https://forum.pjrc.com/attachment.php?attachmentid=1847&d=1398128869
// For details of which physical pin each LED pin maps to.

#ifndef LED_H_
#define LED_H_

#define LED0_MUX PORTD_PCR1
#define LED1_MUX PORTC_PCR0
#define LED2_MUX PORTC_PCR3
#define LED3_MUX PORTD_PCR3
#define LED4_MUX PORTD_PCR2
#define LED5_MUX PORTD_PCR4

#define LED0_PORTSET GPIOD_PSOR
#define LED1_PORTSET GPIOC_PSOR
#define LED2_PORTSET GPIOC_PSOR
#define LED3_PORTSET GPIOD_PSOR
#define LED4_PORTSET GPIOD_PTOR
#define LED5_PORTSET GPIOD_PTOR

#define LED0_PORTCLEAR GPIOD_PCOR
#define LED1_PORTCLEAR GPIOC_PCOR
#define LED2_PORTCLEAR GPIOC_PCOR
#define LED3_PORTCLEAR GPIOD_PCOR
#define LED4_PORTCLEAR GPIOD_PTOR
#define LED5_PORTCLEAR GPIOD_PTOR

#define LED0_PORTTOGGLE GPIOD_PTOR
#define LED1_PORTTOGGLE GPIOC_PTOR
#define LED2_PORTTOGGLE GPIOC_PTOR
#define LED3_PORTTOGGLE GPIOD_PTOR
#define LED4_PORTTOGGLE GPIOD_PTOR
#define LED5_PORTTOGGLE GPIOD_PTOR

#define LED0_PORTMASK (1<<1)
#define LED1_PORTMASK (1<<0)
#define LED2_PORTMASK (1<<3)
#define LED3_PORTMASK (1<<3)
#define LED4_PORTMASK (1<<2)
#define LED5_PORTMASK (1<<4)

void InitLeds();
inline void LedOn(int pin);
inline void LedOff(int pin);
inline void LedToggle(int pin);

#endif  // LED_H_