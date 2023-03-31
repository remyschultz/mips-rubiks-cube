	.data
faceF:	.space 36 # 4 bytes * 9 stickers per face
faceU:	.space 36
faceR:	.space 36
faceD:	.space 36
faceL:	.space 36
faceB:	.space 36

inputBuffer:	.space 4

symbolF:	.asciiz "#"
symbolU:	.asciiz "O"
symbolR:	.asciiz "&"
symbolD:	.asciiz "X"
symbolL:	.asciiz "%"
symbolB:	.asciiz "@"

newline:	.asciiz "\n"
spaces2:	.asciiz "  "
spaces3:	.asciiz "   "
spaces4:	.asciiz "    "
spaces6:	.asciiz "      "
spaces7:	.asciiz "       "
spaces8:	.asciiz "        "
spaces9:	.asciiz "         "
spaces10:	.asciiz "          "
spaces11:	.asciiz "           "

scrambling:	.asciiz "Scrambling...\n"
go:		.asciiz "Go!\n"
solved:		.asciiz "Solved!\n"

lParen:		.asciiz " ("
moves:		.asciiz " moves)\n"

	.text
main:
	jal	fillFaces	# put the stickers on the cube
	jal	draw		# draw the cube to the screen

	jal	scramble	# scramble the cube

	li	$v0, 30		# get system time (start the timer)
	syscall

	move	$s0, $a0	# system time in ms stored in $s0

	jal	gameLoopEnter	# start the loop to get input and make turns

	li	$v0, 10		# exit the program
	syscall


gameLoopEnter:
	addi	$sp, $sp, -4	# entry block
	sw	$ra, 0($sp)	# save the return address
gameLoop:
	li	$v0, 8		# get input as string
	la	$a0, inputBuffer# save input to inputBuffer
	li	$a1, 4		# get 4 characters
	syscall

	lbu	$t0, inputBuffer+1	# check 2nd character; that tells us the direction of the turn
	beq	$t0, '\'', ccw		# ' indicates ccw turn
	beq	$t0, '2', double	# 2 indicates double turn

	li	$a1, 0			# otherwise cw turn
	j	checkFace		# set $a1=0, then check which face is turned
ccw:
	li	$a1, 1			# $a1=1 means ccw turn
	j	checkFace
double:
	li	$a1, 2			# $a1=2 means double turn
	j	checkFace

checkFace:
	lbu	$t0, inputBuffer	# check 1st character
					# that will tell us which face we are turning
	beq	$t0, 'F', f	# F (front)
	beq	$t0, 'f', fw	# F wide

	beq	$t0, 'U', u	# U (up)
	beq	$t0, 'u', uw	# U wide

	beq	$t0, 'R', r	# R (right)
	beq	$t0, 'r', rw	# R wide

	beq	$t0, 'D', d	# D (down)
	beq	$t0, 'd', dw	# D wide

	beq	$t0, 'L', l	# L (left)
	beq	$t0, 'l', lw	# L wide

	beq	$t0, 'B', b	# B (back)
	beq	$t0, 'b', bw	# B wide

	beq	$t0, 'm', m	# M (middle)
	beq	$t0, 'M', m

	beq	$t0, 's', s	# S (slice)
	beq	$t0, 'S', s

	beq	$t0, 'e', e	# E (equator)
	beq	$t0, 'E', e

	beq	$t0, 'x', x	# X rotation
	beq	$t0, 'X', x

	beq	$t0, 'y', y	# y rotation
	beq	$t0, 'Y', y

	beq	$t0, 'z', z	# z rotation
	beq	$t0, 'Z', z

	beq	$t0, 'q', gameLoopExit	# q to quit
	beq	$t0, 'Q', gameLoopExit

	# if we get to here, input was not valid
	# so draw the cube again and get a new input
	jal	draw
	j	gameLoop

# regular turns
# set $a0 to represent face
f:
	li	$a0, 0
	j	doTurn
u:
	li	$a0, 1
	j	doTurn
r:
	li	$a0, 2
	j	doTurn
d:
	li	$a0, 3
	j	doTurn
l:
	li	$a0, 4
	j	doTurn
b:
	li	$a0, 5
	j	doTurn

# slice moves
# turn an inner slice
m:
	li	$a0, 6	# M is parallel to L
	j	doTurn
s:
	li	$a0, 7	# S is parallel to F
	j	doTurn
e:
	li	$a0, 8	# E is parallel to D
	j	doTurn

# wide turns
# combination of a regular move and a slice move
# use turn function for first turn- doesn't draw cube or increment turn counter
# use doTurn for second turn- draw cube once & count wide move as one turn only
fw:
	li	$a0, 0	# turn F
	jal	turn
	li	$a0, 7	# turn S
	j	doTurn
uw:
	li	$a0, 1	# turn U
	jal	turn

	move	$a0, $a1
	jal	invert	# invert direction
	move	$a1, $v0

	li	$a0, 8	# turn E'
	j	doTurn	# (this will turn E in the case of u')
rw:
	li	$a0, 2	# turn R
	jal	turn

	move	$a0, $a1
	jal	invert	# invert direction
	move	$a1, $v0

	li	$a0, 6	# turn M'
	j	doTurn
dw:
	li	$a0, 3	# turn D
	jal	turn
	li	$a0, 8	# turn E
	j	doTurn
lw:
	li	$a0, 4	# turn L
	jal	turn
	li	$a0, 6	# turn M
	j	doTurn
