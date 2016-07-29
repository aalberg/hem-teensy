mflr r0
stw r0, 0x4(r1)
stwu r1,-0x20(r1)
stw r31,0x1C(r1)
stw r30,0x18(r1)
stw r29,0x14(r1)
lis r3,0x8016
ori r3,r3,0xB558
mtlr r3
blrl
cmpwi r3,3
bge- CLEANUP
li r30, 3
LAST_PLAYER_CHECK:
lis r3, 0x8045
ori r3, r3, 0x3130
mulli r4, r30, 0xE90
add r3, r3, r4
lwz r3, 0x0(r3)
cmpwi r3,0
bne LAST_PLAYER_FOUND
subi r30,r30,1
cmpwi r30,1
bge LAST_PLAYER_CHECK
LAST_PLAYER_FOUND:
addi r3, r3, 0x60
cmpw r3,r5
bne CLEANUP
lis r3,0x801A
ori r3,r3,0x4340 
mtlr r3 
lis r3,0x8048 
lbz r3,-0x62D0(r3)
blrl 
cmpwi r3,1
beq- CLEANUP
lis r3,0x8047
lwz r3,-0x493C(r3)
lis r4,0x8048
lwz r4,-0x62A8(r4)
cmpwi r4,0
bne PRE_UPDATE_CHECKS
cmpwi r3,0
bne ON_END_EVENT
bl startExiTransfer
li r3, 0x37
bl sendByteExi
lis r31, 0x8045
ori r31, r31, 0xAC4C
lhz r3, 0x1A(r31)
bl sendHalfExi
li r30, 0
MP_WRITE_PLAYER:
lis r3, 0x8045
ori r3, r3, 0x3130
mulli r4, r30, 0xE90
add r3, r3, r4
lwz r3, 0x0(r3)
cmpwi r3, 0
beq MP_INCREMENT
mr r3, r30
bl sendByteExi
lis r31, 0x8045
ori r31, r31, 0xAC4C
mulli r4, r30, 0x24
add r31, r31, r4
lbz r3, 0x6C(r31)
bl sendByteExi
lbz r3, 0x6D(r31)
bl sendByteExi
lbz r3, 0x6F(r31)
bl sendByteExi
MP_INCREMENT:
addi r30, r30, 1
cmpwi r30, 4
blt MP_WRITE_PLAYER
bl endExiTransfer
b CLEANUP
ON_END_EVENT:
bl startExiTransfer
li r3, 0x39
bl sendByteExi
lis r3, 0x8047
lbz r3, -0x4960(r3)
bl sendByteExi
bl endExiTransfer
b CLEANUP
PRE_UPDATE_CHECKS:
cmpwi r3,0
beq CLEANUP
lis r3, 0x8045
lbz r3, 0x30C9(r3)
cmpwi r3, 0
beq CLEANUP
bl startExiTransfer
li r3, 0x38
bl sendByteExi
lis r3,0x8047
lwz r3,-0x493C(r3)
bl sendWordExi
lis r3,0x804D
lwz r3,0x5F90(r3)
bl sendWordExi
li r30, 0
FU_WRITE_PLAYER:
lis r3, 0x8045
ori r3, r3, 0x3080
mulli r4, r30, 0xE90
add r29, r3, r4
lwz r31, 0xB0(r29)
cmpwi r31, 0
beq FU_INCREMENT
lwz r3,0x70(r31)
cmpwi r3, 0xB
bne FU_WRITE_CHAR_BLOCK
lwz r4, 0xB4(r29)
cmpwi r4, 0
beq FU_WRITE_CHAR_BLOCK
mr r31, r4
FU_WRITE_CHAR_BLOCK:
lwz r3,0x64(r31)
bl sendByteExi
lwz r3,0x70(r31)
bl sendHalfExi
lwz r3,0x110(r31)
bl sendWordExi
lwz r3,0x114(r31)
bl sendWordExi
lwz r3,0x680(r31)
bl sendWordExi
lwz r3,0x684(r31)
bl sendWordExi
lwz r3,0x698(r31)
bl sendWordExi
lwz r3,0x69c(r31)
bl sendWordExi
lwz r3,0x6b0(r31)
bl sendWordExi
lwz r3,0x6bc(r31)
bl sendWordExi
lwz r3,0x1890(r31)
bl sendWordExi
lwz r3,0x19f8(r31)
bl sendWordExi
lwz r3,0x20ec(r31)
bl sendByteExi
lhz r3,0x20f0(r31)
bl sendByteExi
lwz r3,0x1924(r31)
bl sendByteExi
lbz r3,0x8E(r29)
bl sendByteExi
lis r31, 0x804C
ori r31, r31, 0x1FAC
mulli r3, r30, 0x44
add r31, r31, r3
lhz r3, 0x2(r31)
bl sendHalfExi
lwz r3,0x30(r31)
bl sendWordExi
lwz r3,0x34(r31)
bl sendWordExi
FU_INCREMENT:
addi r30, r30, 1
cmpwi r30, 4
blt FU_WRITE_PLAYER
bl endExiTransfer
CLEANUP:
lwz r0, 0x24(r1)
lwz r31, 0x1C(r1)
lwz r30, 0x18(r1)
lwz r29, 0x14(r1)
addi r1, r1, 0x20
mtlr r0
b GECKO_END
startExiTransfer:
lis r11, 0xCC00
lhz r10, 0x4010(r11)
ori r10, r10, 0xFF
sth r10, 0x4010(r11)
li r10, 0x80
stw r10, 0x6814(r11)
blr
sendByteExi:
lis r11, 0xCC00
li r10, 0x9
slwi r3, r3, 24
stw r3, 0x6824(r11)
stw r10, 0x6820(r11)
EXI_CHECK_RECEIVE_WAIT:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT
lwz r3, 0x6824(r11)
srwi r3, r3, 24
blr
sendHalfExi:
lis r11, 0xCC00
li r10, 0x19
slwi r3, r3, 16
stw r3, 0x6824(r11)
stw r10, 0x6820(r11)
EXI_CHECK_RECEIVE_WAIT_HALF:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT_HALF
lwz r3, 0x6824(r11)
srwi r3, r3, 16
blr
sendWordExi:
lis r11, 0xCC00
li r10, 0x39
stw r3, 0x6824(r11)
stw r10, 0x6820(r11)
EXI_CHECK_RECEIVE_WAIT_WORD:                
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT_WORD
lwz r3, 0x6824(r11)
blr
endExiTransfer:
lis r11, 0xCC00
li r10, 0
stw r10, 0x6814(r11)
blr
GECKO_END:
lwz r0, 0x94(r1)