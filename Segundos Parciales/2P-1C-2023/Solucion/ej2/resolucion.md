La pagina debe ser escrita a disco si el bit present en la pde y pte que apuntan a esa direccion fisica en el cr3 de la tarea esta en 0 en ambos o si no encontramos que este mapeada esa direccion fisica en las estructuras de paginacion definidas en el cr3 que nos pasan. Si encontramos que esta mapeada esa direccion y esta presente no lo vamos a cargar en disco. 

```c
uint8_t escribir_a_disco(uint32_t cr3, paddr_t phy){
  pd_entry_t* page_directory = (pd_entry_t*) CR3_TO_PAGE_DIR(cr3);
  for(uint32_t i = 0; i < 1024; i++){
    pt_entry_t* page_table_pointer = (pt_entry_t*)MMU_ENTRY_PADDR(page_directory[i].pt);
    for(uint32_t j = 0; j < 1024; j++){
      if(page_table_pointer[j].attrs & 0x20 && phy = page_table_pointer[j].page){
          // Si esta dirty porque se escribio y apunta a la direccion que estamos buscando devolvemos 0 porque esta tarea la escribio.
          return 0;
      }
    }
  }
  // Si llegamos aca es porque no esta mapeada la direccion, por lo que podemos escribir a disco
  return 1;
}
```