bw:
	li	$a0, 5	# turn B
	jal	turn

	move	$a0, $a1
	jal	invert	# invert direction
	move	$a1, $v0

	li	$a0, 7	# turn S
	j	doTurn

# cube rotations
# a cube rotation is the same as doing 3 moves on parallel slices
# doesn't count as a move for move counter
# so we never call doTurn
x:	# x-rotation = R + M' + L'
	li	$a0, 2	# R
	jal	turn

	move	$a0, $a1
	jal	invert	# invert
	move	$a1, $v0

	li	$a0, 6	# M'
	jal	turn

	li	$a0, 4	# set up L'
	j	finishRotation

y:	# y-rotation = U + E' + D'
	li	$a0, 1	# U
	jal	turn

	move	$a0, $a1
	jal	invert	# invert
	move	$a1, $v0

	li	$a0, 8	# E'
	jal	turn

	li	$a0, 3	# D'
	j	finishRotation

z:	# z-rotation = F + S + B'
	li	$a0, 0	# F
	jal	turn

	li	$a0, 7	# S
	jal	turn

	move	$a0, $a1
	jal	invert	# invert
	move	$a1, $v0

	li	$a0, 5	# B'
	j	finishRotation

finishRotation:
	jal	turn	# complete final turn
	jal	draw	# draw cube
	j	gameLoop# do all it again

doTurn:
	addi	$s1, $s1, 1	# increment turn counter

	jal	turn		# do the turn
	jal	draw		# draw cube
	jal	checkSolved	# is it solved?
	j	gameLoop

gameLoopExit:
	lw	$ra, 0($sp)	# restore return address
	addi	$sp, $sp, 4

	jr	$ra


# inverts a direction
# cw -> ccw
# ccw -> cw
# x2 -> x2
# $a0 = direction
# returns $v0 = opposite direction
invert:
	# this seems complicated but I think it's more efficient than branching
	seq	$t0, $a0, 0	# set $t0 = 1 if direction is 0
	srl	$v0, $a0, 1
	sll	$v0, $v0, 1	# these shifts set $v0 to 0 for cw & ccw, and keep x2 as 2
	add	$v0, $v0, $t0	# now add $t0

	jr	$ra

# scrambles the cube
scramble:
	addi	$sp, $sp, -8	# entry block
	sw	$s0, 0($sp)
	sw	$ra, 4($sp)

	li	$s0, 0		# NOT a leaf function, so lets keep our loop index somewhere safe
scrambleLoop:

	li	$v0, 42	# random int
	li	$a1, 2	# 0-2 (turn direction)
	syscall
	move	$t0, $a0

	li	$a1, 5	# 0-5 (face)
	syscall		# only doing "regular" turns to scramble

	move	$a1, $t0
	jal	turn	# perform the random turn


	beq	$s0, 30, scrambleExit	# exit condition after 30 turns- that should be plenty

	li	$v0, 4		# print string "Scrambling..."
	la	$a0, scrambling
	syscall

	jal	draw	# draw cube


	li	$v0, 32		# pause for 100ms
	li	$a0, 100	# makes the scrambling more dramatic
	syscall

	addi	$s0, $s0, 1	# increment loop counter
	j	scrambleLoop

scrambleExit:
	# there is one last turn that has not yet been displayed
	# tell the user to start solving
	li	$v0, 4
	la	$a0, go
	syscall

	jal	draw

	lw	$s0, 0($sp)	# exit block
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8

	jr	$ra


# $a0 = face
# $a1 = direction
#	0 -> clockwise
#	1 -> counter-clockwise
#	2 -> double turn
turn:
	addi	$sp, $sp, -12
	sw	$a0, 0($sp)
	sw	$a1, 4($sp)
	sw	$ra, 8($sp)

	beq	$a0, 0, turnF	# branch to appropriate face
	beq	$a0, 1, turnU
	beq	$a0, 2, turnR
	beq	$a0, 3, turnD
	beq	$a0, 4, turnL
	beq	$a0, 5, turnB

	beq	$a0, 6, turnM	# or slice
	beq	$a0, 7, turnS
	beq	$a0, 8, turnE

turnF:				# we are turning F
	beq	$a1, 0, turnFCW	# clockwise?
	beq	$a1, 1, turnFCCW# counter-clockwise?
	beq	$a1, 2, turnFX2	# double?

turnFCW:
	jal	cycleInnerStickersCW	# cycle the "inner" stickers
					# these are the sticker directly on the face
					# and is the same relative to every face

					# these "outer" stickers are not so easy to cycle
					# the most straightforward way is brute force
					# we do  3 separate cycles to finish the turn
	# cycle U6, R0, D2, L8
	la	$a0, faceU+24	# load 4 addresses
	la	$a1, faceR+0
	la	$a2, faceD+8
	la	$a3, faceL+32
	jal	cycleStickers	# cycle the stickers in that order

	# cycle U7, R3, D1, L5
	la	$a0, faceU+28
	la	$a1, faceR+12
	la	$a2, faceD+4
	la	$a3, faceL+20
	jal	cycleStickers

	# cycle U8, R6, D0, L2
	la	$a0, faceU+32
	la	$a1, faceR+24
	la	$a2, faceD+0
	la	$a3, faceL+8
	jal	cycleStickers

	j	turnExit

