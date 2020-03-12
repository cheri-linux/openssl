#include "mips_arch.h"

#ifndef __CHERI_PURE_CAPABILITY__
 #define RET	jr	$31
 #define PUSH(rs,off)	sd	rs,(off)*8($29)
 #define POP(rd,off)	ld	rd,(off)*8($29)
 #define SUBSP(imm)	dsubu	$29,(imm)*8
 #define ADDSP(imm)	daddu	$29,(imm)*8
 #define STRSP(rd)	move	rd,$29
 #define LDRSP(rs)	move	$29,rs
 #define FRAME(framereg,size)	.frame	framereg,size,$31
#else
 #define RET	cjr	$c17
 #define PUSH(rs,off)	csd	rs,$zero,(off)*8($c11)
 #define POP(rd,off)	cld	rd,$zero,(off)*8($c11)
 #define SUBSP(imm)	cincoffsetimm	$c11,$c11,-(imm)*8
 #define ADDSP(imm)	cincoffsetimm	$c11,$c11,(imm)*8
 #define STRSP(rd)	cgetaddr	rd,$c11
 #define LDRSP(rs)	csetaddr	$c11,$c11,rs
 #define FRAME(framereg,size)	.frame	framereg,size,$c17
#endif

.text

.set	noat
.set	noreorder

.align	5
.globl	bn_mul_mont
.ent	bn_mul_mont
bn_mul_mont:
#ifdef __CHERI_PURE_CAPABILITY__
	move	$9,$4
	cgetaddr $8,$c7
	cgetaddr $7,$c6
	cgetaddr $6,$c5
	cgetaddr $5,$c4
	cgetaddr $4,$c3
#endif
	slt	$1,$9,4
	bnez	$1,1f
	li	$2,0
	slt	$1,$9,17	# on in-order CPU
	bnez	$1,bn_mul_mont_internal
	nop
1:	RET
	li	$4,0
.end	bn_mul_mont

.align	5
.ent	bn_mul_mont_internal
bn_mul_mont_internal:
	FRAME($30,14*8)
	.mask   0x40000000|16711680,-8
	SUBSP(14)
	PUSH($30,14-1)
	PUSH($23,14-2)
	PUSH($22,14-3)
	PUSH($21,14-4)
	PUSH($20,14-5)
	PUSH($19,14-6)
	PUSH($18,14-7)
	PUSH($17,14-8)
	PUSH($16,14-9)
	STRSP($30)

	.set	reorder
	ld	$8,0($8)
	ld	$13,0($6)	# bp[0]
	ld	$12,0($5)	# ap[0]
	ld	$14,0($7)	# np[0]

	SUBSP(2)	# place for two extra words
	sll	$9,3
	li	$1,-4096
#ifndef __CHERI_PURE_CAPABILITY__
	dsubu $29,$9
	and	$29,$1
#else
	dsubu $9,$zero,$9
	cincoffset $c11,$c11,$9
	dsubu $9,$zero,$9
	candaddr $c11,$c11,$1
#endif

	dmultu	($12,$13)
	ld	$17,8($5)
	ld	$19,8($7)
	mflo	($10,$12,$13)
	mfhi	($11,$12,$13)
	dmultu	($10,$8)
	mflo	($23,$10,$8)

	dmultu	($17,$13)
	mflo	($16,$17,$13)
	mfhi	($17,$17,$13)

	dmultu	($14,$23)
	mflo	($24,$14,$23)
	mfhi	($25,$14,$23)
	dmultu	($19,$23)
	daddu	$24,$10
	sltu	$1,$24,$10
	daddu	$25,$1
	mflo	($18,$19,$23)
	mfhi	($19,$19,$23)

	STRSP($15)
	li	$22,2*8
.align	4
.L1st:
	.set	noreorder
	daddu $12,$5,$22
	daddu $14,$7,$22
	ld	$12,($12)
	ld	$14,($14)

	dmultu	($12,$13)
	daddu	$10,$16,$11
	daddu	$24,$18,$25
	sltu	$1,$10,$11
	sltu	$2,$24,$25
	daddu	$11,$17,$1
	daddu	$25,$19,$2
	mflo	($16,$12,$13)
	mfhi	($17,$12,$13)

	daddu	$24,$10
	sltu	$1,$24,$10
	dmultu	($14,$23)
	daddu	$25,$1
	addu	$22,8
	sd	$24,($15)
	sltu	$2,$22,$9
	mflo	($18,$14,$23)
	mfhi	($19,$14,$23)

	bnez	$2,.L1st
	daddu $15,8
	.set	reorder

	daddu	$10,$16,$11
	sltu	$1,$10,$11
	daddu	$11,$17,$1

	daddu	$24,$18,$25
	sltu	$2,$24,$25
	daddu	$25,$19,$2
	daddu	$24,$10
	sltu	$1,$24,$10
	daddu	$25,$1

	sd	$24,($15)

	daddu	$25,$11
	sltu	$1,$25,$11
	sd	$25,8($15)
	sd	$1,2*8($15)

	li	$21,8
