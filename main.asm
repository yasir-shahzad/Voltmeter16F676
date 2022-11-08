#include "settings.inc"

; CONFIG
; __config 0xFFEC
 __CONFIG _FOSC_INTRCIO & _WDTE_ON & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _CP_OFF & _CPD_OFF


     errorlevel -302 ;	disable the 'not bank 0' error msgs

    ; LCD routines
    extern	    LCDINIT
    extern	    LCDADD
    extern	    LCDSEND
    extern	    LCDCLR
    extern	    LCD_LINE0
    extern	    LCD_LINE1
    extern	    delay
    extern	    LCD_PRINT_VOLTAGE
    

RES_VECT  CODE    0x0000            ; processor reset vector
  
    GOTO    MAIN                   ; go to beginning of program

 


MAIN_PROG CODE                      ; let linker place main program

MAIN
    BCF	    STATUS,RP0 ;Bank 0
    CLRF    PORTA ;Init PORTA
    CLRF    PORTC ;Init PORTC
    CLRF    CMCON ;digital I/O
    BSF	    STATUS,RP0 ;Bank 1
    CLRF    ANSEL ;digital I/O

    BCF	    STATUS,RP0	    ;Bank 0
    movlw   b'00001001'
    movwf   ADCON0
    BSF	    STATUS,RP0	    ;Bank 1
    movwf   b'00010000'	    ; osc selection
    movwf   ADCON1
    movlw   b'00000100'
    movwf   ANSEL
    movlw   b'00000100'	    ;RA2/AN2
    movwf   TRISA
    BCF	    STATUS,RP0	    ;Bank 0
    
;    call 3FFh ;Get the cal value
;    MOVWF OSCCAL ;Calibrate
    
    BCF STATUS,RP0 ;Bank 0
    
    call    LCDINIT
    
    call    LCDCLR
    
    call    LCD_LINE0
    call    LCD_PRINT_VOLTAGE

    movlw   0x02
    movwf   count
LOOP
    bsf	    ADCON0,1	; start a/d conversion
    btfsc   ADCON0,1
    goto    not_yet
    call    SHOW_VOLTAGE
    movlw   0x80
    call    delay
    GOTO    LOOP                       ; loop forever
not_yet
    goto    LOOP

    ; we are going to average 2 readings, so store current
get_next
    movfw   H_byte
    movwf   H_byte2
    bcf    STATUS,C
    rrf	    H_byte2,1	; high/2
    movfw   L_byte
    movwf   L_byte2
    rrf	    L_byte2,1
    goto    LOOP
SHOW_VOLTAGE
    call    get_adc_val
    decf    count,1
    btfss   STATUS,Z
    goto    get_next
    movlw   0x02
    movwf   count
    bcf	    STATUS,C
    rrf	    H_byte,1	; high/2
    rrf	    L_byte,1
    movfw   H_byte2
    movwf   numberH
    movfw   L_byte2
    movwf   numberL
    call    add16   ; add the 2 numbers which have been halved
    
    ; convert to 5 digit BCD (r0,r1,r2)
    movfw   H_byte
    movwf   H_byte
    movfw   L_byte
    movwf   L_byte
    call    B2_BCD
    call    BCD_TO_LCD
    return
    
BCD_TO_LCD
    call    LCD_LINE1

    movfw   R0
    andlw   0x0f
    addlw   0x30
    call    LCDSEND

    movlw   '.'
    call    LCDSEND

    swapf   R1,0
    andlw   0x0f
    addlw   0x30
    call    LCDSEND

    movfw   R1
    andlw   0x0f
    addlw   0x30
    call    LCDSEND
    
    swapf   R2,0
    andlw   0x0f
    addlw   0x30
    call    LCDSEND

    movfw   R2
    andlw   0x0f
    addlw   0x30
    call    LCDSEND

    return


get_adc_val    
    clrf    H_byte
    clrf    L_byte
    btfsc   ADRESH,7
    call    add_61a8
    btfsc   ADRESH,6
    call    add_30d4
    btfsc   ADRESH,5
    call    add_186a
    btfsc   ADRESH,4
    call    add_0c35
    btfsc   ADRESH,3
    call    add_061a
    btfsc   ADRESH,2
    call    add_030d
    btfsc   ADRESH,1
    call    add_0186
    btfsc   ADRESH,0
    call    add_00c3
    BSF	    STATUS,RP0	    ;Bank 1
    btfsc   ADRESL,7
    call    add_0061
    btfsc   ADRESL,6
    call    add_0030
    BCF	    STATUS,RP0	    ;Bank 0
    return
        
add_61a8
    movlw   0x61
    movwf   numberH
    movlw   0xa8
    movwf   numberL
    call    add16
    return
add_30d4
    movlw   0x30
    movwf   numberH
    movlw   0xd4
    movwf   numberL
    call    add16
    return
add_186a
    movlw   0x18
    movwf   numberH
    movlw   0x6a
    movwf   numberL
    call    add16
    return
add_0c35
    movlw   0x0c
    movwf   numberH
    movlw   0x35
    movwf   numberL
    call    add16
    return
add_061a
    movlw   0x06
    movwf   numberH
    movlw   0x1a
    movwf   numberL
    call    add16
    return
add_030d
    movlw   0x03
    movwf   numberH
    movlw   0x0d
    movwf   numberL
    call    add16
    return
add_0186
    movlw   0x01
    movwf   numberH
    movlw   0x86
    movwf   numberL
    call    add16
    return
add_00c3
    clrf    numberH
    movlw   0xc3
    movwf   numberL
    call    add16
    return
add_0061
    clrf    numberH
    movlw   0x61
    movwf   numberL
    call    add16
    return
add_0030
    clrf    numberH
    movlw   0x30
    movwf   numberL
    call    add16
    return

add16		
    movfw	numberL
    addwf	L_byte, f
    skpnc
    incf	H_byte, f
    movfw	numberH
    addwf	H_byte, f
    return 
    
B2_BCD  bcf     STATUS,0                ; clear the carry bit
	movlw   .16
	movwf   count
	clrf    R0
	clrf    R1
	clrf    R2
loop16  rlf     L_byte, F
	rlf     H_byte, F
	rlf     R2, F
	rlf     R1, F
	rlf     R0, F
;
	decfsz  count, F
	goto    adjDEC
	RETLW   0
;
adjDEC  movlw   R2
	movwf   FSR
	call    adjBCD
;
	movlw   R1
	movwf   FSR
	call    adjBCD
;
	movlw   R0
	movwf   FSR
	call    adjBCD
;
	goto    loop16
;
adjBCD  movlw   3
	addwf   0,W
	movwf   temp
	btfsc   temp,3          ; test if result > 7
	movwf   0
	movlw   30
	addwf   0,W
	movwf   temp
	btfsc   temp,7          ; test if result > 7
	movwf   0               ; save as MSD
	RETLW   0    
    
    END