turnFCCW:				# counter-clockwise is very similar, just a slightly different order for the cycle
	jal	cycleInnerStickersCCW

	# cycle U6, L8, D2, R0
	la	$a0, faceU+24
	la	$a1, faceL+32
	la	$a2, faceD+8
	la	$a3, faceR+0
	jal	cycleStickers

	# cycle U7, L5, D1, R3
	la	$a0, faceU+28
	la	$a1, faceL+20
	la	$a2, faceD+4
	la	$a3, faceR+12
	jal	cycleStickers

	# cycle U8, L2, D0, R6
	la	$a0, faceU+32
	la	$a1, faceL+8
	la	$a2, faceD+0
	la	$a3, faceR+24
	jal	cycleStickers

	j	turnExit

turnFX2:				# and then double turn is just swapping stickers across to the opposite side of the cube
	jal	cycleInnerStickersX2

	# swap U6, D2
	lw	$t0, faceU+24
	lw	$t1, faceD+8
	sw	$t0, faceD+8
	sw	$t1, faceU+24

	# swap U7, D1
	lw	$t0, faceU+28
	lw	$t1, faceD+4
	sw	$t0, faceD+4
	sw	$t1, faceU+28

	# swap U8, D0
	lw	$t0, faceU+32
	lw	$t1, faceD+0
	sw	$t0, faceD+0
	sw	$t1, faceU+32

	# swap R0, L8
	lw	$t0, faceR+0
	lw	$t1, faceL+32
	sw	$t0, faceL+32
	sw	$t1, faceR+0

	# swap R3, L5
	lw	$t0, faceR+12
	lw	$t1, faceL+20
	sw	$t0, faceL+20
	sw	$t1, faceR+12

	# swap R6, L2
	lw	$t0, faceR+24
	lw	$t1, faceL+8
	sw	$t0, faceL+8
	sw	$t1, faceR+24

	j	turnExit

turnU:					# and again for the U face
	beq $a1, 0, turnUCW
	beq $a1, 1, turnUCCW
	beq $a1, 2, turnUX2
turnUCW:
	jal cycleInnerStickersCW

	# cycle B2, R2, F2, L2
	la	$a0, faceB+8
	la	$a1, faceR+8
	la	$a2, faceF+8
	la	$a3, faceL+8
	jal cycleStickers

	# cycle B1, R1, F1, L1
	la	$a0, faceB+4
	la	$a1, faceR+4
	la	$a2, faceF+4
	la	$a3, faceL+4
	jal cycleStickers

	# cycle B0, R0, F0, L0
	la	$a0, faceB+0
	la	$a1, faceR+0
	la	$a2, faceF+0
	la	$a3, faceL+0
	jal cycleStickers

	j turnExit

turnUCCW:
	jal cycleInnerStickersCCW

	# cycle B2, R2, F2, L2
	la	$a0, faceB+8
	la	$a1, faceL+8
	la	$a2, faceF+8
	la	$a3, faceR+8
	jal cycleStickers

	# cycle B1, R1, F1, L1
	la	$a0, faceB+4
	la	$a1, faceL+4
	la	$a2, faceF+4
	la	$a3, faceR+4
	jal cycleStickers

	# cycle B0, R0, F0, L0
	la	$a0, faceB+0
	la	$a1, faceL+0
	la	$a2, faceF+0
	la	$a3, faceR+0
	jal cycleStickers

	j turnExit

turnUX2:
	jal cycleInnerStickersX2

	# swap B2, F2
	lw	$t0, faceB+8
	lw	$t1, faceF+8
	sw	$t0, faceF+8
	sw	$t1, faceB+8

	# swap B1, F1
	lw	$t0, faceB+4
	lw	$t1, faceF+4
	sw	$t0, faceF+4
	sw	$t1, faceB+4

	# swap B0, F0
	lw	$t0, faceB+0
	lw	$t1, faceF+0
	sw	$t0, faceF+0
	sw	$t1, faceB+0

	# swap R2, L2
	lw	$t0, faceR+8
	lw	$t1, faceL+8
	sw	$t0, faceL+8
	sw	$t1, faceR+8

	# swap R1, L1
	lw	$t0, faceR+4
	lw	$t1, faceL+4
	sw	$t0, faceL+4
	sw	$t1, faceR+4

	# swap R0, L0
	lw	$t0, faceR+0
	lw	$t1, faceL+0
	sw	$t0, faceL+0
	sw	$t1, faceR+0

	j turnExit

turnR:				# and R
	beq	$a1, 0, turnRCW
	beq	$a1, 1, turnRCCW
	beq	$a1, 2, turnRX2

turnRCW:
	jal cycleInnerStickersCW

	# cycle U8, B0, D8, F8
	la	$a0, faceU+32
	la	$a1, faceB+0
	la	$a2, faceD+32
	la	$a3, faceF+32
	jal 	cycleStickers

	# cycle U5, B3, D5, F5
	la	$a0, faceU+20
	la	$a1, faceB+12
	la	$a2, faceD+20
	la	$a3, faceF+20
	jal 	cycleStickers

	# cycle U2, B6, D2, F2
	la	$a0, faceU+8
	la	$a1, faceB+24
	la	$a2, faceD+8
	la	$a3, faceF+8
	jal 	cycleStickers

	j	turnExit

