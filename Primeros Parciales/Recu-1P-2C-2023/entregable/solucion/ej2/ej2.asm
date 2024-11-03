section .rodata
align 16 ; En los xmm's los datos están como ARGB
mascara_aislar_b:
    dq 0xFFFFFF04FFFFFF00
	dq 0xFFFFFF0CFFFFFF08
align 16
mascara_aislar_r:
    dq 0xFFFFFF06FFFFFF02
	dq 0xFFFFFF0EFFFFFF0A
align 16
mascara_aislar_g:
    dq 0xFFFFFF05FFFFFF01
	dq 0xFFFFFF0DFFFFFF09
align 16
mascara_mover_r:
    dq 0xFF04FFFFFF00FFFF
	dq 0xFF0CFFFFFF08FFFF
align 16
mascara_mover_g:
    dq 0xFFFF04FFFFFF00FF
	dq 0xFFFF0CFFFFFF08FF
; El azul no hace falta moverlo :P
align 16
mascara_todos_unos:
    dq 0xFFFFFFFFFFFFFFFF
	dq 0xFFFFFFFFFFFFFFFF
align 16
mascara_255_en_a:
    dq 0xFF000000FF000000
	dq 0xFF000000FF000000
global combinarImagenes_asm

;########### SECCION DE TEXTO (PROGRAMA)
section .text

; Recibo en rdi src1
; Recibo en rsi src2
; Recibo en rdx dst
; Recibo en ecx width
; Recibo en r8d height
combinarImagenes_asm:
    ;prologo
    push rbp
    mov rbp, rsp ; Pila alíneada a 16 bytes
    imul ecx, r8d ; En ecx esta la cantidad de pixeles totales
    ; Usamos r8 para iterar sobre la imagen
    xor r8, r8
    ciclo:
        cmp r8, rcx
        je epilogo
        ; Movemos src1 y src2 a xmm's
        movdqu xmm0, [rdi]
        movdqu xmm1, [rsi]
        ; Cuando las levanto el los xmm's pasan de estar en memoria BGRA a estar ARGB
        ; Voy a calcular B, G y R por separado en distintos xmm's y despúes los combino
        ; Primero calculo B
        ; Uso xmm2 y xmm3 para calcular B. En xmm2 van a estar solamente los B de A en las partes bajas y en xmm3 van a estar solamente los R de b en la parte baja
        ; Copio a a xmm2 y b a xmm3
        movaps xmm2, xmm0
        movaps xmm3, xmm1
        pshufb xmm2, [mascara_aislar_b]
        pshufb xmm3, [mascara_aislar_r]
        paddd xmm2, xmm3 
        ; En xmm2 tenemos los 4 datos del azul
        ; En xmm2 tenemos el B del resultado
        ; Calculo R. Hay que Aislar B de B y aislar R de A
        ; Muevo BB a xmm3 y RA a xmm4
        movaps xmm3, xmm1 ; Copio B a xmm3
        movaps xmm4, xmm0 ; Copio A a xmm4
        pshufb xmm3, [mascara_aislar_b]
        pshufb xmm4, [mascara_aislar_r]
        psubd xmm3, xmm4
        ; Ahora lo acomodo para que quede a donde tiene que estar el rojo en la respuesta
        pshufb xmm3, [mascara_mover_r]
        ; En xmm3 tenemos los 4 datos del rojo
        ; Ahora calculamos el verde
        ; Me hago dos xmm's con solo el verde
        movaps xmm4, xmm0
        movaps xmm5, xmm1
        pshufb xmm4, [mascara_aislar_g]
        pshufb xmm5, [mascara_aislar_g]
        movaps xmm6, xmm4 ; Copio xmm4 porque se va a pisar
        movaps xmm7, xmm4 ; Copio xmm4 de nuevo porque lo voy a necesitar
        movaps xmm8, xmm5 ; Copio xmm5 porque lo voy a necesitar
        PCMPGTD xmm4, xmm5 ; Si xmm4 es más grande se ponen unos ahí
        ; Usamos xmm4 como máscara para aislar los que hay que hacer A - B
        pand xmm6, xmm4
        pand xmm8, xmm4
        ; En xmm4 y xmm6 tengo los que hay que hacerles A - B. Asi que lo hago
        psubd xmm6, xmm8 ; En xmm6 tengo a todos los que les calcule A - B
        ; Ahora invierto la mascara 
        movaps xmm9, [mascara_todos_unos] ; En xmm9 tengo una mascara con solo unos
        pxor xmm4, xmm9 ; Ahora en xmm4 quedan unos a donde hay que calcular el promedio
        pand xmm5, xmm4
        pand xmm7, xmm4
        ; En xmm5 están los A a los que hay que calcularles el promedio
        ; En xmm7 están los B a los que hay que calcularles el promedio
        pavgb xmm5, xmm7
        ; En xmm5 están a los que les calculamos el promedio
        ; Junto xmm5 con xmm6
        por xmm5, xmm6
        pshufb xmm5, [mascara_mover_g]
        ; Cargo en xmm4 el 255 en A
        movdqa xmm4, [mascara_255_en_a]
        ; Empiezo a juntar los resultados en xmm2 con ors
        por xmm2, xmm3
        por xmm2, xmm4
        por xmm2, xmm5
        ; En xmm2 esta la respuesta
        movdqa [rdx], xmm2
        add r8, 4
        add rdi, 16
        add rsi, 16
        add rdx, 16
        jmp ciclo
    epilogo:
        ;epilogo
        pop rbp
        ret