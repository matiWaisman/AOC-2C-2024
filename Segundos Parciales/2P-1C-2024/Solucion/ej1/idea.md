Idea: 

    La tarea espiadora va a tener que llamar desde su código a una interrupción de software definida para esta syscall. La interrupción tiene que estar entre la 32 y 255 que son las interrupciones definidas para interrupciones de usuario. Considerando las que teníamos definidas de los talleres y que por lo general las syscalls son interrupciones mayores a 80, elijo que sea la 80.

Para la interrupción hay que agregarle una entrada en la idt y especificar en su descriptor que pueda ser llamada desde nivel 3 pero que el codigo que ejecute sea de nivel 0. Por lo que en el archivo `idt.c` habría que agregarla en `idt_init()` poniéndolo junto a las syscalls, quedando:

    ```c
    // COMPLETAR: Syscalls
    IDT_ENTRY3(80); // Definición de la syscall espiadora
    IDT_ENTRY3(88);
    IDT_ENTRY3(98);

    Para pasarle los parametros vamos a usar los registros eax para el selector de la tarea a espiar, edi para la direccion virtual de la tarea a espiar y en esi la direccion virtual a escribir de la tarea espia. 

    Una vez dentro de la rutina de atención y del setup habitual vamos a llamar a una función de C que reciba como parametro 

    Una vez dentro de la rutina de atención y del setup habitual vamos a llamar a una función de C que lo que haga sea con el selector de la tarea a espiar acceda a su tss descriptor dentro de la gdt y con el descriptor acceda a la tss y de ahí extraiga el CR3 de la tarea a espíar. 

    Una vez que tenemos el CR3 de la tarea a espiar tenemos que hacer un proceso muy similar al de map_page en el cual vamos a acceder a la memoria fisica de la pagina de la tarea a espíar. En el proceso si no esta presente o la pde o la pte de la dirección virtual vamos a devolver 1.  
