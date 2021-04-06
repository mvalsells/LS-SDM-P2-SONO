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
tmp EQU 0x17
tmp2 EQU 0x18
count_pwm EQU 0x19
tmp3 EQU 0x1A
tmp4 EQU 0x1B
ram_count EQU 0x1C
tmp_timer EQU 0x1D
tmp2_timer EQU 0x1E
ram_200_bool EQU 0x1F
estat_A EQU 0x20
estat_mesures EQU 0x21
espera_n EQU 0x22
dist_major EQU 0x23
count_major EQU 0x24
tmpRAMH EQU 0x25
tmpRAML EQU 0x26
   
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
    movlw b'11100111'
    movwf TRISB,0
    bcf INTCON2,RBPU,0
    ;C
    movlw b'11000000'
    movwf TRISC,0
    bcf LATC,0,0;apagar 1r led
    bcf LATC,1,0;apagar 2n led
    ;D
    clrf TRISD,0
    clrf LATD,0
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
    clrf count_pwm,0
    clrf FSR1L,0
    clrf FSR1H,0
    movlw .200
    movwf ram_count,0
    clrf ram_200_bool,0
    clrf estat_A,0
    clrf estat_mesures,0
    clrf count_major,0
    clrf dist_major,0
    
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
    
    BTFSC PORTB,0,0
    goto NEXT_LOOP
    ;control rebots
    call CONTROL_REBOTS
    call CONTROL_REBOTS
    ;control rebots
    BTFSS PORTB,0,0
    goto MODE_BOTO
    

    
NEXT_LOOP
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto LOOP
;-------------------------------------------------------------------------------
HIGH_RSI
    BCF INTCON,TMR0IF,0;quan salti una interrupcio qualsevol, nomes tenim timer0 de moment
    call CARREGA_TIMER;reiniciem el timer
    bsf LATA,2,0;reactivem el pin del servo
    
    movlw .250;250
    movwf tmp_timer,0
BUCLE_PWM_05
    movlw .6;5
    movwf tmp2_timer,0
BUCLE2_PWM_05
    decfsz tmp2_timer,f,0
    goto BUCLE2_PWM_05
    decfsz tmp_timer
    goto BUCLE_PWM_05
    
    ;pwm angle precis
    movlw .0
    cpfsgt count_pwm,0
    goto END_PWM
   
    movff count_pwm, tmp2_timer
BUCLE_PWM_COPS
    movlw .20
    movwf tmp_timer,0
BUCLE_PWM_GRAUS
    NOP
    NOP
    decfsz tmp_timer,f,0
    goto BUCLE_PWM_GRAUS
    decfsz tmp2_timer,f,0
    goto BUCLE_PWM_COPS
    
    
END_PWM
    bcf LATA,2,0;apaga servo
    
;PWM ACABAT MESURES AUTO
    btfsc estat_A,0
    call MEDIR;si auto
    
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
    INCF compt_10us,f,0
    BTFSS STATUS,C
    GOTO INCR_10us
    NOP
    NOP
    NOP
    BCF LATA,4,0 ;Trigger a low
ESPERA_ECHO
    BTFSS PORTA,5,0 ; esperem el echo a high
    GOTO ESPERA_ECHO
    CLRF us_echo_cm,0
INICI_ECHO
    MOVLW .60 ;64		;1
    MOVWF us_echo_58,0	;1
COMPTAR_58
    INCFSZ us_echo_58,f,0	;1
    GOTO COMPTAR_58	;2
    INCF us_echo_cm,f,0	;2=1+1
    BTFSC PORTA,5,0	;1 Mentre el echo no estigui a low anem comptant
    GOTO INICI_ECHO	;2
    DECF us_echo_cm,f,0
    
    
    MOVFF us_echo_cm,bn_ascii
    CALL BN_2_ASCII
    CALL TX_BN_2_ASCII
    call TX_CM
    
    ;guardar a ram
    movff us_echo_cm, POSTINC1
    decfsz ram_count,f,0
    RETURN
;    ;reiniciar el punter de la ram
    clrf FSR1L,0
    clrf FSR1H,0
    movlw .200
    movwf ram_count,0
    setf ram_200_bool,0
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
    RETURN
    
;JOYSTICK-ADCON
LLEGIR_JOY
   BSF ADCON0,1,0 ; Comencem la conversió
ESPERA_CONVERSIO
   BTFSC ADCON0,1,0
   GOTO ESPERA_CONVERSIO
   RETURN
   
;-------------------------------------------------------------------------------
;EUSART
TX_CM
    movlw 'c'
    movwf TXREG,0
    call ESPERA_TX
    movlw 'm'
    movwf TXREG,0
    call ESPERA_TX
    call TX_ENTER
    return
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
    call ESPERA_TX
    call TX_ENTER
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
    movlw 'N'
    CPFSEQ eusart_input,0
    goto NEXT_N
    goto MODE_N
NEXT_N
    goto LOOP
    ;boto clicat
    
