    LIST P=PIC18F4321	F=INHX32
    #include <p18f4321.inc>

    CONFIG OSC=HS	    ;Oscillador -> High Speed
    CONFIG PBADEN=DIG	    ;PORTB com a Digital (el posem a 0)
    CONFIG WDT=OFF	    ;Desactivem el Watch Dog Timer
    
    ORG 0x000
    GOTO MAIN
    ORG 0x008
    GOTO HIGH_RSI
    ORG 0x018
    GOTO LOW_RSI
INIT_PORTS
    
    RETURN
HIGH_RSI
    RETFIE FAST
LOW_RSI
    RETFIE FAST
    
MAIN
    CALL INIT_PORTS
LOOP
    GOTO LOOP
    END