A) Para implementar la syscall:

La interrupción tiene que estar entre la 32 y 255 que son las interrupciones definidas para interrupciones de usuario. Considerando las que teníamos definidas de los talleres y que por lo general las syscalls son interrupciones mayores a 80, elijo que sea la 80.

Para la interrupción hay que agregarle una entrada en la idt y especificar en su descriptor que pueda ser llamada desde nivel 3 pero que el codigo que ejecute sea de nivel 0. Por lo que en el archivo idt.c habría que agregarla en idt_init() poniéndolo junto a las syscalls, quedando:

```c
// COMPLETAR: Syscalls
IDT_ENTRY3(80); // Definición de la syscall exit
IDT_ENTRY3(88);
IDT_ENTRY3(98);
```

Tambien en isr.h habria que agregarla: 

```h
void _isr80();
void _isr88();
void _isr98();
```

Luego en isr.asm la implementamos:

```asm
extern current_task

global _isr80
_isr80:
   popad
   call sched_exit_task
   mov word [sched_task_selector], ax
   jmp far [sched_task_offset]
   .fin:
   call tasks_tick
   call tasks_screen_update
   popad iret
```

```c
uint16_t sched_exit_task(void) {
  sched_disable_task(current_task);

  return sched_next_task();
}
```
B) 
```asm
global _isr80
_isr80:
   pushad
   call sched_exit_task
   ; En ax tenemos el selector de la siguiente tarea. 
   push ax ; Selector de segmento de la tarea a saltar
   push DWORD [current_task] ; Id de la tarea actual
   call save_id
   add esp, 4
   pop ax ; Restauramos el selector a saltar
   mov word [sched_task_selector], ax
   jmp far [sched_task_offset]
   .fin:
   call tasks_tick
   call tasks_screen_update
   popad iret
```

```c
void save_id(uint32_t id_tarea_a_guardar, uint16_t selector_a_modificar,){
  uint16_t idx = selector_a_modificar >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

  uint32_t* esp = tss_pointer->esp;

  esp[7] = id_tarea_a_guardar;
}
```

C) Suponiendo que cuando le cae la interrupcion de clock a la tarea que se corrio despues de un exit ahi hay que actualizar quien la llamo:

Pondria dos variables globales en el archivo ```isr.asm``` . Una variable va a servir como un booleano que va a indicar si hace falta o no modificar el eax de la tarea a pausar y la otra variable va a contener el id que hay que ponerle. 

Si el booleano esta en 0 hacemos el procedimiento normal del clock. Si esta en 1 modificamos el eax y lo volvemos a setear en 0 para no modificar siempre el eax de las tareas en las interrupciones de clock. 

Entonces cuando se llame a la syscall exit lo unico que va a hacer es desabilitar la tarea en ejecucion, setear la variables globales y elegir la siguiente tarea a ejecutar. 

En ```isr.asm``` agregamos arriba de todo una seccion ```.data``` con las dos variables inicializando ambas en 0. 

```asm
section .data
global hubo_exit
global id_exit

hubo_exit: db 0 ; Inicializar el booleano en 0
id_exit: dd 0 ; Inicializar en id en 0
```

Modificamos la syscall para que ella no sea la que guarde el id si no que simplemente prenda la flag:

```asm
global _isr80
_isr80:
   pushad
   call sched_exit_task
   ; En ax tenemos el selector de la siguiente tarea. 
   mov byte [hubo_exit], 1 ; Prendemos la flag que hay que modificar el eax de la tarea pausada en el clock
   mov eci, [current_task]
   mov dword [id_exit], eci ; Guardamos en la variable global el id a modificar en el eax de la tarea saliente
   mov word [sched_task_selector], ax
   jmp far [sched_task_offset]
   .fin:
   call tasks_tick
   call tasks_screen_update
   popad iret
```

Ahora modificamos la rutina de atencion del clock:

```asm
global _isr32
_isr32:
    pushad
    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1
    call next_clock
    ; 2. Realizamos el cambio de tareas en caso de ser necesario
    cmp [hubo_exit], 0
    je .cambiar_tarea
    ; Si estamos aca es porque hay que modificar el eax de la tarea saliente
    ; Lo primero que hacemos es volver a setear la flag en 0 para que en el siguiente pulso no se vuelva a escribir en el eax si no hace falta
    mov [hubo_exit], 0
    str ax ; Cargo el selector de la tarea a modificar su eax
    push ax 
    push [id_exit] ; Pusheo el id de la tarea que tenemos que poner en su eax
    call save_id
    add esp, 5 ; Desapilamos
    ; Ya cuando estamos aca hay que seguir el procedimiento habitual
    .cambiar_tarea:
      call sched_next_task
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

D) Es una manera poco eficiente estar pasandose datos por registros de otra tarea ya que conlleva mucho mas trabajo del kernel y estar pisando un registro tan importante como el eax tambien no es muy eficiente. 

Una manera mucho mejor para poder pasar datos entre tareas seria definir un area de memoria compartida entre tareas como hicimos en el taller con el score de los juegos de pong. Asi en vez de tener que hacer una syscall y que el kernel tenga que meterse a la pila de la tarea a modificar simplemente hay que hacer un mov desde la tarea a una posicion de memoria.

Un problema que puede surgir al pisar registros puede ser perder datos o usar eax pensando que es una cosa y realmente tiene otro dato. 