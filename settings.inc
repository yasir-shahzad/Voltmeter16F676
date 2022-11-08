#include "p16F676.inc"
    
#define LCD_D4	PORTC, 3
#define LCD_D5	PORTC, 2	; 4 data lines
#define LCD_D6	PORTC, 1
#define LCD_D7	PORTC, 0
#define	LCD_RS	PORTA, 5	; 0 = Command, 1 = Data
#define LCD_E	PORTC, 4	; 1 to send data
#define LCD_RW	PORTC, 5
TRIS_D7	equ	TRISC
PORT_D7 equ	0
	
    CBLOCK 20h
	dly1	
	dly2	
	dly3	
	LCDTmp
	numberL
	numberH
	H_byte
	L_byte
	H_byte2
	L_byte2
	R0
	R1
	R2
	count
	temp
   ENDC
