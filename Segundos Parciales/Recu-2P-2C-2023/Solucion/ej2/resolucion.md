A) 

B) La tarea que quiere copiar la pagina de la otra va a tener que llamar desde su código a una interrupción de software definida para esta syscall. La interrupción tiene que estar entre la 32 y 255 que son las interrupciones definidas para interrupciones de usuario. Considerando las que teníamos definidas de los talleres y que por lo general las syscalls son interrupciones mayores a 80, elijo que sea la 80.

Para la interrupción hay que agregarle una entrada en la idt y especificar en su descriptor que pueda ser llamada desde nivel 3 pero que el codigo que ejecute sea de nivel 0. Por lo que en el archivo idt.c habría que agregarla en idt_init() poniéndolo junto a las syscalls, quedando:

```c
// COMPLETAR: Syscalls
IDT_ENTRY3(80); // Definición de la syscall que copia
IDT_ENTRY3(88);
IDT_ENTRY3(98);
```

Tambien algo que esta incluido en el mapa anterior pero que es necesario recalcar es que vamos a tener que agregar a la hora de crear las tareas que 