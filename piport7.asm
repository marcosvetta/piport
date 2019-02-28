	ORG 0
	LJMP PIPO				;Programa ppal
	ORG 3
	LJMP INTE				;Interrupcion 0
	ORG 013H
	LJMP INTE1				;Interrupcion 1
	ORG 0Bh
	LJMP TIMER0		  		;Timer 0
;	ORG 1BH
;	LJMP TIMER1;CONTADOR			;Contador 1
	ORG 023H
	LJMP SERIE           ;UART
	ORG 2BH
	LJMP TIMER2
	
;------------------VARIABLES BIT A BIT 

ORG 32
	
   CARD_DATA bit p2.6   ;p17
   CARD_PRESENT bit p2.5 ;p15
   CARD_CLK bit p3.2

   FLAG_INT0 bit TCON.1
   FLAG_INT1 bit TCON.3
      
   Lled bit p2.4
   CLKled bit p2.3
   DATAled bit p2.2
   
   SW1 bit P3.4
   SW2 bit p3.5
   
   COIN bit P2.0

	ctrl_a_out bit P1.0
	ctrl_b_out bit P1.1
	out_inh bit P3.7

	ctrl_a_in bit P1.2	
	ctrl_b_in bit P1.3	
	in_inh bit P1.4	

	pulso_tkout bit P2.1
	active bit P3.3
		   
 	WDRST DATA 0A6H
 	AUXR DATA 08EH		
 	
 	TR2 bit 0C8H.2 
	TF2 bit 0C8H.7
	CT2 bit 0C8H.1
	
	T2CON DATA 0C8H
	T2MOD DATA 0C9H
	RCAP2L DATA 0CAH
	RCAP2H DATA 0CBH
	TL2 DATA 0CCH
	TH2 DATA 0CDH
   
 	
;------------------VARIABLES
  ORG 48 
  
;	contador_ equ 92
	Byte_actual equ 94 ;variable de salida de funcion1 con los bit de CARD_DATA 
	Leyendo equ 95 ;variable que indica que ingreso en la int0
	Itera equ 96	  ;var de iteracion para funcion 1
	Paquete_full equ 97
	Largo_data equ 98
	Veri equ 99  ;Variable de salida de la funcion Verificar_cadena si es A=directo, B-inverida y C=error
   Transmision_OK equ 100
	ValorLRC equ 101   
	Desplazamiento equ 102
	Contador_acomodar_cadena equ 103
	Direccion_actual equ 104
	contador_permutar equ 105
	contador_RC equ 106	
	contador_GC equ 107
	VAR_INI_LED equ 108	
	Contador_rojo equ 109	
	Contador_G equ 90
	Contador_G1 equ 91

	Recive equ   64  ;con 0 recive distinto de cero no recive   
   Tiempo_expire equ 65
   Tiempo_expire_total equ 66
   Cuenta_byte equ 67
   Largo_cadena equ 68
   Tiempo_inter_byte equ 69
   Tiempo_ibytel equ 70
   Tiempo_ibyteh equ 71
   Valor_tibytel equ 72
   Valor_tibyteh equ 73
   Tiempo_etl equ 74
   Tiempo_eth equ 75
   Valor_tetl equ 76
   Valor_teth equ 77
   Valor_cuenta_byte equ 78
   T_expire_total equ 79
   Inicio equ 80
   Valor_CHAIN_CHK equ 81
   Contador_retardo_coin_l equ 82
   Contador_retardo_coin_h equ 83
	Flag_lectura_tarjeta equ 84   
	Pagando equ 85
	Acumulador_pago equ 86
   Contador_retardo_pago_l equ 87
   Contador_retardo_pago_h equ 88
   
   Contador_retardol equ 89
   Contador_retardoh equ 92
	
	Habilita_pago_TKE equ 93
	Pago_opcion equ 110
	Pago_activo equ 111
	
	Error_card equ 63
	Habilita_pago_TKF equ 62
	
	Contador_retardo_luzl equ 112
	Contador_retardo_luzh equ 113

	Habilita_pago_AUTO equ 114	 ;Autorecharger
	Habilita_pago_TKA equ 115  ;ticket eater	
	
	LED1 equ 116	
	LED2 equ 117
	LED3 equ 118
	LED4 equ 119
	LED5 equ 120
	LED6 equ 121
	LED7 equ 122	
	LED8 equ 123
	LED9 equ 124
	LED10 equ 125
	LED11 equ 126
	LED12 equ 127
	
			
;------------------ARRAY
  ORG 080H
  START_SEN: DS 14
  ORG 08EH
  END_SEN:DS 1
  ORG 08FH
  LRC1: DS 1

  ORG 090H  
  START_SEN2: DS 14
  ORG 09EH
  END_SEN2:DS 1
  ORG 09FH
  LRC2: DS 1  
 
  ORG 0B0H     ;0A0H
  BRG: DS 6

  ORG 0C0H     ;0B0H
  SERIAL: DS 16
  
  
;------------------PROGRAMA
  ORG 0300H
;XRESET:


PIPO:	

;----------INTERRUPT0

 ; SETB IP0.0									;MAXIMA PIORIDAD A INT0
	SETB TCON.0						
  ;FLANCO DESC
 ; CLR TCON.0									;nivel
	SETB TCON.2
	clr IE.2										;desHAB INT01
	;SETB IE.0									;HAB INT0
	clr IE.0									 ;desHAB INT0 18/5/2018
	SETB IE.7									;HAB INTER EN GRAL

;------------TIMER0
	
	mov tmod,#01h	                       ;permite hab o desh el timing
	mov TL0,#01h	
	mov TH0,#00h	
	setb ET0											;Hab. timer0 (IE.1)
	setb EA											;hab. interrup. en gral(IE.7).
	clr TR0	   									;paro el counter 0
;	setb TR0	   									;arranco el counter 0	       

;------------SERIAL
	

	clr SM0
	setb SM1	;modo 1
	setb SCON.4 ;Habilitar la recepcion serail
	setb ie.7	;hab. de int GRAL.
	setb ie.4	;y serie
	mov th1,#0FCH	;det el baud rate
	mov tl1,#0FCH
	mov tmod,#20h	;timer1 modo 2
	;clr ES
	setb ES
	setb tr1	;arranco timer 1
;---------Timer 0
;	setb tr0	;arranco timer 1

;;------------TIMER2
;	
	mov t2mod,#00h	
	mov t2con,#00H
	mov TL2,#0BFH;07Fh	
	mov TH2,#0E0H;0FFh	
;	mov TL2,#07Fh	
;	mov TH2,#0FFh	
	setb IE.5											;Hab. timer2 (IE.6)
	;setb EA											;hab. interrup. en gral(IE.7).
	clr TR2			   									;paro el timer 2
	;setb TR2

;---------------------


;call Tiempo
;iniciializaciones
mov Recive,#00H;#0FFh ;No recibe comunicacion serial
mov Transmision_OK,#00H
mov Flag_lectura_Tarjeta,#0FFH ;LECTURA DE TARJETA DESHABILITADA 26/6/2018
call INI_VAR_READ ;Inicializa las variables de lectura de tarjeta
Call INI_TIEMPO ;Inicializa las variables de comunicacion serie
Call INI_PAGO
;call CP_CAD
;call VERIFICAR_CADENA_FINAL
mov Contador_retardo_luzl,#08H
mov Contador_retardo_luzh,#01H ;;low: 08H Hig:02H t= 0,25ms   5/6/20018 cambio de 2 a 1

mov Contador_retardo_coin_l,#0FEH ;low: 0FEH Hig:070H t= 115ms   20/7/2018
mov Contador_retardo_coin_h,#070H ;low: 0FEH Hig:070H t= 115ms   20/7/2018

