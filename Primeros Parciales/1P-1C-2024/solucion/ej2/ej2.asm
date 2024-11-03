global YUYV_to_RGBA
; Los y1uy2v  van a estar en memoria como v_y2_u_y1
; y quiero que queden dentro del xmm como Y2VU, Y1VU
align 16
mascara_acomodar_yuyvs:
    dq 0xFF020301FF000301 ; Y2VU Y dp Y1VU en la parte baja
    dq 0xFF0A0B09FF080B09 ; Y2VU Y dp Y1VU en la parte baja
align 16
yuyv_127:
    dq 0x00007F7F00007F7F
    dq 0x00007F7F00007F7F 
align 16
mascara_vu: ; Esta mascara hace que queden solo los datos de u y v
    dq 0x0000FFFF0000FF7F
    dq 0x0000FFFF0000FFFF
align 16
mascara_todos_1s:
    dq 0xFFFFFFFFFFFFFFFF
    dq 0xFFFFFFFFFFFFFFFF
align 16
rgba_iguales: ; Los escribo en formato RGBA para que quede RGBA(127,255,0,255).
    dq 0x7FFF00FF7FFF00FF
    dq 0x7FFF00FF7FFF00FF
align 16
mascara_128: ; Pongo 128 en cada U y V de YUV
    dq 0x0000808000008080
    dq 0x0000808000008080

align 16
mascara_255_en_a:
    dq 0x000000FF000000FF
    dq 0x000000FF000000FF
align 16 
mascara_Y: ; Paso de tener YUV a solo tener Y
    dq 0xFFFFFFFF0E0A0602
    dq 0xFFFFFFFFFFFFFFFF
align 16
mascara_U: ; Paso de tener YUV a solo tener U
    dq 0xFFFFFFFF0D090501
    dq 0xFFFFFFFFFFFFFFFF
align 16
mascara_V: ; Paso de tener YUV a solo tener V
    dq 0xFFFFFFFF0C080400
    dq 0xFFFFFFFFFFFFFFFF
align 16
operando_rojo: times 4 dd 1.370705
align 16
operando_verde_1: times 4 dd 0.698001
align 16
operando_verde_2: times 4 dd 0.337633
align 16
operando_azul: times 4 dd 1.732446
align 16
mascara_acomodar_rojo: ; Quiero que quede rgba, entonces paso de la parte baja a la alta
    dq 0x04FFFFFF00FFFFFF
    dq 0x0CFFFFFF08FFFFFF 
align 16
mascara_acomodar_verde: ; Quiero que quede rgba
    dq 0xFF04FFFFFF00FFFF
    dq 0xFF0CFFFFFF08FFFF 
