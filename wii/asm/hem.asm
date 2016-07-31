#**************************************************************************
# Hardware Enhanced Melee ASM
#
# Taken from Fizzi's Hardware Enhanced Melee code and modified to use other gecko codes as
# functions:
# https://github.com/JLaferri/HardwareEnhancedMelee/blob/master/ASM/MatchDataExtraction.asm
#
# Inject at address 0x8006C0D8
# Unsure what the inject target function does exactly but it ends up calling the stock subtraction
# instructions. It is called once per frame per character. It is also called during the score
# screen. The replaced code line is executed at the end of this function.
# 
# The injected asm is put at the end of the function, and doesn't use any of the volatiles registers
# before returning. r3-r12 should be safe to use.
#***************************************************************************

#***************************************************************************
# subroutine: writeStats
# description: writes stats to the EXI port on each frame
# inputs: r5 = pointer of the player calculations are being run on + 0x60
#***************************************************************************
# Create stack frame and store link register.
mflr r0
stw r0, 0x4(r1)
stwu r1,-0x20(r1)
stw r31,0x1C(r1)
stw r30,0x18(r1)
stw r29,0x14(r1)

# Check if there are 5 or more players, skip sending any packet if so.
lis r3,0x8016 # Load and call CountPlayers function.
ori r3,r3,0xB558
mtlr r3
blrl
cmpwi r3,5 # Check if there are 3 or more players, and skip everything if so.
bge- CLEANUP
mr r9, r3 # Copy the number of players to r9 so we don't have to calculate it later.

# Check if r5 contains a pointer to the last player in the game. If not, don't run this function,
# since we don't want to send data more than once per frame.
li r30, 3 # Scan backwards from player 4.
LAST_PLAYER_CHECK:
lis r3, 0x8045 # Compute the address to the player data.
ori r3, r3, 0x3130
mulli r4, r30, 0xE90
add r3, r3, r4
lwz r3, 0x0(r3) # Dereference player state (first thing in the struct).
cmpwi r3,0 # Check if the current player is in the game
bne LAST_PLAYER_FOUND # If so, proceed to the next check.

subi r30,r30,1 # If not, decrement player number and keep looking.
cmpwi r30,1
bge LAST_PLAYER_CHECK

LAST_PLAYER_FOUND:
addi r3, r3, 0x60 # Check if the last player in the game is the one calculations are being run on.
cmpw r3, r5
bne CLEANUP # If not, don't send data.

# Check if for single player mode, and if so don't sent data.
lis r3,0x801A # Load and call SinglePlayer_Check function.
ori r3,r3,0x4340 
mtlr r3 
lis r3,0x8048 
lbz r3,-0x62D0(r3) # load menu controller major
blrl 
cmpwi r3,1 # Return value stored in r3, 1 if single player mode.
beq- CLEANUP # If in single player, don't sent data.

# Figure out what part of the match we're in. The frame count increments starting the first frame
# of the match, and the scene controller will be 0 during the start and end of a match, and nonzero
# otherwise.
lis r3,0x8047
lwz r3,-0x493C(r3) # Load match frame count.
lis r4,0x8048
lwz r4,-0x62A8(r4) # Load scene controller value.

# Check the scene controller first, if it's nonzero then send an update packet.
cmpwi r4,0
bne PRE_UPDATE_CHECKS

# Send a START or END packet depending on the frame count. The frame count will be 0 if this is the
# start of a match.
cmpwi r3,0
bne ON_END_EVENT

#***************************************************************************
# START packet
#***************************************************************************
bl startExiTransfer # Load and call startExiTransfer function.

li r3, 0x37 # Send the START packet code.
bl sendByteExi

lis r31, 0x8045 # I have no idea what this address contains, but it's apparently the right data?
ori r31, r31, 0xAC4C
lhz r3, 0x1A(r31) # Dereference the stage ID.
bl sendHalfExi

mr r3, r9 # Send the number of player params.
bl sendByteExi

li r30, 0 # Loop variable, player index.
MP_WRITE_PLAYER:
# Load the character data pointer for the current player.
lis r3, 0x8045
ori r3, r3, 0x3130
mulli r4, r30, 0xE90
add r3, r3, r4
lwz r3, 0x0(r3)

# Skip this player if they are not in the game.
cmpwi r3, 0
beq MP_INCREMENT

mr r3, r30 # Send the player port number.
bl sendByteExi

# Get the start address of some player struct (see above comment about 0x8045AC4C).
lis r31, 0x8045
ori r31, r31, 0xAC4C
mulli r4, r30, 0x24
add r31, r31, r4

lbz r3, 0x6C(r31) # Character ID.
bl sendByteExi
lbz r3, 0x6D(r31) # Player type.
bl sendByteExi
lbz r3, 0x6F(r31) # Costume ID.
bl sendByteExi

MP_INCREMENT:
addi r30, r30, 1
cmpwi r30, 4
blt MP_WRITE_PLAYER

bl endExiTransfer # Load and call endExiTransfer function.
b CLEANUP

#***************************************************************************
# END packet
#***************************************************************************
ON_END_EVENT:
bl startExiTransfer # Load and call startExiTransfer function.

li r3, 0x39 # Send the END packet code.
bl sendByteExi

# Send the win condition byte. This byte will be 0 on ragequit, 3 on win by stock loss.
lis r3, 0x8047
lbz r3, -0x4960(r3)
bl sendByteExi

