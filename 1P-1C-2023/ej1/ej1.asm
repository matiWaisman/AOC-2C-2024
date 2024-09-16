global templosClasicos
global cuantosTemplosClasicos

extern malloc

TAM_STRUCT_TEMPLO equ           24
OFFSET_LARGO equ                0
OFFSET_NOMBRE equ               8
OFFSET_CORTO equ                16

; Me dejo anotado aca asi ya lo tengo a mano
;typedef struct {
;  uint8_t colum_largo; 1 Byte
;  char *nombre; 8 bytes
;  uint8_t colum_corto; 1 byte
;} templo;
; Cada templo tiene que estar alíneado a 8 bytes, por lo que lo que mide el total la estructura contando padding son:
; 1 byte para column_largo, 7 bytes de padding
; 8 bytes para el puntero a char
; 1 byte para column_corto y 7 bytes de padding
; Por lo que pasar de una estructura a la otra son 24 bytes

;########### SECCION DE TEXTO (PROGRAMA)
section .text
; Si largo = 2 corto + 1 sumamos uno 
cuantosTemplosClasicos: ; cuantosTemplosClasicos_c(templo *temploArr[rdi], size_t temploArr_len[rsi])
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    ; Uso eax como contador, lo limpio por las dudas
    xor eax, eax
    ; Voy a usar a r8 de iterador, así que primero lo limpio por las dudas
    xor r8, r8
    cicloContador:
        cmp r8, rsi
        je epilogoContador
        ; Limpio r9 y r10 para que no tengan los datos de la iteracion pasada
        xor r9, r9
        xor r10, r10

        mov r9b, byte [rdi + OFFSET_LARGO] ; cargo en r9b largo
        mov r10b, byte [rdi + OFFSET_CORTO] ; en r10b esta corto
        imul r10, 2
        inc r10
        ; en r10 tengo 2 corto + 1
        cmp r10, r9
        jne casiFin
        ; si estamos aca es porque son iguales por lo que hay que incrementar en uno eax
        inc eax
        casiFin:
            inc r8
            add rdi, TAM_STRUCT_TEMPLO ; incremento el puntero de rdi para que apunte a la siguiente posicion del array
            jmp cicloContador
    epilogoContador:    
        ;epilogo
        pop rbp
        ret

templosClasicos: ; templosClasicos(templo *temploArr[rdi], size_t temploArr_len[rsi]);
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    ; Primero hay que calcular la cantidad de templos clasicos para hacerle malloc, por lo que hay que llamar a la funcion
    ; Guardo en rdi el dato del puntero previo para no perderlo
    push rdi ; stack alíneado a 8 bytes
    sub rsp, 8 ; stack alíneado a 16 bytes
    call cuantosTemplosClasicos
    ; En eax tenemos la cantidad de templos clasicos, hay que moverlo a rdi
    mov rdi, rax
    ; Como cada dato mide 24 bytes multiplico por 24 rdi
    imul rdi, 24
    push rsi ; Guardo rsi en la pila porque malloc lo usa
    sub rsp, 8 ; Hago padding para alinear el stach
    call malloc
    ; en rax tenemos el puntero, voy a pasar el dato a otro registro y iterar con otro registro
    ; En r11 tengo el puntero que vamos a devolver al final, lo voy a usar para iterar sobre la estructura
    mov r11, rax
    add rsp, 8
    pop rsi
    ; restauramos el dato de rdi
    ; primero sacamos el padding 
    add rsp, 8
    pop rdi
    ; Guardo en la pila r12, r13 y r14 que voy a usar en el ciclo 
    push r12
    push r13
    push r14
    ; Esta alíneado a 16 porque antes estaba desalíneado por 8
    ; Voy a usar a r8 de iterador, así que primero lo limpio por las dudas
    xor r8, r8
    cicloTemplos:
        cmp r8, rsi
        je epilogoTemplos
        ; Limpio r9 y r10 para que no tengan los datos de la iteracion pasada
        xor r9, r9
        xor r10, r10
        mov r9b, byte [rdi + OFFSET_LARGO] ; cargo en r9b largo
        mov r10b, byte [rdi + OFFSET_CORTO] ; en r10b esta corto
        imul r10, 2
        inc r10 ; en r10 tengo 2 corto + 1
        cmp r10w, r9w
        jne casiFinTemplos
        ; si estamos aca es porque son iguales por lo que hay que guardar el dato actual
        ; usamos r12 para mover el dato de rdi a r11
        mov r12b, [rdi + OFFSET_LARGO]
        mov [r11 + OFFSET_LARGO], r12b
        ; Movi largo 
        ; usamos r13 para mover el nombre
        mov r13, [rdi + OFFSET_NOMBRE]
        mov [r11 + OFFSET_NOMBRE], r13
        ; Movi nombre
        ; Usamos r14 para mover el corto
        mov r14b, [rdi + OFFSET_CORTO]
        mov [r11 + OFFSET_CORTO], r14b
        ; Movi corto mas su padding
        add r11, TAM_STRUCT_TEMPLO
        casiFinTemplos:
            add rdi, TAM_STRUCT_TEMPLO
            inc r8
            jmp cicloTemplos
    epilogoTemplos:
        pop r14
        pop r13
        pop r12
        ;epilogo
        pop rbp 
        ret