;==============================
call Girar
call INI_MEM
call INI_LED
;call RGB_LED    led en blanco lo saco por alta temperatura
call MUTE_HAB
mov Contador_retardol,#010H ;low: 010H Hig:02H t= 0,5ms
mov Contador_retardoh,#02H ;low: 010H Hig:02H t= 0,5ms
call  RETARDO_0xms   ;22ms

call INI_CMD
;=========WDT
;mov AUXR,#08H
;setb TR2 ;activar timer2 para WDog 24/9
;clr CT2 ;Depende de la frecuencia de clk
;=========WDT

LOOP:

 jnb SW1,SW1_PRES
 jnb SW2,SW2_PRES

;		mov acc,Cuenta_byte
;		jz	LAZ1
		   mov a,Tiempo_expire   ;expiro tiempo interbyte
		 	jnz LAZ2 
;		 	   mov a,Tiempo_expire_total    ;paso el tiempo de rta maximo 600mseg
;		 	   jnz LAZ3
				mov a,Habilita_pago_TKE
				jnz PAYING_TKE
				mov a,Habilita_pago_TKF
				jnz PAYING_TKF
				mov a,Habilita_pago_AUTO
				jnz PAYING_TKF

LOOP_1:
 mov a,Flag_lectura_tarjeta
 jnz LOOP
			 	    mov a,Leyendo
			 	    jnz READING    ;mira si mientras estaban las luces entro una tarjeta
	jb CARD_PRESENT,LOOP  ;SI baja el card prersent va a leyendo tarjeta
		jmp READING	 
    
jmp LOOP


LAZ2: ;Cuando se supera el tiempo interbye analiza lo que llega y actua
clr TR0 ; Paro el timer0
jmp CHK_ENTRADA

SW2_PRES:
	mov Recive,#0FFh ;No recive  comunicacion serie
	call carga_BRG_FUEGO
   call Buffer_fill_LED
 	mov Transmision_OK,#00H
 	mov sbuf,#049H ;Boton 1
SW_TX:
	 	mov a,Transmision_OK
 		jz SW_TX
		mov Transmision_OK,#00H
		mov Recive,#00h ;Recive  comunicacion serie		
  	jmp LOOP

SW1_PRES:
	mov Recive,#0FFh ;No recive  comunicacion serie
	call Hab_TTL
   call Carga_VERDE_CIAN
   call Buffer_fill_LED
 	mov Transmision_OK,#00H
 	mov sbuf,#050H   ;Boton 2  
   jmp SW_TX

READING:	
	 jnb CARD_PRESENT,READING
jmp LEER_TARJETA_TTL	 	
  
PAYING_TKF:
   call MUTE_DES
	
mov a,Acumulador_pago ;Pagando/contando tikerts fisicos
jz LOOP_1
	mov sbuf,#041H  ;Pago de tickets fisico 'A'
Pay_CTRLTKF:
	 	mov a,Transmision_OK
 		jz Pay_CTRLTKF
  		mov Transmision_OK,#00H
dec Acumulador_pago  		

	call carga_AMARILLO
   call Buffer_fill_LED
	call Girar_color

jmp LOOP

PAYING_TKE:
				mov a,Pago_activo      ;Este valor se refiere si es x alto 00h o es x bajo 0ffh 
			   jz CHEKA_P_B
			  		jb active,PAYING_TKE1 ; Salta a Pagar Tikets pero Activo LOW
 					jmp LOOP_1
CHEKA_P_B:
					jb active,PAYING_TKE1 ; Salta a Pagar Tikets pero Activo HIG
					jmp LOOP_1
PAYING_TKE1:			   

   call MUTE_DES
   
	mov sbuf,#040H  ;Pago de tickets @
Pay_CTRL:
	 	mov a,Transmision_OK
 		jz Pay_CTRL
  		mov Transmision_OK,#00H
   ;Iniciar un timer
   ;iniciar variables de recepcion serie
   ;esperar respuesta @
   ;pasado el timer vuelve aenviar el tk
	  	call F_TKE


	call CARGA_LUZ_PAGO_MEM
   call Buffer_fill_LED
	call CARGA_LUZ_PAGO_MEM	
   call Buffer_fill_LED
	call CARGA_LUZ_PAGO_MEM
   call Buffer_fill_LED

	call CARGA_LUZ_PAGO_MEM2
   call Buffer_fill_LED
	call CARGA_LUZ_PAGO_MEM2	
   call Buffer_fill_LED
	call CARGA_LUZ_PAGO_MEM2
   call Buffer_fill_LED


;	call Girar_color
	  	
jmp LOOP

;PAYING_AUTO:
;   call MUTE_DES
;	
;mov a,Acumulador_pago ;Pagando/contando tikerts fisicos
;jz LOOP_1
;	mov sbuf,#041H  ;Pago de tickets fisico 'A'
;Pay_CTRLAUTO:
;	 	mov a,Transmision_OK
; 		jz Pay_CTRLAUTO
;  		mov Transmision_OK,#00H
;dec Acumulador_pago  		
;
;	call carga_AMARILLO
;   call Buffer_fill_LED
;	call Girar_color
;
;jmp LOOP


CHK_ENTRADA:
 call CHAIN_CHK

	mov a,VALOR_CHAIN_CHK
	xrl a,#024H  ;!
	jz ES_COLOR 

	mov a,VALOR_CHAIN_CHK
	xrl a,#02AH  ;*
	jz ES_COIN 

	mov a,VALOR_CHAIN_CHK
	xrl a,#025H  ;%
	jz ES_GIRO 

	mov a,VALOR_CHAIN_CHK
	xrl a,#026H  ;&
	jz ES_Hab_TTL 

	mov a,VALOR_CHAIN_CHK
	xrl a,#027H  ;'
	jz ES_Des_TTL 

	mov a,VALOR_CHAIN_CHK
	xrl a,#028H  ;(
	jz ES_GIRO_N 

	mov a,VALOR_CHAIN_CHK
	xrl a,#029H  ;)
	jz ES_Tiempo 

	mov a,VALOR_CHAIN_CHK
	xrl a,#030H  ;0
	jz ES_HAB_PAGO 

	mov a,VALOR_CHAIN_CHK
	xrl a,#03AH  ; :
	jz ES_HAB_MUTE 

	mov a,VALOR_CHAIN_CHK
	xrl a,#03CH  ; <
	jz ES_DHAB_MUTE 

	mov a,VALOR_CHAIN_CHK
	xrl a,#031H  ; 1
	jz ES_TIEMPO_GIRO 

	mov a,VALOR_CHAIN_CHK
	xrl a,#032H  ; 2
	jz ES_GIRO_IZQ 

	mov a,VALOR_CHAIN_CHK
	xrl a,#033H  ; 2
	jz ES_LED_PAGO 

	mov a,VALOR_CHAIN_CHK
	xrl a,#034H  ; 2
	jz ES_LED_PAGO2 
	
	call INI_TIEMPO	
	jmp LOOP

ES_COLOR:
		call CP_CAD
		call Buffer_fill_LED
      jmp ES_SALIDA1
ES_COIN:
;		call F_COIN
;      call GIRAR1
      jmp ES_SALIDAY
ES_GIRO:
      call GIRAR1
      jmp ES_SALIDA1
ES_Hab_TTL:
		call Hab_TTL
      jmp ES_SALIDAZ
ES_Des_TTL:
		call Des_TTL
      jmp ES_SALIDAZ
ES_GIRO_N:
      call GIRAR1
      call GIRAR1
      jmp ES_SALIDA1
ES_Tiempo:
		call Seteo_tiempo
      jmp ES_SALIDA
ES_HAB_PAGO:
		call SET_PAGO
		jmp ES_SALIDA
ES_HAB_MUTE:
		call MUTE_HAB
		jmp ES_SALIDAT
