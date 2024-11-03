extern free
extern malloc
extern printf
extern strlen

section .rodata
porciento_ese: db "%s", 0

section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; El tipo de los `texto_cualquiera_t` que son cadenas de caracteres clásicas.
TEXTO_LITERAL       EQU 0
; El tipo de los `texto_cualquiera_t` que son concatenaciones de textos.
TEXTO_CONCATENACION EQU 1

; Un texto que puede estar compuesto de múltiples partes. Dependiendo del campo
; `tipo` debe ser interpretado como un `texto_literal_t` o un
; `texto_concatenacion_t`.
;
; Campos:
;   - tipo: El tipo de `texto_cualquiera_t` en cuestión (literal o
;           concatenación).
;   - usos: Cantidad de instancias de `texto_cualquiera_t` que están usando a
;           este texto.
;
; Struct en C:
;   ```c
;   typedef struct {
;       uint32_t tipo;
;       uint32_t usos;
;       uint64_t unused0; // Reservamos espacio
;       uint64_t unused1; // Reservamos espacio
;   } texto_cualquiera_t;
;   ```
TEXTO_CUALQUIERA_OFFSET_TIPO EQU 0
TEXTO_CUALQUIERA_OFFSET_USOS EQU 4
TEXTO_CUALQUIERA_SIZE        EQU 24

; Un texto que tiene una única parte la cual es una cadena de caracteres
; clásica.
;
; Campos:
;   - tipo:      El tipo del texto. Siempre `TEXTO_LITERAL`.
;   - usos:      Cantidad de instancias de `texto_cualquiera_t` que están
;                usando a este texto.
;   - tamanio:   El tamaño del texto.
;   - contenido: El texto en cuestión como un array de caracteres.
;
; Struct en C:
;   ```c
;   typedef struct {
;       uint32_t tipo;
;       uint32_t usos;
;       uint64_t tamanio;
;       const char* contenido;
;   } texto_literal_t;
;   ```
TEXTO_LITERAL_OFFSET_TIPO      EQU 0
TEXTO_LITERAL_OFFSET_USOS      EQU 4
TEXTO_LITERAL_OFFSET_TAMANIO   EQU 8
TEXTO_LITERAL_OFFSET_CONTENIDO EQU 16
TEXTO_LITERAL_SIZE             EQU 24

; Un texto que es el resultado de concatenar otros dos `texto_cualquiera_t`.
;
; Campos:
;   - tipo:      El tipo del texto. Siempre `TEXTO_CONCATENACION`.
;   - usos:      Cantidad de instancias de `texto_cualquiera_t` que están
;                usando a este texto.
;   - izquierda: El tamaño del texto.
;   - derecha:   El texto en cuestión como un array de caracteres.
;
; Struct en C:
;   ```c
;   typedef struct {
;       uint32_t tipo;
;       uint32_t usos;
;       texto_cualquiera_t* izquierda;
;       texto_cualquiera_t* derecha;
;   } texto_concatenacion_t;
;   ```
TEXTO_CONCATENACION_OFFSET_TIPO      EQU 0
TEXTO_CONCATENACION_OFFSET_USOS      EQU 4
TEXTO_CONCATENACION_OFFSET_IZQUIERDA EQU 8
TEXTO_CONCATENACION_OFFSET_DERECHA   EQU 16
TEXTO_CONCATENACION_SIZE             EQU 24

; Muestra un `texto_cualquiera_t` en la pantalla.
;
; Parámetros:
;   - texto: El texto a imprimir.
global texto_imprimir
texto_imprimir:
	; Armo stackframe
	push rbp
	mov rbp, rsp

	; Guardo rdi
	sub rsp, 16
	mov [rbp - 8], rdi

	; Este texto: ¿Literal o concatenacion?
	cmp DWORD [rdi + TEXTO_CUALQUIERA_OFFSET_TIPO], TEXTO_LITERAL
	je .literal
.concatenacion:
	; texto_imprimir(texto->izquierda)
	mov rdi, [rdi + TEXTO_CONCATENACION_OFFSET_IZQUIERDA]
	call texto_imprimir

	; texto_imprimir(texto->derecha)
	mov rdi, [rbp - 8]
	mov rdi, [rdi + TEXTO_CONCATENACION_OFFSET_DERECHA]
	call texto_imprimir

	; Terminamos
	jmp .fin

