    LIST P=PIC18F4321	F=INHX32
    #include <p18f4321.inc>

    CONFIG OSC=HSPLL	    ;Oscillador -> High Speed
    CONFIG PBADEN=DIG	    ;PORTB com a Digital (el posem a 0)
    CONFIG WDT=OFF	    ;Desactivem el Watch Dog Timer
    CONFIG LVP=OFF	    ;Evitar resets eusart
    
    ;vars
    display0 EQU 0x00   ; 7seg
    display1 EQU 0x01
    display3 EQU 0x02
    display4 EQU 0x03
    display5 EQU 0x04
    display6 EQU 0x05
    display7 EQU 0x06
    display8 EQU 0x07
    display9 EQU 0x08
    
    ORG 0x000
    GOTO MAIN
    ORG 0x008
    GOTO HIGH_RSI
    ORG 0x018
    retfie FAST
;-------------------------------------------------------------------------------
MAIN
    call INIT_PORTS
    call INIT_OSC
    call INIT_EUSART
    call INIT_VARS
LOOP
    ;codi
    goto LOOP
;-------------------------------------------------------------------------------
INIT_PORTS
    ;A
    movlw b'00100001'
    movwf TRISA,0
    ;B
    movlw b'11000011'
    movwf TRISB,0
    ;C
    movlw b'11000000'
    movwf TRISC,0
    ;D
    setf TRISD,0
    ;ADCON
    bsf ADCON0,0,0;activem ADC
    movlw b'00001110'
    movwf ADCON1,0
    movlw b'00001000'
    movwf ADCON2,0
    return
    
INIT_VARS
    movlw b'00111111';7segments
    movwf display0,0
    movlw b'00000110'
    movwf display1,0
    movlw b'01011011'
    movwf display2,0
    movlw b'01001111'
    movwf display3,0
    movlw b'01100110'
    movwf display4,0
    movlw b'1101101' 
    movwf display5,0
    movlw b'0111101'
    movwf display6,0
    movlw b'00000111'
    movwf display7,0
    movlw b'0111111'
    movwf display8,0
    movlw b'11001111'
    movwf display9,0
    return
INIT_OSC
    ;valors per defecta ja funcionen
    return
INIT_EUSART
    bsf TXSTA,5,0;TXEN
    bsf TXSTA,2,0;BRGH (9600)
    bsf RCSTA,7,0;SPEN
    bsf RCSTA,4,0;CREN
    bsf BAUDCON,1,0;WUE wake up, no para mai
    return
HIGH_RSI
    RETFIE FAST
END