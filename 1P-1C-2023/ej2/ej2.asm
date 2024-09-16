
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text
;void miraQueCoincidencia_c( uint8_t *A[rdi], uint8_t *B[rsi], uint32_t N[rdx], 
                        ;    uint8_t *laCoincidencia[rcx] ){
global miraQueCoincidencia
miraQueCoincidencia:   
    ;prologo
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

    epilogo:
        ;epilogo
        pop rbp 
        ret
    

