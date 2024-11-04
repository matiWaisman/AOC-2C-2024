A)  Las entradas que se agregan a la GDT que van a ser relevantes van a ser los TSS descriptors de las tareas creadas. Gracias a ellos vamos a poder pausar/ restaurar las tareas y incrementar el valor de ecx cada vez que la tarea vuelva a ser ejecutada. Tambien va a servir para comparar el valor de ecx entre las diferentes tareas.

B) Lo que habria que agregar es que despues de determinar en la rutina de atención de la interrupción cual es la proxima tarea al llamar a sched_next_task() llamamos a una función en C que va a recibir por parametro el selector de la tarea elegida. En esa función lo que vamos a hacer va a ser acceder a la tss por medio de la gdt y incrementar en uno edx. El codigo de la función sería: 

```c
void incrementar_edx(uint16_t segsel){
  uint16_t idx = segsel >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

  tss_pointer->edx += 1;
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
    push ax
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
 
  uint32_t utc_a_comparar = tss_pointer->ecx;

  return mi_utc > utc_a_comparar;
}
```

