;
; InterruptButton.asm
;
; Created: 29.12.2016 17:23:36
; Author : Michael Silvanovich
;

.NOLIST
.INCLUDE "tn85def.inc"
.LIST

.DEF portState=R16
.DEF temp=R17
.EQU LED_PIN=PB0
.EQU BUTTON_PIN=PB2

.CSEG
.ORG 0000
    rjmp RESET ; RESET
    rjmp INT0_ISR ; INT0
    reti ; PCINT0
    reti ; TIMER1_COMPA
    reti ; TIMER1_OVF
    reti ; TIMER0_OVF
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

INT0_ISR:
; Saving status register state
    in temp, SREG
    push temp

; Toggle LED state
    mov temp,portState
    sbrs temp,LED_PIN 
    ldi portState,(1<<LED_PIN)
    sbrc temp,LED_PIN 
    ldi portState,0
    out PORTB,portState

; Resetting status register state
    pop temp
    out SREG, temp

    reti

RESET:
; initializing the stack
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

; settign data direction register to output for led pin
    sbi DDRB,LED_PIN

; ISC01 ISC00 Description
;
; 0     0     The low level of INT0 generates an interrupt request.
; 0     1     Any logical change on INT0 generates an interrupt request.
; 1     0     The falling edge of INT0 generates an interrupt request.
; 1     1     The rising edge of INT0 generates an interrupt request.
    ldi temp, (1 << ISC01) | (1 << ISC00)
    out MCUCR, temp
; When the INT0 bit of GIMSK is set (one)
    ldi temp, (1 << INT0)
    out GIMSK, temp
; and the I-bit in the Status Register (SREG) is set (one), the external pin interrupt is enabled (datasheet p. 51)
    sei

main:
    rjmp main
