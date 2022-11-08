#include "settings.inc"
    
    global  LCDINIT
    global  LCDADD
    global  LCDSEND
    global  LCDCLR
    global  LCD_LINE0
    global  LCD_LINE1
    global  delay
    global  LCD_PRINT_VOLTAGE

    ; pre-program the eeprom
    org	0x2100

VOLTS	DE	"Voltage \0"
	
PROG    CODE
    
;*************************************************************
; Initialize LCD functions
;*************************************************************
LCDINIT
; Set correct TRIS values for LCD ports
	bsf 	STATUS, RP0 		;Bank 1
	bcf	LCD_RS
	bcf	LCD_E
	bcf	LCD_RW
	bcf	LCD_D4
	bcf	LCD_D5
	bcf	LCD_D6
	bcf	LCD_D7
	bcf	STATUS, RP0		;Bank 0
	bcf	LCD_E
	bcf	LCD_RW
	bcf	LCD_RS
	bcf	LCD_D4
	bcf	LCD_D5
	bcf	LCD_D6
	bcf	LCD_D7
	
	movlw	50
	call	delay	    ; wait for the display to initialise internally (10ms in the manual)
	
	; software reset of the display, according to the manual!

	movlw	b'00110000'
	call	LCDSEND
	movlw	0x14
	call	delay
	movlw	b'00110000'
	call	LCDSEND
	movlw	0x1
	call	delay
	movlw	b'00110000'
	call	LCDSEND

	; reset should of happened, now start programming interface details
	movlw	b'00101000'
	call	LCDSEND
	movlw	b'00001100'
	call	LCDSEND
	movlw	b'00000001'
	call	LCDSEND
	

	bsf	LCD_RS			; Data mode0
	RETURN


;*************************************************************
; Moves "cursor"
;*************************************************************
LCDADD
	bcf	LCD_RS			; Command mode
	iorlw	0x80			; Goto DDRAM adress
	call	LCDSEND
	bsf	LCD_RS			; Data mode
	call	delay_1ms		; Takes a couple of ms
	RETURN


;*************************************************************
; Sends contens of W to display
;*************************************************************
LCDSEND	; Sends character in W to lcd.

	bsf	LCD_E
	
	movwf	LCDTmp
	bcf	LCD_D4
	bcf	LCD_D5
	bcf	LCD_D6
	bcf	LCD_D7
	
	btfsc	LCDTmp, 7
		bsf	LCD_D7
	btfsc	LCDTmp, 6
		bsf	LCD_D6
	btfsc	LCDTmp, 5
		bsf	LCD_D5
	btfsc	LCDTmp, 4
		bsf	LCD_D4

	bcf	LCD_E

	bsf	LCD_E
	
	bcf	LCD_D4
	bcf	LCD_D5
	bcf	LCD_D6
	bcf	LCD_D7

	btfsc	LCDTmp, 3
		bsf	LCD_D7
	btfsc	LCDTmp, 2
		bsf	LCD_D6
	btfsc	LCDTmp, 1
		bsf	LCD_D5
	btfsc	LCDTmp, 0
		bsf	LCD_D4
	
	bcf	LCD_E
	
	call	LCD_WAIT_ON_BUSY
	return

;*************************************************************
; Clears display
;*************************************************************
LCDCLR ; clears the entire display
	bcf	LCD_RS			; Set command mode
	movlw	b'00000001'		; Clear screen
	call	LCDSEND	
	movlw	b'00000010'		; cursor home
	call	LCDSEND	
	bsf	LCD_RS			; Set data mode
	return
	
;*************************************************************
; wait on the busy flag
;*************************************************************

LCD_WAIT_ON_BUSY
	banksel	TRIS_D7
	bsf	LCD_D7
	banksel	PORT_D7
	bsf	LCD_RW
	bsf	LCD_E
_LCD_WAIT_LOOP
	btfsc	LCD_D7
	goto	_LCD_WAIT_BUSY
_LCD_WAIT_LOOP_DONE
	banksel	TRIS_D7
	bcf	LCD_D7
	banksel	PORT_D7
	bcf	LCD_E
	bcf	LCD_RW
	return
_LCD_WAIT_BUSY
	goto	_LCD_WAIT_LOOP
	
	
;*************************************************************
; cursor to start of line 0
;*************************************************************
LCD_LINE0
	bcf	LCD_RS			; Set command mode
	movlw	b'10000000'		; 
	call	LCDSEND	
	bsf	LCD_RS			; Set data mode
	return	
;*************************************************************
; cursor to start of line 1
;*************************************************************
LCD_LINE1
	bcf	LCD_RS			; Set command mode
	movlw	b'11000000'		; 
	call	LCDSEND	
	bsf	LCD_RS			; Set data mode
	return

;*************************************************************
; Calls the delay_1ms W times
;*************************************************************
delay
	movwf	dly3
dly_loop
	call	delay_1ms
	decfsz	dly3, F
	goto	dly_loop
	return


;*************************************************************	
; 1ms delay.
; Modify this to match your processor speed.
; http://www.piclist.org/techref/piclist/codegen/delay.htm
;*************************************************************
delay_1ms
	movlw	0xF3		;2498 cycles
	movwf	dly1
	movlw	0x02
	movwf	dly2
Delay_0
	decfsz	dly1, f
	goto	$+2
	decfsz	dly2, f
	goto	Delay_0
	goto	$+1		;2 cycles
	return			;4 cycles (including call)


;*************************************************************	
; 40us delay.
; Modify this to match your processor speed.
; http://www.piclist.org/techref/piclist/codegen/delay.htm
;*************************************************************
short_dly
	movlw	0x1F		;94 cycles
	movwf	dly1
short_dly_0
	decfsz	dly1, f
	goto	short_dly_0
	goto	$+1		;2 cycles
	return			;4 cycles (including call)
	
LCD_PRINT_VOLTAGE
	bsf	STATUS,RP0
	movlw	VOLTS
LCD_PV_LOOP
	movwf	EEADR
	bsf	EECON1,RD
	movf	EEDATA,W
	btfsc	STATUS,Z
	goto	LCD_PV_EXIT
	bcf	STATUS, RP0
	call	LCDSEND
	bsf	STATUS,RP0
	incf	EEADR,0
	goto	LCD_PV_LOOP
LCD_PV_EXIT
	bcf	STATUS, RP0
	return
	
	END