turnRCCW:
	jal cycleInnerStickersCCW

	# cycle U8, B0, D8, F8
	la	$a0, faceU+32
	la	$a1, faceF+32
	la	$a2, faceD+32
	la	$a3, faceB+0
	jal cycleStickers

	# cycle U5, B3, D5, F5
	la	$a0, faceU+20
	la	$a1, faceF+20
	la	$a2, faceD+20
	la	$a3, faceB+12
	jal cycleStickers

	# cycle U2, B6, D2, F2
	la	$a0, faceU+8
	la	$a1, faceF+8
	la	$a2, faceD+8
	la	$a3, faceB+24
	jal cycleStickers

	j turnExit

turnRX2:
	jal cycleInnerStickersX2

	# swap U8, D8
	lw	$t0, faceU+32
	lw	$t1, faceD+32
	sw	$t0, faceD+32
	sw	$t1, faceU+32

	# swap U5, D5
	lw	$t0, faceU+20
	lw	$t1, faceD+20
	sw	$t0, faceD+20
	sw	$t1, faceU+20

	# swap U2, D2
	lw	$t0, faceU+8
	lw	$t1, faceD+8
	sw	$t0, faceD+8
	sw	$t1, faceU+8

	# swap B0, F8
	lw	$t0, faceB+0
	lw	$t1, faceF+32
	sw	$t0, faceF+32
	sw	$t1, faceB+0

	# swap B3, F5
	lw	$t0, faceB+12
	lw	$t1, faceF+20
	sw	$t0, faceF+20
	sw	$t1, faceB+12

	# swap B6, F2
	lw	$t0, faceB+24
	lw	$t1, faceF+8
	sw	$t0, faceF+8
	sw	$t1, faceB+24

	j turnExit

turnD:				# and D
	beq $a1, 0, turnDCW
	beq $a1, 1, turnDCCW
	beq $a1, 2, turnDX2
turnDCW:
	jal cycleInnerStickersCW

	# cycle F6, R6, B6, L6
	la	$a0, faceF+24
	la	$a1, faceR+24
	la	$a2, faceB+24
	la	$a3, faceL+24
	jal cycleStickers

	# cycle F7, R7, B7, L7
	la	$a0, faceF+28
	la	$a1, faceR+28
	la	$a2, faceB+28
	la	$a3, faceL+28
	jal cycleStickers

	# cycle F8, R8, B8, L8
	la	$a0, faceF+32
	la	$a1, faceR+32
	la	$a2, faceB+32
	la	$a3, faceL+32
	jal cycleStickers

	j turnExit

turnDCCW:
	jal cycleInnerStickersCCW

	# cycle F6, R6, B6, L6
	la	$a0, faceF+24
	la	$a1, faceL+24
	la	$a2, faceB+24
	la	$a3, faceR+24
	jal cycleStickers

	# cycle F7, R7, B7, L7
	la	$a0, faceF+28
	la	$a1, faceL+28
	la	$a2, faceB+28
	la	$a3, faceR+28
	jal cycleStickers

	# cycle F8, R8, B8, L8
	la	$a0, faceF+32
	la	$a1, faceL+32
	la	$a2, faceB+32
	la	$a3, faceR+32
	jal cycleStickers

	j turnExit
turnDX2:
	jal cycleInnerStickersX2

	# swap F6, B6
	lw	$t0, faceF+24
	lw	$t1, faceB+24
	sw	$t0, faceB+24
	sw	$t1, faceF+24

	# swap F7, B7
	lw	$t0, faceF+28
	lw	$t1, faceB+28
	sw	$t0, faceB+28
	sw	$t1, faceF+28

	# swap F8, B8
	lw	$t0, faceF+32
	lw	$t1, faceB+32
	sw	$t0, faceB+32
	sw	$t1, faceF+32

	# swap R6, L6
	lw	$t0, faceR+24
	lw	$t1, faceL+24
	sw	$t0, faceL+24
	sw	$t1, faceR+24

	# swap R7, L7
	lw	$t0, faceR+28
	lw	$t1, faceL+28
	sw	$t0, faceL+28
	sw	$t1, faceR+28

	# swap R8, L8
	lw	$t0, faceR+32
	lw	$t1, faceL+32
	sw	$t0, faceL+32
	sw	$t1, faceR+32

	j turnExit

turnL:				# ...and L
	beq $a1, 0, turnLCW
	beq $a1, 1, turnLCCW
	beq $a1, 2, turnLX2
turnLCW:
	jal cycleInnerStickersCW

	# cycle U0, F0, D0, B8
	la	$a0, faceU+0
	la	$a1, faceF+0
	la	$a2, faceD+0
	la	$a3, faceB+32
	jal cycleStickers

	# cycle U3, F3, D3, B5
	la	$a0, faceU+12
	la	$a1, faceF+12
	la	$a2, faceD+12
	la	$a3, faceB+20
	jal cycleStickers

	# cycle U6, F6, D6, B2
	la	$a0, faceU+24
	la	$a1, faceF+24
	la	$a2, faceD+24
	la	$a3, faceB+8
	jal cycleStickers

	j turnExit

turnLCCW:
	jal cycleInnerStickersCCW

	# cycle U0, F0, D0, B8
	la	$a0, faceU+0
	la	$a1, faceB+32
	la	$a2, faceD+0
	la	$a3, faceF+0
	jal cycleStickers

	# cycle U3, F3, D3, B5
	la	$a0, faceU+12
	la	$a1, faceB+20
	la	$a2, faceD+12
	la	$a3, faceF+12
	jal cycleStickers

	# cycle U6, F6, D6, B2
	la	$a0, faceU+24
	la	$a1, faceB+8
	la	$a2, faceD+24
	la	$a3, faceF+24
	jal cycleStickers

	j turnExit
