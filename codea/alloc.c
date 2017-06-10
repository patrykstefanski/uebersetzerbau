#include "common.h"
#include <stdio.h>
#include <stdlib.h>

void *
alloc(size_t size)
{
    void *ptr;
    ptr = calloc(1, size);
    if (ptr != NULL) {
        return ptr;
    }
    (void) fputs("Out of memory\n", stderr);
    exit(4);
}
