	ORG 0
	LJMP PIPO				;Programa ppal
	ORG 3
	LJMP INTE				;Interrupcion 0
;	ORG 013H
;	LJMP INTE1				;Interrupcion 1
	ORG 0Bh
	LJMP TIMER0		  		;Timer 0
;	ORG 1BH
;	LJMP CONTADOR			;Contador 1
	ORG 023H
	LJMP SERIE           ;UART

;------------------VARIABLES BIT A BIT 

ORG 32
	
   CARD_DATA bit p1.7
   CARD_PRESENT bit p1.5
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
   Contador_retardo8l equ 82
   Contador_retardo8h equ 83
	Flag_lectura_tarjeta equ 84   
	
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
	SETB IE.0									;HAB INT0
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


;iniciializaciones
mov Recive,#00H;#0FFh ;No recibe comunicacion serial
mov Transmision_OK,#00H
call INI_VAR_READ ;Inicializa las variables de lectura
Call INI_TIEMPO

;call CP_CAD

;==============================
call Girar
call INI_MEM
call INI_LED
call RGB_LED

LOOP:

 jnb SW1,SW1_PRES
 jnb SW2,SW2_PRES

;		mov acc,Cuenta_byte
;		jz	LAZ1
		   mov a,Tiempo_expire   ;expiro tiempo interbyte
		 	jnz LAZ2 
;		 	   mov a,Tiempo_expire_total    ;paso el tiempo de rta maximo 600mseg
;		 	   jnz LAZ3
		 	    mov a,Leyendo
		 	    jnz READING    ;mira si mientras estaban laas luces entro una tarjeta
	jb CARD_PRESENT,LOOP  ;SI baja el card prersent va a leyendo tarjeta
		jmp READING	 

jmp LOOP


LAZ2: ;Cuando se supera el tiempo interbye analiza lo que llega y actua
clr TR0 ; Paro el timer0
jmp CHK_ENTRADA

SW2_PRES:
	call carga_BRG_FUEGO
   call Buffer_fill_LED
 	mov Transmision_OK,#00H
 	mov sbuf,#0B1H ;Boton 1
SW_TX:
	 	mov a,Transmision_OK
 		jz SW_TX
		mov Transmision_OK,#00H
  	jmp LOOP

SW1_PRES:
	call Hab_TTL
   call Carga_VERDE_CIAN
   call Buffer_fill_LED
 	mov Transmision_OK,#00H
 	mov sbuf,#0B2H   ;Boton 2  
   jmp SW_TX


READING:	
	 
	 jnb CARD_PRESENT,READING
;-----------
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
      call Enviar  ;Enviar por puerto serie

call INI_MEM  ; inicializa la memoria de trabajo
call INI_VAR_READ ;inicializa las varibles de lectura
call Girar
jmp LOOP

FIN_LOOP:     	
call INI_MEM  ; inicializa la memoria de trabajo
call INI_VAR_READ ;inicializa las varibles de lectura
jmp LOOP

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
	
	call INI_TIEMPO	
	jmp LOOP

ES_COLOR:
		call CP_CAD
		call Buffer_fill_LED
      jmp ES_SALIDA
ES_COIN:
		call F_COIN
      call GIRAR1
      jmp ES_SALIDA
ES_GIRO:
      call GIRAR1
      jmp ES_SALIDA
ES_Hab_TTL:
		call Hab_TTL
      jmp ES_SALIDA
ES_Des_TTL:
		call Des_TTL
      jmp ES_SALIDA
ES_SALIDA:
		call INI_TIEMPO
		mov sbuf,#055H
ES_CTRL:
	 	mov a,Transmision_OK
 		jz ES_CTRL
  		mov Transmision_OK,#00H
  		jmp LOOP		

;------------------------------INTE
INTE:
push acc
push PSW
mov a,r0
push acc
   
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


;------------------------------INTE1
INTE1:
push acc
push PSW





FIN_INTE1:
pop PSW
pop acc
reti

;---------------------------SERIE
SERIE:
push acc
push PSW
mov acc,r1
push acc

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
call RETARDO_05ms
call RETARDO_05ms 



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
mov Largo_data,#00h
mov Paquete_full,#00h
mov Byte_actual,#00h

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

RETARDO_05ms:
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
		mov r2,#02H ;02
	rut_ret1_c:	
		mov r3,#010H ;20
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

RETARDO_025ms:
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
rut_ret_c1:	
		mov r2,#02H ;02
	rut_ret1_c1:	
		mov r3,#08H ;20
	   	rut_ret2_c1:
			djnz r3,rut_ret2_c1
		djnz r2,rut_ret1_c1	
	djnz r1,rut_ret_c1	

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
clr IE0
setb IE.0
mov Flag_lectura_Tarjeta,#00H
ret

Des_TTL:
clr IE.0
mov Flag_lectura_Tarjeta,#0FFH
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
call  RETARDO_05ms
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
call  RETARDO_05ms
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
call  RETARDO_025ms
cpl CLKled 
call  RETARDO_025ms

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


Rotar_LED:
push acc
push PSW
mov a,r0
push acc

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
  	call Rotar_led
  	call Rotar_led
  	call Rotar_led
  	djnz r0,ROTA_FILL
   
fill: 
  call Buffer_fill_LED
  inc contador_G
djnz Contador_G1,GIRA_INI

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
call  RETARDO_155ms
setb COIN

pop PSW
pop acc
ret

;-------------------Retardo 155ms
RETARDO_155ms:
push acc
push PSW
	mov Contador_retardo8l,#0FEH
	mov Contador_retardo8h,#070H

RETA_155:
		mov a,Contador_retardo8l
		dec a
		mov Contador_retardo8l,a
		jnz RETA_155
	
			mov Contador_retardo8l,#0FFH
			mov a,Contador_retardo8h
	      dec a
	      mov Contador_retardo8h,a
	      jnz RETA_155
	
pop PSW
pop acc
ret

Pago_act_LOW:
clr Pulso_tkout
ret

Pago_act_HI:
setb Pulso_tkout
ret



end                                           
