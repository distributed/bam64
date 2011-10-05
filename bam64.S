#include <avr/io.h>
#include "bam64defs.h"

.section .bss
.global bam64flags
bam64flags:	
.skip BAM64NUMFLAGS

bam64_to:
.byte 1
bam64_bitnum:
.byte 1
bam64_colnum:
.byte 1
bam64_colpattern:
.byte 1
bam64_front:
.byte 2
bam64_shadow:
.byte 2



#define to r16
#define settmp1 r16
#define colpattern r16	// column pattern is generated before a column is drawn
#define tmp1 r16
#define colnum r17
#define bitnum r18
	
.section .text
	
bam64step:
	push to
	in to, SREG-0x20
	push to
	lds to, bam64_to
	dec to
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
	//turn columns off
        in settmp1, DDRC-0x20
        andi settmp1, ~((1<<PC0)|(1<<PC1)|(1<<PC2)|(1<<PC3))
        out DDRC-0x20, settmp1
        in settmp1, DDRD-0x20
        andi settmp1, ~((1<<PD4)|(1<<PD5)|(1<<PD6)|(1<<PD7))
        out DDRD-0x20, settmp1

	// TODO: turn right column on, bitnum is unused now
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
#define BAM64NUMFAST 4

// user has to quote numbers nicely	
//#define burn(n)	ldi tmp1, 3\
//	5:	dec tmp1\
//	brne 5b\
	
//#define burn(n) ldi tmp1, (n)


//#define waste nop
//#define wasten(n) ldi tmp1, n

.macro waste n=25
	ldi tmp1, (\n-1)/3
5:	dec tmp1
	brne 5b
.rept ((\n-1)%3)
	nop
.endr
.endm
	
	
#define A 20
	
// one LSB takes "a" cycles


#if BAM64NUMFAST >= 1
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 2
	// the sleeps are here to quickly navigate an objdump
	sleep
	waste (A-3)
#endif
#endif

#if BAM64NUMFAST >= 2
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 3 
	// waste (2a-3)
	sleep
	waste((2*A)-3)
#endif
#endif

#if BAM64NUMFAST >= 3
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 4 
	// waste (4a-3)
	sleep
	waste((4*A)-3)
#endif
#endif

#if BAM64NUMFAST >= 4
	ld tmp1, Z+
	out PORTB-0x20, tmp1
#if BAM64NUMFAST >= 5 
	// waste (8a-3)
	sleep
	waste((2*A)-3)	
#endif
#endif

	ldi bitnum, BAM64NUMFAST
	// TODO: load to
	
	rjmp bam64_cexit

bam64_regular:
	add ZL, bitnum
	brcc 1f
	inc ZH
1:	ld tmp1, Z			// load pattern at offset bitnum
	out PORTB-0x20, tmp1		// output to rows
	inc bitnum			// blindly increment bitnum
	sts bam64_bitnum, bitnum	// check for end of column later

	// so far, so good
	// TODO: clean this up, it does not make a lot of sense
	// idea: bitnum++. on bitnum < 8, set to according to bitnum
	// and BAM64NUMFAST. if bitnum == 8, we have to move to the next
	// column, thus bitnum = 0, colnum++ and colpattern <<= 1.
	// if colnum < 8,
	// we switched to a normal column, all is fine. if colnum == 8,
	// we are at the end of an image, thus we have to set colnum = 0,
	// colpattern = 0, 
	
	cpi bitnum, 8
	brne bam64_cexit
	// move to next column
	lds colnum, bam64_colnum	// TODO: necessary?
	inc colnum
	cpi colnum, 8
	brne 2f
	rjmp bam64_endimg
2:	
	// next column
	inc colnum
	sts bam64_colnum, colnum
	lds colpattern, bam64_colpattern
	lsl colpattern
	sts bam64_colpattern, colpattern

	subi bitnum, BAM64NUMFAST	// don't count fast cycles
	ldi to, 1
	lsr to
1:	lsl to
	dec bitnum
	brne 1b
	sts bam64_to, to

	sts bam64_to, to
	
	
	rjmp bam64_cexit // relax?



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
	reti

bam64_endimg:
	ldi bitnum, 0
	sts bam64_bitnum, bitnum
	sts bam64_colnum, bitnum

	ldi bitnum, 1
	sts bam64_colpattern, bitnum
	sts bam64_to, bitnum
	
	rjmp bam64_cexit