ES_DHAB_MUTE:
		call MUTE_DES
		jmp ES_SALIDAT
ES_TIEMPO_GIRO:
		call Tiempo_GIRO
		jmp ES_SALIDA
ES_GIRO_IZQ:
		call GIRAR2
		jmp ES_SALIDA1
ES_LED_PAGO:
		call LED_PAGO
		jmp ES_SALIDA1
ES_LED_PAGO2:
		call LED_PAGO2
		jmp ES_SALIDA1


ES_SALIDA:
		call INI_TIEMPO
		mov sbuf,#055H      ;Confimacion de comandos U
;---------------------------22/3/2018
      jmp ES_CTRL
ES_SALIDA1:
		call INI_TIEMPO
		mov sbuf,#056H    ;confirmacion de luces  con V
;---------------------------18/4/2018     
      jmp ES_CTRL
ES_SALIDAT:
		call INI_TIEMPO
		mov sbuf,#054H      ;Confimacion de comandos T
;---------------------------4/5/2018
      jmp ES_CTRL
ES_SALIDAY:
		call INI_TIEMPO
		mov sbuf,#059H      ;Confimacion de comandos Y
;---------------------------18/4/2018
		call F_COIN
      call GIRAR1
      jmp ES_CTRL
ES_SALIDAZ:
		call INI_TIEMPO
		mov sbuf,#05AH      ;Confimacion de comandos Z
;---------------------------18/4/2018
;      jmp ES_CTRL

ES_CTRL:
	 	mov a,Transmision_OK
 		jz ES_CTRL
  		mov Transmision_OK,#00H
  		jmp LOOP		

LEER_TARJETA_TTL:
;-----------
      ;----------22/3/2018		
		call Des_TTL
      ;----------22/3/2018
      		
		clr IE.0 ;no puede entrar mas a leer la int
		call VERIFICAR_CADENA ;Verifica cadena si llego al derecho o al reves
;		mov veri,#0BH	
;---------
		mov a,Veri
		cjne a,#0CH,VERIFICA_DIRECTO  ;comprueba si sale por error
		    jmp FIN_LOOP ;Vuelve a empezar
VERIFICA_DIRECTO:
			cjne a,#0AH,VERIFICA_INVERTIDO
            jmp ENVIAR_CAD
VERIFICA_INVERTIDO:			
           cjne a,#0BH,FIN_LOOP    ;ALgo raro no envia vuelve a empezar
ENVIAR_CAD:
		call SUMA30
		call VERIFICAR_CADENA_FINAL
			mov a,Error_card
			jnz FIN_LOOP


      call Enviar  ;Enviar por puerto serie

      ;----------22/3/2018
      ;mov Recive,#00H ;vuelvo a hab recepcion
      ;---------22/3/2018

call INI_MEM  ; inicializa la memoria de trabajo
call INI_VAR_READ ;inicializa las varibles de lectura
;call Girar   
call INI_TIEMPO ;26/3/2018 reiniciba el buffer serie
;---------------------------26/3/2018     
mov Transmision_OK,#00H
mov sbuf,#058H    ;Fin de giro X
ES_CTRL3:
	 	mov a,Transmision_OK
 		jz ES_CTRL3
  		mov Transmision_OK,#00H

      mov Recive,#00H ;vuelvo a hab recepcion

;---------------------------26/3/2018     
jmp LOOP

FIN_LOOP:     	
;---------------------------22/3/2018     
;mov a,Flag_lectura_tarjeta
;jnz FIN_TARJ_ERROR
mov Transmision_OK,#00H
mov sbuf,#057H    ;Error de tarjeta W
ES_CTRL2:
	 	mov a,Transmision_OK
 		jz ES_CTRL2
  		mov Transmision_OK,#00H

FIN_TARJ_ERROR:
      mov Recive,#00H ;vuelvo a hab recepcion
;---------------------------22/3/2018     
call INI_MEM  ; inicializa la memoria de trabajo
call INI_VAR_READ ;inicializa las varibles de lectura
jmp LOOP

;------------------------------INTE
INTE:
push acc
push PSW
mov a,r0
push acc
      ;----------22/3/2018
      mov Recive,#0FFH ;freno cualquier recepcion
      ;---------22/3/2018
      
      mov a,Leyendo  ;Se fija si es el primer uno
		jnz SIGUE_INTE  ;si Letynedo sigue en 00  
			jb CARD_DATA,FIN_INTE    ;si es un cero negado sale todavia no entro ningun 1
				mov Leyendo,#0FFH     ;si el entro es el primer 1

SIGUE_INTE:

	mov acc,Byte_actual
	mov c,CARD_DATA
	cpl c
	rrc a
	mov Byte_actual,acc
	mov acc,Itera
	xrl a,#04h ;xrl a,#07h ahora comparo con 4 es decir que entraron 5 bytes
	jz Buffer_full
	   inc Itera
;	   mov Paquete_full,#00h 
	   jmp Fin_f2
BUFFER_FULL:
		mov acc,Byte_actual
      rrc a
      rrc a
      rrc a
      anl a,#01FH
		mov Byte_actual,acc       
;      mov Paquete_full,#0FFh
      mov Itera,#00h
     
Fin_f1:	
;		mov a,Paquete_full
;		jz Sigue_f2
			mov r0,Direccion_actual
	      mov @r0,Byte_actual	;Call Guarda_ram apartir de Startsentinel      	
   	   inc r0
   	   inc Largo_data
   	   mov Direccion_actual,r0
;   	   mov Byte_actual,#00H
   	   ;clr c
  	      ;jmp Fin_f2  ;Sale para guardar dato en ram
  	      mov a,Largo_data
  	      xrl a,#031H     ;tama;o maximo de buffer en mem
  	      jz ERROR_INT0
  	         jmp Fin_f2
ERROR_INT0:
		call INI_VAR_READ ;inicializa las varibles de lectura
Sigue_f2:	

		
Fin_f2:
      	
FIN_INTE:

pop acc
mov r0,acc
pop PSW
pop acc
reti


;------------------------------CONTADOR0
INTE1:
clr IE.2
push acc
push PSW

         call Tiempox4
         call Tiempox4         
         call Tiempox4         
			jb p3.3,fin_inte1
         call Tiempox4         
         call Tiempox4
         call Tiempox4         
			jb p3.3,fin_inte1
         call Tiempox4
         call Tiempox4         
         call Tiempox4  
         call Tiempox4                                        
			jb p3.3,fin_inte1

mov Pagando,#0FFH
inc acumulador_pago 
 
; 	setb TR0 ;arranco un timer para medir tiempo interpago
;		mov TH0,#00H
;		mov TL0,#00H

;		mov TiempoL_I,#0EH
;		mov TiempoH_I,#01H
 	


FIN_INTE1:
pop PSW
pop acc
SETB IE.2
clr IE1	
reti

;---------------------------SERIE
SERIE:
push acc
push PSW
mov acc,r1
push acc

;mov WDRST,#01EH
;mov WDRST,#0E1H

	jb RI,Rxon
	jb TI,Txon
	jmp fin_serie
Rxon:	
  mov a,Recive
  jnz FIN_SERIE1

  setb Tr0  ;activo tiempo para interbyte

  mov acc,Inicio
  add a,Largo_cadena
  mov r1,acc
  
  mov acc,sbuf  
;  mov Orden,a    ;espera recibir 103 del controller 
;  mov Flag_orden,#0FFH

   mov @R1,acc
 
   inc Largo_cadena

	dec Cuenta_byte ;despues verificar si llega a cero hay un error de desborde
	
	mov Tiempo_inter_byte,#0FFH

	mov TL0,#01h	
	mov TH0,#00h	
	setb TR0   ;Arranco el timer 0 para empezar con tiempo interbyte

	clr RI	   
	jmp fin_serie