turnLX2:
	jal cycleInnerStickersX2

	# swap U0, D0
	lw	$t0, faceU+0
	lw	$t1, faceD+0
	sw	$t0, faceD+0
	sw	$t1, faceU+0

	# swap U3, D3
	lw	$t0, faceU+12
	lw	$t1, faceD+12
	sw	$t0, faceD+12
	sw	$t1, faceU+12

	# swap U6, D6
	lw	$t0, faceU+24
	lw	$t1, faceD+24
	sw	$t0, faceD+24
	sw	$t1, faceU+24

	# swap F0, B8
	lw	$t0, faceF+0
	lw	$t1, faceB+32
	sw	$t0, faceB+32
	sw	$t1, faceF+0

	# swap F3, B5
	lw	$t0, faceF+12
	lw	$t1, faceB+20
	sw	$t0, faceB+20
	sw	$t1, faceF+12

	# swap F6, B2
	lw	$t0, faceF+24
	lw	$t1, faceB+8
	sw	$t0, faceB+8
	sw	$t1, faceF+24

	j turnExit

turnB:				# and finally B
	beq $a1, 0, turnBCW
	beq $a1, 1, turnBCCW
	beq $a1, 2, turnBX2
turnBCW:
	jal cycleInnerStickersCW

	# cycle U2, L0, D6, R8
	la	$a0, faceU+8
	la	$a1, faceL+0
	la	$a2, faceD+24
	la	$a3, faceR+32
	jal cycleStickers

	# cycle U1, L3, D7, R5
	la	$a0, faceU+4
	la	$a1, faceL+12
	la	$a2, faceD+28
	la	$a3, faceR+20
	jal cycleStickers

	# cycle U0, L6, D8, R2
	la	$a0, faceU+0
	la	$a1, faceL+24
	la	$a2, faceD+32
	la	$a3, faceR+8
	jal cycleStickers

	j turnExit

turnBCCW:
	jal cycleInnerStickersCCW

	# cycle U2, L0, D6, R8
	la	$a0, faceU+8
	la	$a1, faceR+32
	la	$a2, faceD+24
	la	$a3, faceL+0
	jal cycleStickers

	# cycle U1, L3, D7, R5
	la	$a0, faceU+4
	la	$a1, faceR+20
	la	$a2, faceD+28
	la	$a3, faceL+12
	jal cycleStickers

	# cycle U0, L6, D8, R2
	la	$a0, faceU+0
	la	$a1, faceR+8
	la	$a2, faceD+32
	la	$a3, faceL+24
	jal cycleStickers

	j turnExit

turnBX2:
	jal cycleInnerStickersX2

	# swap U2, D6
	lw	$t0, faceU+8
	lw	$t1, faceD+24
	sw	$t0, faceD+24
	sw	$t1, faceU+8

	# swap U1, D7
	lw	$t0, faceU+4
	lw	$t1, faceD+28
	sw	$t0, faceD+28
	sw	$t1, faceU+4

	# swap U0, D8
	lw	$t0, faceU+0
	lw	$t1, faceD+32
	sw	$t0, faceD+32
	sw	$t1, faceU+0

	# swap L0, R8
	lw	$t0, faceL+0
	lw	$t1, faceR+32
	sw	$t0, faceR+32
	sw	$t1, faceL+0

	# swap L3, R5
	lw	$t0, faceL+12
	lw	$t1, faceR+20
	sw	$t0, faceR+20
	sw	$t1, faceL+12

	# swap L6, R2
	lw	$t0, faceL+24
	lw	$t1, faceR+8
	sw	$t0, faceR+8
	sw	$t1, faceL+24

	j turnExit

turnM:				# but wait, theres more!
	beq $a1, 0, turnMCW	# for slice moves, we only cycle the outer stickers
	beq $a1, 1, turnMCCW	# but it's the same idea
	beq $a1, 2, turnMX2

turnMCW:
	# cycle U1, F1, D1, B7
	la	$a0, faceU+4
	la	$a1, faceF+4
	la	$a2, faceD+4
	la	$a3, faceB+28
	jal cycleStickers

	# cycle U4, F4, D4, B4
	la	$a0, faceU+16
	la	$a1, faceF+16
	la	$a2, faceD+16
	la	$a3, faceB+16
	jal cycleStickers

	# cycle U7, F7, D7, B1
	la	$a0, faceU+28
	la	$a1, faceF+28
	la	$a2, faceD+28
	la	$a3, faceB+4
	jal cycleStickers

	j turnExit

turnMCCW:


	# cycle U1, F1, D1, B7
	la	$a0, faceU+4
	la	$a1, faceB+28
	la	$a2, faceD+4
	la	$a3, faceF+4
	jal cycleStickers

	# cycle U4, F4, D4, B4
	la	$a0, faceU+16
	la	$a1, faceB+16
	la	$a2, faceD+16
	la	$a3, faceF+16
	jal cycleStickers

	# cycle U7, F7, D7, B1
	la	$a0, faceU+28
	la	$a1, faceB+4
	la	$a2, faceD+28
	la	$a3, faceF+28
	jal cycleStickers

	j turnExit

