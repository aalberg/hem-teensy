// Source: http://www.seanet.com/~karllunt/bareteensy31.html
// Definitions common to all ARM Cortex M4 processors.

#ifndef _CPU_ARM_CM4_H
#define _CPU_ARM_CM4_H

#include "common.h"

// ARM Cortex M4 implementation for interrupt priority shift.
#define ARM_INTERRUPT_LEVEL_BITS 4

// Determines the correct IRQ number from a INT value.
#define IRQ(N) (N - (1 << ARM_INTERRUPT_LEVEL_BITS))

// Sets the priority of an interrupt.
#define NVIC_SET_PRIORITY(irqnum, priority) \
  (*((volatile uint8_t *)0xE000E400 + (irqnum)) = (uint8_t)(priority))

void stop(void);
void wait(void);
void write_vtor(int);
void enable_irq(int);
void disable_irq(int);
void set_irq_priority(int, int);

#define ENABLE_INTERRUPTS asm(" CPSIE i")
#define DISABLE_INTERRUPTS asm(" CPSID i")

#ifdef  FALSE
#undef  FALSE
#endif
#define FALSE (0)

#ifdef  TRUE
#undef  TRUE
#endif
#define  TRUE (1)

#ifdef  NULL
#undef  NULL
#endif
#define NULL (0)

#ifdef  ON
#undef  ON
#endif
#define ON (1)

#ifdef  OFF
#undef  OFF
#endif
#define OFF (0)

typedef unsigned char uint8;
typedef unsigned short int uint16;
typedef unsigned long int uint32;

typedef char int8;
typedef short int int16;
typedef int int32;

typedef volatile int8 vint8;
typedef volatile int16 vint16;
typedef volatile int32 vint32;

typedef volatile uint8 vuint8;
typedef volatile uint16 vuint16;
typedef volatile uint32 vuint32;

int main(void);

#endif  // _CPU_ARM_CM4_H