mascara_acomodar_azul: ; Quiero que quede rgba
    dq 0xFFFF04FFFFFF00FF
    dq 0xFFFF0CFFFFFF08FF 

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;void YUYV_to_RGBA( int8_t *X, uint8_t *Y, uint32_t width, uint32_t height);
; En rdi tengo el puntero a X
; En rsi tengo el puntero a Y
; En edx tengo el width 
; En ecx tengo el height
YUYV_to_RGBA:
    ;prologo
    push rbp
    mov rbp, rsp ; Pila alíneada a 16 bytes
    ; Muevo el ancho a r8 para usarlo para calcular la cantidad total de píxeles
    mov r8d, edx
    imul r8d, ecx
    ; En r8w tengo la cantidad total de píxeles. 
    xor r9, r9 
    ; Uso r9w para iterar sobre la imagen
    ; Voy a iterar de a dos píxeles yuyv, haciendo que itere de a 4 píxeles rgba
    ciclo:
        cmp r9, r8
        je epilogo
        ; Uso edx para levantar el primer YUYV y ecx para levantar el segundo
        mov edx, [rdi] ; En edx tengo el primer YUYV
        mov ecx, [rdi + 4] ; En ecx tengo el segundo YUYV
        ; ahora los muevo a un registro xmm
        ; primero muevo edx a xmm0, le hago un pshufd para moverlo a los 64 bits mas altos
        ; limpio los xmm's
        pxor xmm0, xmm0
        pxor xmm1, xmm1
        movd xmm0, edx
        movd xmm1, ecx
        pshufd xmm1, xmm1, 0b11001111 ; Los 1's son para que agarre la ultima posicion que tiene todos ceros igual    
        por xmm0, xmm1 
        ; En xmm0 tengo dos yuyv's
        ; Ahora muevo xmm0 para que me queden acomodados los datos
        ; Paso de tener dos YUYV'S a tener Y4 V U, Y3 V U, Y2 V U e Y1 V U
        pshufb xmm0, [mascara_acomodar_yuyvs]
        ; Ahora voy a hacer el chequeo de que u y v no sean 0x7F simultaneamente. 
        ; Voy a en un registro xmm ponerle esos dos valores y armar una mascara para limpiar de xmm0 los datos que no son U y V
        movdqa xmm2, [mascara_vu] ; Uso xmm2 para limpiar vu de los yuyvs
        movdqa xmm3, [yuyv_127] ; Cargo 127 en cada vu
        ; Copio los yuyvs a xmm1 al que le voy a aplicar la mascara
        movaps xmm1, xmm0
        pand xmm1, xmm2 ; En xmm1 solo quedaron los vu
        ; Como quiero que queden uno's en todos los 32 bits uso PCMPEQD en vez del de bytes, porque el de bytes va a dejar uno en 16 de los 32 bits
        PCMPEQD xmm1, xmm3
        ; En xmm1 hay uno's a donde tiene que colocar 127,255,0,255 y 0's a donde hay que hacer la conversión
        ; Uso una mascara de uno's para invertir xmm1 para ahí cargar los datos que hay que convertir
        movaps xmm2, xmm1 ; En xmm2 esta como quedo el resultado, ahora lo voy a invertir
        movdqa xmm3, [mascara_todos_1s] ; Pongo la mascara en xmm3
        pxor xmm2, xmm3 ; Ahora xmm2 tiene unos a donde hay que levantar los datos
        pand xmm2, xmm0 ; En xmm2 estan todos los datos a los que hay que aplicarles la transformacion
        ; En xmm1 hay que poner RGBA(127,255,0,255).
        movdqa xmm3, [rgba_iguales] ; Cargo en xmm3 RGBA(127,255,0,255)
        pand xmm1, xmm3 ; En xmm1 estan todos los que coinciden y ya terminado
        ; Cargo en xmm3 128 en las u y v 
        movdqa xmm3, [mascara_128]
        ; Hago U = in.u - 128; y V = in.v - 128;
        psubb xmm2, xmm3
        ; Pongo en un xmm todos los Y, en otro todos los V y en otro todos los U 
        ; Primero copio xmm0
        movaps xmm3, xmm2
        movaps xmm4, xmm2
        movaps xmm5, xmm2 
        ; Las mascaras mandan todos los bytes al principio para despúes usar pmovzxd para extender el signo
        pshufb xmm3, [mascara_Y]
        pshufb xmm4, [mascara_U]
        pshufb xmm5, [mascara_V]
        PMOVSXBD xmm3, xmm3
        PMOVSXBD xmm4, xmm4
        PMOVSXBD xmm5, xmm5
        ; Para convertir todos a float primero tengo que extenderles el signo
        ; Convierto a todos a float
        CVTDQ2PS xmm3, xmm3 
        CVTDQ2PS xmm4, xmm4
        CVTDQ2PS xmm5, xmm5
        ; Primero calculo el rojo con xmm3 y xmm5
        ; Me copio xmm3 a xmm6 y xmm5 a xmm7 porque lo voy a hacer pelota
        movaps xmm6, xmm3
        movaps xmm7, xmm5
        mulps xmm7, [operando_rojo]
        addps xmm7, xmm6
        cvtps2dq xmm7, xmm7 ; Convierto de float a entero. En xmm7 tengo el valor de los 4 rojos
        ; Ahora calculo el verde con los 3 xmm's
        ; Primero muevo los registros que voy a hacer pelota y necesito despues, el V no lo voy a volver a usar asi que lo hago pelota
        movaps xmm6, xmm3
        movaps xmm8, xmm4
        ; En xmm5 tengo v, en 6 y, en 7 u
        mulps xmm5, [operando_verde_1]
        mulps xmm8, [operando_verde_2]
        subps xmm6, xmm5
        subps xmm6, xmm8
        cvtps2dq xmm6, xmm6 ; Convierto en entero
        ; En xmm6 tengo el verde
        ; Ahora calculo el azul. No hace falta copiar los datos
        mulps xmm4, [operando_azul]
        addps xmm3, xmm4
        cvtps2dq xmm3, xmm3 ; Convierto en entero
        ; En xmm7 tengo el rojo, en xmm6 el verde y en xmm3 el azul
        ; Ahora muevo los datos a donde corresponden para que quede rgba dentro de cad uno y despues hago or's
        pshufb xmm7, [mascara_acomodar_rojo]
        pshufb xmm6, [mascara_acomodar_verde]
        pshufb xmm3, [mascara_acomodar_azul]
        movdqa xmm0, [mascara_255_en_a]
        ; Junto los datos en xmm0
        por xmm0, xmm7
        por xmm0, xmm6
        por xmm0, xmm3
        ; En xmm0 tengo el resultado de los que había que transformar. Lo junto con xmm1
        por xmm0, xmm1
        movdqa [rsi], xmm0
        add r9, 2
        add rsi, 16
        add rdi, 8
        jmp ciclo
    
    epilogo:
        ;epilogo
        pop rbp
        ret