#include <stdint.h>
#include <stdio.h>
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include "bam64.h"



/*#define RXBUFSIZ (64)
#define RXBUFMASK (RXBUFSIZ-1)
volatile uint8_t rxbuf_head;
volatile uint8_t rxbuf_tail;
uint8_t rxbuf[RXBUFSIZ];

ISR(USART0_RX_vect) {  
  uint8_t tmphead = (rxbuf_head+1) & RXBUFMASK;
  
  if (tmphead == rxbuf_tail) {
    // WARNING: no error handling
    uint8_t tmp = UDR0;
    return;
  } else {
    rxbuf_head = tmphead;
    rxbuf[tmphead] = UDR0;
  }
}


uint8_t rxbyte_ready() {
  uint8_t sregtemp = SREG;
  cli();

  uint8_t tmphead = rxbuf_head;
  uint8_t tmptail = rxbuf_tail;

  SREG = sregtemp;

  return (tmphead != tmptail);
}

uint8_t unsafe_rx_getbyte() {
  uint8_t tmptail = (rxbuf_tail+1) & RXBUFMASK;
  uint8_t res = rxbuf[tmptail];
  //  tmptail = (tmptail+1) & RXBUFMASK;
  rxbuf_tail = tmptail;
  return res;
}


uint8_t initrxbuf() {
  rxbuf_head = 0;
  rxbuf_tail = 0;
}
*/



#define TXBUFSIZ (64)
#define TXBUFMASK (TXBUFSIZ-1)
volatile uint8_t txbuf_head;
volatile uint8_t txbuf_tail;
uint8_t txbuf[TXBUFSIZ];


ISR(USART0_UDRE_vect) {
  uint8_t tmphead, tmptail;
  tmphead = txbuf_head;
  tmptail = txbuf_tail;

  if (tmphead == tmptail) {
    UCSR0B &= ~(1<<UDRIE0);
  } else {
    //PINB = (1<<PB7);
    tmptail = (tmptail + 1) & TXBUFMASK;
    uint8_t tmp = txbuf[tmptail];
    txbuf_tail = tmptail;
    UDR0 = tmp;
  }
}


void txputchar(uint8_t c) {
  uint8_t tmphead = (txbuf_head + 1) & TXBUFMASK;
  while (1) {
    uint8_t tmptail = txbuf_tail;
    if (tmphead != tmptail) {
      txbuf[tmphead] = c;
      txbuf_head = tmphead;
      UCSR0B |= (1<<UDRIE0);
      return;
    }
  }
}

int _txputchar(char c, FILE *fp) {
  txputchar(c);
  return 0;
}

static FILE mystdout = FDEV_SETUP_STREAM(_txputchar, NULL, _FDEV_SETUP_WRITE);

void inittxbuf() {
  txbuf_head = 0;
  txbuf_tail = 0;
}


uint8_t getbyte() {
  while (!(UCSR0A & (1 << RXC0))) {}
  return UDR0;
}


bam64image imgs;

void printbam64state(int i) {
    printf("%03d: p%01x%01x to %02x bitnum % 1d colpattern %02x\n", i, bam64_colnum, bam64_bitnum, bam64_to, bam64_bitnum, bam64_colpattern);
}

int main() {

  stdout = &mystdout;
  inittxbuf();

  UCSR0B = (1<<UDRIE0) | (1<<RXEN0) | (1<<TXEN0);
  UCSR0C = (1<<UCSZ01) | (1<<UCSZ00);

  // 57600kbit/s @ 16MHz
  UBRR0 = 16;


  bam64_front = &(imgs[0]);
  bam64_shadow = &(imgs[1]);

  bam64_to = 1;
  bam64_colpattern = 1;

  sei();

  printf("running bam64 testbench\n");
  bam64flags[0] = 1;




  printbam64state(-1);
  int i = 0;
  while (1) {
      if (i<130) {
	  uint8_t begin = (bam64_to == 1);
	  bam64step();
	  if (!begin) printf("\t");
	  printbam64state(i);
	  i++;
      }
  }

}
