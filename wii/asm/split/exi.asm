#***************************************************************************
# EXI transfer functions
# Taken from Fizzi's Hardware Enhanced Melee code:
# https://github.com/JLaferri/HardwareEnhancedMelee/blob/master/ASM/MatchDataExtraction.asm
# 
# These functions are injected as separate Gecko codes. The injection point for each function is
# specified in the comment block before the function.
#
# All functions use lr, r3, r10, and r11. Those registeres must be saved before calling the EXI
# functions if the caller cares about the value of them.
#***************************************************************************

#***************************************************************************
# subroutine: startExiTransfer
# injection point: 0x8022887C
# description: prepares port B exi to be written to
#***************************************************************************
lis r11, 0xCC00 # top bytes of address of EXI registers

# disable read/write protection on memory pages
lhz r10, 0x4010(r11)
ori r10, r10, 0xFF
sth r10, 0x4010(r11) # disable MP3 memory protection

# set up EXI, see http://www.gc-forever.com/yagcd/chap5.html Section 5.9 for details.
li r10, 0xB0 # bit pattern to set clock to 1 MHz and enable CS for device 0
stw r10, 0x6814(r11) # start transfer, write to parameter register

blr

#***************************************************************************
# subroutine: sendByteExi
# injection point: 0x80228880
# description: sends one byte over port B exi
# inputs: r3 byte to send
# outputs: r3 received byte
#***************************************************************************
lis r11, 0xCC00 # top bytes of address of EXI registers
li r10, 0x9 # bit pattern to write to control register to write one byte

# write value in r3 to EXI
slwi r3, r3, 24 # the byte to send has to be left shifted
stw r3, 0x6824(r11) # store current byte into transfer register
stw r10, 0x6820(r11) # write to control register to begin transfer

# wait until byte has been transferred
EXI_CHECK_RECEIVE_WAIT:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT

# read values from transfer register to r3 for output
lwz r3, 0x6824(r11) # read from transfer register
srwi r3, r3, 24 # shift byte to the right of the register

blr

#***************************************************************************
# subroutine: sendHalfExi
# injection point: 0x80228884
# description: sends two bytes over port B exi
# inputs: r3 bytes to send
# outputs: r3 received bytes
#***************************************************************************
lis r11, 0xCC00 # top bytes of address of EXI registers
li r10, 0x19 # bit pattern to write to control register to write one byte

# write value in r3 to EXI
slwi r3, r3, 16 # the bytes to send have to be left shifted
stw r3, 0x6824(r11) # store bytes into transfer register
stw r10, 0x6820(r11) # write to control register to begin transfer

# wait until byte has been transferred
EXI_CHECK_RECEIVE_WAIT_HALF:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT_HALF

# read values from transfer register to r3 for output
lwz r3, 0x6824(r11) # read from transfer register
srwi r3, r3, 16 # shift byte to the right of the register

blr

#***************************************************************************
# subroutine: sendWordExi
# injection point: 0x80228888
# description: sends one word over port B exi
# inputs: r3 word to send
# outputs: r3 received word
#***************************************************************************
lis r11, 0xCC00 # top bytes of address of EXI registers
li r10, 0x39 # bit pattern to write to control register to write four bytes

# write value in r3 to EXI
stw r3, 0x6824(r11) # store current bytes into transfer register
stw r10, 0x6820(r11) # write to control register to begin transfer

# wait until byte has been transferred
EXI_CHECK_RECEIVE_WAIT_WORD:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT_WORD

# read values from transfer register to r3 for output
lwz r3, 0x6824(r11) # read from transfer register

blr

#***************************************************************************
# subroutine: endExiTransfer
# injection point: 0x8022888C
# description: stops port B writes
#***************************************************************************
lis r11, 0xCC00 # top bytes of address of EXI registers

li r10, 0
stw r10, 0x6814(r11) # write 0 to the parameter register

blr
