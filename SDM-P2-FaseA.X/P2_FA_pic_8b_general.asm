    LIST P=PIC18F4321	F=INHX32
    #include <p18f4321.inc>

    CONFIG OSC=HSPLL	    ;Oscillador -> High Speed PLL
    CONFIG PBADEN=DIG	    ;PORTB com a Digital (el posem a 0)
    CONFIG WDT=OFF	    ;Desactivem el Watch Dog Timer
    CONFIG LVP=OFF	    ;Evitar resets eusart
    
    ;vars
    display0 EQU 0x00   ; 7seg
    display1 EQU 0x01
    display2 EQU 0x02
    display3 EQU 0x03
    display4 EQU 0x04
    display5 EQU 0x05
    display6 EQU 0x06
    display7 EQU 0x07
    display8 EQU 0x08
    display9 EQU 0x09
    eusart_input EQU 0x10
    lletra EQU 0x11
    
    ORG 0x000
    GOTO MAIN
    ORG 0x008
    GOTO HIGH_RSI
    ORG 0x018
    retfie FAST

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
    bcf LATC,0,0;apagar 1r led
    bcf LATC,1,0;apagar 2n led
    ;D
    clrf TRISD,0
    movlw b'00000000';apagar 7seg
    movwf LATD,0
    ;ADCON
    bsf ADCON0,ADON,0
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
INIT_EUSART
    movlw b'00100100'
    movwf TXSTA,0
    movlw b'10010000'
    movwf RCSTA,0
    movlw b'00001000'
    movwf BAUDCON,0
    movlw HIGH(.1040)
    movwf SPBRGH,0
    movlw LOW(.1040)
    movwf SPBRG,0
    
    return
INIT_INTCONS
    BSF RCON,IPEN,0
    MOVLW b'11100000' ;Només timer, ja canviarem quan anem fent els altres
    MOVWF INTCON,0
    BSF INTCON2,TMR0IP,0 ; Timer -> High priority
    ;MOVLW b'0000100'; ;Només timer, ja canviarem quan anem fent els altres
    ;MOVWF INTCON2,0
    return
INIT_TIMER
    MOVLW b'10011000'
    MOVWF T0CON,0
    return
    
;-------------------------------------------------------------------------------
MAIN
    call INIT_PORTS
    ;call INIT_OSC	;valors default
    call INIT_EUSART
    call INIT_VARS
    call INIT_INTCONS
    call INIT_TIMER
    call CARREGA_TIMER
    
LOOP
    ;codi
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto LOOP
;-------------------------------------------------------------------------------
HIGH_RSI
    BCF INTCON,TMR0IF,0
    call CARREGA_TIMER
    BTG LATC,0,0
    retfie FAST
    
;TIMER
CARREGA_TIMER
    ;5º (55,2us) = 64994
    ;1º (11,1us) = 65438
    MOVLW HIGH(.65438)
    MOVWF TMR0H,0
    MOVLW LOW(.65438)
    MOVWF TMR0L,0
    return
INTERRUPT_TIMER
    BTG LATC,0,0
    BCF INTCON,TMR0IF,0
    call CARREGA_TIMER
    return
;-------------------------------------------------------------------------------
;EUSART
LECTOR_EUSART
    movf RCREG,0,0
    movwf eusart_input,0
    movff eusart_input,TXREG
ESPERA_TX
    BTFSS TXSTA,TRMT,0
    GOTO ESPERA_TX
    
    movlw 'D'
    CPFSEQ eusart_input,0
    goto NEXT_D
    goto MODE_D
NEXT_D
    movlw 'I'
    CPFSEQ eusart_input,0
    goto NEXT_I
    goto MODE_I
NEXT_I
    movlw 'M'
    CPFSEQ eusart_input,0
    goto NEXT_M
    goto MODE_M
NEXT_M
    movlw 'R'
    CPFSEQ eusart_input,0
    goto NEXT_R
    goto MODE_R
NEXT_R
    goto LOOP
    ;no s'ha clicat cap tecla si arriba aqui
    
    
    
    
;-------------------------------
MODE_D
    movff display3,LATD
    ;pulsadors +5º -5º per pulsador
    
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_D
    
MODE_I
    ;fixar 7seg a 0
    movff display0,LATD
    ;llegir caracters  fins un /n (no ben bé \n). Guardar-lo cada cop que el reben.
    
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_I
    
MODE_M
    movff display2,LATD
    ;mostrar ultima mesura si no estem a 0 de mesures
    
    
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_M
    
MODE_R
    movff display1,LATD
    ;mostrar nom
    ;mostrar últimes mesures màx 200 són.
    
    
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_R

END