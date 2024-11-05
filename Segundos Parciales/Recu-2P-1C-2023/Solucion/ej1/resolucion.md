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
   call sched_exit_task
   mov word [sched_task_selector], ax
   jmp far [sched_task_offset]
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
   call sched_exit_task
   ; En ax tenemos el selector de la siguiente tarea. 
   push ax ; Selector de segmento de la tarea a saltar
   push DWORD [current_task] ; Id de la tarea actual
   call save_id
   add esp, 4
   pop ax ; Restauramos el selector a saltar
   mov word [sched_task_selector], ax
   jmp far [sched_task_offset]
```

```c
void save_id(uint16_t selector_a_modificar, uint32_t id_tarea_a_guardar){
  uint16_t idx = selector_a_modificar >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

  uint32_t* esp = tss_pointer->esp;

  esp[7] = id_tarea_a_guardar;
}
```

C) Suponiendo que cuando le cae la interrupcion de clock a la tarea que se corrio despues de un exit ahi hay que actializar quien la llamo:

Pondria dos variables globales (preguntar el tema de variables globales dentro del kernel) o reservar 3 bytes de memoria del kernel donde: 

Los primeros 2 bytes van a contener el id de la tarea que llamo al exit y el ultimo byte va a ser un booleano que indique si hay que modificar o no el eax de la tarea que esta terminando. Por lo que el id puede quedar inutil si el booleano indica que no hay que escribir. 

Entonces cuando una tarea hace exit antes de saltar a la siguiente tarea seteamos el booleano en 1 y guardamos el id. Luego en la rutina de atencion del reloj antes de decidir cual va a ser la proxima tarea a correr verificamos si el booleano esta en verdadero, si esta hacemos el mismo proceso que en el B para modificar el eax de la tarea que llamo el exit pasandole a la funcion el id que esta guardado en memoria. Luego seteamos el booleano en falso para que si hay un nuevo pulso de clock no se vuelva a pisar eax hasta el siguiente exit. 

En caso que el booleano este en 0 seguimos el proceso habitual. 

FALTA COMPLETAR IMPLEMENTACION Y EL D.