Txon:
	mov Transmision_OK,#0FFH
	clr TI
fin_serie:
  jmp FIN_FIN
  
FIN_SERIE1:
clr RI

FIN_FIN:
pop acc
mov r1,acc
pop PSW
pop acc
reti
       
;-------------------------TIMER0/contador
TIMER0:
push acc
push PSW

;mov WDRST,#01EH
;mov WDRST,#0E1H

	mov a,Tiempo_inter_byte
	jz NO_INTERBYTE
			mov a,Tiempo_ibytel
			dec a
			mov Tiempo_ibytel,a
			jnz FIN_TIBL
					mov a,Tiempo_ibyteh
					dec a
					mov Tiempo_ibyteh,a
					jnz FIN_TIBH
						mov Tiempo_expire,#0FFH	
					   mov Tiempo_inter_byte,#00H
				      jmp NO_INTERBYTE
FIN_TIBH:
       mov Tiempo_ibytel,Valor_tibytel
FIN_TIBL:
		 

NO_INTERBYTE:	

	mov a,T_expire_total
   jz NO_T_EXPIRE
       mov a,Tiempo_etl
       dec a
       mov Tiempo_etl,a
       jnz FIN_TETL
       		mov a,Tiempo_eth
       		dec a
       		mov Tiempo_eth,a
       		jnz FIN_TETH
       			mov Tiempo_expire_total,#0FFH
       		   mov T_expire_total,#00H
       		   jmp NO_T_EXPIRE

FIN_TETH:
      mov Tiempo_etl,Valor_tetl
FIN_TETL:

   
NO_T_EXPIRE:

pop PSW
pop acc
reti

;CONTADOR:
;push acc
;push PSW
;
;
;
;pop PSW
;pop acc
;reti


;-------------------Funcion 1
;Guarda los bits de datos en el acumulador hasta completarlo
;las entradas son > CARRY 
;Las salidas son> Paquete_full (00h:incompleto, 0FFh:lleno) , Byte_actual
;          
;Funcion1:
;push acc
;push PSW
;
;	
;	mov acc,Byte_actual
;	rrc a
;	mov Byte_actual,acc
;	mov acc,Itera
;	xrl a,#04h ;xrl a,#07h ahora comparo con 4 es decir que entraron 5 bytes
;	jz Buffer_full
;	   inc Itera
;	   mov Paquete_full,#00h 
;	   jmp Fin_f1
;BUFFER_FULL:
;		mov acc,Byte_actual
;      rrc a
;      rrc a
;      rrc a
;      anl a,#01FH
;		mov Byte_actual,acc       
;      mov Paquete_full,#0FFh
;      mov Itera,#00h
;     
;Fin_f1:	
;pop PSW
;pop acc
;ret

;-------------------Funcion 2
;Verifica si Paquete_full esta lleno , si es asi llama a guardarlo a Ram
;sale con Largo_dat con la cantidad de registros insertados en RAM 
;Sino llama a funcion 1          
;Funcion2:
;push acc
;push PSW
;
;;		mov c,CARD_DATA
;;		cpl c
;		Call Funcion1
;		mov a,Paquete_full
;		jz Sigue_f2
;	      mov @r0,Byte_actual	;Call Guarda_ram apartir de Startsentinel      	
;   	   inc r0
;   	   inc Largo_data
;   	   mov Byte_actual,#00H
;   	   clr c
;  	     jmp Fin_f2  ;Sale para guardar dato en ram
;Sigue_f2:	
;
;		
;      	
;Fin_f2:
;pop PSW
;pop acc
;ret
;-------------------LRC
;Salida en el registro 2 del LRC
;Analiza la Cadena que se encuentra en START_SEN de la RAM

LRC:
push acc
push PSW
mov a,r0
push acc
mov a,r2
push acc


mov r2,#00h
mov r0,#START_SEN

Loop1:

	mov a,@r0
	anl a,#0Fh
	xch a,r2
	xrl a,r2
	xch a,r2
	inc r0
	cjne a,#0Fh,Loop1	
		mov  ValorLRC,r2

pop acc
mov r2,acc
pop acc
mov r0,acc
pop PSW                                                                                                                                                       
pop acc
ret
;=================Enviar
;Funcion Que envia los los valores de la tarjeta
;Entradas: Cantidad de bytes a enviar en LARGO_DATA,
;Si esta hab la transmision con HAB_RX=00H y inicio de 
;cadena a enviar en r0

Enviar:
push acc
push PSW
mov a,r0
push acc
 

mov Recive,#0FFh ; DesHabilita recibe comunicacion serial
mov r0,#START_SEN
;mov r2,Largo_data
;mov Largo_data,#010H
mov Largo_data,#0FH

Lazo_TX:
mov a,@r0
mov sbuf,a
inc r0

ESPERA:
	mov a,Transmision_OK
	JZ ESPERA

mov Transmision_OK,#00H
mov Contador_retardol,#010H ;low: 010H Hig:02H t= 0,5ms
mov Contador_retardoh,#02H ;;low: 010H Hig:02H t= 0,5ms
call RETARDO_0xms
call RETARDO_0xms 



djnz Largo_data,Lazo_TX 

;mov r0,#LRC1
;mov sbuf,@r0
;call RETARDO_05ms
;call RETARDO_05ms 
;mov sbuf,ValorLRC 
;
mov Recive,#00h ; Habilita ecibe comunicacion serial

pop acc
mov r0,acc
pop PSW
pop acc
ret

INI_VAR_READ:
push acc
push PSW

mov Direccion_actual,#START_SEN
mov r0,#START_SEN
mov Itera,#00H
mov Leyendo,#00h
mov Pagando,#00H
mov Largo_data,#00h
mov Paquete_full,#00h
mov Byte_actual,#00h
mov Error_card,#00H ;Sin Error

clr IE0 ;borro el flag de int0
mov a,Flag_lectura_tarjeta 
jnz No_Lea_Card
	setb IE.0; Habillito la lectura de tarjeta
No_Lea_card:
 
pop PSW
pop acc
ret

VERIFICAR_CADENA:
push acc
push PSW
mov a,r0
push acc

       mov r0,#START_SEN
       mov a,@r0
       cjne a,#0BH,ERROROINV
          mov r0,#END_SEN
          mov a,@r0
          cjne a,#01FH,ERROROINV
            mov VERI,#0AH
            jmp ERROR
ERROROINV:
		mov r0,#LRC1
		mov a,@r0
		cjne a,#0DH,PRUEBA1
		   jmp TIPO2
PRUEBA1:
					cjne a,#01AH,PRUEBA2
					 jmp TIPO1
PRUEBA2:					 
						cjne a,#06H,PRUEBA3
							jmp TIPO3
							
PRUEBA3:						cjne a,#03H,PRUEBA4						
		                       jmp TIPO4
PRUEBA4:
										jmp TIPO5
												
TIPO1:		
call F_PERMUTAR
jmp TIPO11

TIPO2:		
call F_PERMUTAR
jmp TIPO22

TIPO3:
call F_PERMUTAR
jmp TIPO33

TIPO4:
call F_PERMUTAR
jmp TIPO44

TIPO5:
call F_PERMUTAR
call Rotar_CADENA		
TIPO44:
call Rotar_CADENA
TIPO33:
call Rotar_CADENA
TIPO22:
call Rotar_CADENA		
TIPO11:
call Girar_CADENA
call ACOMODAR_CADENA
mov VERI,#0BH
jmp ERROR

;     	jmp ERROR
ERROR:

    call LRC
    mov r0,#LRC1
    mov a,@r0
    anl a,#0FH
    mov @r0,a
    mov a,ValorLRC
    xrl a,@r0
    jz FIN_VERI
ERROR_CAD:
		mov Veri,#0CH

