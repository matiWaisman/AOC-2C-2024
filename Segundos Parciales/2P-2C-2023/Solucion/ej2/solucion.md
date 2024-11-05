A) Cuando un proceso menos privilegiado trata de ejecutar un HLT se produce la excepcion de software numero 13, general protection error por tratar de usar una instruccion privilegiada desde codigo usuario.

B) Como cuando ocurre una excepcion GP se pushea a la pila de mas arriba a mas abajo: EFLAGS, CS, el instruction pointer que apunta a la instruccion que produjo la excepcion, y el error code.

Lo que se puede hacer para determinar que lo que produjo el GP fue el halt es sacar de la pila el eip y ver si apunta o no a una instruccion halt, la instruccion halt tiene el opcode 0xF4 (https://www.felixcloutier.com/x86/hlt#real-address-mode-exceptions) por lo que si apunta a 0xF4 es porque se quiso ejecutar un halt y si no fue llamar a kernel exception. 

C) Para finalizar el proceso podemos ponerle de tipo a la tarea TASK_SLOT_FREE para que si se quiere agregar una tarea nueva en su lugar pueda agregarse o simplemente pausarla para que nunca mas se vuelva a ejecutar. Luego habria que saltar o a la tarea siguiente que "elija" el scheduler o podemos saltar a la tarea idle y al siguiente pulso de clock se va a ir a la siguiente tarea a ejecutar.

D) Para determinar el proximo proceso a ejecutar habria que llamar a sched next task y saltar a esa tarea. Otra cosa que se podria hacer es saltar a la tarea idle y cuando sea el proximo pulso de clock pasamos a la siguiente tarea.

E) Para poder agregar el mecanismo lo unico que habria que hacer es en isr.asm borrar la linea ```ISRE 13``` y implementar la rutina de atencion. 

F) En isr.asm: 

Para pausar la tarea como tenemos en vamos a conseguir el selector de la tarea actual usando el registro que lo contiene, tr, y vamos a hacer un ciclo hasta encontrar en el array del scheduler la tarea que tenga ese selector.

```asm
global _isr13
_isr13:
  ;pushad No se si hace falta total nunca vas a volver a la tarea pase lo que pase
  mov eax, [esp + 4] ; Obtenemos el eip de la intruccion que produjo la excepcion
  mov eax, [eax] ; Cargamos en eax la instruccion a la que apunta
  cmp eax, 0XF4
  jne .fin
  ; Si estamos aca es porque hay que pausar la tarea y pasar a la nueva 
  str ax ; Guardamos el tr en ax
  push ax ; Le pasamos el selector como parametro a pause_task
  call pause_task
  call sched_next_task
  add esp, 2
  mov word [sched_task_selector], ax
  jmp far [sched_task_offset]
  jmp $ ; Por si acaso termina antes del pulso de clock
  .fin:
    call kernel_exception
    jmp $
```

En sched.c definimos pause_task:

```c
void pause_task(uint16_t selector_tarea_a_pausar){
  for (int8_t i = 0; i < MAX_TASKS; i++) {
    if (sched_tasks[i].selector == selector_tarea_a_pausar) {
      sched_tasks[i] = (sched_entry_t) {
        .selector = selector_tarea_a_pausar,
	      .state = TASK_PAUSED,
      };
      return;
    }
  }
}
```

No hace falta modificar el codigo del scheduler next task porque nunca va a ejecutar una tarea que no sea TASK_RUNNABLE. Si quisieramos que se elimine directamente la tarea podemos usar TASK_SLOT_FREE. 