A) El esquema seria el mismo que el taller pero agregando que la parte de memoria virtual asignada a compartido va a estar de 0x08004000 a 0x08005FFF. Esta parte va a ser read-write y de nivel 3. Esa direccion virtual o va a apuntar a la pantalla real en memoria fisica o a la dummy. 

Tambien cada tarea va a tener su propia direccion fisica para la pila de nivel 3 y codigo de nivel 3 dentro del kernel. 

B) En init_task_dir habria que agregar el mapeo de la direccion virtual del video a la fisica de la dummy. 

En defines deberiamos agregar la constante de la direccion fisica de la pantalla real y la dummy y la direccion virtual de la pantalla. 

```h
// direccion virtual del video
#define TASK_VIDEO_MEM_START  0x08004000
#define TASK_VIDEO_MEM_END  0x08005FFF

// direccion fisica del video real y el dummy
#define REAL_VIDEO_MEM_START  0xB8000
#define REAL_VIDEO_MEM_END 0xB9FFF
#define DUMMY_VIDEO_MEM_START 0x1E000
#define DUMMY_VIDEO_MEM_END 0x1FFFF
```

Dentro de init task dir habria que mapear las dos paginas de video. 

```c
paddr_t mmu_init_task_dir(paddr_t phy_start) {
  // Inicializamos la tarea y hacemos que apunte al kernel
  paddr_t pd = mmu_next_free_kernel_page();
  copy_page(pd, (paddr_t)kpd);
  //copiamos la page table del kernel
  paddr_t pt = mmu_next_free_kernel_page();
  copy_page(pt, (paddr_t)kpt);

  // Inicializamos las dos paginas para el codigo nivel 3 read only
  mmu_map_page(pd, TASK_CODE_VIRTUAL, phy_start, READ_ONLY_USER_ATTR);

  mmu_map_page(pd,TASK_CODE_VIRTUAL + PAGE_SIZE, phy_start + PAGE_SIZE, READ_ONLY_USER_ATTR); // Preguntar si no hay que incrementar phy start

  // Definimos la pila en el area libre de kernel
  // El area libre de tareas va a ser para usuario, asi que lo hacemos dentro de una pagina nueva
 
  mmu_map_page(pd, TASK_STACK_BASE - PAGE_SIZE, mmu_next_free_user_page(), READ_WRITE_USER_ATTR);
  // Como la pila va de abajo hacia arriba le restamos para que arranque en 8k - 1 en vez de 4k
  // Definimos el compartido en kernel
  //phy_shared_init
  mmu_map_page(pd, TASK_SHARED_PAGE, SHARED, READ_ONLY_USER_ATTR); 

  // Mapeos memoria de video

  mmu_map_page(pd, TASK_VIDEO_MEM_START, DUMMY_VIDEO_MEM_START, READ_WRITE_USER_ATTR);

  mmu_map_page(pd, TASK_VIDEO_MEM_END, DUMMY_VIDEO_MEM_END, READ_WRITE_USER_ATTR);

  return (paddr_t) pd;
}
```

En las demas funciones no habria que cambiar nada ya que siemrpre llaman a esta la cual es la que reserva la memoria nueva que tenemos para video.

C y D) Si el cambio de acceso de pantalla es ciclico se parece mucho al scheduler. Lo que podemos hacer es construir un "sistema" analogo al scheduler que determine a que tarea le toca, y en vez de que se cambie de tarea con el cambio de clock se va a cambiar de video cuando en la interrupcion de teclado se detecte que se solto el tab. 

Asumo que al principio nadie escribe en la pantalla real y se hace el cambio unicamente al soltar el tab. 

Como voy a empezar sin ninguna tarea con video no hace falta hacer una inicializacion como init_task_dir en sched. Lo unico que voy a hacer es agregar una variable global que indique que tarea tiene video en ese momento y agregar la funcion ```sched_next_video``` que determina el selector de la siguiente tarea a darle video. Entonces en ```sched.c``` agrego:

