;
; Switch.asm
;
; Created: 28.12.2016 14:33:32
; Author : Michael Silvanovich
;

.NOLIST
.INCLUDE "tn85def.inc"
.LIST

.DEF portState=R16
.DEF temp=R17
.DEF left=R18
.DEF right=R19

.EQU LED_PIN=PB0
.EQU BUTTON_PIN=PB4

reset:
    sbi DDRB,LED_PIN
    sbi PORTB,BUTTON_PIN
    ldi portState,0
    rjmp start

toggle:
; Toggle LED state
    mov temp,portState
    sbrs temp,LED_PIN 
    ldi portState,(1<<LED_PIN)
    sbrc temp,LED_PIN 
    ldi portState,0
    out PORTB,portState
    rcall await // awaits button up

start:
    rcall await // awaits button down
    rjmp toggle

await:
    in temp,PINB
    sbrs temp,BUTTON_PIN
    ldi left,0
    sbrc temp,BUTTON_PIN
    ldi left,1
    cp left,right
    breq await
    mov right,left
    ret