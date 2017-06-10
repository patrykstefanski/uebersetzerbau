#ifndef COMMON_H
#define COMMON_H

#include <stddef.h>

/*
 * The allowed operators in an abstract syntax tree.
 * The order must be the same as specified in the codegen.
 */
enum {
    OP_ADD    = 1,
    OP_CONST  = 2,
    OP_EQ     = 3,
    OP_FUNC   = 4,
    OP_LT     = 5,
    OP_MUL    = 6,
    OP_NEG    = 7,
    OP_NOT    = 8,
    OP_OR     = 9,
    OP_READ   = 10,
    OP_RETURN = 11,
    OP_WRITE  = 12,
    OP_VAR    = 13,
};

/*
 * Parameters and variables will be stored in the described bellow order i.e.
 * RDI, RSI, ..., the temporary variables in the reverse order i.e RAX, R11, ...
 */
enum {
    REG_RDI = 1,
    REG_RSI,
    REG_RDX,
    REG_RCX,
    REG_R8,
    REG_R9,
    REG_R10,
    REG_R11,
    REG_RAX,
};

enum {
    REG_START = REG_RDI,
    REG_END   = REG_RAX,
};

/* Symbol type. */
enum {
    SYM_ANY,
    SYM_LABEL,
    SYM_VAR,
};

/* These definitions are required for iburg. */

typedef struct ast_node   *NODEPTR_TYPE;

#ifdef USE_IBURG
    #ifndef BURM
        typedef struct burm_state *STATEPTR_TYPE;
    #endif
#else
    #define STATEPTR_TYPE int
#endif

struct ast_node {
    STATEPTR_TYPE   state;
    struct ast_node *kids[2];
    long            value;
    int             operator;
    int             reg;
    const char      *string;
};

struct symbol {
    struct symbol *next;
    const char    *string;
    int           type;
    int           reg;
};

void *
alloc(size_t size);

struct ast_node *
ast_constant(long value);

struct ast_node *
ast_function(const char *name, struct ast_node *stats, long registers);

struct ast_node *
ast_operator(int operator, struct ast_node *left, struct ast_node *right);

struct ast_node *
ast_var(int reg);

void
generate_function(struct ast_node *root);

struct symbol *
sym_add_label(struct symbol *symbols, const char *string);

struct symbol *
sym_add_var(struct symbol *symbols, const char *string);

struct symbol *
sym_lookup_label(struct symbol *symbols, const char *name);

struct symbol *
sym_lookup_var(struct symbol *symbols, const char *name);

long
sym_needed_registers(struct symbol *symbols);

#endif /* !COMMON_H */