```c
/**
 * Tarea actualmente en ejecución (excepto que esté pasuada, en cuyo caso se
 * corre la idle).
 */
int8_t current_task = 0;
int8_t current_task_with_video = 0;

void sched_next_video(void) {
  // Buscamos la próxima tarea viva (comenzando en la actual)
  int8_t i;
  for (i = (current_task_with_video + 1); (i % MAX_TASKS) != current_task_with_video; i++) {
    // Si esta tarea está disponible la ejecutamos
    if (sched_tasks[i % MAX_TASKS].state == TASK_RUNNABLE) {
      int16_t i_selector = sched_tasks[i % MAX_TASKS].selector;
      int16_t idx = i_selector >> 3;
      if(idx != GDT_IDX_TASK_IDLE && idx != GDT_IDX_TASK_INITIAL){ // Para no darle video ni a la inicial ni a la idle nunca
        current_task_with_video = i % MAX_TASKS;
      }
    }
  }
  // Asumo que nunca va a quedar ninguna tarea sin video
}
```

Ahora es modifico la interrupcion de teclado para que se fije si la tecla que produjo la interrupcion fue que se solto el tab y en ese caso cambiar el video.

Le agregamos la variable compartida entre ```sched``` y ```ism``` current_task_with_video agregandola al principio de ```isr.asm``` como un extern. 

```asm
global _isr33

_isr33:
    pushad
    ; 1. Le decimos al PIC que vamos a atender la interrupción
    call pic_finish1
    ; 2. Leemos la tecla desde el teclado y la procesamos
    in al, 0x60
    cmp al, 0x8F
    jne .fin
    ; Si estamos aca es porque hay que cambiar el video
    ; Si el video actual es de la idle o la inicial no se lo desabilitamos porque nunca se lo dimos en primer lugar. Esto solo puede pasar la primer vez que se suelta el tab porque no habia ninguna tarea asignada
    cmp  [current_task_with_video], GDT_IDX_TASK_IDLE
    je .habilitar
    cmp  [current_task_with_video], GDT_IDX_TASK_INITIAL
    je .habilitar
    ; Si estamos aca hay que deshabilitar el video de la tarea actual
    ; Primero obtenemos su selector
    call selector_video_actual
    push ax
    call cr3_de_selector
    push eax
    call deshabilitar_video
    .habilitar: 
        call sched_next_video
        call selector_video_actual
        push ax
        call cr3_de_selector
        push eax
        call habilitar_video 
    .fin:
        push eax
        call tasks_input_process
        add esp, 4
        popad
        iret
```
Con las funciones auxiliares: 

En ```sched.c```:

```c
int16_t selector_video_actual(void){
    return sched_tasks[current_task_with_video].selector;
}
```

En ```tss.c```:
```c
uint32_t cr3_de_selector(int16_t segsel){
    int16_t idx = segsel >> 3;

    tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

    return tss_pointer->cr3;
}
```
En ```mmu.c```: 

```c
void deshabilitar_video(uint32_t cr3_a_deshabilitar){
    mmu_unmap_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_START);
    mmu_unmap_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_END);

    mmu_map_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_START, DUMMY_VIDEO_MEM_START, MMU_U | MMU_P | MMU_W);
    mmu_map_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_START, DUMMY_VIDEO_MEM_END, MMU_U | MMU_P | MMU_W);
}

void habilitar_video(uint32_t cr3_a_habilitar){
    mmu_unmap_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_START);
    mmu_unmap_page(cr3_a_deshabilitar, TASK_VIDEO_MEM_END);

    mmu_map_page(cr3_a_habilitar, TASK_VIDEO_MEM_START, REAL_VIDEO_MEM_START, MMU_U | MMU_P | MMU_W);
    mmu_map_page(cr3_a_habilitar, TASK_VIDEO_MEM_START, REAL_VIDEO_MEM_END, MMU_U | MMU_P | MMU_W);
}
```

E) Una manera de que las tareas sepan cual tarea tiene la pantalla es agregar una syscall que devuelva el id de la tarea que esta usando la pantalla actualmente. 