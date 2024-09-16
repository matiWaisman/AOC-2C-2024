extern malloc
;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

global cesar_asm
global strLen

; char* cesar(char* source, uint32_t x)
; En rdi recibo source y en esi x
cesar_asm:
    ; Prologo
    push rbp
    mov rbp, rsp
    ; Guardar rdi en la pila para no perderlo
    push rdi
    sub rsp, 8 ; Le resto 8 a la pila para que este alíneada
    call strLen
    ; En eax tengo el largo del string, lo muevo a r9d
    mov r14d, eax ; En r14d tengo el largo del string
    mov edi, r14d ; Muevo el largo del string como parámetro a malloc
    inc rdi ; Aumento el valor de rdi para malloc para tener uno que sea el final
    call malloc ; En rax tengo el puntero al string a donde tengo que escribir
    add rsp, 8 ; Vuelvo a desalínear la pila total no hago mas llamadas a funciones
    pop rdi ; En rdi tengo el puntero a src
    mov r8, rax ; Guardar el puntero al nuevo buffer en r8
    xor ecx, ecx ; Limpiar ecx para usarlo de iterador
ciclo:
    cmp ecx, r14d
    je epilogoCesar
    movzx edx, byte [rdi] 
    sub edx, 65 ; Restar 65 para obtener el índice de la letra
    add edx, esi 
    ; Calcular el módulo 26
    mov eax, edx
    and edx, 0x1F 
    add edx, 65
    mov [r8], dl ; Almacenar el byte en el final
    inc r8 
    inc rdi 
    inc ecx 
    jmp ciclo
; Epílogo
epilogoCesar:
    mov byte [r8], 0  
    pop rbp 
    ret

; uint32_t strLen(char* a)
; en rdi recibo a
strLen:
    ; Prologo
    push rbp
    mov rbp, rsp
    xor eax, eax ; Limpiar eax
strLoop:
    cmp byte [rdi], 0
    je epilogo
    inc eax ; Incrementar el tamaño del string
    inc rdi ; Avanzar el puntero
    jmp strLoop
; Epílogo
epilogo:
    pop rbp
    ret
