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
pos_servo EQU 0x0B
carrier EQU 0x0C;variable canvi de linia putty
eusart_output EQU 0x0D
eeprom_addr EQU 0x0E
eeprom_data EQU 0x0F
compt_10us EQU 0x10
us_echo_58 EQU 0x11
us_echo_cm EQU 0x12
bn_ascii EQU 0x13
ascii_u EQU 0x14
ascii_d EQU 0x15
ascii_c EQU 0x16
TMP EQU 0x17
TMP_2 EQU 0x18
   
    ORG 0x000
    GOTO MAIN
    ORG 0x008
    GOTO HIGH_RSI
    ORG 0x018
    retfie FAST

INIT_PORTS
    ;A
    movlw b'00100011'
    movwf TRISA,0
    bcf LATA,2,0
    bcf LATA,4,0
    ;B
    movlw b'11100110'
    movwf TRISB,0
    bcf INTCON2,RBPU,0
    ;C
    movlw b'11000000'
    movwf TRISC,0
    bcf LATC,0,0;apagar 1r led
    bcf LATC,1,0;apagar 2n led
    ;D
    clrf TRISD,0
    movlw b'00000000';apagar 7seg
    movwf LATD,0
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
    ;nom db "Nom: "
    ;mesures db "Mesures: "
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
    MOVLW b'11100000' ;Nom�s timer, ja canviarem quan anem fent els altres
    MOVWF INTCON,0
    BSF INTCON2,TMR0IP,0 ; Timer -> High priority
    ;MOVLW b'0000100'; ;Nom�s timer, ja canviarem quan anem fent els altres
    ;MOVWF INTCON2,0
    return
INIT_TIMER
    MOVLW b'10010001'
    MOVWF T0CON,0
    RETURN
    
INIT_EEPROM
    BCF EECON1, EEPGD
    BCF EECON1, CFGS
    RETURN
    
INIT_ADCON
    MOVLW b'00001110'
    MOVWF ADCON2,0
    MOVLW b'00001110'
    MOVWF ADCON1,0
    BSF ADCON0,ADON,0
    RETURN
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
    call INIT_ADCON
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

;Lectura EEPROM
EEPROM_READ
    movf eeprom_addr,0
    movwf EEADR,0
    BCF EECON1, EEPGD    ; Point to DATA memory
    BCF EECON1, CFGS     ; Access EEPROM
    BSF EECON1, RD        ; EEPROM Read
    MOVFF EEDATA, eeprom_data
    return
;Escriptura EEPROM
EEPROM_WRITE
    movf eeprom_addr,0
    movwf EEADR,0
    movf eeprom_data,0
    movwf EEDATA,0
    bsf EECON1,WREN
    bcf INTCON,GIE
    movlw 55h
    movwf EECON2,0
    movlw 0AAh
    movwf EECON2
    bsf EECON1,WR
    call ESPERA_EEPROM_ESCRIURE
    bsf INTCON,GIE
    bcf EECON1,WREN
    return
	

ESPERA_EEPROM_ESCRIURE
    BTFSC EECON1,WR
    GOTO ESPERA_EEPROM_ESCRIURE
    RETURN
    
; Ultrasons
MEDIR
    MOVLW .232
    MOVWF compt_10us
    BSF LATA,4,0 ; Trigger a high
INCR_10us
    INCF compt_10us,1,0
    BTFSS STATUS,C
    GOTO INCR_10us
    NOP
    NOP
    NOP
    BCF LATA,4,0 ;Trigger a low
        
ESPERA_ECHO
    BTFSS PORTA,5,0 ; esperem el echo a high
    GOTO ESPERA_ECHO
    ;BSF LATD,3,0
    CLRF us_echo_cm,0
INICI_ECHO
    MOVLW .64		;1
    MOVWF us_echo_58,0	;1
COMPTAR_58
    INCFSZ us_echo_58,1,0	;1
    GOTO COMPTAR_58	;2
    INCF us_echo_cm	;2=1+1
    BTG LATD,2,0
    BTFSC PORTA,5,0	;1 Mentre el echo no estigui a low anem comptant
    GOTO INICI_ECHO	;2
    MOVFF us_echo_cm,LATD
    RETURN
    
;Binary -> ASCII
BN_2_ASCII ;Input: bn_ascii; Output: ascii_c, ascii_d, ascii_u
    CLRF ascii_u,0
    CLRF ascii_d,0
    CLRF ascii_c,0
BN_2_ASCII_LOOP
    MOVLW .0
    CPFSGT bn_ascii,0; Si bn_ascii <=0 -> Fi ASCII
    GOTO FI_ASCII
    
    INCF ascii_u,f,0
    MOVLW .10
    CPFSLT ascii_u,0 ; Si >=10 anem a desenes
    GOTO DESENES_ASCII
    GOTO BN_2_ASCII_LOOP_FI

DESENES_ASCII
    CLRF ascii_u,0
    INCF ascii_d,f,0
    MOVLW .10
    CPFSLT ascii_d,0 ; Si >=10 anem a centenes
    GOTO CENTENES_ASCII
    GOTO BN_2_ASCII_LOOP_FI
    
CENTENES_ASCII
    CLRF ascii_d,0
    INCF ascii_c,f,0
    
BN_2_ASCII_LOOP_FI
    DCFSNZ bn_ascii,f,0 ; Decrementem, bn_ascii=0 -> Fi, !=0 -> Loop
    GOTO FI_ASCII
    GOTO BN_2_ASCII_LOOP
        
FI_ASCII
    MOVLW .48
    ADDWF ascii_u,f,0
    MOVLW .48
    ADDWF ascii_d,f,0
    MOVLW .48
    ADDWF ascii_c,f,0
    RETURN
    