FIN_VERI:
pop acc
mov r0,acc
pop PSW
pop acc
ret

VERIFICAR_CADENA_FINAL:
push acc
push PSW
mov a,r0
push acc

mov r0,#START_SEN
mov a,@r0
xrl a,#03BH
jnz Error_final

mov r0,#START_SEN+1
mov Desplazamiento,#00H

Mirar_cadena:
	mov a,@r0
	xrl a,#03FH
	jz ERROR_FINAL
	inc r0
	inc Desplazamiento
	mov a,Desplazamiento
	cjne a,#0DH,Mirar_cadena
   	jmp NO_ERROR_FINAL

ERROR_FINAL:
mov Error_card,#0FFH ;Error
NO_ERROR_FINAL:

pop acc
mov r0,acc
pop PSW
pop acc
ret


RETARDO_0xms:
push acc
push PSW
	push acc
	mov acc,r1
	push acc
	mov acc,r2
	push acc
	mov acc,r3
	push acc

	mov r1,#09H      
rut_ret_c:	
		mov r2,Contador_retardoh ;#02H ;02
	rut_ret1_c:	
		mov r3,Contador_retardol;#010H ;20
	   	rut_ret2_c:
			djnz r3,rut_ret2_c
		djnz r2,rut_ret1_c	
	djnz r1,rut_ret_c	

	pop acc
	mov r3,acc
	pop acc
	mov r2,acc
	pop acc
	mov r1,acc
	pop acc
pop PSW
pop acc	
ret


Hab_TTL:
push acc
push PSW

clr IE0
setb IE.0
mov Flag_lectura_Tarjeta,#00H

pop PSW
pop acc
ret

Des_TTL:
push acc
push PSW

clr IE.0
mov Flag_lectura_Tarjeta,#0FFH

pop PSW
pop acc
ret


INI_TIEMPO:
push acc
push PSW

mov Valor_cuenta_byte,#010H ;Se puede usar como Tamano maximo de Buffer

mov Valor_tibytel,#02H ; l:20 y h:1 son 215ms
mov Valor_tibyteh,#01H

mov Valor_tetl,#078H      ;40seg
mov Valor_teth,#01EH      ;40seg para darle tiempo a la FFFF

mov T_expire_total,#00H     ;no cuenta
mov Tiempo_expire_total,#00H


;mov Cuenta_byte,Valor_cuenta_byte
mov Largo_cadena,#00H
;mov T_byte,#0FFH
mov Tiempo_expire,#00H

mov Tiempo_inter_byte,#00H ;#0FFH   NO CUENTA
mov Tiempo_ibytel,Valor_tibytel
mov Tiempo_ibyteh,Valor_tibyteh


mov T_expire_total,#0FFH     ; cuenta
mov Tiempo_etl,Valor_tetl
mov Tiempo_eth,Valor_teth

mov Cuenta_byte,Valor_cuenta_byte

;mov Inicio,#BRG
mov Inicio,#SERIAL
mov Recive,#00H
 
pop PSW
pop acc
ret


INI_MEM:
push acc
push PSW
mov a,r0
push acc
mov a,r2
push acc

mov r2,#00h
mov r0,#START_SEN

Loop_mem:

	mov @r0,#00H
	inc r0
	inc r2
	mov a,r2
	cjne a,#032h,Loop_mem	

pop acc
mov r2,acc
pop acc
mov r0,acc
pop PSW                                                                                                                                                       
pop acc
ret

SUMA30:
push acc
push PSW
mov a,r0
push acc
mov a,r2
push acc


mov r2,#00h
mov r0,#START_SEN
;mov r0,Desplazamiento

Loop_suma:

	mov a,@r0
	anl a,#00FH
	add a,#030H
	mov @r0,a
	inc r0
	inc r2
	mov a,r2
	cjne a,#0Fh,Loop_suma	

pop acc
mov r2,acc
pop acc
mov r0,acc
pop PSW
pop acc
ret
;==========Buscar Cadena --------------
;Busca la cadena ;=0bh CUANDO LA ENCUENTRA DEVUELVE
;DESPLAZAMIENTO CON EL VALOR QUE CORRESPONDE AL PRINCIPIO

;BUSCAR_CADENA:
;push acc
;push PSW

;       mov r0,#START_SEN
;       mov Desplazamiento,#00H
 
; SIGUE_BUSCANDO:
;       mov a,@r0
;       xrl a,#0BH
;       jz IGUAL
;       	inc r0
;       	mov a,r0
;       	subb a,#START_SEN
;       	mov Desplazamiento,a
       	
;       	mov a,Largo_data
;       	xrl a,Desplazamiento
;       	jz NO_IGUAL
;       	jmp SIGUE_BUSCANDO

;NO_IGUAL:
	
	
;IGUAL:       

 
 
 
;pop PSW
;pop acc
;ret

;===================Funcion Permutar================
;Permuta los bits de la cedena leida y los guarda en la cadena2
;
F_PERMUTAR:
push acc
push PSW
mov a,r0
push acc

mov r0,#START_SEN
mov Contador_permutar,#00H

SIGUE_PERMUTAR:

mov a,@r0

mov c,acc.4
mov b.4,c
mov c,acc.0
mov b.3,c
mov c,acc.1
mov b.2,c
mov c,acc.2
mov b.1,c
mov c,acc.3
mov b.0,c

mov a,b

mov @r0,a
inc r0
inc Contador_permutar
mov a,Contador_permutar 		  
cjne a,#010H,SIGUE_PERMUTAR	



pop acc
mov r0,a
pop PSW
pop acc
ret


Rotar_CADENA:
push acc
push PSW
mov a,r0
push acc

mov r0,#START_SEN
mov Contador_RC,#00H
mov B,#00h


SIGUE_RC:

mov a,@r0

mov c,b.6         ;carry del byte anterior
mov  acc.5,c
                ;booro el reg b
             
mov b,#00h

mov c,acc.4    ;salvo el carry que va al proximo
mov acc.6,c

mov c,acc.0
mov b.4,c

mov c,acc.3
mov b.2,c

mov c,acc.2
mov b.1,c

mov c,acc.1
mov b.0,c

mov c,acc.5      ;paso el carry que venia de antes 
mov b.3,c

mov c,acc.6

mov a,b
mov b.6,c        ;salvo el carry proximo

mov @r0,a
inc r0
inc Contador_RC
mov a,Contador_RC 		  
cjne a,#010H,SIGUE_RC	



pop acc
mov r0,a
pop PSW
pop acc
ret

;--------------Girar Cadena
;Gira byte antes de terminar la inversion total de cadena
GIRAR_CADENA:
push acc
push PSW
mov a,r0
push acc


mov r0,#START_SEN
mov Contador_GC,#00H
mov b,#00h

SIGUE_GC:

mov a,@r0

mov c,acc.4
mov b.0,c
mov c,acc.0
mov b.1,c
mov c,acc.1
mov b.2,c
mov c,acc.2
mov b.3,c
mov c,acc.3
mov b.4,c

mov a,b

mov @r0,a
inc r0
inc Contador_GC
mov a,Contador_GC 		  
cjne a,#010H,SIGUE_GC	


pop acc
mov r0,a
pop PSW
pop acc
ret



ACOMODAR_CADENA:
push acc
push PSW
        
 		  mov r0,#LRC1
 		  mov r1,#START_SEN2
 		  mov Contador_acomodar_cadena,#00H

SIGUE_ACOMODA:
      		  
        mov a,@r0
 		  mov @r1,a
 		  dec r0
 		  inc r1
 		  inc Contador_acomodar_cadena
 		  mov a,Contador_acomodar_cadena 		  
 		  cjne a,#010H,SIGUE_ACOMODA	

 		  mov r0,#START_SEN2
 		  mov r1,#START_SEN
 		  mov Contador_acomodar_cadena,#00H

