#include <avr/io.h>

.section .text


#define bytecnt r18

.global br8t
br8t:
.byte 0, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 10, 11
.byte 13, 16, 19, 23, 27, 32, 38, 45, 54, 64, 76
.byte 91, 108, 128, 152, 181, 215, 255

.global br2bam
br2bam:	ldi bytecnt, 64
	ldi XL, lo8(bambuf)
	ldi XH, hi8(bambuf)

lookup:	ld ZL, X
	clr ZH
	subi ZL, lo8(-(br8t))
	sbci ZH, hi8(-(br8t))
	lpm ZL, Z
	st X+, ZL
	dec bytecnt
	brne lookup

	ret



