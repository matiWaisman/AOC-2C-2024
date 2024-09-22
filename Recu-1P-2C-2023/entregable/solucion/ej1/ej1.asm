; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0
%define STRING_PROC_LIST_SIZE 16
%define STRING_PROC_LIST_OFFSET_FIRST 0
%define STRING_PROC_LIST_OFFSET_LAST 8
%define STRING_PROC_NODE_SIZE 32
%define STRING_PROC_NODE_OFFSET_NEXT 0
%define STRING_PROC_NODE_OFFSET_PREVIOUS 8
%define STRING_PROC_NODE_OFFSET_TYPE 16
%define STRING_PROC_NODE_OFFSET_HASH 24

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    mov rdi, STRING_PROC_LIST_SIZE ; le cargo a rdi el size de la estructura para llamar a malloc
    call malloc
    ; string_proc_list* res = malloc(sizeof(string_proc_list));
    mov qword [rax + STRING_PROC_LIST_OFFSET_FIRST], 0 ; res->first = NULL;
    mov qword [rax + STRING_PROC_LIST_OFFSET_LAST], 0 ; res->last = NULL;
    ;epilogo
    pop rbp
    ret

; Recibo en dil el type y en rsi el puntero al char hash
string_proc_node_create_asm:
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    push rdi ; Stack alíneado a 8 bytes
    sub rsp, 8 ; Stack alíneado a 16 bytes
    mov rdi, STRING_PROC_NODE_SIZE ; le cargo a rdi el size de la estructura para llamar a malloc
    call malloc
    add rsp, 8 
    pop rdi
    ; string_proc_node* res = malloc(sizeof(string_proc_node));
    mov qword [rax + STRING_PROC_NODE_OFFSET_NEXT], 0 ; res->next = NULL;
    mov qword [rax + STRING_PROC_NODE_OFFSET_PREVIOUS], 0 ; res->previous = NULL;
    mov [rax + STRING_PROC_NODE_OFFSET_TYPE], dil ; res->type = type;
    mov [rax + STRING_PROC_NODE_OFFSET_HASH], rsi ; res->hash = hash;
    ;epilogo
    pop rbp
    ret

; Recibo en rdi el puntero a la lista
; Recibo en sil el tipo del nodo
; Recibo en rdx el puntero al string
string_proc_list_add_node_asm:
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    ; Primero guardo los datos de los parametros en el stack para llamar a la función para crear el nodo y despúes los intercambio entre si
    push rdi ; Stack alíneado a 8 bytes
    push rsi ; Stack alíneado a 16 bytes
    push rdx ; Stack alíneado a 8 bytes
    sub rsp, 8 ; Stack alíneado a 16 bytes
    ; Tengo que poner en dil sil y en rsi rdx
    mov sil, dil
    mov rsi, rdx
    call string_proc_node_create_asm ; string_proc_node* nodo_a_agregar = string_proc_node_create(type, hash);
    ; En rax tengo el puntero al nodo que acabo de crear
    ; Restauro lo que pushie al stack
    add rsp, 8
    pop rdx
    pop rsi
    pop rdi
    mov r8, qword [rdi + STRING_PROC_LIST_OFFSET_LAST] ; string_proc_node* anterior_ultimo = list->last;
    mov qword [rdi + STRING_PROC_LIST_OFFSET_LAST], rax ; list->last = nodo_a_agregar;
    cmp r8, 0 
    je ningun_nodo
    mov qword [r8 + STRING_PROC_NODE_OFFSET_NEXT], rax ; anterior_ultimo->next = nodo_a_agregar;
    mov qword [rax + STRING_PROC_NODE_OFFSET_PREVIOUS], r8 ; nodo_a_agregar->previous = anterior_ultimo;
    jmp epilogo_add_node
    ningun_nodo:
        mov qword [rdi + STRING_PROC_LIST_OFFSET_FIRST], rax ; list->first = nodo_a_agregar;
    epilogo_add_node:
        ;epilogo
        pop rbp
        ret

; En rdi recibo el puntero a la lista
; En sil recibo el tipo del nodo
; En rdx recibo el puntero al hash
string_proc_list_concat_asm:
    ;prologo
    push rbp
    mov rbp, rsp ; Stack alíneado a 16 bytes
    ; Muevo el hash a rax que voy a devolver
    mov rax, rdx ; char* res = hash;
    mov r8, qword [rdi + STRING_PROC_LIST_OFFSET_FIRST] ; string_proc_node* iterador = list->first;
    ciclo:
        cmp r8, 0
        je epilogo
        ; Primero vemos si coincide el tipo actual con el que estamos buscando
        cmp byte [r8 + STRING_PROC_NODE_OFFSET_TYPE], sil
        jne fin_ciclo
        ; Vamos a tener que hacer free del string viejo, muevo rax a r9
        mov r9, rax
        ; Si estamos aca es porque hay que concatenar los strings 
        ; str_concat espera en rdi el puntero al primer string y en rsi al segundo
        ; Primero guardo los registros volatiles que me interesan en el stack
        push r8 ; Stack alíneado a 8 bytes
        push rdi ; Stack alíneado a 16 bytes
        push rsi ; Stack alíneado a 8 bytes
        push r9 ; Stack alíneado a 16 bytes
        mov rdi, rax
        mov rsi, [r8 + STRING_PROC_NODE_OFFSET_NEXT]
        call str_concat
        ; En rax tengo el resultado de la concatenación
        pop r9
        pop rsi
        mov rdi, r9
        call free
        pop rdi
        pop r8
        fin_ciclo:
            mov r8, qword [r8 + STRING_PROC_NODE_OFFSET_NEXT]
            jmp ciclo
    epilogo:    
        ;epilogo
        pop rbp
        ret