global YUYV_to_RGBA

mascara_acomodar_en_primeros_64: ; Va a estar como VYUY
	dq 0xFFFFFFFFFFFFFFFF
	dq 0xFFFFFFFF00020406 
 

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
    mov rbp, rsp
    mov r8w, edx
    imul r8w, ecx 
    ; En r8w tengo la cantidad total de píxeles. 
    xor r9w, r9w 
    ; Uso r9w para iterar sobre la imagen
    ; Voy a iterar de a dos píxeles yuyv, haciendo que itere de a 4 píxeles rgba
    ciclo:
        cmp r9w, r8w
        je epilogo
        ; Uso edx para levantar el primer YUYV y ecx para levantar el segundo
        mov edx, [rdi] ; En edx tengo el primer YUYV
        mov ecx, [rdi + 4] ; En edx tengo el segundo YUYV
        ; ahora los muevo a un registro xmm
        ; primero muevo edx a xmm0, le hago un pshufb para moverlo a los 64 bits mas altos
        ; limpio los xmm's
        pxor xmm0
        pxor xmm1
        movdqa xmm0, edx
        pshufb xmm0, [mascara_acomodar_en_primeros_64]
        movdqa xmm1, ecx
        por xmm0, xmm1 
        ; En xmm0 tengo dos yuyv's
        ; Ahora muevo xmm0 para que me queden acomodados los datos
        ; Paso de tener dos YUYV'S a tener Y1 V U, Y2 V U, Y3 V U e Y4 V U
        jmp ciclo
    
    epilogo:
        ;epilogo
        pop rbp
        ret