turnMX2:
	# swap U1, D1
	lw	$t0, faceU+4
	lw	$t1, faceD+4
	sw	$t0, faceD+4
	sw	$t1, faceU+4

	# swap U4, D4
	lw	$t0, faceU+16
	lw	$t1, faceD+16
	sw	$t0, faceD+16
	sw	$t1, faceU+16

	# swap U7, D7
	lw	$t0, faceU+28
	lw	$t1, faceD+28
	sw	$t0, faceD+28
	sw	$t1, faceU+28

	# swap F1, B7
	lw	$t0, faceF+4
	lw	$t1, faceB+28
	sw	$t0, faceB+28
	sw	$t1, faceF+4

	# swap F4, B4
	lw	$t0, faceF+16
	lw	$t1, faceB+16
	sw	$t0, faceB+16
	sw	$t1, faceF+16

	# swap F7, B1
	lw	$t0, faceF+28
	lw	$t1, faceB+4
	sw	$t0, faceB+4
	sw	$t1, faceF+28

	j turnExit


turnS:				# then S
	beq $a1, 0, turnSCW
	beq $a1, 1, turnSCCW
	beq $a1, 2, turnSX2
turnSCW:
	# cycle U3, R1, D5, L7
	la	$a0, faceU+12
	la	$a1, faceR+4
	la	$a2, faceD+20
	la	$a3, faceL+28
	jal cycleStickers

	# cycle U4, R4, D4, L4
	la	$a0, faceU+16
	la	$a1, faceR+16
	la	$a2, faceD+16
	la	$a3, faceL+16
	jal cycleStickers

	# cycle U5, R7, D3, L1
	la	$a0, faceU+20
	la	$a1, faceR+28
	la	$a2, faceD+12
	la	$a3, faceL+4
	jal cycleStickers

	j turnExit

turnSCCW:
	# cycle U3, R1, D5, L7
	la	$a0, faceU+12
	la	$a1, faceL+28
	la	$a2, faceD+20
	la	$a3, faceR+4
	jal cycleStickers

	# cycle U4, R4, D4, L4
	la	$a0, faceU+16
	la	$a1, faceL+16
	la	$a2, faceD+16
	la	$a3, faceR+16
	jal cycleStickers

	# cycle U5, R7, D3, L1
	la	$a0, faceU+20
	la	$a1, faceL+4
	la	$a2, faceD+12
	la	$a3, faceR+28
	jal cycleStickers

	j turnExit

turnSX2:
	# swap U3, D5
	lw	$t0, faceU+12
	lw	$t1, faceD+20
	sw	$t0, faceD+20
	sw	$t1, faceU+12

	# swap U4, D4
	lw	$t0, faceU+16
	lw	$t1, faceD+16
	sw	$t0, faceD+16
	sw	$t1, faceU+16

	# swap U5, D3
	lw	$t0, faceU+20
	lw	$t1, faceD+12
	sw	$t0, faceD+12
	sw	$t1, faceU+20

	# swap R1, L7
	lw	$t0, faceR+4
	lw	$t1, faceL+28
	sw	$t0, faceL+28
	sw	$t1, faceR+4

	# swap R4, L4
	lw	$t0, faceR+16
	lw	$t1, faceL+16
	sw	$t0, faceL+16
	sw	$t1, faceR+16

	# swap R7, L1
	lw	$t0, faceR+28
	lw	$t1, faceL+4
	sw	$t0, faceL+4
	sw	$t1, faceR+28

	j turnExit

turnE:				# and FINALLY finally, there's E
	beq $a1, 0, turnECW
	beq $a1, 1, turnECCW
	beq $a1, 2, turnEX2
turnECW:
	# cycle F3, R3, B3, L3
	la	$a0, faceF+12
	la	$a1, faceR+12
	la	$a2, faceB+12
	la	$a3, faceL+12
	jal cycleStickers

	# cycle F4, R4, B4, L4
	la	$a0, faceF+16
	la	$a1, faceR+16
	la	$a2, faceB+16
	la	$a3, faceL+16
	jal cycleStickers

	# cycle F5, R5, B5, L5
	la	$a0, faceF+20
	la	$a1, faceR+20
	la	$a2, faceB+20
	la	$a3, faceL+20
	jal cycleStickers

	j turnExit

turnECCW:
	# cycle F3, R3, B3, L3
	la	$a0, faceF+12
	la	$a1, faceL+12
	la	$a2, faceB+12
	la	$a3, faceR+12
	jal cycleStickers

	# cycle F4, R4, B4, L4
	la	$a0, faceF+16
	la	$a1, faceL+16
	la	$a2, faceB+16
	la	$a3, faceR+16
	jal cycleStickers

	# cycle F5, R5, B5, L5
	la	$a0, faceF+20
	la	$a1, faceL+20
	la	$a2, faceB+20
	la	$a3, faceR+20
	jal cycleStickers

	j turnExit

turnEX2:
	# swap F3, B3
	lw	$t0, faceF+12
	lw	$t1, faceB+12
	sw	$t0, faceB+12
	sw	$t1, faceF+12

	# swap F4, B4
	lw	$t0, faceF+16
	lw	$t1, faceB+16
	sw	$t0, faceB+16
	sw	$t1, faceF+16

	# swap F5, B5
	lw	$t0, faceF+20
	lw	$t1, faceB+20
	sw	$t0, faceB+20
	sw	$t1, faceF+20

	# swap R3, L3
	lw	$t0, faceR+12
	lw	$t1, faceL+12
	sw	$t0, faceL+12
	sw	$t1, faceR+12

	# swap R4, L4
	lw	$t0, faceR+16
	lw	$t1, faceL+16
	sw	$t0, faceL+16
	sw	$t1, faceR+16

	# swap R5, L5
	lw	$t0, faceR+20
	lw	$t1, faceL+20
	sw	$t0, faceL+20
	sw	$t1, faceR+20

	j turnExit

