#ifndef BAM64DEFS_H
#define BAM64DEFS_H

// pay attention to update BAM64NUMFLAGS!
#define BAM64FLAG_COPY     0   // request buffer swap. app -> ISR
#define BAM64FLAG_COPIED   1   // buffer swap done. ISR -> app
#define BAM64FLAG_FRMCNT   2   // 8 bit frame counter. to whom it may concern
#define BAM64FLAG_COPYFCNT 3   // FRMCNT of first frame after last buffer swap.
                               // to whom it may concern
#define BAM64NUMFLAGS      4   // number of flag bytes for space allocation

#endif