.literal:
	; printf("%s", texto->contenido)
	mov rsi, [rdi + TEXTO_LITERAL_OFFSET_CONTENIDO]
	mov rdi, porciento_ese
	mov al, 0
	call printf

.fin:
	; Desarmo stackframe
	mov rsp, rbp
	pop rbp
	ret

; Libera un `texto_cualquiera_t` pasado por parámetro. Esto hace que toda la
; memoria usada por ese texto (y las partes que lo componen) sean devueltas al
; sistema operativo.
;
; Si una cadena está siendo usada por otra entonces ésta no se puede liberar.
; `texto_liberar` notifica al usuario de esto devolviendo `false`. Es decir:
; `texto_liberar` devuelve un booleando que representa si la acción pudo
; llevarse a cabo o no.
;
; Parámetros:
;   - texto: El texto a liberar.
global texto_liberar
texto_liberar:
	; Armo stackframe
	push rbp
	mov rbp, rsp

	; Guardo rdi
	sub rsp, 16
	mov [rbp - 8], rdi

	; ¿Nos usa alguien?
	cmp DWORD [rdi + TEXTO_CUALQUIERA_OFFSET_USOS], 0
	; Si la rta es sí no podemos liberar memoria aún
	jne .fin_sin_liberar

	; Este texto: ¿Es concatenacion?
	cmp DWORD [rdi + TEXTO_CUALQUIERA_OFFSET_TIPO], TEXTO_LITERAL
	; Si no es concatenación podemos liberarlo directamente
	je .fin
.concatenacion:
	; texto->izquierda->usos--
	mov rdi, [rdi + TEXTO_CONCATENACION_OFFSET_IZQUIERDA]
	dec DWORD [rdi + TEXTO_CUALQUIERA_OFFSET_USOS]
	; texto_liberar(texto->izquierda)
	call texto_liberar

	; texto->derecha->usos--
	mov rdi, [rbp - 8]
	mov rdi, [rdi + TEXTO_CONCATENACION_OFFSET_DERECHA]
	dec DWORD [rdi + TEXTO_CUALQUIERA_OFFSET_USOS]
	; texto_liberar(texto->derecha)
	call texto_liberar

	; Terminamos
	jmp .fin

.fin:
	; Liberamos el texto que nos pasaron por parámetro
	mov rdi, [rbp - 8]
	call free

.fin_sin_liberar:
	; Desarmo stackframe
	mov rsp, rbp
	pop rbp
	ret

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - texto_literal
;   - texto_concatenar
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Crea un `texto_literal_t` que representa la cadena pasada por parámetro.
;
; Debe calcular la longitud de esa cadena.
;
; El texto resultado no tendrá ningún uso (dado que es un texto nuevo).
;
; Parámetros:
;   - texto: El texto que debería ser representado por el literal a crear.
; Recibimos en rdi un puntero al texto.
global texto_literal
texto_literal:
	;prologo
	push rbp
	mov rbp, rsp ; Pila alíneada a 16 bytes
	xor rax, rax ; Limpiamos lo que va a ser el resultado
	; En rdi tiene que estar el tamaño de la estructura que vamos a crear cuando llamamos a malloc
	; En rdi tenemos el puntero al texto, asi que lo guardamos en la pila
	push rdi ; Pila alíneada a 8 bytes
	sub rsp, 8 ; Pila alíneada a 16 bytes
	mov rdi, TEXTO_LITERAL_SIZE 
	call malloc
	; Cuando estamos aca en rax tenemos el puntero al texto_literal que acabamos de crear
	; Restauramos el valor original de rdi
	add rsp, 8
	pop rdi
	mov dword [rax + TEXTO_LITERAL_OFFSET_TIPO], TEXTO_LITERAL ; resultado->tipo = 0;
	mov dword [rax + TEXTO_LITERAL_OFFSET_USOS], 0 ; resultado->usos = 0;
	mov qword [rax + TEXTO_LITERAL_OFFSET_CONTENIDO], rdi ; resultado->contenido = texto;
	; Ahora hay que calcular el tamaño del string que me pasaron, llamo a una función auxiliar. Primero guardo en la pila rax y rdi que me los van a hacer pelota
	push rdi ; Pila alineada a 8 bytes
	push rax ; Pila alineada a 16 bytes
	call stringLength
	; En rax tenemos el largo del string, lo paso a otro registro y restauro rax
	mov r8, rax
	pop rax
	pop rdi
	mov qword [rax + TEXTO_LITERAL_OFFSET_TAMANIO], r8 ; resultado->tamanio = tamanioTexto;
	;epilogo
	pop rbp
	ret