turnExit:
	lw	$a0, 0($sp)	# exit block
	lw	$a1, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12

	jr	$ra


# cycles the stickers located at addresses
# $a0-3
cycleStickers:
	lw	$t0, ($a0)
	lw	$t1, ($a1)
	lw	$t2, ($a2)
	lw	$t3, ($a3)

	sw	$t0, ($a1)	# 0 -> 1
	sw	$t1, ($a2)	# 1 -> 2
	sw	$t2, ($a3)	# 2 -> 3
	sw	$t3, ($a0)	# 3 -> 0

	jr	$ra

# cycles the inner stickers on a face CLOCKWISE
# $a0 = face
cycleInnerStickersCW:
	mul	$t9, $a0, 36
	la	$t9, faceF($t9)	# get the address of the face

	#	0	1	2
	#	3	4	5
	#	6	7	8

	# corner stickers
	lw	$t0, 0($t9)	#0
	lw	$t1, 8($t9)	#2
	lw	$t2, 24($t9)	#6
	lw	$t3, 32($t9)	#8

	sw	$t0, 8($t9)	#0 -> 2
	sw	$t1, 32($t9)	#2 -> 8
	sw	$t3, 24($t9)	#8 -> 6
	sw	$t2, 0($t9)	#6 -> 0

	# edge stickers
	lw	$t0, 4($t9)	#1
	lw	$t1, 12($t9)	#3
	lw	$t2, 20($t9)	#5
	lw	$t3, 28($t9)	#7

	sw	$t0, 20($t9)	#1 -> 5
	sw	$t2, 28($t9)	#5 -> 7
	sw	$t3, 12($t9)	#7 -> 3
	sw	$t1, 4($t9)	#3 -> 1

	jr	$ra

# cycles the inner stickers on a face COUNTER-CLOCKWISE
# $a0 = face
cycleInnerStickersCCW:
	mul	$t9, $a0, 36
	la	$t9, faceF($t9)	# get the address of the face

	#	0	1	2
	#	3	4	5
	#	6	7	8
	# corner stickers
	lw	$t0, 0($t9)	#0
	lw	$t1, 8($t9)	#2
	lw	$t2, 24($t9)	#6
	lw	$t3, 32($t9)	#8

	sw	$t0, 24($t9)	#0 -> 6
	sw	$t2, 32($t9)	#6 -> 8
	sw	$t3, 8($t9)	#8 -> 2
	sw	$t1, 0($t9)	#2 -> 0

	# edge stickers
	lw	$t0, 4($t9)	#1
	lw	$t1, 12($t9)	#3
	lw	$t2, 20($t9)	#5
	lw	$t3, 28($t9)	#7

	sw	$t0, 12($t9)	#1 -> 3
	sw	$t1, 28($t9)	#3 -> 7
	sw	$t3, 20($t9)	#7 -> 5
	sw	$t2, 4($t9)	#5 -> 1

	jr	$ra

# cycles the inner stickers on a face a DOUBLE TURN
# $a0 = face
cycleInnerStickersX2:
	mul	$t9, $a0, 36
	la	$t9, faceF($t9)	# get the address of the face

	#	0	1	2
	#	3	4	5
	#	6	7	8
	# corner stickers
	lw	$t0, 0($t9)	#0
	lw	$t1, 8($t9)	#2
	lw	$t2, 24($t9)	#6
	lw	$t3, 32($t9)	#8

	sw	$t0, 32($t9)	#0 -> 8
	sw	$t3, 0($t9)	#8 -> 0
	sw	$t1, 24($t9)	#2 -> 6
	sw	$t2, 8($t9)	#6 -> 2

	# edge stickers
	lw	$t0, 4($t9)	#1
	lw	$t1, 12($t9)	#3
	lw	$t2, 20($t9)	#5
	lw	$t3, 28($t9)	#7

	sw	$t0, 28($t9)	#1 -> 7
	sw	$t3, 4($t9)	#7 -> 1
	sw	$t1, 20($t9)	#3 -> 5
	sw	$t2, 12($t9)	#5 -> 3

	jr	$ra


# puts stickers on the faces in the solved position
fillFaces:
	li	$t0, 0	# outer loop index
facesOuterLoop:
	beq	$t0, 6, facesReturn # 6 faces on the cube
	li	$t1, 0	# inner loop index
facesInnerLoop:
	beq	$t1, 9, facesFinishInnerLoop	# 9 stickers per face

	mul	$t2, $t0, 36	# $t0 * 36
	sll	$t3, $t1, 2	# $t1 * 4
	add	$t2, $t2, $t3	# offset of sticker relative to faceF

	sw	$t0, faceF+0($t2)	# put the sticker on

	addi	$t1, $t1, 1		# increment inner loop
	j	facesInnerLoop

facesFinishInnerLoop:		# done with a face
	addi	$t0, $t0, 1	# increment outer loop
	j	facesOuterLoop

facesReturn:
	jr	$ra