SIGUE_ACOMODA1:
      		  
        mov a,@r0
 		  mov @r1,a
 		  inc r0
 		  inc r1
 		  inc Contador_acomodar_cadena
 		  mov a,Contador_acomodar_cadena 		  
 		  cjne a,#010H,SIGUE_ACOMODA1	


pop PSW
pop acc
ret

INI_LED:
push acc
push PSW
 
clr Lled
setb DATAled  

mov VAR_INI_LED,#060h
lazo_ini_led:
cpl CLKled 
mov Contador_retardol,#010H ;low: 010H Hig:02H t= 0,5ms
mov Contador_retardoh,#02H  ;low: 010H Hig:02H t= 0,5ms
call  RETARDO_0xms
djnz VAR_INI_LED,lazo_ini_led
 
setb Lled

pop PSW
pop acc
ret

RGB_LED:
push acc
push PSW
 
clr Lled
clr DATAled  

mov VAR_INI_LED,#060h
lazo_RGB_led:
cpl CLKled 
mov Contador_retardol,#010H ;low: 010H Hig:02H t= 0,5ms
mov Contador_retardoh,#02H  ;low: 010H Hig:02H t= 0,5ms
call  RETARDO_0xms
djnz VAR_INI_LED,lazo_ini_led
 
setb Lled

pop PSW
pop acc
ret

CARGA_BRG_FUEGO:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,#049H
mov r0,#BRG+1
mov @r0,#24H
mov r0,#BRG+2
mov @r0,#096H
mov r0,#BRG+3
mov @r0,#0dbh
mov r0,#BRG+4
mov @r0,#06dH
mov r0,#BRG+5
mov @r0,#0fAH

pop acc
mov r0,acc
pop PSW
pop acc
ret

CARGA_VERDE_CIAN:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,#0A6H
mov r0,#BRG+1
mov @r0,#9AH
mov r0,#BRG+2
mov @r0,#069H
mov r0,#BRG+3
mov @r0,#0A6h
mov r0,#BRG+4
mov @r0,#09AH
mov r0,#BRG+5
mov @r0,#069H

pop acc
mov r0,acc
pop PSW
pop acc
ret
 

BUFFER_FILL_LED:
push acc
push PSW
mov a,r0
push acc

clr LLed

mov r0,#BRG

startrojo:
mov Contador_rojo,#08H

lazo_rojo:
mov a,@r0
clr c
rlc a
mov @r0,a

jc UNO
  setb DATAled
  jmp sigue_r
UNO:
clr DATAled
sigue_r:
cpl CLKled 
;mov Contador_retardol,#08H ;low: 08H Hig:02H t= 0,25ms
;mov Contador_retardoh,#01H ;;low: 08H Hig:02H t= 0,25ms   4/6/20018 cambio de 2 a 1
mov Contador_retardol,Contador_retardo_luzl
mov Contador_retardoh,Contador_retardo_luzh ;;low: 08H Hig:02H t= 0,25ms   4/6/20018 cambio de 2 a 1
call  RETARDO_0xms
cpl CLKled 
mov Contador_retardol,Contador_retardo_luzl
mov Contador_retardoh,Contador_retardo_luzh ;;low: 08H Hig:02H t= 0,25ms   4/6/20018 cambio de 2 a 1
;mov Contador_retardol,#08H ;low: 02H Hig:08H t= 0,25ms	 4/6/20018 cambio de 2 a 1
;mov Contador_retardoh,#01H ;low: 02H Hig:08H t= 0,25ms
call  RETARDO_0xms

djnz contador_rojo,lazo_rojo

inc r0

;cjne r0,#076H,startrojo  ;mira si ya cambio los 6 bytes
cjne r0,#BRG+6,startrojo  ;mira si ya cambio los 6 bytes

setb Lled 


pop acc
mov r0,a
pop PSW
pop acc
ret


Rotar_LEDI:
push acc
push PSW
mov a,r0
push acc

;mov WDRST,#01EH
;mov WDRST,#0E1H

mov r0,#BRG+5
mov Contador_RC,#00H
mov B,#00h

clr c

SIGUE_RR:

mov c,b.7

mov a,@r0
rlc a
mov @r0,a

mov b.7,c

dec r0

inc Contador_RC
mov a,Contador_RC 		  
cjne a,#06H,SIGUE_RR	

mov r0,#BRG+5
mov a,@r0
mov c,b.7
mov acc.0,c
mov @r0,a

pop acc
mov r0,a
pop PSW
pop acc
ret

Rotar_LED:
push acc
push PSW
mov a,r0
push acc

;mov WDRST,#01EH
;mov WDRST,#0E1H

mov r0,#BRG
mov Contador_RC,#00H
mov B,#00h

clr c

SIGUE_RL:

mov c,b.0

mov a,@r0
rrc a
mov @r0,a

mov b.0,c

inc r0

inc Contador_RC
mov a,Contador_RC 		  
cjne a,#06H,SIGUE_RL	

mov r0,#BRG
mov a,@r0
mov c,b.0
mov acc.7,c
mov @r0,a

pop acc
mov r0,a
pop PSW
pop acc
ret


GIRAR1:
push acc
push PSW

 mov contador_G,#00H
 mov contador_G1,#010H

GIRA_INI:

 call CP_CAD 
 mov a,contador_G
 jz fill
  	mov r0,Contador_G
ROTA_FILL: 
      ;---------------------------21/3/2018
	
	;	jnb CARD_PRESENT,FIN_GIRAR1  ;SI baja el card prersent va a leyendo tarjeta      ;21/3/2018
                                   ;corta lo que esta haciendo y envia tarjeta  21/3/2018
     ;-----------------------------

  	call Rotar_led
  	call Rotar_led
  	call Rotar_led
  	djnz r0,ROTA_FILL
   
fill: 
      
  call Buffer_fill_LED
  inc contador_G
djnz Contador_G1,GIRA_INI

FIN_GIRAR1:

pop PSW
pop acc
ret

GIRAR2:
push acc
push PSW

 mov contador_G,#00H
 mov contador_G1,#010H

GIRA_INI2:

 call CP_CAD 
 mov a,contador_G
 jz fill2
  	mov r0,Contador_G
ROTA_FILL2: 
      ;---------------------------21/3/2018
	
	;	jnb CARD_PRESENT,FIN_GIRAR1  ;SI baja el card prersent va a leyendo tarjeta      ;21/3/2018
                                   ;corta lo que esta haciendo y envia tarjeta  21/3/2018
     ;-----------------------------

  	call Rotar_ledI
  	call Rotar_ledI
  	call Rotar_ledI
  	djnz r0,ROTA_FILL2
   
fill2: 
      
  call Buffer_fill_LED
  inc contador_G
djnz Contador_G1,GIRA_INI2

FIN_GIRAR2:

pop PSW
pop acc
ret

GIRAR:
push acc
push PSW

 mov contador_G,#00H
 mov contador_G1,#010H

GIRA_INI1:

 call Carga_BRG_FUEGO
 mov a,contador_G
 jz fill1
  	mov r0,Contador_G
ROTA_FILL1: 
  	call Rotar_led
  	call Rotar_led
  	call Rotar_led
  	djnz r0,ROTA_FILL1
   
fill1: 
  call Buffer_fill_LED
  inc contador_G
djnz Contador_G1,GIRA_INI1

pop PSW
pop acc
ret

CP_CAD:
push acc
push PSW
mov a,r0
push acc
mov a,r1
push acc

mov r1,#SERIAL
inc r1
mov r0,#BRG

mov a,@r1
mov @r0,a
inc r1
inc r0

mov a,@r1
mov @r0,a
inc r1
inc r0

mov a,@r1
mov @r0,a
inc r1
inc r0

