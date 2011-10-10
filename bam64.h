#ifndef BAM64_H
#define BAM64_H

#include "bam64defs.h"

typedef uint8_t bam64image[64];
typedef bam64image bam64images[2];

volatile extern uint8_t bam64flags[BAM64NUMFLAGS];


volatile extern uint8_t bam64_to;
volatile extern uint8_t bam64_bitnum;
volatile extern uint8_t bam64_colnum;
volatile extern uint8_t bam64_colpattern;
volatile extern uint8_t *bam64_front;
volatile extern uint8_t *bam64_shadow;

// just for debugging, actually it's an ISR
void bam64step();

void br2bam();
void bam64bend();

#endif
