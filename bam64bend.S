#include <avr/io.h>

.section .text

// bam64bend rearranges PWM/BAM values into a format that is well suited
// for output. while scanning some column and in this column bit number n,
// the BAM matrix routine needs to have all the bits n of all the pixels
// in the column readily available. bam64 reads 8 columns of 8 pixels
// each.
// bam64bend transposes the bits of the 8 bytes representing one column
// of the display. for every column, all the 0th bits go into the first output
// byte, all the 1st bits go into the second output byte and so on.


// register usage is as follows:
#define bitacc r23
#define colcnt r24
#define bitcnt r25
#define d0 r15	// needs to be saved
#define d1 r16	// needs to be saved
#define d2 r17	// needs to be saved
#define d3 r18
#define d4 r19
#define d5 r20
#define d6 r21
#define d7 r22
// source index register: X
// destination index register: Z

.extern bambuf
.extern bam64shadow
	
.global bam64bend
bam64bend:
	push d0
	push d1
	push d2
	push XL
	push XH

	ldi XL, lo8(bambuf)
	ldi XH, hi8(bambuf)
	lds ZL, bam64_shadow
	lds ZH, bam64_shadow+1

	ldi colcnt, 8

column:	ldi bitcnt, 8
	ld d0, X+
	ld d1, X+
	ld d2, X+
	ld d3, X+
	ld d4, X+
	ld d5, X+
	ld d6, X+
	ld d7, X+
	
bit:	lsr d0
	ror bitacc
	lsr d1
	ror bitacc
	lsr d2
	ror bitacc
	lsr d3
	ror bitacc
	lsr d4
	ror bitacc
	lsr d5
	ror bitacc
	lsr d6
	ror bitacc
	lsr d7
	ror bitacc

	st Z+, bitacc
	dec bitcnt
	brne bit

	dec colcnt
	brne column

	pop XH
	pop XL
	pop d2
	pop d1
	pop d0
	ret

