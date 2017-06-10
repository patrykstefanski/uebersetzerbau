#include "util.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

void *
xalloc(size_t size)
{
    void *ptr;
    ptr = calloc(1, size);
    if (ptr != NULL) {
        return ptr;
    }
    (void) fputs("Out of memory\n", stderr);
    exit(3);
}