;---------------------------------------------------------------------------------
MODE_A
    movff display7,LATD
    
    movlw .0
    cpfsgt estat_mesures,0
    goto ACTIVAR_A;estava a 0, activa A
    movlw .1
    cpfsgt estat_mesures,0
    goto ACTIVAR_A;estava a U, activa a A
    
    btfss estat_A,0;2, ja estavem a A, toggle mesures
    goto ACTIVAR_AUTO;activar mesures, estava a 0
    ;desactivar mesures, estava a 1
DESACTIVAR_AUTO;mesures
    clrf estat_A,0
    goto LOOP
ACTIVAR_AUTO
    setf estat_A,0
    goto LOOP
ACTIVAR_A;mode A
    bsf LATC,0,0
    bsf LATC,1,0
    movlw .2
    movwf estat_mesures,0
    goto LOOP
MODE_D
    movff display3,LATD
    ;pulsadors +5º -5º per pulsados

    
    BTFSC PORTB,1,0
    goto NEXT_BTN
    ;control rebots
    call CONTROL_REBOTS
    call CONTROL_REBOTS
    ;control rebots
    BTFSC PORTB,1,0
    goto NEXT_BTN
    
    movlw .175 ;valor maxim
    cpfslt count_pwm
    goto NEXT_BTN
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
ESPERA_BTN1
    btfss PORTB,1,0
    goto ESPERA_BTN1
    
NEXT_BTN
    
    btfsc PORTB,2,0
    goto FI_D
    ;control rebots
    call CONTROL_REBOTS
    call CONTROL_REBOTS
    ;control rebots
    BTFSC PORTB,2,0
    goto FI_D
    
    movlw .4 ;valor minim
    cpfsgt count_pwm
    goto FI_D
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
    
ESPERA_BTN2
    btfss PORTB,2,0
    goto ESPERA_BTN2
    
FI_D
    
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_D
    
CONTROL_REBOTS
    setf tmp3,0
BUCLE_D_1
    setf tmp4,0
BUCLE2_D_1
    decfsz tmp4,f,0
    goto BUCLE2_D_1
    decfsz tmp3,f,0
    goto BUCLE_D_1
    return

MODE_I
    ;fixar 7seg a 0
    movff display0,LATD
    ;llegir caracters  fins un /n (no ven bé \n). Guardar-lo cada cop que el reben.
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
    movlw .200
    cpfseq ram_count,0
    goto MOSTRAR_MESURA
    btfss ram_200_bool,0
    goto MOSTRA_GUIO2
    
MOSTRAR_MESURA
    movff INDF1,bn_ascii
    call BN_2_ASCII
    call TX_BN_2_ASCII
    call TX_CM
    call TX_ENTER
    goto M_FINAL
MOSTRA_GUIO2
    ;cas cap guardat
    movlw '-'
    movwf TXREG,0
    call ESPERA_TX
    call TX_ENTER
    
M_FINAL
    ;acabat
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto LOOP
    
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
    ;LLEGIR RAM
    
    btfsc ram_200_bool,0;hem fet una volta?
    goto MOSTRA_TOT
    ;goto MOSTRA_ALTRES
;MOSTRA_ALTRES
    movlw .200
    cpfslt ram_count,0;hem fet minim una?
    goto GUIO
    ;goto MOSTRA_PARCIAL
;MOSTRA_PARCIAL
    movff FSR1H, tmpRAMH;copia
    movff FSR1L, tmpRAML
BUCLE_RAM_PARCIAL
    movff PREINC1,bn_ascii
    call BN_2_ASCII
    call TX_BN_2_ASCII
    call TX_CM
    
    decfsz tmpRAML,f,0
    goto BUCLE_RAM_PARCIAL
    
    movff tmpRAMH, FSR1H ;retorna copia
    movff tmpRAML, FSR1L
    
    goto LOOP
MOSTRA_TOT
    movff FSR1H, tmpRAMH;copia
    movff FSR1L, tmpRAML
    clrf FSR1H,0
    clrf FSR1L,0
BUCLE_RAM_TOT
    movff PREINC1,bn_ascii
    call BN_2_ASCII
    call TX_BN_2_ASCII
    call TX_CM
    
    movlw .200
    cpfseq FSR1L,0
    goto BUCLE_RAM_TOT
    
    movff tmpRAMH, FSR1H ;retorna copia
    movff tmpRAML, FSR1L
    
    goto LOOP 
