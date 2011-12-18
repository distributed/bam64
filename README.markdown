BAM64
=====

Purpose
-------

BAM64 is a set of routines for Atmel AVR microcontrollers to allow
them to drive an 8x8 LED matrix with 32 brightness values per
pixel. The routines use a technique called Bit Angle Modulation to
provide brightness control.


Technical Overview
------------------

The routines are written in assembler and they are designed to be
integrated with a program written in avr-gcc. All functions and
interrupt routines are crafted to interact nicely with the avr-gcc
calling convention. C header files are provided for interaction
between an application, possibly written in C, and the BAM64 routines.

The provided routines are rather CPU hungry. In my experimentation
setup I use an ATMega168 running at 8 MHz from the internal RC
oscillator. A quick check with my trusty analog scope shows that
performing BAM on the 8x8 matrix at 650 frames per second the display
refresh uses about 1/3 of processor time.  This still leaves about 5
MIPS to your application code.

### Frame Preparation

Frames displayed by BAM64 have 64 pixels with brightness values
between 0 and 31. These frames are stored as arrays of 64
bytes. Pixels are arranged in column major order, i.e. a pixels linear
index is i = x*8 + y where x is the row number and y is the column
number.
Before being displayed a frame has to undergo a number of processing
steps.  First, the linear brightness values have to be gamma
corrected. 5 bit linear brightness values translate to 8 bit duty
cycle information. Then, the bits of the 8 bytes of every column in
the frame have to be transposed using the ```bam64bend```
routine. This step enables fast access to duty cycle information by
the BAM64 display routines. Finally, the application has to inform the
display routines that it wants a frame buffer switch to be
performed. The application is notified when the buffer switch takes
place through flags.


### Display Principle

The display is refreshed in ```bam64step```, a routine which is to be
used as an ISR. ```bam64step``` displays the frame column by column.
In every column, BAM is applied to the pixels. This is where the bit
transposition, detailed above, comes in handy. Upon switching to a
column, all the pixels which have their brightness LSB set are turned
on. The display routine waits for the duration of the LSB, then turns
on all the pixels which have their bit 1 set (and clearing the others)
and waits for the duration of 2 LSBs. The display routine proceeds
through all the brightness bits in this manner, always multiplying
wait time by a factor of two.

Since LSB duration is typically on the order of a couple of processor
cycles, it is not feasible to perform every bit cycle in one
ISR. Therefore a configurable number of ```BAM64NUMFASTCYCLES``` (in
bam64config.h) bit cycles are performed in one ISR. The following
```8-BAM64NUMFASTCYCLES``` bit cycles are all executed in their own
ISR. A count down / time out variable is used to time the increasingly
long bit cycles.

A graphical overview of this method can be found in bam64timing.svg.

The first ```BAM64NUMFASTCYCLES``` being collapsed into one ISR mean
that the timing of the display is not only given by the underlying
timer, but also by the execution speed of the code. To achieve a
stable and correct display, cycle-true timing needs to be employed
during these first cycles. This is why I chose to write the display
routines in assembler.

Please note that there's a little timing quirk. The provided routines
accept 8-bit bam values in the range 0 through 255. The display
refresh ISR is designed to be called 2^n times for every column. This
means that in fact there 256 LSB times between two columns, but LEDs
can only be on for 255 LSB times maximum. However, I think you won't
notice the difference. The difference of 1 LSB time is _not_ accounted
for in the code, but for small BAM64LSBCYCLES, i.e. 5-15, the
additional run time caused by the row pattern update code will
compensate for this.

### Hardware

Currently, the matrix connections are hardcoded. An 8x8 matrix is
connected to the microcontroller. Lines 0-7 are on
```PB0```-```PB7```. Columns 0-3 are ond ```PC0```-```PC3``` and
Columns 4-7 are ond ```PD4```-```PD7```.  The LEDs are forward biased
from line to column. Current limiting resistors are provided on the
wires feeding the lines.  I'm currently using an ATMega168
microcontroller clocked at 8 MHz from the internal RC oscillator.


### More!

If you have questions, don't hesitate to contact me on github.


License
-------

See file LICENSE.



(C) 2011, Michael Meier
