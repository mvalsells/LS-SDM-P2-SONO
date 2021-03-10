LIST P=PIC18F4321	F=INHX32
    #include <p18f4321.inc>

    CONFIG OSC=HSPLL	    ;Oscillador -> High Speed
    CONFIG PBADEN=DIG	    ;PORTB com a Digital (el posem a 0)
    CONFIG WDT=OFF	    ;Desactivem el Watch Dog Timer
    CONFIG LVP=OFF	    ;Evitar resets eusart
    
    dada EQU 0x001
    
    ORG 0x000
    GOTO MAIN
    ORG 0x008
    RETFIE FAST
    ORG 0x018
    RETFIE FAST

MAIN
;    movlw HIGH(.64)
;    movwf SPBRGH,0
;    movlw LOW(.64)
;    movwf SPBRG,0
;    ;init ports
;    movlw b'11000000'
;    movwf TRISC,0
;    ;init eusart
;    movlw b'00100110'
;    movwf TXSTA,0
;    movlw b'10010000'
;    movwf RCSTA,0
    CLRF TRISD,0
    SETF LATD,0
    bcf TRISA,2,0
    
    
    
   
LOOP
   ; btfss PIR1,RCIF,0
    ;GOTO LOOP
    ;movff RCREG,TXREG
;    movlw 'A'
 ;   movwf TXREG,0
  ;  bsf LATC,0,0
;ESPERA_TX
;    BTFSS TXSTA,TRMT,0
;    GOTO ESPERA_TX
;    BCF LATC,0,0
  BSF LATA,2,0
  NOP
  BCF LATA,2,0
    GOTO LOOP
    END
    