A)  Las entradas que se agregan a la GDT que van a ser relevantes van a ser los TSS descriptors de las tareas creadas. Gracias a ellos vamos a poder pausar/ restaurar las tareas y incrementar el valor de ecx cada vez que la tarea vuelva a ser ejecutada. Tambien va a servir para comparar el valor de ecx entre las diferentes tareas.

B) Lo que habria que agregar es que despues de determinar en la rutina de atención de la interrupción cual es la proxima tarea al llamar a sched_next_task() llamamos a una función en C que va a recibir por parametro el selector de la tarea elegida. Como el edx que esta en la tss puede estar sucio despues de hacer las calls a C lo que vamos a hacer es entrar a la posicion de la pila de la tarea y incrementar el edx de ahi. 

```c
void incrementar_edx(uint16_t segsel){
  uint16_t idx = segsel >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));
  
  uint32_t* stack_pointer = tss_pointer->esp;

  stack_pointer[5] = stack_pointer[5] + 1;
}
```

El codigo de la rutina de atencion de reloj quedaria:

```asm
_isr32:
    pushad
    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1
    call next_clock
    ; 2. Realizamos el cambio de tareas en caso de ser necesario
    call sched_next_task
    push ax ; El ax que devuelve sched_next_task es el que queremos incrementar
    call incrementar_edx
    cmp ax, 0
    je .fin

    str bx
    cmp ax, bx
    je .fin

    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]

    .fin:
    ; 3. Actualizamos las estructuras compartidas ante el tick del reloj
    call tasks_tick
    ; 4. Actualizamos la "interfaz" del sistema en pantalla
    call tasks_screen_update
    popad
    iret

```

C) Para que una tarea pueda consultar si fue llamada mas que otra va a tener que pasar por el kernel para esto. Por lo tanto va a ser una syscall. 

Para definir una syscall hay que definir una nueva entrada en la IDT, que tenga atributos para ser llamada desde nivel usuario y ejecute codigo nivel 0. Para las syscalls por lo general se situan en la IDT a partir de la entrada 80, asi que la definimos ahi, por lo que en IDT_INIT habria que agregar:

```c
// COMPLETAR: Syscalls
IDT_ENTRY3(80); // Definición de la syscall fuiLlamadaMasVeces
IDT_ENTRY3(88);
IDT_ENTRY3(98);
```
En isr.h agregar ```void _isr80();```

Y luego agregar en isr.asm el codigo de la rutina de atención a la excepción.

D) El codigo va a ser:

isr.asm: 

```asm
global _isr80 
  _isr80:
    pushad
    push ecx ; Habria que checkear si sirve usar este ecx o si habria que sacarlo de la tss de la tarea actual
    push edi
    call fuiLlamadaMasVeces
    ;acomodo la pila
    add ESP, 8
    ;Para no pisar el resultado con el popad
    mov [ESP+offset_EAX], eax

    popad
    iret
```

Y la funcion fuiLlamadaMasVeces: 

```c 
uint32_t fuiLlamadaMasVeces(uint16_t segsel, uint32_t mi_utc){
  uint16_t idx = segsel >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));
 
  uint32_t* stack_pointer = tss_pointer->esp;

  return mi_utc > stack_pointer[5];
}
```

E) Una mejor manera de guardar el UTC seria dentro de un espacio de memoria reservado de la tarea donde lo guarde. Como el .data del codigo o en una parte shared si se quiere compartir con otras tareas como para hacer algo de este estilo de comparar si fuiste llamada mas veces sin tener que pasar por el kernel. 

