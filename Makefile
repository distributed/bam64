COBJS=main.o
ASMOBJS=bam64.o bam64bend.o

CCARCH=atmega1280
ADARCH=m1280
F_CPU=16000000UL
PORT=/dev/tty.usbserial-A900cfyj

CC=avr-gcc
OBJCOPY=avr-objcopy
AVRDUDE=avrdude

CFLAGS=-Os
CFLAGS+=-mmcu=${CCARCH}
CFLAGS+=-gstabs
CFLAGS+=-DF_CPU=${F_CPU}
CFLAGS+=-std=c99
CFLAGS+=-Wall

ASMCFLAGS=-mmcu=${CCARCH}
ASMCFLAGS+=-DF_CPU=${F_CPU}
ASMCFLAGS+=-Wall

AVRDUDE_PROGRAMMER=arduino
AVRDUDE_OPTS=-b 57600


LDFLAGS=-mmcu=${CCARCH} -gstabs


hex: main
	${OBJCOPY} -j .text -j .data -O ihex main main.hex

main: ${COBJS} ${ASMOBJS}
	${CC} -o main ${LDFLAGS} ${COBJS} ${ASMOBJS}

.c.o:
	${CC} ${CFLAGS} -c $<

.S.o:
	${CC} ${ASMCFLAGS} -c $<


clean:
	rm -rf *.o main *.hex pcreader

dump: main
	avr-objdump -S main

burn: hex
	${AVRDUDE} -p ${ADARCH} -c ${AVRDUDE_PROGRAMMER} ${AVRDUDE_OPTS} -P ${PORT} -U flash:w:main.hex:i

pc:
	gcc -o pcreader -DPCREADER pcreader.c bitstream.c amx.c compact.c

avrdudeline:
	echo ${AVRDUDE} -p ${ADARCH} -c ${AVRDUDE_PROGRAMMER} ${AVRDUDE_OPTS} -P ${PORT}