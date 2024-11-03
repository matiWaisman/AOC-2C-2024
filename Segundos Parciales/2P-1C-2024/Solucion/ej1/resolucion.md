Idea: 

La tarea espiadora va a tener que llamar desde su código a una interrupción de software definida para esta syscall. La interrupción tiene que estar entre la 32 y 255 que son las interrupciones definidas para interrupciones de usuario. Considerando las que teníamos definidas de los talleres y que por lo general las syscalls son interrupciones mayores a 80, elijo que sea la 80.

Para la interrupción hay que agregarle una entrada en la idt y especificar en su descriptor que pueda ser llamada desde nivel 3 pero que el codigo que ejecute sea de nivel 0. Por lo que en el archivo `idt.c` habría que agregarla en `idt_init()` poniéndolo junto a las syscalls, quedando:

```c
// COMPLETAR: Syscalls
IDT_ENTRY3(80); // Definición de la syscall espiadora
IDT_ENTRY3(88);
IDT_ENTRY3(98);
```

Para pasarle los parametros vamos a usar los registros eax para el selector de la tarea a espiar, edi para la direccion virtual de la tarea a espiar y en esi la direccion virtual a escribir de la tarea espia. 

Una vez dentro de la rutina de atención y del setup habitual vamos a llamar a una función de C que se encargue de hacer todo el proceso. 

El codigo de la interrupción dentro de isr.asm va a ser: 

```asm
global _isr80 
  _isr80:
    pushad
    push ESI
    push EDI
    push EAX
    call espiar

    ;acomodo la pila
    add ESP, 12
    ;Para no pisar el resultado con el popad
    mov [ESP+offset_EAX], eax

    popad
    iret
```

Luego desde esa funcion vamos a llamar a otra que reciba como parametro el selector de la tarea a espiar.
Esta función va a con el selector obtener el TSS descriptor de la GDT y con ese descriptor obtener el cr3 guardado de la tarea a espíar en su tss y devolver el cr3.

```c
uint32_t obtener_cr3(uint16_t segsel){
  uint16_t idx = segsel >> 3;

  tss_t* tss_pointer = (tss_t*)((gdt[idx].base_15_0) | (gdt[idx].base_23_16 << 16) | (gdt[idx].base_31_24 << 24));

  return tss_pointer->cr3;
}
```
Luego vamos a llamar a otra función que se va a encargar de determinar si se encuentra o no presente la pagina en memoria. La función recibe por parametros el cr3 y direccion virtual que queremos espiar.  
Para esto al principio de la función vamos a hacer lo mismo que hacemos en mmu.map_page, buscando la pde y pte que vienen en el cr3 y si no se encuentran devolvemos false.

```c
bool mmu_page_present(uint32_t cr3, vaddr_t virt){
  uint32_t directory_index = VIRT_PAGE_DIR(virt); 
  uint32_t table_index = VIRT_PAGE_TABLE(virt);

  pd_entry_t* page_directory = (pd_entry_t*) CR3_TO_PAGE_DIR(cr3);
  pd_entry_t dpt_entry = page_directory[directory_index]; //Convierte la direccion que obtuvimos para poder acceder a .pt y .attr
  uint32_t present_bit_directory = (dpt_entry.attrs) & MMU_P;

  if(!present_bit_directory){
    return false;
  }

  pt_entry_t* page_table_pointer = (pt_entry_t*)MMU_ENTRY_PADDR(page_directory[directory_index].pt) ;
  uint32_t present_bit_table = page_table_pointer[table_index].attrs & MMU_P;

  if(!present_bit_table){
    return false;
  }

  return true;
}
``` 

Si continuamos ahora llamamos a una funcion que obtenga el dato a leer de la tarea espiada y lo devuelva.

```c
uint32_t obtener_dato(uint32_t cr3, vaddr_t virt){
  uint32_t directory_index = VIRT_PAGE_DIR(virt); 
  uint32_t table_index = VIRT_PAGE_TABLE(virt);
  uint32_t offset = VIRT_PAGE_OFFSET(virt);

  pd_entry_t* page_directory = (pd_entry_t*) CR3_TO_PAGE_DIR(cr3);

  pt_entry_t* page_table_pointer = (pt_entry_t*)MMU_ENTRY_PADDR(page_directory[directory_index].pt);
  paddr_t direccion_dato_a_copiar  = page_table_pointer[table_index].page + offset;
  uint32_t* pointer_dato_a_copiar = (uint32_t*) direccion_dato_a_copiar;
  return &pointer_dato_a_copiar;
}
```

Por ultimo escribimos en la direccion virtual de la tarea espia. Como estamos en esa tarea no hace falta tocar el cr3.

Entonces la funcion de C queda: 

```c
int espiar(uint16_t selector, vaddr_t direccion_a_espiar, vaddr_t direccion_a_escribir){
    uint32_t cr3_tarea_espiada = obtener_cr3(selector);

    if(!mmu_page_present(cr3_tarea_espiada, direccion_a_espiar)){
        return 1;
    }   

    uint32_t dato_a_escribir = obtener_dato(cr3_tarea_espiada, direccion_a_espiar);
    uint32_t* puntero_a_escribir = (uint32_t*)direccion_a_espiar;
    puntero_a_escribir[0] = dato_a_escribir;

    return 0;
}
```