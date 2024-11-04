A) Cuando un proceso menos privilegiado trata de ejecutar un HLT se produce la excepcion de software numero 13, general protection error por tratar de usar una instruccion privilegiada desde codigo usuario.

B) Como cuando ocurre una excepcion GP se pushea a la pila de mas arriba a mas abajo: EFLAGS, CS, el instruction pointer que apunta a la instruccion que produjo la excepcion, y el error code.

Lo que se puede hacer para determinar que lo que produjo el GP fue el halt es sacar de la pila el eip y ver si apunta o no a una instruccion halt, la instruccion halt tiene el opcode F4 (https://www.felixcloutier.com/x86/hlt#real-address-mode-exceptions) por lo que si apunta a 0xF4 es porque se quiso ejecutar un halt y si no fue otro motivo. 

C) Para finalizar el proceso podemos ponerle de tipo a la tarea TASK_SLOT_FREE para que si se quiere agregar una tarea nueva en su lugar pueda agregarse. (Preguntar proceso para saltar a la siguiente tarea si no va a quedar a destiempo)

D) Para determinar el proximo proceso a ejecutar habria que llamar a sched next task (Preguntar si no se podria ir directamente a la interrupcion de reloj)

E) Para soportar este mecanismo tendriamos que modificar la idt entry 13 para que pueda ser llamada por nivel usuario (checkear si hace falta esto) y definir en isr.asm la rutina de atencion a esta interrupcion (preguntar por la rutina ya existente)