;
; USI_I2C.asm
;
; Created: 04.01.2017 15:57:15
; Author : Michael Silvanovich
;
; This is just an example of I2C single master (without reading at the moment) implementation with USI.
; This code doesn't use interrupts.
;
; This code was tested only with ATtiny85 ([lfuse: 62, hfuse: d7, efuse: ff] <=> 1MHz int. osc.), but should work on 25, and 45 as well.
; It is likely that some devices won't 'understand' the output, 'cause there is no rate control.
;

.NOLIST
.INCLUDE "tn85def.inc"
.LIST

;
; SCL is PB2, SDA is PB0 according to datasheet.
;
.EQU SCL=PB2
.EQU SDA=PB0

;
; USICR is USI Control Register.
; We are gonna use 2-wire mode: USIWM1 = 1, USIWM0 = 0 with software clock strobe:  USICS1 = 1, USICS0 = 0.
; Setting USITC to one toggles SCL, setting USICLK (to one) shifts USIDR, microcontroller sets value of MSB of USIDR as an output for SDA (if corresponding DDRB-bit set) according to datasheet.
;
.EQU USICR_STROBE=(0 << USISIE) | (0 << USIOIE) | (1 << USIWM1) | (0 << USIWM0) | (1 << USICS1) | (0 << USICS0) | (1 << USICLK) | (1 << USITC) ; toggle SCL and shift register
.EQU USICR_CLK=   (0 << USISIE) | (0 << USIOIE) | (1 << USIWM1) | (0 << USIWM0) | (1 << USICS1) | (0 << USICS0) | (0 << USICLK) | (1 << USITC) ; toggle SCL, but don't shift register

;
; USISR is USI Status Register.
;
; USICNT[3:0] are used to set initial 4-bit counter value.
;
; USIOIF: The flag is set (one) when the 4-bit counter overflows. 
;         The flag will only be cleared if a one is written to the USIOIF bit. 
;         Clearing this bit will release the counter overflow hold of SCL.
;
; USISIF: When two-wire mode is selected, the USISIF Flag is set (to one) when a start condition has been detected. 
;         The flag will only be cleared by writing a logical one to the USISIF bit. 
;         Clearing this bit will release the start detection hold of USCL.
;
; We won't use other flags of this register, so you can find its detailed description in the datasheet.
;
.EQU USISR_8BIT=(0<<USIDC) | (0<<USIPF) | (1<<USIOIF) | (1 << USISIF) | (0 << USICNT3) | (0 << USICNT2) | (0 << USICNT1) | (0 << USICNT0)
.EQU USISR_1BIT=(0<<USIDC) | (0<<USIPF) | (1<<USIOIF) | (1 << USISIF) | (1 << USICNT3) | (1 << USICNT2) | (1 << USICNT1) | (0 << USICNT0)

.EQU LED_PIN=PB1

.DEF transferResult=r21
.DEF temp=r22
.DEF singleByte=r24
.DEF address=r23
.DEF transferArgument=r25

;
; setting DEBUG_MODE to one will decrease bitrate, so you will be able to debug it using simple oscilloscope.
;
.EQU DEBUG_MODE=0

RESET:
; initializing the stack.
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    sbi DDRB, LED_PIN
    sbi PORTB, LED_PIN

    ldi address, 0x3C
    rcall INIT_I2C

    ldi singleByte, 0xAF
    rcall SEND_SINGLEBYTE

    ldi singleByte, 0xAE
    rcall SEND_SINGLEBYTE

    rcall DEINIT_I2C

    cbi PORTB, LED_PIN

; lights the LED if last command is confirmed
    sbrc transferResult, USIDR7
    brne start
    sbi PORTB, LED_PIN

start:
    rjmp start

WAIT_SCL:
    push temp
    available:
        in temp, PINB
        sbrs temp, SCL
        rjmp available
    pop temp
    ret

INIT_I2C:
    lsl address
    ori address, 0x0 // we're gonna write only
    sbi PORTB, SCL
    cbi DDRB, SCL // HIGH
    rcall WAIT_SCL
    ret

DEINIT_I2C:
; setting input pullup for both SDA and SCL
    sbi PORTB, SDA
    cbi DDRB, SDA
    sbi PORTB, SCL
    cbi DDRB, SCL
; setting USI mode: Disabled
    clr temp
    out USICR, temp 
    ret

.IF DEBUG_MODE==1
DELAY_500ms:
    ldi  r18, 3
    ldi  r19, 138
    ldi  r20, 86
    DELAY_500ms_L1: dec  r20
        brne DELAY_500ms_L1
        dec  r19
        brne DELAY_500ms_L1
        dec  r18
        brne DELAY_500ms_L1
        nop
    ret
.ENDIF

DELAY_QUARTER:
.IF DEBUG_MODE==1 
    ldi  r18, 7
    ldi  r19, 125
    DELAY_QUARTER_L1: dec  r19
        brne DELAY_QUARTER_L1
        dec  r18
        brne DELAY_QUARTER_L1
        nop
    ret
.ELSE
    nop
    nop
    ret
.ENDIF

DELAY_HALF:
.IF DEBUG_MODE==1 
    ldi  r18, 13
    ldi  r19, 252
    DELAY_HALF_L1: dec  r19
        brne DELAY_HALF_L1
        dec  r18
        brne DELAY_HALF_L1
    ret
.ELSE
    nop
    nop
    nop
    nop
    ret
.ENDIF

START_CONDITION:
    sbi PORTB, SCL
    sbi PORTB, SDA
    cbi DDRB, SCL
    rcall WAIT_SCL
    rcall DELAY_QUARTER
    sbi DDRB, SCL
    sbi DDRB, SDA
    cbi PORTB, SDA // LOW
    rcall DELAY_HALF
    cbi PORTB, SCL // LOW
    rcall DELAY_QUARTER
    sbi PORTB, SDA // HIGH
    ret

TRANSFER:

    out USISR, temp ; 8-bit or 1-bit: 8-bit is used to transfer payload, 1-bit - ACK or NACK
    out USIDR, transferArgument

    not_transferred:

        rcall DELAY_QUARTER        
        ldi temp, USICR_CLK out USICR, temp
        rcall WAIT_SCL
        rcall DELAY_HALF
        ldi temp, USICR_STROBE out USICR, temp
        in temp, USISR sbrs temp, USIOIF

        rjmp not_transferred

    in transferResult, USIDR

    ldi temp, 0xff ; When the output driver is enabled for the SDA pin it will force the line SDA low if the output of the USI Data Register or the corresponding bit in the PORTB register is zero. 
    out USIDR, temp ; we want to release SDA
    sbi DDRB, SDA
    sbi PORTB, SDA // HIGH
    
    ret

STOP_CONDITION:
    rcall DELAY_QUARTER
    cbi PORTB, SDA
    rcall DELAY_QUARTER
    cbi DDRB, SCL
    rcall WAIT_SCL
    rcall DELAY_HALF
    cbi DDRB, SDA
    ret

SEND_SINGLEBYTE:

    ; see i2c normal mode specification for details

    rcall START_CONDITION

    mov transferArgument, address
    ldi temp, USISR_8BIT
    rcall TRANSFER

    ldi temp, USISR_1BIT
    cbi DDRB, SDA
    rcall TRANSFER

    mov transferArgument, singleByte
    ldi temp, USISR_8BIT
    rcall TRANSFER

    ldi temp, USISR_1BIT
    cbi DDRB, SDA
    rcall TRANSFER

    rcall STOP_CONDITION

    ret