#include <avr/io.h>

.section .text

// br2bam performs gamma correction on the 64 byte buffer
// bambuf in place. the input values are considered to be
// 5 bit linear brightness values. br2bam outputs 8 bit
// values appropriate for BAM.
// br2bam follows the AVR-GCC calling convention.

// pretty standard gamma correction table
// courtesy of http://www.mikrocontroller.net/articles/LED-Fading
.global br8t
br8t:
.byte 0, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 10, 11
.byte 13, 16, 19, 23, 27, 32, 38, 45, 54, 64, 76
.byte 91, 108, 128, 152, 181, 215, 255

// adjacent bit table
// this table has no gaps between two on bits. this can
// can come in handy when trying to find proper frame
// rate values.
/*.global br8t
br8t:
.byte 0x00, 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03
.byte 0x04, 0x04, 0x06, 0x06, 0x08, 0x08, 0x0c, 0x0c
.byte 0x10, 0x10, 0x18, 0x18, 0x20, 0x20, 0x30, 0x30
.byte 0x40, 0x40, 0x60, 0x60, 0x80, 0x80, 0xc0, 0xc0*/

#define bytecnt r18

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



