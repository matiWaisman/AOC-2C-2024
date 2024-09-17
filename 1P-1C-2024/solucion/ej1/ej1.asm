section .data

TAM_STRUCT_OT equ 16 ; Cada struct ocupa 16 bytes, un byte para el table size, 7 de padding y 8 bytes del puntero
TAM_STRUCT_NODO_OT equ 16 ; Cada struct ocupa 16 bytes porque tiene dos punteros de 8 bytes
TAM_STRUCT_NODO_DL equ 24 ; El puntero a función ocupa 8 bytes, luego estan los 3 uints_8 uno al lado del otro, 5 bytes de offset y el puntero al siguiente
OFFSET_TABLE_SIZE equ 0
OFFSET_TABLE equ 8
OFFSET_PRIMITIVA equ 0
OFFSET_X equ 8
OFFSET_Y equ 9
OFFSET_Z equ 10
OFFSET_SIGUIENTE_DL equ 16

section .text

global inicializar_OT_asm
global calcular_z_asm
global ordenar_display_list_asm

extern malloc
extern free
extern calloc


;########### SECCION DE TEXTO (PROGRAMA)

; ordering_table_t* inicializar_OT(uint8_t table_size);
; En rdi tengo el table_size
inicializar_OT_asm:
    ;prologo
    push rbp
    mov rbp, rsp ;Pila alíneada a 16
    push rdi ; Pusheo el rdi porque lo voy a tener que sobreescribir para hacer el malloc
    ; Alíneo la pila
    sub rsp, 8
    ; Limpio rdi
    xor rdi, rdi
    add rdi, TAM_STRUCT_OT
    call malloc 
    ; En rax tengo el puntero a la estructura
    ; Saco el dato de la pila y restauro rdi
    add rsp, 8
    pop rdi
    mov [rax + OFFSET_TABLE_SIZE], dil
    ; Si table size es 0 el puntero va a apuntar a null, si no lo es va a haber que hacer calloc
    cmp rdi, 0
    je emptyTable
    ; Si estamos aca es porque hay al menos un elemento en la tabla, usamos calloc para inicializarla vacía
    ; Muevo a rsi el tamaño de los datos
    ; Guardo el rax previo que tiene el puntero a la estructura que quiero devolver
    push rax
    sub rsp, 8 ; Acomodo la pila para que este alíneada previo al llamado de la función
    xor rsi, rsi
    add rsi, TAM_STRUCT_NODO_OT
    call calloc
    ; En rax tenemos el puntero a la tabla, lo muevo a otro registro y restauro rax
    mov r8, rax
    add rsp, 8
    pop rax
    mov [rax + OFFSET_TABLE], r8
    jmp epilogoInicializar
    emptyTable:
        ; Si estamos aca es porque la tabla es vacía
        xor r9, r9 ; Hago que r9 sea 0
        mov [rax + OFFSET_TABLE], r9
    epilogoInicializar:
        ;epilogo
        pop rbp
        ret


; void* calcular_z(nodo_display_list_t* display_list, uint8_t z_size) ;
; En rdi tengo el puntero a la display_list
; En sil (la parte baja de rsi) tengo el z_size
calcular_z_asm:
    ;prologo
    push rbp
    mov rbp, rsp ;Pila alíneada a 16
    ; Muevo el size a rdx para cuando llame a la función en el ciclo
    mov rdx, rsi
    ; Uso r8 para recorrer la lista porque rdi voy a tener que estar cambiandolo siempre para llamar a la función. Así que me ahorro de usar la pila en cada iteración
    mov r8, rdi
    ciclo_calcular_z: 
        cmp r8, 0
        je epilogo_calcular_z
        ; Muevo x a rdi
        mov dil, byte[r8 + OFFSET_X]
        ; muevo y a rsi
        mov sil, byte[r8 + OFFSET_Y]
        call [r8 + OFFSET_PRIMITIVA]
        ; Cuando salgo de aca en al tengo lo que tiene que ir en z
        mov byte[r8 + OFFSET_Z], al
        ; Muevo el puntero y vuelvo a iterar
        mov r8, [r8 + OFFSET_SIGUIENTE_DL]
        jmp ciclo_calcular_z
    epilogo_calcular_z:
        ;epilogo
        pop rbp
        ret

; void* ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) ;
ordenar_display_list_asm:

