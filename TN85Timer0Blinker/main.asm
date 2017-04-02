;
; Blinker.asm
;
; Created: 30.12.2016 14:33:32
; Author : Michael Silvanovich
;

.NOLIST
.INCLUDE "tn85def.inc"
.LIST

.DEF portState=R16
.DEF temp=R17
.DEF counter=R18
.EQU LED_PIN=PB0

.CSEG
.ORG 0000
    rjmp RESET ; RESET
    reti ; INT0
    reti ; PCINT0
    reti ; TIMER1_COMPA
    reti ; TIMER1_OVF
    rjmp TIMER0_OVF_ISR; TIMER0_OVF
    reti ; EE_RDY
    reti ; ANA_COMP
    reti ; ADC
    reti ; EE_RDY
    reti ; TIMER1_COMPB
    reti ; TIMER0_COMPA
    reti ; TIMER0_COMPB
    reti ; WDT
    reti ; USI_START
    reti ; USI_OVF

TIMER0_OVF_ISR:
; Saving status register state.
    in temp, SREG
    push temp

    inc counter
; Checking it is the 4th overflow, and if not so, return.
    cpi counter, 4
    brne RET1

; Toggle LED state.
    mov temp, portState
    sbrs temp, LED_PIN 
    ldi portState, (1<<LED_PIN)
    sbrc temp, LED_PIN 
    ldi portState, 0
    out PORTB, portState
    clr counter

RET1:
; Resetting status register state.
    pop temp
    out SREG, temp
    reti

RESET:

; initializing the stack.
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

; setting the counter ot zero.
    clr counter

; setting data direction register to output for led pin.
    sbi DDRB, LED_PIN
    ldi portState, 0 ; initial led state is off

;
; TCCR0B aka Timer/Counter Control Register B: || FOC0A | FOC0B | – | – | WGM02 | CS02 | CS01 | CS00 ||
;
; CS02 CS01 CS00 Description
; 0    0    0    No clock source (Timer/Counter stopped)
; 0    0    1    clkI/O/(No prescaling)
; 0    1    0    clkI/O/8 (From prescaler)
; 0    1    1    clkI/O/64 (From prescaler)
; 1    0    0    clkI/O/256 (From prescaler)
; 1    0    1    clkI/O/1024 (From prescaler)
; 1    1    0    External clock source on T0 pin. Clock on falling edge.
; 1    1    1    External clock source on T0 pin. Clock on rising edge.
;
; Full description look at p. 77-82.
;
    ldi temp, (1<<CS02)|(1<<CS00) ; /1024 (p. 80)
    out TCCR0B, temp

; Clear TOV0/ pending interrupts.
    ldi temp, (1<<TOV0)
    out TIFR, temp 

; When the TOIE0 bit is written to one, and the I-bit in the Status Register is set, the Timer/Counter0 Overflow interrupt is enabled.
    ldi temp, (1<<TOIE0)
    out TIMSK, temp 

    sei ; enable interrupts

main:
    rjmp main