; uint64_t stringLength(char* a)
; Recibe el puntero en rdi
stringLength:
	;prologo
	push rbp
	mov rbp, rsp ; Pila alíneada a 16 bytes
	; Limpiamos el rax x las dudas
	xor rax, rax
	strLoop:
		cmp byte [rdi], 0
		je epilogo
		; Si no es 0 le sumamos uno a la respuesta y al puntero
		inc rax
		inc rdi
		jmp strLoop
	;epilogo
	epilogo:	
		pop rbp
		ret




; Crea un `texto_concatenacion_t` que representa la concatenación de ambos
; parámetros.
;
; Los textos `izquierda` y `derecha` serán usadas por el resultado, por lo que
; sus contadores de usos incrementarán.
;
; Parámetros:
;   - izquierda: El texto que debería ir a la izquierda. Viene en rdi
;   - derecha:   El texto que debería ir a la derecha. Viene en rsi
global texto_concatenar
texto_concatenar:
	;prologo
	push rbp
	mov rbp, rsp ; Pila alíneada a 16 bytes
	xor rax, rax ; Limpiamos lo que va a ser el resultado
	; Voy a llamar a malloc con el tamaño de la estructura, en rdi. Asi que guardo en la pila rdi y rsi
	push rdi ; Pila alineada a 8 bytes
	push rsi ; Pila alineada a 16 bytes 
	mov rdi, TEXTO_CONCATENACION_SIZE
	call malloc
	; En rax tenemos el puntero a la memoria que acabamos de reservar
	; Restauramos los parametros
	pop rsi
	pop rdi
	inc dword [rdi + TEXTO_CUALQUIERA_OFFSET_USOS] ; izquierda-> usos = izquierda->usos + 1;
	inc dword [rsi + TEXTO_CUALQUIERA_OFFSET_USOS] ; derecha->usos += derecha->usos + 1;
	mov dword [rax + TEXTO_CONCATENACION_OFFSET_TIPO], TEXTO_CONCATENACION ; resultado->tipo = 1;
	mov dword [rax + TEXTO_CONCATENACION_OFFSET_USOS], 0 ; resultado->usos = 0;
	mov qword [rax + TEXTO_CONCATENACION_OFFSET_IZQUIERDA], rdi; resultado->izquierda = izquierda;
	mov qword [rax + TEXTO_CONCATENACION_OFFSET_DERECHA], rsi ; resultado->derecha = derecha;
	;epilogo
	pop rbp
	ret

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - texto_tamanio_total
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Calcula el tamaño total de un `texto_cualquiera_t`. Es decir, suma todos los
; campos `tamanio` involucrados en el mismo.
;
; Parámetros:
;   - texto: El texto en cuestión.
; En rdi recibo el puntero al texto cualquiera
global texto_tamanio_total
texto_tamanio_total:
	;prologo
	push rbp
	mov rbp, rsp ; Pila alíneada a 16 bytes
	cmp dword [rdi + TEXTO_CUALQUIERA_OFFSET_TIPO], 0
	je caso_base
	; Si estamos aca es porque es el "caso recursivo"
	; Interpretamos el texto cualquiera como texto concatenación texto_concatenacion_t* concatenacion = (texto_concatenacion_t*) texto;
	; Como vamos a hacer el llamado recursivo me guardo el dato al puntero rdi
	push rdi ; Pila alíneada a 8 bytes
	sub rsp, 8 ; Pila alíneada a 16 bytes
	mov rdi, qword [rdi + TEXTO_CONCATENACION_OFFSET_IZQUIERDA]
	call texto_tamanio_total
	; Cuando salimos de aca en rax tenemos el resultado de izquierda
	add rsp, 8 
	pop rdi
	; No nos interesa ahora guardar rdi en la pila total no lo vamos a volver a necesitar. Pero si nos interesa rax
	push rax ; Pila alíneada a 8 bytes
	sub rsp, 8 ; Pila alíneada a 16 bytes
	mov rdi, qword [rdi + TEXTO_CONCATENACION_OFFSET_DERECHA]
	call texto_tamanio_total
	; Ahora en rax tenemos el resultado de la concatenacion de la derecha, hay que juntarlo con el de la izquierda
	add rsp, 8
	pop rdi ; Restauramos el valor de rax viejo en rdi porque no lo vamos a volver a usar
	add rax, rdi ; texto_tamanio_total(concatenacion->derecha) + texto_tamanio_total(concatenacion->izquierda);
	jmp epilogo_tamanio_total
	caso_base:
		; texto_literal_t* literal = (texto_literal_t*) texto; Lo tengo que interpretar como si fuera un texto_literal
		mov rax, qword [rdi + TEXTO_LITERAL_OFFSET_TAMANIO] ; return literal->tamanio;
	epilogo_tamanio_total: 
		;epilogo
		pop rbp
		ret

