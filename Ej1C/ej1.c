#include "ej1.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uint32_t longitud_de_string(char* string) {
    uint32_t res = 0;
    while (string[res] != '\0') {
        res++;
    }
    return res;
}

char* cesar(char* source, uint32_t x) {
    uint32_t len = longitud_de_string(source);
    char* res = (char*)malloc(len + 1); 
    for (uint32_t i = 0; i < len; i++) {
        char c = source[i];
        uint32_t ord = c - 'A'; 
        uint32_t pos_chr = (ord + x) % 26; 
        res[i] = 'A' + pos_chr; 
    }
    res[len] = '\0';
    return res;
}
