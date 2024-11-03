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
  calcular_z(display_list, ot->table_size); // Con esto calculo el z para todos los nodos
  // Una vez que ya tengo calculado el z para todos los nodos tengo que recorrer la display_list
  // Para cada nodo de la display list dado su z lo tengo que ubicar en una posición del array
  // Una vez que ubico su posición del array tengo que recorrer la lista de nodos ot creando nodos nuevos al final
  while(display_list != NULL){ // Con este nodo recorro la display_list
    uint8_t z_actual = display_list->z;
    nodo_ot_t *nodo_ot_iterador = ot->table[z_actual];
    // Primero checkeo que el primer nodo no sea null, si no lo es hay que recorrer la lista de nodos ot
    if(nodo_ot_iterador == NULL){
      nodo_ot_t *nodo_a_crear = malloc(sizeof(nodo_ot_t));
      nodo_a_crear->display_element = display_list; // Hago que apunte al nodo de la display list actual
      nodo_a_crear->siguiente = NULL;
      ot->table[z_actual] = nodo_a_crear;
    }
    else{
      while(nodo_ot_iterador->siguiente != NULL){ // Con este ciclo recorro la lista de nodos ot del z actual para llegar al ultimo. Cuando llego al ultimo corto el ciclo y actualizo la estructura
        nodo_ot_iterador = nodo_ot_iterador->siguiente;
      } 
      // Cuando estamos aca es porque el siguiente nodo apunta a nada
      nodo_ot_t *nodo_a_crear = malloc(sizeof(nodo_ot_t));
      nodo_a_crear->display_element = display_list; // Hago que apunte al nodo de la display list actual
      nodo_a_crear->siguiente = NULL;
      nodo_ot_iterador->siguiente = nodo_a_crear; // El ultimo nodo ot apunta al nuevo
    }
    
   
  }
  
}
