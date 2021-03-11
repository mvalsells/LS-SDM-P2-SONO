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
    eusart_input EQU 0x0A   ;entrada per eusart
    nom_eeprom_adr EQU 0x0B;adressa eeprom
    carrier EQU 0x0C;variable canvi de linia putty
    eusart_output EQU 0x0D
    
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
    movlw b'11100011'
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
    movlw b'00001101';posem un carrier reurn a temp
    movwf carrier,0
    
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
    MOVLW b'10010001'
    MOVWF T0CON,0
    return
INIT_EEPROM
    bcf EECON1, EEPGD
    bcf EECON1, CFGS
    
    movlw .0		;establir la 1ra adressa a carrier return
    movwf EEADR,0
    movff carrier,EEDATA
    bsf EECON1,WREN
    bcf INTCON,GIE
    movlw 55h
    movwf EECON2,0
    movlw 0AAh
    movwf EECON2
    bsf EECON1,WR
    ESPERA_EEPROM_ESCRIURE_INIT
	btfsc EECON1,WR
	goto ESPERA_EEPROM_ESCRIURE_INIT
    bsf INTCON,GIE
    bcf EECON1,WREN
    return
    
;-------------------------------------------------------------------------------
MAIN
    call INIT_VARS
    call INIT_PORTS
    ;call INIT_OSC	;valors default
    call INIT_EUSART
    call INIT_INTCONS
    call INIT_EEPROM
    call INIT_TIMER
    call CARREGA_TIMER
LOOP
    ;codi
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto LOOP
;-------------------------------------------------------------------------------
HIGH_RSI
    BCF INTCON,TMR0IF,0;quan salti una interrupcio qualsevol, nomes tenim timer0 de moment
    call CARREGA_TIMER;reiniciem el timer
    bsf LATA,2,0;reactivem el pin del servo
    retfie FAST
    
;TIMER
CARREGA_TIMER
    MOVLW HIGH(.15536);cada 20ms
    MOVWF TMR0H,0
    MOVLW LOW(.15536)
    MOVWF TMR0L,0
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
    movlw 'S'
    CPFSEQ eusart_input,0
    goto NEXT_S
    goto MODE_S
NEXT_S
    movlw 'T'
    CPFSEQ eusart_input,0
    goto NEXT_T
    goto MODE_T
NEXT_T
    
    goto LOOP
    ;no s'ha clicat cap tecla si arriba aqui
    
    
    
    
;-------------------------------
MODE_D
    movff display3,LATD
    ;pulsadors +5º -5º per pulsador
    
    ;acabat
    goto LOOP
    
MODE_I
    ;fixar 7seg a 0
    movff display0,LATD
    ;llegir caracters  fins un /n (no ben bé \n). Guardar-lo cada cop que el reben.
    movlw b'00000000';reinici adressa
    movwf nom_eeprom_adr
    
    ;llegir
    LLEGIR_I
    
	btfss PIR1,RCIF,0;esperem la primera tecla
	goto LLEGIR_I
	movf RCREG,0,0
	movwf eusart_input,0
	
	movf nom_eeprom_adr,0
	movwf EEADR,0
	movf eusart_input,0
	movwf EEDATA,0
	bsf EECON1,WREN
	bcf INTCON,GIE
	movlw 55h
	movwf EECON2,0
	movlw 0AAh
	movwf EECON2
	bsf EECON1,WR
	ESPERA_EEPROM_ESCRIURE
	    btfsc EECON1,WR
	    goto ESPERA_EEPROM_ESCRIURE
	bsf INTCON,GIE
	bcf EECON1,WREN
	
	movlw b'00001101';esperem a un enter
	cpfseq eusart_input,0
	goto NO_ENTER
	goto ACABAT_I
	NO_ENTER
	
	movff eusart_input,TXREG
	ESPERA_TX2
	BTFSS TXSTA,TRMT,0
	GOTO ESPERA_TX2
	
	incf nom_eeprom_adr;seguent adr
	
	movlw .120		;mirar si >120
	cpfseq nom_eeprom_adr,0
	goto LLEGIR_I
	;guardar un carrier return extra
	movf nom_eeprom_adr,0
	movwf EEADR,0
	movlw b'00001101'
	movwf EEDATA,0
	bsf EECON1,WREN
	bcf INTCON,GIE
	movlw 55h
	movwf EECON2,0
	movlw 0AAh
	movwf EECON2
	bsf EECON1,WR
	ESPERA_EEPROM_ESCRIURE2
	    btfsc EECON1,WR
	    goto ESPERA_EEPROM_ESCRIURE2
	bsf INTCON,GIE
	bcf EECON1,WREN
	
	
    ACABAT_I
    
    
    ;acabat
    goto LOOP
    
MODE_M
    movff display2,LATD
    ;mostrar ultima mesura si no estem a 0 de mesures
    
    
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_M
    
MODE_R;mostrar nom i 200 mesures
    movff display1,LATD
    ;MOSTRAR NOM (part 1/2)
    movlw b'00000000';reinici adressa
    movwf nom_eeprom_adr
    
    BUCLE_NOM

    movff nom_eeprom_adr, EEADR
    bcf EECON1, EEPGD
    bcf EECON1, CFGS
    
    bsf EECON1, RD
    movff EEDATA, eusart_output
    movff eusart_output, RCREG
    ;movwf,TXREG;envia el nom
    ESPERA_TX3
    BTFSS TXSTA,TRMT,0
    GOTO ESPERA_TX3
    movf eusart_output
    cpfseq carrier,0
    goto CONTINUA_NOM
    goto MOSTRA_MESURES
    CONTINUA_NOM
    incf nom_eeprom_adr
    goto BUCLE_NOM
    
    
    ;MOSTRAR ULTIMES 200 MESURES (PART 2/2)
    MOSTRA_MESURES
    
    ;acabat
    goto LOOP
MODE_S
    movff display4,LATD
    ;codi S
    goto LOOP
MODE_T
    movff display5,LATD
    ;codi T
    goto LOOP

END