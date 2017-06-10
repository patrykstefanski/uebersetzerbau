#ifndef COMMON_H
#define COMMON_H

#include <stdbool.h>
#include <stddef.h>

#define SWAP(a, b) do {    \
    __typeof__(a) tmp = a; \
    a = b;                 \
    b = tmp;               \
} while (0)

/*
 * The allowed operators in an abstract syntax tree.
 * The order must be the same as specified in the codegen.
 */
enum {
    OP_ADD      = 1,
    OP_ARG      = 2,
    OP_BIGCONST = 3,
    OP_CALL     = 4,
    OP_CONST    = 5,
    OP_EQ       = 6,
    OP_GUARD    = 7,
    OP_JMPNE    = 8,
    OP_JMPNL    = 9,
    OP_LT       = 10,
    OP_MUL      = 11,
    OP_NEG      = 12,
    OP_NOT      = 13,
    OP_OR       = 14,
    OP_READ     = 15,
    OP_STRING   = 16,
    OP_VAR      = 17,
    OP_WRITE    = 18,
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

typedef struct ast_node *NODEPTR_TYPE;

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
    const char      *string;
    long            value;
    int             operator;
    int             reg;
};

#define IS_OP_CONST(node) \
    ((node)->operator == OP_BIGCONST || (node)->operator == OP_CONST)

struct symbol {
    struct symbol *next;
    const char    *string;
    /* Use for labels to make them unique. */
    size_t        counter;
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
ast_guard(void);

struct ast_node *
ast_operator(int operator, struct ast_node *left, struct ast_node *right);

struct ast_node *
ast_string(const char *string);

struct ast_node *
ast_var(int reg);

void
generate_call(const char *name);

void
generate_control_pass(struct symbol *label, size_t depth, bool forward);

void
generate_do_begin(struct symbol *label, size_t depth);

void
generate_do_end(struct symbol *label, size_t depth);

void
generate_function_begin(const char *name);

void
generate_function_end(const char *name);

void
generate_guarded(struct ast_node *expr, size_t depth, size_t used_regs);

void
generate_return(struct ast_node *expr, size_t used_regs);

void
generate_term(struct ast_node *expr, size_t used_regs);

void
generate_var_assignment(struct ast_node *expr, int reg, size_t used_regs);

void
generate_var_definition(struct ast_node *expr, size_t used_regs);

void
generate_write(struct ast_node *left, struct ast_node *right, size_t used_regs);

struct symbol *
sym_add_label(struct symbol *symbols, const char *string);

struct symbol *
sym_add_var(struct symbol *symbols, const char *string);

struct symbol *
sym_lookup_label(struct symbol *symbols, const char *name);

struct symbol *
sym_lookup_var(struct symbol *symbols, const char *name);

size_t
sym_needed_registers(struct symbol *symbols);

#endif /* !COMMON_H */
