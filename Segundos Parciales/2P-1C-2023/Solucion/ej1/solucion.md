A) Para implementar la syscall hay que elegir una interrupcion no definida previamente en el kernel la cual va a ser el medio por el cual las tareas se van a comunicar al kernel pidiendole que pase a la tarea que calcula. Las syscalls se suelen definir despues de la interrupcion numero 80, asi que usemos esa. 

Para definir la syscall hay que agregarla a la idt, para que pueda ser llamada desde codigo de nivel usuario tiene que tener dpl nivel 3 y para que ejecute codigo de kernel su selector tiene que ser el GDT_CODE_0_SEL. Por lo que vamos a usar IDT_ENTRY3 para definir esta syscall. Por lo que en la funcion ```idt_init()``` habria que agregar a donde estan definidas las syscalls la numero 80. En ```idt_init()``` quedaria:

```c
// COMPLETAR: Syscalls
  IDT_ENTRY3(80);
  IDT_ENTRY3(88);
  IDT_ENTRY3(98);
```

Para inicializar las tareas habria que crear una nueva funcion muy parecida a ```mmu_init_task_dir``` para definir una tarea de nivel 0. Para esto la funcion tambien deberia recibir una direccion fisica donde comienza el codigo de la tarea de nivel 0 y hacer lo mismo pero que los atributos sean read-write level 0. Luego habria que llamar a esta funcion desde asm. La direccion fisica que le damos para empezar tendria que ser dentro del area de kernel donde no haya ya otra cosa, pongamosle que empieza en 0x100000 si es que no hay nada alli ya definido.  (CHECKEAR ESTA PARTE)  

Tambien para que al hacer que sched_next_task nunca elija la "tarea compartida" como la siguiente a ejecutar tenemos que hacer que esa tarea no tenga como estado ```TASK_RUNNABLE``` nunca, por lo que le voy a poner que sea ```TASK_PAUSED``` en todo momento. (Preguntar si esta bien esto porque si no habria que crear un tipo nuevo, capaz crearia otro nuevo como para al menos darle mas semantica)

Por lo que la inicializacion de las tareas deberia ser dentro de tasks_init suponiendo que las 5 tareas tienen el mismo tipo y la sexta otro
```c
/**
 * Inicializa el sistema de manejo de tareas
 */
void tasks_init(void) {
  int8_t task_id;
  // Dibujamos la interfaz principal
  tasks_screen_draw();

  // Creamos las tareas de tipo A
  task_id = create_task(TASK_A);
  sched_enable_task(task_id);
  task_id = create_task(TASK_A);
  sched_enable_task(task_id);
  task_id = create_task(TASK_A);
  sched_enable_task(task_id);
  task_id = create_task(TASK_A);
  sched_enable_task(task_id);
  task_id = create_task(TASK_A);
  sched_enable_task(task_id);
  // Creamos las tareas de tipo B
  task_id = create_task(TASK_B); // Al crearse se crea pausada habria que modificar TASK_B para que apunte a la direccion fisica donde comienza el codigo de nivel 0. Sup que es 0x100000
}
```


Y lo siguiente que deberiamos modificar seria agregar en isr.asm la rutina de atencion de la interrupcion.

B) La rutina de atencion seria:
```asm

```


