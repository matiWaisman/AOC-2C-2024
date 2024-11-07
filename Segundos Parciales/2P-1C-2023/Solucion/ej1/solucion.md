A) Para definir las nuevas tareas habria que modificar el archivo `tasks.c` agregandole nuevos tipos donde cada tipo va a tener una direccion fisica del inicio del codigo de cada tarea nueva. Y en `tasks_init` crear las 5 tareas cada una con su tipo correspondiente.

Tambien habria que crear una nueva funcion para inicializar una tarea pero que sea de nivel 0. La funcion `mmu_init_shared_task_dir` seria identica a `init_task_dir` pero no va a tener atributos de usuario si no que de kernel y en vez de que la pila sea una pagina de usuario va a ser de kernel.

```c
tss_t tss_create_user_task(paddr_t code_start) {
  if(code_start == SHARED_TASK_CODE_START){
    uint32_t cr3 = mmu_init_shared_task_dir(code_start);
  }
  else{
    uint32_t cr3 = mmu_init_task_dir(code_start);
  }
  uint32_t cr3 = mmu_init_task_dir(code_start);
  vaddr_t stack = TASK_STACK_BASE - 1 ; 
  vaddr_t code_virt = TASK_CODE_VIRTUAL;
  // Como queremos tambien un stack de nivel 0 pedimos la pagina y lo agregamos al directorio con un map
  vaddr_t stack0 = mmu_next_free_kernel_page();
  //mmu_map_page(cr3, stack0, (paddr_t)stack0, MMU_P | MMU_W);
  vaddr_t esp0 = stack0 + (PAGE_SIZE - 1); 
  return (tss_t) {
    .cr3 = cr3,
    .esp = stack,
    .ebp = stack,
    .eip = code_virt,
    .cs = GDT_CODE_3_SEL,
    .ds = GDT_DATA_3_SEL,
    .es = GDT_DATA_3_SEL,
    .fs = GDT_DATA_3_SEL,
    .gs = GDT_DATA_3_SEL,
    .ss = GDT_DATA_3_SEL,
    .ss0 = GDT_DATA_0_SEL,
    .esp0 = esp0,
    .eflags = EFLAGS_IF,
  };
}
```

Tambien en `sched.c` vamos a agregar un nuevo state que es `TASK_SHARED` y definimos una variable global que va a ser el selector de la tarea shared. La llamo `shared_selector`

Modificamos `create_task` para que en caso que el tipo de la tarea sea la compartida la cree con el estado compartida.

```c
static int8_t create_task(tipo_e tipo) {
  size_t gdt_id;
  for (gdt_id = GDT_TSS_START; gdt_id < GDT_COUNT; gdt_id++) {
    if (gdt[gdt_id].p == 0) {
      break;
    }
  }
  kassert(gdt_id < GDT_COUNT, "No hay entradas disponibles en la GDT");
  if(tipo == TASK_SHARED){
    sched_add_shared_task(gdt_id << 3);
  }
  else{
    int8_t task_id = sched_add_task(gdt_id << 3);
  }
  tss_tasks[task_id] = tss_create_user_task(task_code_start[tipo]);
  gdt[gdt_id] = tss_gdt_entry_for_task(&tss_tasks[task_id]);
  return task_id;
}
```

Y `sched_add_shared_task` es:

```c
int8_t sched_add_shared_task(uint16_t selector) {
  kassert(selector != 0, "No se puede agregar el selector nulo");

  // Se busca el primer slot libre para agregar la tarea
  for (int8_t i = 0; i < MAX_TASKS; i++) {
    if (sched_tasks[i].state == TASK_SLOT_FREE) {
      sched_tasks[i] = (sched_entry_t) {
        .selector = selector,
	      .state = TASK_SHARED,
      };
      shared_selector = selector;
      return i;
    }
  }
  kassert(false, "No task slots available");
}
```

Para implementar la syscall hay que elegir una interrupcion no definida previamente en el kernel la cual va a ser el medio por el cual las tareas se van a comunicar al kernel pidiendole que pase a la tarea que calcula. Las syscalls se suelen definir despues de la interrupcion numero 80, asi que usemos esa. 

Para definir la syscall hay que agregarla a la idt, para que pueda ser llamada desde codigo de nivel usuario tiene que tener dpl nivel 3 y para que ejecute codigo de kernel su selector tiene que ser el GDT_CODE_0_SEL. Por lo que vamos a usar IDT_ENTRY3 para definir esta syscall. Por lo que en la funcion ```idt_init()``` habria que agregar a donde estan definidas las syscalls la numero 80. En ```idt_init()``` quedaria:

```c
// COMPLETAR: Syscalls
  IDT_ENTRY3(80);
  IDT_ENTRY3(88);
  IDT_ENTRY3(98);
``` 

Y en isr.h habria que agregar junto a las syscalls la definicion de la funcion:

```h
void _isr80();
void _isr88();
void _isr98();
```

Y lo siguiente que deberiamos modificar seria agregar en isr.asm la rutina de atencion de la interrupcion.


B) Voy a asumir que una tarea no va llamar a la compartida hasta que esta termine. Si quisiera forzar esto lo unico que tendria que agregar son mas condicionales.

La rutina de atencion seria:
```asm
global _isr80 
  _isr80:
    pushad
    ; Guardamos en la pila el eax actual de nuevo 
    push eax
    ltr ax
    push ax
    call pause_task
    add esp, 2 ; Restauramos la pila
    push [shared_selector]
    call pisar_eax_shared_task

    popad 
    iret

```
En `sched.c` agregamos la funcion: 

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

Y en `tss.c` agregamos la funcion: 

```c
void pisar_eax(uint16_t selector, uint32_t dato_a_poner){
  uint16_t idx = segsel >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

  uint32_t* stack_pointer = tss_pointer->esp;

  stack_pointer[7] = dato_a_poner;
}
```