;    
;    movlw .200
;    cpfslt ram_count,0
;    goto MOSTRA_GUIO;no n'hi ha cap
;    
;    movff FSR1H, tmp2;copia
;    movff FSR1L, tmp3
;    
;BUCLE_RAM2
;    movff POSTDEC1,bn_ascii
;    call BN_2_ASCII
;    call TX_BN_2_ASCII
;    call TX_CM
;    
;    movlw .0
;    cpfseq FSR1L,0
;    goto BUCLE_RAM2
;    ;mostrar la 0
;    
;    ;si mostrar els que queden per fer la volta
;    btfss ram_200_bool,0
;    
;    movff tmp2, FSR1H
;    movff tmp3, FSR1L
;    goto LOOP;no volta
;    ;si volta
;    
;    movlw HIGH(.200)
;    movwf FSR1H,0
;    movlw LOW(.200)
;    movwf FSR1L,0
;BUCLE_RAM3
;    movff POSTDEC1,bn_ascii
;    call BN_2_ASCII
;    call TX_BN_2_ASCII
;    call TX_CM
;    
;    movf tmp3,w,0
;    cpfseq FSR1L,0
;    goto BUCLE_RAM3
;    
;    movff tmp2, FSR1H
;    movff tmp3, FSR1L
;    goto LOOP
;MOSTRA_GUIO
;    btfss ram_200_bool,0
;    goto GUIO
;    ;cas si volta, 200 justos
;    movff FSR1H, tmp2
;    movff FSR1L, tmp3
;    
;    movlw HIGH(.200)
;    movwf FSR1H,0
;    movlw LOW(.200)
;    movwf FSR1L,0
;    
;    movlw .200
;    movwf tmp,0
;BUCLE_RAM1
;    movff POSTDEC1,bn_ascii
;    call BN_2_ASCII
;    call TX_BN_2_ASCII
;    call TX_CM
;    decfsz tmp,f,0
;    goto BUCLE_RAM1
;    
;    movff tmp2, FSR1H
;    movff tmp3, FSR1L
;    goto LOOP
;    
GUIO
    ;cas cap guardat
    movlw '-'
    movwf TXREG,0
    call ESPERA_TX
    call TX_ENTER
    
    goto LOOP
    
MODE_S
    movff display4,LATD
    ;codi S
    CALL LLEGIR_JOY
    MOVLW .250
    CPFSGT ADRESH,0
    GOTO CP_LOW
    movlw .175 ;valor maxim
    cpfslt count_pwm
    goto CP_LOW
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
    incf count_pwm,f,0
BUCLE_JOY_H   
    CALL LLEGIR_JOY
    MOVLW .136
    CPFSLT ADRESH,0
    GOTO BUCLE_JOY_H   
CP_LOW
    CALL LLEGIR_JOY
    MOVLW .5
    CPFSLT ADRESH,0
    GOTO FI_S
    movlw .4 ;valor minim
    cpfsgt count_pwm
    goto FI_S
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
    decf count_pwm,f,0
BUCLE_JOY_L
    CALL LLEGIR_JOY
    MOVLW .116
    CPFSGT ADRESH,0
    GOTO BUCLE_JOY_L
FI_S
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_S

MODE_T
    movff display5,LATD
    CALL LLEGIR_JOY
    
    MOVLW .90
    CPFSLT ADRESH,0
    GOTO MES_90
    ;MENYS 90
    MOVFF ADRESH,count_pwm
    GOTO FI_T
    
MES_90
    MOVLW .160
    CPFSGT ADRESH,0
    GOTO MIG
    MOVLW .85
    SUBWF ADRESH,w,0
    MOVWF count_pwm,0
    GOTO FI_T
MIG
    MOVLW .75
    MOVWF count_pwm,0
FI_T
    btfsc PIR1,RCIF,0
    goto LECTOR_EUSART
    goto MODE_T
MODE_U
    
    movlw .2
    cpfslt estat_mesures,0
    goto ACTIVAR_U
    movlw .1
    cpfseq estat_mesures,0
    goto ACTIVAR_U
    call MEDIR
    goto LOOP
    
ACTIVAR_U
    BSF LATC,0,0
    bcf LATC,1,0
    movlw .1
    movwf estat_mesures,0
    clrf estat_A,0
    goto LOOP
MODE_BOTO
    btfss PORTB,0,0
    goto MODE_BOTO
    
    movlw .2
    cpfslt estat_mesures,0
    goto MODE_A
    movlw .0
    cpfsgt estat_mesures,0
    goto LOOP
    goto MODE_U

MODE_N
    clrf dist_major,0;distancia major
    clrf count_pwm,0
    CALL DELAY;espera que torni a 0graus si no hi era
    CALL DELAY
    
BUCLE_N
    ;call DELAY
    CALL MEDIR
    incf count_pwm,f,0
    call DELAY
    ;CALL DELAY;DELAYS AQUI SOLS
    
    ;mirar si es la mes llunyana / gran
    movf us_echo_cm,w,0
    cpfsgt dist_major,0
    CALL SAVE_DIST
    ;-^
    
    movlw .179;179;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;reduir a 10 pq funcioni
    cpfseq count_pwm,0
    goto BUCLE_N
    
    ;anar a la mes llunyana / gran
    ;call DELAY;
    call TX_ENTER
    movff dist_major,bn_ascii
    call BN_2_ASCII
    call TX_BN_2_ASCII
    call TX_CM
    call TX_ENTER
    movff count_major, count_pwm
    ;-^
   
    goto LOOP
    
DELAY
    MOVLW .10
    MOVWF tmp3,0
DELAY_B0
    movlw .255
    movwf tmp,0
DELAY_B1
    movlw .255
    movwf tmp2,0
DELAY_B2
    decfsz tmp2,f,0
    goto DELAY_B2
    decfsz tmp,f,0
    goto DELAY_B1
    DECFSZ tmp3,f,0
    goto DELAY_B0
    
    return
SAVE_DIST
    movff count_pwm, count_major
    movff us_echo_cm, dist_major
    RETURN
    
    END