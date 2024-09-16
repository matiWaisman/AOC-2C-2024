#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <float.h>

#include "test-utils.h"
#include "ej1.h"

int main(){
    char* result1 = cesar_asm("CASA", 3);
    char* result2 = cesar_asm("CALABAZA", 7);
    if (strcmp(result1, "FDVD") == 0) {
        printf("Test 1 PASSED\n");
    }
    else{
        printf("Test 1 Failed\n");
        printf("Contenido de la cadena 1: %s\n", result1);
    }
    if (strcmp(result2, "JHSHIHGH") == 0) {
        printf("Test 2 PASSED\n");
    }
    else{
        printf("Test 2 Failed\n");
        printf("Contenido de la cadena 2: %s\n", result2);
    }
    free(result1);
    free(result2);
    return 0;
}