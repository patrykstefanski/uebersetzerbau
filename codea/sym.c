#include "common.h"
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static bool
exists_any(struct symbol *symbols, const char *string)
{
    assert(string != NULL);
    while (symbols != NULL) {
        if (strcmp(symbols->string, string) == 0) {
            return true;
        }
        symbols = symbols->next;
    }
    return false;
}

struct symbol *
sym_add_label(struct symbol *symbols, const char *string)
{
    struct symbol *node;
    if (string == NULL) {
        return symbols;
    }
    if (exists_any(symbols, string)) {
        (void) fprintf(stderr, "symbol %s redefined\n", string);
        exit(3);
    }
    node = alloc(sizeof(*node));
    node->next = symbols;
    node->string = string;
    node->type = SYM_LABEL;
    node->reg = -1;
    return node;
}

struct symbol *
sym_add_var(struct symbol *symbols, const char *string)
{
    struct symbol *node;
    if (string == NULL) {
        return symbols;
    }
    if (exists_any(symbols, string)) {
        (void) fprintf(stderr, "symbol %s redefined\n", string);
        exit(3);
    }
    node = alloc(sizeof(*node));
    node->next = symbols;
    node->string = string;
    node->type = SYM_VAR;
    /* Allocate a register for the variable. */
    while (symbols != NULL && symbols->type == SYM_LABEL) {
        symbols = symbols->next;
    }
    if (symbols != NULL) {
        if (symbols->reg == REG_END) {
            (void) fputs("No more free registers for variables\n", stderr);
            exit(4);
        }
        node->reg = symbols->reg + 1;
    } else {
        node->reg = REG_START;
    }
    return node;
}

struct symbol *
sym_lookup_label(struct symbol *symbols, const char *name)
{
    while (symbols != NULL) {
        if (symbols->type == SYM_LABEL && strcmp(symbols->string, name) == 0) {
            return symbols;
        }
        symbols = symbols->next;
    }
    (void) fprintf(stderr, "the label '%s' doesn't exist in the scope\n",
            name);
    exit(3);
}

struct symbol *
sym_lookup_var(struct symbol *symbols, const char *name)
{
    while (symbols != NULL) {
        if (symbols->type == SYM_VAR && strcmp(symbols->string, name) == 0) {
            return symbols;
        }
        symbols = symbols->next;
    }
    (void) fprintf(stderr, "the variable '%s' doesn't exist in the scope\n",
            name);
    exit(3);
}

long
sym_needed_registers(struct symbol *symbols)
{
    long registers = 0;
    size_t reg = 0;
    while (symbols != NULL) {
        if (symbols->type == SYM_VAR) {
            reg = symbols->reg;
            break;
        }
        symbols = symbols->next;
    }
    while (reg >= REG_START) {
        registers |= (1 << reg);
        --reg;
    }
    return registers;
}