bl endExiTransfer # Load and call endExiTransfer function.
b CLEANUP

#***************************************************************************
# UPDATE packet
#***************************************************************************
PRE_UPDATE_CHECKS:
# If the frame count is 0, the game is still in the countdown freeze, so don't send data.
cmpwi r3,0
beq CLEANUP

# If we are in the results screen, don't send data. The address checked exists for all players and
# appears to be 1 in game, and 0 during the results screen.
lis r3, 0x8045
lbz r3, 0x30C9(r3)
cmpwi r3, 0
beq CLEANUP

#***************************
# Start sending UPDATE data.
#***************************
bl startExiTransfer # Load and call startExiTransfer function.

li r3, 0x38
bl sendByteExi # Send the UPDATE packet code.

lis r3,0x8047
lwz r3,-0x493C(r3) # Match frame count.
bl sendWordExi

lis r3,0x804D
lwz r3,0x5F90(r3) # RNG seed.
bl sendWordExi

mr r3, r9 # Send the number of player params.
bl sendByteExi

li r30, 0 # Loop variable, player index.
FU_WRITE_PLAYER:
# Load the character data pointer for the current player.
lis r3, 0x8045
ori r3, r3, 0x3080
mulli r4, r30, 0xE90
add r29, r3, r4 # Load the Static Player Block address into r29.
lwz r31, 0xB0(r29) # Load Player Entity Struct address into r31.
# This code makes the stupid terrible assumption that the Player Character Data address is 0x60
# after the Player Entity Struct, but it seems to work.

# Skip this player if they are not in the game.
cmpwi r31, 0
beq FU_INCREMENT

# Check if the current character is sheik, zelda, or ICs. The pointer at offset 0xB4 will be 0 if the
# character is not sheik, zelda, or ICs
lwz r4, 0xB4(r29)
cmpwi r4, 0
beq FU_WRITE_CHAR_BLOCK

# Check for sleep action state to load alternate character (sheik/zelda). The action state will
# never be the sleep state for ICs.
lwz r3,0x70(r31) # Action state ID.
cmpwi r3, 0xB # The sleep state is 0xB.
bne FU_WRITE_CHAR_BLOCK

mr r31, r4 # Move the alternate character pointer to the active pointer.

FU_WRITE_CHAR_BLOCK:
lwz r3,0x64(r31) # Internal char ID.
bl sendByteExi
lwz r3,0x70(r31) # Action state ID.
bl sendHalfExi
lwz r3,0x110(r31) # Top-N X coord.
bl sendWordExi
lwz r3,0x114(r31) # Top-N Y coord.
bl sendWordExi
lwz r3,0x680(r31) # Joystick X axis.
bl sendWordExi
lwz r3,0x684(r31) # Joystick Y axis.
bl sendWordExi
lwz r3,0x698(r31) # C-stick X axis.
bl sendWordExi
lwz r3,0x69c(r31) # C-stick Y axis.
bl sendWordExi
lwz r3,0x6b0(r31) # Analog trigger input.
bl sendWordExi
lwz r3,0x6bc(r31) # Buttons pressed this frame.
bl sendWordExi
lwz r3,0x1890(r31) # Current damage.
bl sendWordExi
lwz r3,0x19f8(r31) # Shield size.
bl sendWordExi
lwz r3,0x20ec(r31) # Last attack landed.
bl sendByteExi
lhz r3,0x20f0(r31) # Combo count.
bl sendByteExi
lwz r3,0x1924(r31) # Player who last hit this player.
bl sendByteExi

lbz r3,0x8E(r29) # Stocks remaining.
bl sendByteExi

# Raw controller inputs.
lis r31, 0x804C
ori r31, r31, 0x1FAC
mulli r3, r30, 0x44
add r31, r31, r3

lhz r3, 0x2(r31) # Constant button presses.
bl sendHalfExi
lwz r3,0x30(r31) # L analog trigger.
bl sendWordExi
lwz r3,0x34(r31) # R analog trigger.
bl sendWordExi

FU_INCREMENT:
addi r30, r30, 1
cmpwi r30, 4
blt FU_WRITE_PLAYER

bl endExiTransfer # Call endExiTransfer function.

b CLEANUP

#***************************************************************************
# subroutine: startExiTransfer
# description: prepares port B exi to be written to
#***************************************************************************
startExiTransfer:
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
# description: sends one byte over port B exi
# inputs: r3 byte to send
# outputs: r3 received byte
#***************************************************************************
sendByteExi:
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
# description: sends two bytes over port B exi
# inputs: r3 bytes to send
# outputs: r3 received bytes
#***************************************************************************
sendHalfExi:
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
# description: sends one word over port B exi
# inputs: r3 word to send
# outputs: r3 received word
#***************************************************************************
sendWordExi:
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
# description: stops port B writes
#***************************************************************************
endExiTransfer:
lis r11, 0xCC00 # top bytes of address of EXI registers

li r10, 0
stw r10, 0x6814(r11) # write 0 to the parameter register

blr

#***************************************************************************
# CLEANUP step
#***************************************************************************
CLEANUP:
# Restore registers and stack pointer.
lwz r0, 0x24(r1)
lwz r31, 0x1C(r1)
lwz r30, 0x18(r1)
lwz r29, 0x14(r1)
addi r1, r1, 0x20
mtlr r0

lwz r0, 0x94(r1) # Execute the replaced code line.