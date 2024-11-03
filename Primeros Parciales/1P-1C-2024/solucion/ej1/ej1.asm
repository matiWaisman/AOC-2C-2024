section .data
align 16
TAM_STRUCT_OT equ 16 ; Cada struct ocupa 16 bytes, un byte para el table size, 7 de padding y 8 bytes del puntero
align 16
TAM_STRUCT_NODO_OT equ 16 ; Cada struct ocupa 16 bytes porque tiene dos punteros de 8 bytes
align 16
TAM_STRUCT_NODO_DL equ 24 ; El puntero a función ocupa 8 bytes, luego estan los 3 uints_8 uno al lado del otro, 5 bytes de offset y el puntero al siguiente
OFFSET_TABLE_SIZE equ 0
OFFSET_TABLE equ 8
OFFSET_PRIMITIVA equ 0
OFFSET_X equ 8
OFFSET_Y equ 9
OFFSET_Z equ 10
OFFSET_SIGUIENTE_DL equ 16
OFFSET_ORDERING_TABLE_SIZE equ 0
OFFSET_DISPLAY_ELEMENT_NODO_OT equ 0
OFFSET_SIGUIENTE_NODO_OT equ 8

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
; El puntero a la ot viene en rdi
; El puntero a la display_list viene en rsi
ordenar_display_list_asm:
    ;prologo
    push rbp
    mov rbp, rsp ;Pila alíneada a 16
    ; Primero tengo que calcular el z para todos los nodos de la display_list
    ; Muevo los parametros y por las dudas me guardo los parametros en la pila por si calcular_z los usa y los cambia
    ; Como voy a pushear dos datos de 8 bytes la pila va a quedar alíneada a 16 como corresponde
    push rdi
    push rsi
    ; La función calcular z espera tener en rdi el puntero a la display_list y en sil el z_size 
    ; Asi que me ocupo de mover los datos. 
    mov rdi, rsi
    ; En ot->size tengo el size. Lo tengo que mover a sil (rsi)
    mov sil, [rsi + OFFSET_ORDERING_TABLE_SIZE]
    call calcular_z_asm
    ; Restauro los valores de rdi y rsi
    pop rsi ; Rsi tiene el puntero al primer nodo de la display_list
    pop rdi ; Rdi tiene el puntero a la ot
    ; Uso rsi para recorrer la display_list
    ciclo_display_list:
        cmp rsi, 0
        je epilogo_ordenar
        ; Ahora habría que chequear si hay un nodo_ot ya creado para iterar hasta llegar al ultimo o si hay que recorrer la lista de nodos_ot hasta llegar al ultimo
        ; Hay que chequear que ot->table[z_actual] != Null, si es Null nos vamos a crear_nodo_inicial
        ; En r8 ponemos ot->table y despues vamos a acceder a z_actual desde r8 porque es un puntero de punteros
        mov r8, [rdi + OFFSET_TABLE] ; r8 va a ser el puntero que apunta a ot -> table
        ; En r10 pongo el primer nodo_ot de ot->table[z_actual]
        ; En r9 pongo el z actual, piso los datos de r9 por si acaso
        xor r9, r9
        mov r9b, [rsi + OFFSET_Z]
        ; Como cada posicion de la tabla ocupa 8 bytes (porque son punteros) para llegar a z_actual habría que hacer [r8 + z * 8]
        mov r10, [r8 + r9 * 8] ; r10 apunta al nodo ot
        ; Con esto en r10 tenemos al nodo ot al que apunta la ot en z. Puede ser null
        cmp r10, 0 ; Si el nodo es null hay que inicializarlo y hacer que la ot apunte al nodo creado
        je crear_nodo_inicial
        ; Si estamos aca es porque hay que iterar sobre los nodos ot hasta llegar al ultimo
        ; Usamos r10 para iterar
        ciclo_nodo_ot:
            cmp qword [r10 + OFFSET_SIGUIENTE_NODO_OT], 0 ; while(nodo_ot_iterador->siguiente != NULL)
            je agregar_nodo_ot
            mov r10, [r10 + OFFSET_SIGUIENTE_NODO_OT] ; nodo_ot_iterador = nodo_ot_iterador->siguiente;
            jmp ciclo_nodo_ot
        agregar_nodo_ot: 
            ; Si estamos aca es porque hay que agregar un nodo_ot al final de la lista de nodos_ot, y hacer que r10 siguiente apunte a ese nodo
            ; Primero hacemos el malloc, guardo en la pila rdi y r10
            push rdi ; Pila alíneada a 8
            push r10 ; Pila alíneada a 16
            ; El malloc espera en rdi el tamaño de la memoria que vamos a reservar
            mov rdi, TAM_STRUCT_NODO_OT
            call malloc ; En rax tenemos el puntero al nodo que acabamos de crear nodo_ot_t *nodo_a_crear = malloc(sizeof(nodo_ot_t));
            pop r10
            pop rdi
            mov [rax + OFFSET_DISPLAY_ELEMENT_NODO_OT], rsi ; nodo_a_crear->display_element = display_list;
            mov qword [rax + OFFSET_SIGUIENTE_NODO_OT], 0 ; nodo_a_crear->siguiente = NULL;
            mov [r10 + OFFSET_SIGUIENTE_NODO_OT], rax ; nodo_ot_iterador->siguiente = nodo_a_crear;
            jmp epilogo_ciclo_display_list
        crear_nodo_inicial:
            ; Para crear el nodo inicial hay que hacer malloc. Malloc espera el size en rdi y usa r8 asi que me guardo los dos en la pila porque los va a pisar
            ; Devuelve el puntero al espacio de memoria reservado en rax
            push r8 ; Pila alíneada a 8 bytes
            push r9 ; Pila alíneada a 16 bytes
            push rdi ; Pila alíneada a 8 bytes
            sub rsp, 8 ; Pila alíneada a 16 bytes
            mov rdi, TAM_STRUCT_NODO_OT
            call malloc
            ; En rax tenemos el puntero del dato que acabamos de crear. Restauro r8 y rdi primero
            add rsp, 8
            pop rdi
            pop r9
            pop r8
            ; Rax = "nodo_a_crear" de mi codigo en c
            mov [rax + OFFSET_DISPLAY_ELEMENT_NODO_OT], rsi ; nodo_a_crear->display_element = display_list;
            mov qword [rax + OFFSET_SIGUIENTE_NODO_OT], 0 ; nodo_a_crear->siguiente = NULL;
            mov [r8 + r9 * 8], rax ; ot->table[z_actual] = nodo_a_crear;
        epilogo_ciclo_display_list:
            ; Aca actualizo los punteros para no tener codigo repetido en crear_nodo_inicial y ciclo_nodo_ot
            mov rsi, [rsi + OFFSET_SIGUIENTE_DL]
            jmp ciclo_display_list
    epilogo_ordenar: 
        ;epilogo
        pop rbp
        ret

