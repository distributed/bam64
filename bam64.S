#include <avr/io.h>
#include "bam64defs.h"
#include "bam64config.h"

.section .bss
// allocate space for all flags
.global bam64flags
bam64flags:	
.skip BAM64NUMFLAGS

// time out to next BAM cycle. every ISR decrements "to" by one.
// if it's > 0, the ISR returns. if it's 0, the ISR executes a
// a BAM cycle
.global bam64_to
bam64_to:
.space 1

// the next bit number to be displayed
// range: BAM64NUMFAST to 7
.global bam64_bitnum
bam64_bitnum:
.space 1

// the number of the next column to be displayed
.global bam64_colnum
bam64_colnum:
.space 1

// the column bit pattern. it's (1<<bam64_colnum)
// but cached in memory for speed reasons
.global bam64_colpattern
bam64_colpattern:
.space 1

// pointer to the front frame buffer, i.e. the buffer
// which is going to be displayed in the next frame
.global bam64_front
bam64_front:
.space 2

// pointer to the shadow frame buffer, i.e. the buffer
// which is fine to be modified from application code.
.global bam64_shadow
bam64_shadow:
.space 2


// register definitions. some of them overlap. the code
// schedules operations such that semantics are correct.
#define to r16
#define colpattern r16	// column pattern is generated before a column is drawn
#define tmp1 r16
#define colnum r17
#define tmp2 r17
#define bitnum r18
#define settmp1 r18
	
.section .text

.global bam64step
bam64step:
	sbi PORTC-0x20, PC4 // interrupt active line high
	push to
	in to, SREG-0x20
	push to
	lds to, bam64_to
	dec to		   // is it time to execute a BAM cycle already?
	sts bam64_to, to
	breq 1f
	rjmp bam64_minexit

1:
cprolog:	
	push colnum
	push ZL
	push ZH
	push bitnum

	lds colnum, bam64_colnum
	mov tmp1, colnum
	swap tmp1  	// << 3
	lsr tmp1	// "

	lds ZL, bam64_front
	lds ZH, bam64_front+1
	add ZL, tmp1
	brcc 1f		// we don't have a zero reg, so we propagate the carry
	inc ZH		// "manually"
1:	
	
	lds bitnum, bam64_bitnum
	and bitnum, bitnum
	brne bam64_regular
	
	
bam64_fast:
	// turn off all lines
	out PORTB-0x20, bitnum // this works since in bam64_fast we obviously
			       // have bitnum == 0.
	//turn columns off
        in settmp1, DDRC-0x20
        andi settmp1, ~((1<<PC0)|(1<<PC1)|(1<<PC2)|(1<<PC3))
        out DDRC-0x20, settmp1
        in settmp1, DDRD-0x20
        andi settmp1, ~((1<<PD4)|(1<<PD5)|(1<<PD6)|(1<<PD7))
        out DDRD-0x20, settmp1

	// turn one column on, decide if it's low (on PORTC) or
	// hight (on PORTD)
	lds colpattern, bam64_colpattern
        cpi colpattern, 0x10  // check if bit in high/low nibble is set
        brsh 2f
        in settmp1, DDRC-0x20 // lower cols
        or settmp1, colpattern
        out DDRC-0x20, settmp1
        rjmp 3f
2:      in settmp1, DDRD-0x20 // higher cols
        or settmp1, colpattern
        out DDRD-0x20, settmp1



3:    	
// waste is designed to burn n processor cycles
// note that 4 <= n <= 768
.macro waste n=25
	ldi tmp1, (\n-1)/3
5:	dec tmp1
	brne 5b
.rept (((\n-1)%3)+1)
	nop
.endr
.endm
	
	
#if BAM64NUMFAST >= 1
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 2
	waste (BAM64LSBCYCLES-3)
#endif
#endif

#if BAM64NUMFAST >= 2
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 3 
	waste((2*BAM64LSBCYCLES)-3)
#endif
#endif

#if BAM64NUMFAST >= 3
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 4 
	waste((4*BAM64LSBCYCLES)-3)
#endif
#endif

#if BAM64NUMFAST >= 4
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 5 
	waste((8*BAM64LSBCYCLES)-3)	
#endif
#endif

#if BAM64NUMFAST >= 5
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 6 
	waste((16*BAM64LSBCYCLES)-3)	
#endif
#endif

	ldi bitnum, BAM64NUMFAST
	sts bam64_bitnum, bitnum
	ldi to, 1
	sts bam64_to, to
	
	rjmp bam64_cexit

bam64_regular:
	add ZL, bitnum
	brcc 1f
	inc ZH
1:	ld tmp1, Z			// load pattern at offset bitnum
	out PORTB-0x20, tmp1		// output to rows
	inc bitnum			// blindly increment bitnum
	sts bam64_bitnum, bitnum	// check for end of column later

	// idea: bitnum++. on bitnum < 8, set the time out
	// "to" according to bitnum and BAM64NUMFAST.
	// if bitnum == 8, we have to move to the next
	// column, thus bitnum = 0, colnum++ and colpattern <<= 1.
	// if colnum < 8,
	// we switched to a normal column, all is fine. if colnum == 8,
	// we are at the end of an image, thus we have to set colnum = 0,
	// colpattern = 0, 

	// starting from bitnum, subtract the number of fast cycles (and
	// compensate for the fact that bitnum has already been
	// incremented), then generate generate the time out "to"
	// from it.
	push bitnum	
	subi bitnum, BAM64NUMFAST
	ldi to, 1
	lsr to
1:	rol to
	dec bitnum
	brne 1b
	sts bam64_to, to
	pop bitnum
	
	// if bitnum < 8, we continue with BAM on this column, thus go to bam64_cexit
	cpi bitnum, 8
	brne bam64_cexit

	ldi bitnum, 0
	sts bam64_bitnum, bitnum
	//ldi to, 1
	//sts bam64_to, to
	
	// move to next column
	lds colpattern, bam64_colpattern
	lsl colpattern
	sts bam64_colpattern, colpattern
	lds colnum, bam64_colnum	// TODO: necessary?
	inc colnum
	sts bam64_colnum, colnum
	
	// if colnum == 8, we reached the end of the matrix, do clean ups at
	// bam64_endimg
	cpi colnum, 8
	brne 2f
	rjmp bam64_endimg
2:	
bam64_cexit:
	//sts bam64_colnum, colnum
	pop bitnum
	pop ZH
	pop ZL
	pop colnum
	
bam64_minexit:
	pop to
	out SREG-0x20, to
	pop to
	cbi PORTC-0x20, PC4 // interrupt active line low
	reti

bam64_endimg:
	sbi PORTC-0x20, PC5 // end of frame trigger high
	ldi bitnum, 0
	sts bam64_bitnum, bitnum
	sts bam64_colnum, bitnum

	ldi colpattern, 1
	sts bam64_colpattern, colpattern
	//sts bam64_to, bitnum 			// to is already set up and correct

	cbi PORTC-0x20, PC5 // end of frame trigger line low

	// increment frame counter
	lds tmp2, bam64flags+BAM64FLAG_FRMCNT
	inc tmp2
	sts bam64flags+BAM64FLAG_FRMCNT, tmp2
	
	// do front/shadow buffers need to be switched?
	lds tmp1, bam64flags+BAM64FLAG_COPY
	and tmp1, tmp1
	breq bam64_cexit
	
	// switch front/shadow
	// we directly store tmp1 (which is bam64flags[BAM64FLAG_COPY] == 1) to
	// the copied flag
	// (actually it's not == 1, but != 0. the main routine should just
	// write a 1)
	sts bam64flags+BAM64FLAG_COPIED, tmp1
	//clear the copy flag
	clr tmp1
	sts bam64flags+BAM64FLAG_COPY, tmp1

	// update COPYFCNT with FRMCNT
	sts bam64flags+BAM64FLAG_COPYFCNT, tmp2

	// switch the pointers
	lds tmp1, bam64_front
	lds tmp2, bam64_shadow
	sts bam64_shadow, tmp1
	sts bam64_front, tmp2	
	lds tmp1, bam64_front+1
	lds tmp2, bam64_shadow+1
	sts bam64_shadow+1, tmp1
	sts bam64_front+1, tmp2

	// this implementation using sts/lds requires more code than a variant
	// which would, say, use the Z pointer to index into the flags.
	// it does, however, execute faster since the Z register does not
	// have to be loaded. i realize that the speed gain is marginal and
	// the size increase is perceptible, but if we we have code like
	// bam64bend, why not? ;)
	
	rjmp bam64_cexit



