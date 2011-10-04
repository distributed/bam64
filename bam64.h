#ifndef BAM64_H
#define BAM64_H

#include "bam64defs.h"

typedef uint8_t bam64image[64];
typedef bam64image bam64images[2];

volatile extern uint8_t bam64flags[BAM64NUMFLAGS];

#endif
