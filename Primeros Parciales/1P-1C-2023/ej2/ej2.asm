
section .data
; Estan en AGBR
align 16
mascara_azul:
	dq 0xFFFFFFFF0E0A0602
    dq 0xFFFFFFFFFFFFFFFF
mascara_verde:
align 16
	dq 0xFFFFFFFF0D090501
    dq 0xFFFFFFFFFFFFFFFF
align 16
mascara_rojo:
	dq 0xFFFFFFFF0C080400
    dq 0xFFFFFFFFFFFFFFFF
align 16
operando_rojo: times 4 dd 0.299
align 16
operando_verde: times 4 dd 0.587
align 16
operando_azul: times 4 dd 0.114
align 16
mascara_res: 
    dq 0xFFFFFFFF0C080400
    dq 0xFFFFFFFFFFFFFFFF
align 16
mascara_unos:
    dq 0xFFFFFFFFFFFFFFFF    
    dq 0xFFFFFFFFFFFFFFFF


;########### SECCION DE TEXTO (PROGRAMA)
section .text
;void miraQueCoincidencia_c( uint8_t *A[rdi], uint8_t *B[rsi], uint32_t N[rdx], 
                        ;    uint8_t *laCoincidencia[rcx] ){
global miraQueCoincidencia
miraQueCoincidencia:   
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    ; Hago rdx por rdx para que quede la cantidad total de píxeles
    imul rdx, rdx
    ; Uso a r8 como iterador
    xor r8, r8
    ciclo:
        cmp r8, rdx
        je epilogo
        movdqa xmm0, [rdi] ; En xmm0 estan los 4 datos del píxel A actual
        movdqa xmm1, [rsi] ; En xmm1 estan los 4 datos del píxel B actual
        ; Ahora comparamos los paquetes, si son iguales va a escribir 1 en xmm0, si son distintos va a escribir 0
        PCMPEQD xmm0, xmm1
        pand xmm1, xmm0 ; En xmm1 tengo todos a los que le tengo que hacer la escala de grises
        pxor xmm0, [mascara_unos] ; En xmm0 tengo todos los que no coinciden con 1's
        movaps xmm2, xmm1 ; Copio xmm1 a xmm2 para despues filtrar el rojo
        movaps xmm3, xmm1 ; Copio xmm3 a xmm1 para despues filtrar azul
        pshufb xmm2, [mascara_rojo] ; Tengo los datos del rojo 
        pshufb xmm3, [mascara_azul] ; Tengo los datos del azul
        pshufb xmm1, [mascara_verde] ; Tengo los datos del verde
        PMOVZXBD xmm1, xmm1
        PMOVZXBD xmm2, xmm2
        PMOVZXBD xmm3, xmm3
        ; Acomodo los datos de rojo verde y azul
        ; Convierto los datos a floats
        CVTDQ2PS xmm1, xmm1 ; Convierto los verdes a floats
        CVTDQ2PS xmm2, xmm2 ; Convierto los rojos a floats
        CVTDQ2PS xmm3, xmm3 ; Convierto los azules a floats
        mulps xmm1, [operando_verde]
        mulps xmm2, [operando_rojo]
        mulps xmm3, [operando_azul]
        addps xmm1, xmm2
        addps xmm1, xmm3
        CVTTPS2DQ xmm1, xmm1 ; Trunco 
        por xmm1, xmm0
        ; En xmm0 tengo el res, solo falta mandar todo a la parte alta
        pshufb xmm1, [mascara_res]
        movd r9d, xmm1
        mov dword [rcx], r9d ; Aca escribimos los datos
        ; Incremento los iteradores
        add rcx, 4
        add r8, 4
        add rdi, 16
        add rsi, 16
        jmp ciclo
    epilogo:
        ;epilogo
        pop rbp 
        ret
    