; Marca el ejercicio 1C como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - texto_chequear_tamanio
global EJERCICIO_1C_HECHO
EJERCICIO_1C_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Chequea si los tamaños de todos los nodos literales internos al parámetro
; corresponden al tamaño de la cadenas que apuntadan.
;
; Es decir: si los campos `tamanio` están bien calculados.
;
; Parámetros:
;   - texto: El texto verificar. Que viene en rdi
global texto_chequear_tamanio
texto_chequear_tamanio:
	;prologo
	push rbp
	mov rbp, rsp ; Pila alíneada a 16 bytes
	cmp dword [rdi + TEXTO_CUALQUIERA_OFFSET_TIPO], 0
	je caso_base_chequear_tamanio
	; Si estoy aca es porque es el "caso recursivo"
	; texto_concatenacion_t* concatenacion = (texto_concatenacion_t*) texto;
	; Interpretamos a rdi como si fuera un texto_concatenacion
	; Guardamos el puntero viejo
	push rdi ; Pila alíneada a 8 bytes
	sub rsp, 8 ; Pila alíneada a 16 bytes
	; Ponemos en rdi el puntero a la izquierda
	mov rdi, qword [rdi + TEXTO_CONCATENACION_OFFSET_IZQUIERDA]
	call texto_chequear_tamanio
	; Ahora aca en rax tenemos el booleano de la izquierda
	; Restauramos rdi
	add rsp, 8
	pop rdi
	; Guardamos el rax viejo en la pila
	push rax ; Pila alíneada a 8 bytes
	sub rsp, 8 ; Pila alíneada a 16 bytes
	; Hacemos que rdi apunte al texto de la derecha
	mov rdi, qword [rdi + TEXTO_CONCATENACION_OFFSET_DERECHA]
	call texto_chequear_tamanio
	; Ahora en rax tenemos el resultado de la derecha
	; Restauro el rax viejo pero en rdi total no lo voy a usar más
	add rsp, 8
	pop rdi
	test rax, rdi
	jnz devolver_1 ; Si el and es verdadero vamos a devolver true
	jmp devolver_0 ; Si es falso devolvemos false
	caso_base_chequear_tamanio:
		; texto_literal_t* literal = (texto_literal_t*) texto; Lo tengo que interpretar como si fuera un texto_literal
		; Guardo el rdi en la pila antes de llamar a la función stringLength. 
		push rdi ; Pila alíneada a 8 bytes
		sub rsp, 8 ; Pila alíneada a 16 bytes
		; Muevo a rdi el puntero al string
		mov rdi, [rdi + TEXTO_LITERAL_OFFSET_CONTENIDO]
		call stringLength
		; en rax tengo el tamaño de verdad del texto
		add rsp, 8
		pop rdi
		cmp rax, qword [rdi + TEXTO_LITERAL_OFFSET_TAMANIO]
		je devolver_1 ; Son iguales
		; Son distintos
		jmp devolver_0
	devolver_1:
		xor rax, rax
		inc rax
		jmp epilogo_chequear_tamanio
	devolver_0:
		xor rax, rax	
	epilogo_chequear_tamanio: 
		;epilogo
		pop rbp
		ret
	
