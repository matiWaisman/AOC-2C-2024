#include "ej1.h"

nodo_display_list_t* inicializar_nodo(
  uint8_t (*primitiva)(uint8_t x, uint8_t y, uint8_t z_size),
  uint8_t x, uint8_t y, nodo_display_list_t* siguiente) {
    nodo_display_list_t* nodo = malloc(sizeof(nodo_display_list_t));
    nodo->primitiva = primitiva;
    nodo->x = x;
    nodo->y = y;
    nodo->z = 255;
    nodo->siguiente = siguiente;
    return nodo;
}

ordering_table_t* inicializar_OT(uint8_t table_size) {
  ordering_table_t *res = malloc(sizeof(ordering_table_t));
  res->table_size = table_size;
  if(table_size == 0){
    res->table = NULL;
  }
  else{
    res->table = calloc(table_size, sizeof(nodo_ot_t*));
  }
  return res;

}

void calcular_z(nodo_display_list_t* nodo, uint8_t z_size) {
  while(nodo != NULL){
    nodo->z = nodo->primitiva(nodo->x, nodo->y, z_size);
    nodo = nodo->siguiente; 
  }
}

void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) {
  calcular_z(display_list, ot->table_size);
  
}
