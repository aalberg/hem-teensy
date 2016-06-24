# Makefile for teensy projects.
#
# Made by Kevin Cuzner, modified by Alex Alberg.
#
# Purpose: To not depend on Arduino dev environment.

PROJECT = hem-teensy

# Project Structure
SRCDIR = src
COMDIR = common
BINDIR = bin
OBJDIR = obj
INCDIR = include

# Project target
CPU = cortex-m4

# Sources
SRC = $(wildcard $(SRCDIR)/*.c) $(wildcard $(COMDIR)/*.c)
ASM = $(wildcard $(SRCDIR)/*.s) $(wildcard $(COMDIR)/*.s)

# Include directories
INCLUDE  = -I$(INCDIR)

# Linker script
LSCRIPT = $(COMDIR)/Teensy31_flash.ld

# C Flags
GCFLAGS  = -Wall -fno-common -mthumb -mcpu=$(CPU)
GCFLAGS += $(INCLUDE)
LDFLAGS += -nostartfiles -T$(LSCRIPT) -mthumb -mcpu=$(CPU)
ASFLAGS += -mcpu=$(CPU)

# Tools
TOOLPATH = C:/Users/Alex/Documents/toolchains/arm/bin
CC = $(TOOLPATH)/arm-none-eabi-gcc
AS = $(TOOLPATH)/arm-none-eabi-as
AR = $(TOOLPATH)/arm-none-eabi-ar
LD = $(TOOLPATH)/arm-none-eabi-ld
OBJCOPY = $(TOOLPATH)/arm-none-eabi-objcopy
SIZE = $(TOOLPATH)/arm-none-eabi-size
OBJDUMP = $(TOOLPATH)/arm-none-eabi-objdump

## Build process

OBJ := $(addprefix $(OBJDIR)/,$(notdir $(SRC:.c=.o)))
OBJ += $(addprefix $(OBJDIR)/,$(notdir $(ASM:.s=.o)))

all:: $(BINDIR)/$(PROJECT).hex

Build: $(BINDIR)/$(PROJECT).hex

dump: $(BINDIR)/$(PROJECT).elf
	$(OBJDUMP) -D $(BINDIR)/$(PROJECT).elf > $(BINDIR)/$(PROJECT).S

$(BINDIR)/$(PROJECT).hex: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(BINDIR)/$(PROJECT).elf $(BINDIR)/$(PROJECT).hex

$(BINDIR)/$(PROJECT).elf: $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) $(OBJ) $(LDFLAGS) -o $(BINDIR)/$(PROJECT).elf


cleanBuild: clean

clean:
	find $(BINDIR) -type 'f' | grep -v "stable" | xargs rm
	rm -rf $(OBJDIR)

# Compilation
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(GCFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<


$(OBJDIR)/%.o: $(COMDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(GCFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(COMDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