mov a,@r1
mov @r0,a
inc r1
inc r0

mov a,@r1
mov @r0,a
inc r1
inc r0

mov a,@r1
mov @r0,a
inc r1
inc r0

pop acc
mov r1,a
pop acc
mov r0,a
pop PSW
pop acc
ret 

CHAIN_CHK:
push acc
push PSW
mov a,r0
push acc

mov r0,#SERIAL
mov VALOR_CHAIN_CHK,@r0

pop acc
mov r0,acc
pop PSW
pop acc
ret

F_COIN:
push acc
push PSW

clr COIN

mov Contador_retardol,Contador_retardo_coin_l ;low: 0FEH Hig:025H t= 38ms
mov Contador_retardoh,Contador_retardo_coin_h ;low: 0FEH Hig:025H t= 38ms

call  RETARDO_xxxms

setb COIN

pop PSW
pop acc
ret

;-------------------Retardo xxxms===========================
RETARDO_xxxms:
push acc
push PSW

RETA_155:
		mov a,Contador_retardol
		dec a
		mov Contador_retardol,a
		jnz RETA_155
	
			mov Contador_retardol,#0FFH
			mov a,Contador_retardoh
	      dec a
	      mov Contador_retardoh,a
	      jnz RETA_155
	
pop PSW
pop acc
ret
;==============================================
F_TKE:
push acc
push PSW

cpl Pulso_tkout
	mov Contador_retardol,Contador_retardo_pago_l ;low: 0FEH Hig:025H t= 38ms
	mov Contador_retardoh,Contador_retardo_pago_h ;low: 0FEH Hig:025H t= 38ms
	call  RETARDO_xxxms
 cpl Pulso_tkout
	mov Contador_retardol,Contador_retardo_pago_l ;low: 0FEH Hig:025H t= 38ms
	mov Contador_retardoh,Contador_retardo_pago_h ;low: 0FEH Hig:025H t= 38ms
	call  RETARDO_xxxms

pop PSW
pop acc
ret


Tiempo:
push PSW
push acc
mov acc,r0
push acc
mov acc,r1
push acc

		mov r0,#01H
sal0: mov r1,#0FFH
sal1:	djnz r1,sal1
		djnz r0,sal0


pop acc
mov r1,acc
pop acc
mov r0,acc
pop acc
pop PSW
Ret

INI_PAGO:
push acc
push PSW

clr ctrl_b_out
setb ctrl_a_out
;clr out_inh
setb out_inh

clr ctrl_b_in
clr ctrl_a_in
;clr in_inh 
setb in_inh 

;===================TKE
mov Habilita_pago_TKE,#00H
mov Pago_activo,#00h
;--------------------
;=================TKF
mov Acumulador_pago,#00h
mov Habilita_pago_TKF,#00H
mov Pagando,#00H
;-------------------
;=================AUTO
mov Habilita_pago_AUTO,#00H


pop PSW
pop acc
ret

Seteo_tiempo:
push acc
push PSW
mov a,r0
push acc

mov r0,#serial+1
mov a,@r0
jz COIN_NORMAL
anl a,#0FH
jz COIN_NORMAL
mov a,@r0
anl a,#0FH
xrl a,#01H
jz COIN_LARGO
mov a,@r0
anl a,#0FH
xrl a,#02H
jz COIN_CORTO

COIN_NORMAL:
	mov Contador_retardo_coin_l,#0FEH ;low: 0FEH Hig:070H t= 115ms
	mov Contador_retardo_coin_h,#070H ;low: 0FEH Hig:070H t= 115ms
   jmp SETEO_PAGO
   
COIN_LARGO:
	mov Contador_retardo_coin_l,#0FEH ;low: 0FEH Hig:0A0H t= 150ms
	mov Contador_retardo_coin_h,#0A0H ;low: 0FEH Hig:0A0H t= 150ms
   jmp SETEO_PAGO

COIN_CORTO:
	mov Contador_retardo_coin_l,#07FH ;low: 0FEH Hig:030H t= 10ms
	mov Contador_retardo_coin_h,#0CH ;low: 07FH Hig:00cH t= 10ms
   jmp SETEO_PAGO

SETEO_PAGO:
mov r0,#serial+1
mov a,@r0
jz PAGO_NORMAL
anl a,#0F0H
jz PAGO_NORMAL
mov a,@r0
anl a,#0F0H
xrl a,#010H
jz PAGO_LARGO
mov a,@r0
anl a,#0F0H
xrl a,#020H
jz PAGO_CORTO

PAGO_NORMAL:
	mov Contador_retardo_pago_l,#0FEH ;low: 0FEH Hig:025H t= 38ms
	mov Contador_retardo_pago_h,#070H ;low: 0FEH Hig:025H t= 38ms
	jmp fin_set
	
PAGO_LARGO:
	mov Contador_retardo_pago_l,#0FEH ;low: 0FEH Hig:025H t= 38ms
	mov Contador_retardo_pago_h,#0E0H ;low: 0FEH Hig:025H t= 38ms
   jmp fin_set

PAGO_CORTO:
	mov Contador_retardo_pago_l,#07FH ;low: 0FEH Hig:025H t= 38ms
	mov Contador_retardo_pago_h,#012H ;low: 0FEH Hig:025H t= 38ms
	jmp fin_set
	
FIN_SETEO:


fin_set:
pop acc
mov r0,a
pop PSW
pop acc
ret


SET_PAGO:
push acc
push PSW
mov a,r0 
push acc

mov r0,#serial+1
mov a,@r0
xrl a,#01H
jnz PAGO_TKE_DIS

PAGO_TKE_EN:
mov Habilita_pago_TKE,#0FFH
jmp fin_set_pago_TKE 
PAGO_TKE_DIS:
mov Habilita_pago_TKE,#00H

fin_set_pago_TKE: 
mov r0,#serial+1
mov a,@r0
anl a,#0F0H
xrl a,#010H
jnz PAGO_TKF_DIS

PAGO_TKF_EN:
mov Habilita_pago_TKF,#0FFH
jmp fin_set_pago_TKF 
PAGO_TKF_DIS:
mov Habilita_pago_TKF,#00H

fin_set_pago_TKF: 
;--------------
mov r0,#serial+1
mov a,@r0
xrl a,#02H
jnz PAGO_AUTO_DIS

PAGO_AUTO_EN:
mov Habilita_pago_AUTO,#0FFH
jmp fin_set_pago_AUTO 
PAGO_AUTO_DIS:
mov Habilita_pago_AUTO,#00H

fin_set_pago_AUTO: 
;---------------

mov r0,#serial+2
mov Pago_opcion,@r0
mov a,Pago_opcion
anl a,#0FH
mov Pago_opcion,acc

             
xrl a,#00H
jz S_D_12_A
   mov a,Pago_opcion
	xrl a,#01H
	jz S_D_12_B
  		mov a,Pago_opcion
		xrl a,#02H
		jz S_D_5_A
	  		mov a,Pago_opcion
			xrl a,#03H
			jz S_D_5_B 
	  			mov a,Pago_opcion
				xrl a,#04H
				jz S_H_12_A
		  			mov a,Pago_opcion
					xrl a,#05H
					jz S_H_12_B
			  			mov a,Pago_opcion
						xrl a,#06H
						jz S_H_5_A
				  			mov a,Pago_opcion
							xrl a,#07H
							jz S_H_5_B

S_D_12_A:
clr ctrl_b_out
clr ctrl_a_out
clr pulso_tkout
setb out_inh
jmp Entrada_chk

S_D_12_B:
clr ctrl_b_out
clr ctrl_a_out
setb pulso_tkout
setb out_inh
jmp Entrada_chk

S_D_5_A:
clr ctrl_b_out
setb ctrl_a_out
clr pulso_tkout
setb out_inh
jmp Entrada_chk

