CC :=gcc
CFLAGS += -Wall -Wextra -O0 -ggdb -lm -Wno-unused-variable -Wno-unused-parameter -no-pie
TARGETS:= tests_ej1 
NASM=nasm
NASMFLAGS=-f elf64 -g -F DWARF


# Target default, corre todos los targets de compilación, que declaramos en la variable TARGETS
all: $(TARGETS)

# Declara targets run_tests_vector, run_tests_contar_espacios, run_tests_lista_enlazada, run_tests_classify_chars
# Que permiten correr los tests con valgrind
RUN := $(patsubst %,run_%, $(TARGETS))

# Target para borrar binarios compilados y archivos objeto
clean:
	rm -f *.o $(TARGETS)

# Crea targets declarados en la variable RUN
# Corre el binario correspondiente con valgrind (el nombre del binario corrido sera la parte después de run_ del target)
# Esto obedece una Static Pattern Rule, que limita la regla del target a los archivos especificados por la variable (en este caso RUN)
# Todos los archivos de RUN se evaluan contra la expresión posterior (run_%) y se extrae la "stem" a la expresión %.
# Usamos esa expresión para armar las dependencias (en este caso los binarios tests_lista_enlazada, tests_vector, etc).
# En el cuerpo del target, la stem extraída (antes %) se puede acceder con la expresión $* (ya no con %)
# Más información: https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
$(RUN): run_%: % 
	valgrind --show-reachable=yes --leak-check=full --error-exitcode=1 ./$* \
	&& echo "No se detectaron errores de memoria" 

tests_ej1: tests_ej1.o ej1.o
	$(CC) $(CFLAGS) $^ -o $@

ej1.0 : ej1.c

.PHONY: all clean $(RUN) 