# checks to see if the cube is solved
checkSolved:
	beqz	$s1, checkSolvedUnsolved	# make sure we have made a turn already
						# we dont want to check the cube while scrambling
	li	$t0, 0		# outer loop iterates over faces
checkSolvedLoop:
	beq	$t0, 216, checkSolvedSolved	# 36 * 6 = 216; cube is solved if we check the whole thing without finding an incorrect sticker

	la	$t9, faceF+0($t0)		# address of current face
	lw	$t8, 16($t9)			# center sticker - match against this

	li	$t1, 0		# inner loop iterates over stickers on one face
checkSolvedInnerLoop:
	beq	$t1, 36, checkSolvedInnerFinish	# 9 * 4 = 36
						# move on to next face if we don't find an incorrect sticker
	add	$t7, $t9, $t1			# add sticker offset to face
	lw	$t7, ($t7)			# load the sticker we are checking
	bne	$t7, $t8, checkSolvedUnsolved	# the cube is unsolved once we find a single incorrect sticker

	addi	$t1, $t1, 4

checkSolvedInnerFinish:		# end of the inner loop
	addi	$t0, $t0, 36	# increment outer loop
	j	checkSolvedLoop	# check next face

checkSolvedSolved:		# cube is solved
	li	$v0, 4		# let the user know
	la	$a0, solved
	syscall

	li	$v0, 10		# exit the program
	syscall

checkSolvedUnsolved:		# not solved yet
	jr	$ra		# just return


# display the elapsed time and move counter
# most importantly, draw the cube
draw:
	# if the user has not made a move yet, we are scrambling the cube
	# so ignore the timer and move counter
	beqz	$s1, drawCube

	li	$v0, 30	# get system time
	syscall
				# remember, $s0 stores start time
	sub	$t0, $a0, $s0	# elapsed time in ms
	div	$t0, $t0, 1000	# elapsed time in sec

	div	$t1, $t0, 60	# get minutes (integer division)

	move	$a0, $t1	# display minutes
	li	$v0, 1
	syscall

	li	$v0, 11		# :
	li	$a0, ':'
	syscall

	rem	$t0, $t0, 60	# seconds is remainder
	bge	$t0, 10, noPadding

	li	$a0, '0'	# we need to pad seconds with a zero if less than 10
	syscall

noPadding:
	move	$a0, $t0	# print seconds
	li	$v0, 1
	syscall

	li	$v0, 4		# print " ("
	la	$a0, lParen
	syscall
				# move counter stored in $s1
	li	$v0, 1		# print num moves
	move	$a0, $s1
	syscall

	li	$v0, 4		# print " moves)"
	la	$a0, moves
	syscall

# now draw the cube
drawCube:
	# we see 3 faces at once
	# U (top), F (left), R (right)
	#           O
	#       3       1
	#   6       4       2
	#       7       5
	# O         8         2
	#     1           1
	# 3       2   O       5
	#     4           4
	# 6       5   3       8
	#     7           7
	#         8   6


	# line 1
	# U0
	la	$a0, spaces10	# left padding
	li	$v0, 4
	syscall

	lw	$a0, faceU+0 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 2
	# U3 U1
	la	$a0, newline
	syscall
	la	$a0, spaces6	# left padding
	syscall

	lw	$a0, faceU+12 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceU+4 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 3
	# U6 U4 U2
	la	$a0, newline
	syscall
	la	$a0, spaces2	# left padding
	syscall

	lw	$a0, faceU+24 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceU+16 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceU+8 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 4
	# U7 U5
	la	$a0, newline
	syscall
	la	$a0, spaces6	# left padding
	syscall

	lw	$a0, faceU+28 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceU+20 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 5
	# F0 U8 R2
	la	$a0, newline
	syscall

	lw	$a0, faceF+0 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces9
	syscall

	lw	$a0, faceU+32 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces9
	syscall

	lw	$a0, faceR+8 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 6
	# F1 R1
	la	$a0, newline
	syscall

	la	$a0, spaces4	# left padding
	syscall

	lw	$a0, faceF+4 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces11
	syscall

	lw	$a0, faceR+4 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 7
	# F3 F2 R0 R5
	la	$a0, newline
	syscall

	lw	$a0, faceF+12 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceF+8 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces3
	syscall

	lw	$a0, faceR+0 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceR+20 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 8
	# F4 R4
	la	$a0, newline
	syscall

	la	$a0, spaces4	# left padding
	syscall

	lw	$a0, faceF+16 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces11
	syscall

	lw	$a0, faceR+16 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 9
	# F6 F5 R3 R8
	la	$a0, newline
	syscall

	lw	$a0, faceF+24 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceF+20 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces3
	syscall

	lw	$a0, faceR+12 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces7
	syscall

	lw	$a0, faceR+32 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 10
	# F7 R7
	la	$a0, newline
	syscall

	la	$a0, spaces4	# left padding
	syscall

	lw	$a0, faceF+28  		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces11
	syscall

	lw	$a0, faceR+28 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	# line 11
	# F8 R6
	la	$a0, newline
	syscall

	la	$a0, spaces8
	syscall

	lw	$a0, faceF+32 		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, spaces3
	syscall

	lw	$a0, faceR+24  		# get sticker / symbol number
	sll	$a0, $a0, 1		# multiply by 2
	la	$a0, symbolF($a0)	# get symbol as string
	syscall				# print

	la	$a0, newline
	syscall
	la	$a0, newline
	syscall

	jr	$ra