S_D_5_B:
clr ctrl_b_out
setb ctrl_a_out
setb pulso_tkout
setb out_inh
jmp Entrada_chk

S_H_12_A:
clr ctrl_b_out
clr ctrl_a_out
clr pulso_tkout
clr out_inh
jmp Entrada_chk

S_H_12_B:
clr ctrl_b_out
clr ctrl_a_out
setb pulso_tkout
clr out_inh
jmp Entrada_chk
 
S_H_5_A:
clr ctrl_b_out
setb ctrl_a_out
clr pulso_tkout
clr out_inh
jmp Entrada_chk

S_H_5_B:
clr ctrl_b_out
setb ctrl_a_out
setb pulso_tkout
clr out_inh
jmp Entrada_chk

Entrada_chk:
mov r0,#serial+2
mov Pago_opcion,@r0
mov a,Pago_opcion
anl a,#0F0H
mov Pago_opcion,acc

xrl a,#00H
jz E_D_TKE_A
   mov a,Pago_opcion
	xrl a,#010H
	jz E_D_TKE_B
  		mov a,Pago_opcion
		xrl a,#020H
		jz E_H_TKE_A
	  		mov a,Pago_opcion
			xrl a,#030H
			jz E_H_TKE_B 
	  			mov a,Pago_opcion
				xrl a,#040H
				jz E_H_TKF_A
		  			mov a,Pago_opcion
					xrl a,#050H
					jz E_H_TKF_B
			  			mov a,Pago_opcion
						xrl a,#060H
						jz E_H_TKF_A
				  			mov a,Pago_opcion
							xrl a,#070H
							jz E_H_TKF_B


E_D_TKE_A:
clr ctrl_b_in
setb ctrl_a_in
setb in_inh
mov Pago_activo,#0FFh
jmp FIN_SET_PAGO 

E_D_TKE_B:
clr ctrl_b_in
clr ctrl_a_in
setb in_inh
mov Pago_activo,#00h
jmp FIN_SET_PAGO 

E_H_TKE_A:
clr ctrl_b_in
setb ctrl_a_in
clr in_inh
mov Pago_activo,#0FFh
jmp FIN_SET_PAGO
 
E_H_TKE_B:
clr ctrl_b_in
clr ctrl_a_in
clr in_inh
mov Pago_activo,#00h
jmp FIN_SET_PAGO 

E_D_TKF_A:
clr IE.2   ;deshabilitar la int1

jmp FIN_SET_PAGO 

E_D_TKF_B:
clr IE.2   ;deshabilitar la int1

jmp FIN_SET_PAGO 

E_H_TKF_A:
clr ctrl_b_in
clr ctrl_a_in
clr in_inh
setb IE.2   ;habilitar la int1
jmp FIN_SET_PAGO 

E_H_TKF_B:
clr ctrl_b_in
clr ctrl_a_in
clr in_inh
setb IE.2   ;habilitar la int1
jmp FIN_SET_PAGO 



fin_set_pago:
pop acc
mov r0,a
pop PSW
pop acc
ret 

Tiempox4:
call Tiempo
call Tiempo
call Tiempo
call Tiempo
ret

MUTE_HAB:
clr p2.7
ret

MUTE_DES:
setb p2.7
ret


Tiempo_GIRO:
;--------------------------------------
;Velocidad de tiempo de giro
;Se pasa parametro 0x31,Tiempol,TiempoH
;Por defecto se va a pasar Hig:0x01 y LOW:0x08
;---------------------------------------
push acc
push PSW
mov a,r0
push acc

mov r0,#serial+1
mov a,@r0
mov Contador_retardo_luzl,a ;low: 08H Hig:02H t= 0,125ms
mov r0,#serial+2
mov a,@r0
mov Contador_retardo_luzh,a ;low: 08H Hig:02H t= 0,125ms   4/6/20018 cambio de 2 a 1

pop acc
mov r0,a
pop PSW
pop acc
ret


CARGA_AMARILLO:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,#0DBH
mov r0,#BRG+1
mov @r0,#06DH
mov r0,#BRG+2
mov @r0,#0B6H
mov r0,#BRG+3
mov @r0,#0DBh
mov r0,#BRG+4
mov @r0,#06DH
mov r0,#BRG+5
mov @r0,#0B7H

pop acc
mov r0,acc
pop PSW
pop acc
ret

CARGA_NEGRO:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,#00H
mov r0,#BRG+1
mov @r0,#00H
mov r0,#BRG+2
mov @r0,#00H
mov r0,#BRG+3
mov @r0,#00h
mov r0,#BRG+4
mov @r0,#00H
mov r0,#BRG+5
mov @r0,#00H

pop acc
mov r0,acc
pop PSW
pop acc
ret

GIRAR_Color:
push acc
push PSW

 mov contador_G,#00H
 mov contador_G1,#010H

GIRA_INI1c:

 call Carga_AMARILLO
 mov a,contador_G
 jz fill1c
  	mov r0,Contador_G
ROTA_FILL1c: 
  	call Rotar_led
  	call Rotar_led
  	call Rotar_led
  	djnz r0,ROTA_FILL1c
   
fill1c: 
  call Buffer_fill_LED
  inc contador_G
djnz Contador_G1,GIRA_INI1c

pop PSW
pop acc
ret

INI_CMD:
push PSW
push acc
 	mov Transmision_OK,#00H
 	mov sbuf,#042H ; envio B  para indicar inicio
cmd_TX:
	 	mov a,Transmision_OK
 		jz cmd_TX
		mov Transmision_OK,#00H
pop acc
pop PSW
ret

;=========Funcion de carga de luz de pago en variables

LED_PAGO:
push acc
push PSW
mov a,r0
push acc

mov r0,#serial+1
mov LED1,@r0
mov r0,#serial+2
mov LED2,@r0
mov r0,#serial+3
mov LED3,@r0
mov r0,#serial+4
mov LED4,@r0
mov r0,#serial+5
mov LED5,@r0
mov r0,#serial+6
mov LED6,@r0

pop acc
mov r0,a
pop PSW
pop acc
ret

LED_PAGO2:
push acc
push PSW
mov a,r0
push acc

mov r0,#serial+1
mov LED7,@r0
mov r0,#serial+2
mov LED8,@r0
mov r0,#serial+3
mov LED9,@r0
mov r0,#serial+4
mov LED10,@r0
mov r0,#serial+5
mov LED11,@r0
mov r0,#serial+6
mov LED12,@r0

pop acc
mov r0,a
pop PSW
pop acc
ret

;========

Carga_luz_pago_mem:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,LED1
mov r0,#BRG+1
mov @r0,LED2
mov r0,#BRG+2
mov @r0,LED3
mov r0,#BRG+3
mov @r0,LED4
mov r0,#BRG+4
mov @r0,LED5
mov r0,#BRG+5
mov @r0,LED6

pop acc
mov r0,acc
pop PSW
pop acc
ret

Carga_luz_pago_mem2:
push acc
push PSW
mov a,r0
push acc

mov r0,#BRG
mov @r0,LED7
mov r0,#BRG+1
mov @r0,LED8
mov r0,#BRG+2
mov @r0,LED9
mov r0,#BRG+3
mov @r0,LED10
mov r0,#BRG+4
mov @r0,LED11
mov r0,#BRG+5
mov @r0,LED12


pop acc
mov r0,acc
pop PSW
pop acc
ret



TIMER2:
push acc
push PSW

mov AUXR,#08H; arrancar el WDT

mov WDRST,#01EH
mov WDRST,#0E1H
mov TL2,#0BFh	
mov TH2,#0E0h	
;mov TL2,#07Fh	
;mov TH2,#0FFh	

 ; clr TF2
 ; clr TR2
  
pop PSW
pop acc
reti

nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop

end                                           