; ASCII -> EUSART    
TX_BN_2_ASCII
    MOVFF ascii_c,TXREG
    CALL ESPERA_TX
    MOVFF ascii_d,TXREG
    CALL ESPERA_TX
    MOVFF ascii_u,TXREG
    CALL ESPERA_TX
    CALL TX_ENTER
    RETURN
    
;JOYSTICK-ADCON
LLEGIR_JOY
   BSF ADCON0,1,0 ; Comencem la conversi�
ESPERA_CONVERSIO
   BTFSC ADCON0,1,0
   GOTO ESPERA_CONVERSIO
   MOVFF ADRESH,bn_ascii
   CALL BN_2_ASCII
   CALL TX_BN_2_ASCII
   MOVFF ADRESL,bn_ascii
   CALL BN_2_ASCII
   CALL TX_BN_2_ASCII
   RETURN
;-------------------------------------------------------------------------------
;EUSART

ESPERA_TX
    BTFSS TXSTA,TRMT,0
    GOTO ESPERA_TX
    return    
LLEGIR_RX
    btfss PIR1,RCIF,0
    goto LLEGIR_RX
    movf RCREG,0,0
    movwf eusart_input,0
    movff eusart_input,TXREG
    call ESPERA_TX
    return
    
TX_ENTER
    MOVLW '\n';salt de linia
    MOVWF TXREG,0
    CALL ESPERA_TX
    MOVLW '\r';inici de linia
    MOVWF TXREG,0
    CALL ESPERA_TX
    return
    
;---- INICI MODE ----
LECTOR_EUSART
    movf RCREG,0,0
    movwf eusart_input,0
    movff eusart_input,TXREG
   ; movff eusart_input,LATD ;DEBUGGING
    call ESPERA_TX
    call TX_ENTER
    ;Canvi de mode, apaguem els LEDS i el 7 seg
    ;REVISAR SI ES OK EN CAS DE QUE POSSIN UNA LLETRA INCORRECTE
    CLRF LATD,0
    BCF LATC,0,0
    BCF LATC,1,0
    movlw 'A'
    CPFSEQ eusart_input,0
    goto NEXT_A
    goto MODE_A
NEXT_A
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
    movlw 'U'
    CPFSEQ eusart_input,0
    goto NEXT_U
    goto MODE_U
NEXT_U
    call MEDIR
    goto LOOP
    ;no s'ha clicat cap tecla si arriba aqui
    
    
    
    
;-------------------------------
MODE_A
    movff display7,LATD
    MOVLW .104
    MOVWF bn_ascii,0
    CALL BN_2_ASCII
    MOVFF ascii_c,TXREG
    CALL ESPERA_TX
    MOVFF ascii_d,TXREG
    CALL ESPERA_TX
    MOVFF ascii_u,TXREG
    CALL ESPERA_TX
    CALL TX_ENTER
    ;acabat
    GOTO LOOP
MODE_D
    movff display3,LATD
    ;pulsadors +5� -5� per pulsador
    btfsc PORTB,2,0
    GOTO MirarRB1
    MOVLW .180
    CPFSEQ pos_servo,0 
;    call moure_5graus_mes
MirarRB1    
    btfss PORTB,1,0
    btg LATC,1,0
    
   ; GOTO MODE_D
    ;acabat
    goto LOOP
    

MODE_I
    ;fixar 7seg a 0
    movff display0,LATD
    ;llegir caracters  fins un /n (no ven b� \n). Guardar-lo cada cop que el reben.
    movlw .0 ;reinici adressa
    movwf eeprom_addr
    
    ;llegir
LLEGIR_I

    call LLEGIR_RX
    movff eusart_input,eeprom_data
    call EEPROM_WRITE

    movlw '\r';esperem a un enter
    cpfseq eusart_input,0
    goto NO_ENTER
    goto ACABAT_I
NO_ENTER
    incf eeprom_addr;seguent adr
    movlw .120		;mirar si >120
    cpfseq eeprom_addr,0
    goto LLEGIR_I

ACABAT_I
    call TX_ENTER
     ;guardar un carrier return extra
    movlw b'00001101'
    movwf eeprom_data
    call EEPROM_WRITE

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
    movlw 'N'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'o'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'm'
    movwf TXREG,0
    call ESPERA_TX
    movlw ':'
    movwf TXREG,0
    call ESPERA_TX
    movlw ' '
    movwf TXREG,0
    call ESPERA_TX
    movlw .0 ;reinici adressa
    movwf eeprom_addr
    
BUCLE_NOM
    ;call ESPERA_TX
    call EEPROM_READ
    movff eeprom_data, TXREG
    call ESPERA_TX
    movlw '\r' ;carrier
    cpfseq eeprom_data,0
    goto CONTINUA_NOM
    movlw '\n'
    movwf TXREG,0
    call ESPERA_TX
    goto MOSTRA_MESURES
CONTINUA_NOM
    incf eeprom_addr
    goto BUCLE_NOM  
    
    ;MOSTRAR ULTIMES 200 MESURES (PART 2/2)
MOSTRA_MESURES
    movlw 'M'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'e'
    movwf TXREG,0
    call ESPERA_TX
    movlw 's'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'u'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'r'
    movwf TXREG,0
    movlw 'e'
    movwf TXREG,0
    call ESPERA_TX
    movlw 's'
    movwf TXREG,0
    call ESPERA_TX
    movlw ':'
    movwf TXREG,0
    call ESPERA_TX
    call TX_ENTER
    ;acabat
    goto LOOP
MODE_S
    movff display4,LATD
    ;codi S
    CALL LLEGIR_JOY
    GOTO LOOP
MODE_T
    movff display5,LATD
    ;codi T
    goto LOOP
MODE_U
    call MEDIR
    
    ;Acabat
    GOTO LOOP

    END