.align	4
.Louter:
	daddu $13,$6,$21
	ld	$13,($13)
	ld	$12,($5)
	ld	$17,8($5)
	POP($20,0)

	dmultu	($12,$13)
	ld	$14,($7)
	ld	$19,8($7)
	mflo	($10,$12,$13)
	mfhi	($11,$12,$13)
	daddu	$10,$20
	dmultu	($10,$8)
	sltu	$1,$10,$20
	daddu	$11,$1
	mflo	($23,$10,$8)

	dmultu	($17,$13)
	mflo	($16,$17,$13)
	mfhi	($17,$17,$13)

	dmultu	($14,$23)
	mflo	($24,$14,$23)
	mfhi	($25,$14,$23)

	dmultu	($19,$23)
	daddu	$24,$10
	sltu	$1,$24,$10
	daddu	$25,$1
	mflo	($18,$19,$23)
	mfhi	($19,$19,$23)

	STRSP($15)
	li	$22,2*8
	ld	$20,8($15)
.align	4
.Linner:
	.set	noreorder
	daddu $12,$5,$22
	daddu $14,$7,$22
	ld	$12,($12)
	ld	$14,($14)

	dmultu	($12,$13)
	daddu	$10,$16,$11
	daddu	$24,$18,$25
	sltu	$1,$10,$11
	sltu	$2,$24,$25
	daddu	$11,$17,$1
	daddu	$25,$19,$2
	mflo	($16,$12,$13)
	mfhi	($17,$12,$13)

	daddu	$10,$20
	addu	$22,8
	dmultu	($14,$23)
	sltu	$1,$10,$20
	daddu	$24,$10
	daddu	$11,$1
	sltu	$2,$24,$10
	ld	$20,2*8($15)
	daddu	$25,$2
	sltu	$1,$22,$9
	mflo	($18,$14,$23)
	mfhi	($19,$14,$23)
	sd	$24,($15)
	bnez	$1,.Linner
	daddu $15,8
	.set	reorder

	daddu	$10,$16,$11
	sltu	$1,$10,$11
	daddu	$11,$17,$1
	daddu	$10,$20
	sltu	$2,$10,$20
	daddu	$11,$2

	ld	$20,2*8($15)
	daddu	$24,$18,$25
	sltu	$1,$24,$25
	daddu	$25,$19,$1
	daddu	$24,$10
	sltu	$2,$24,$10
	daddu	$25,$2
	sd	$24,($15)

	daddu	$24,$25,$11
	sltu	$25,$24,$11
	daddu	$24,$20
	sltu	$1,$24,$20
	daddu	$25,$1
	sd	$24,8($15)
	sd	$25,2*8($15)

	addu	$21,8
	sltu	$2,$21,$9
	bnez	$2,.Louter

	.set	noreorder
#ifndef __CHERI_PURE_CAPABILITY__
	daddu $20,$29,$9	# &tp[num]
#else
	cgetaddr $1,$c11
	daddu $20,$1,$9
#endif
	STRSP($15)
	STRSP($5)
	li	$11,0		# clear borrow bit

.align	4
.Lsub:	ld	$10,($15)
	ld	$24,($7)
	daddu $15,8
	daddu $7,8
	dsubu	$24,$10,$24	# tp[i]-np[i]
	sgtu	$1,$24,$10
	dsubu	$10,$24,$11
	sgtu	$11,$10,$24
	sd	$10,($4)
	or	$11,$1
	sltu	$1,$15,$20
	bnez	$1,.Lsub
	daddu $4,8

	dsubu	$11,$25,$11	# handle upmost overflow bit
	STRSP($15)
	dsubu $4,$9	# restore rp
	not	$25,$11

.Lcopy:	ld	$14,($15)	# conditional move
	ld	$12,($4)
	sd	$0,($15)
	daddu $15,8
	and	$14,$11
	and	$12,$25
	or	$12,$14
	sltu	$1,$15,$20
	sd	$12,($4)
	bnez	$1,.Lcopy
	daddu $4,8

	li	$4,1
	li	$2,1

	.set	noreorder
	LDRSP($30)
	POP($30,14-1)
	POP($23,14-2)
	POP($22,14-3)
	POP($21,14-4)
	POP($20,14-5)
	POP($19,14-6)
	POP($18,14-7)
	POP($17,14-8)
	POP($16,14-9)
	RET
	ADDSP(14)
.end	bn_mul_mont_internal
.rdata
.asciiz	"Montgomery Multiplication for MIPS, CRYPTOGAMS by <appro@openssl.org>"
