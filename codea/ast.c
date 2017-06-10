#include "common.h"
#include <assert.h>
#include <stdbool.h>

/* Constant folds an expression. */
static struct ast_node *
fold(int operator, struct ast_node *left, struct ast_node *right)
{
    switch (operator) {
    /* The unary ops. */
    case OP_NEG:
    case OP_NOT:
        assert(left != NULL);
        if (left->operator != OP_CONST) {
            return NULL;
        }
        break;
    /* The arithmetic binary ops. */
    case OP_ADD:
    case OP_MUL:
    case OP_OR:
    /* The compare binary ops. */
    case OP_EQ:
    case OP_LT:
        assert(left != NULL);
        assert(right != NULL);
        if (left->operator != OP_CONST || right->operator != OP_CONST) {
            return NULL;
        }
        break;
    default:
        return NULL;
    }
    /* Do fold. */
    switch (operator) {
    /* The unary ops. */
    case OP_NEG:
        left->value = -left->value;
        break;
    case OP_NOT:
        left->value = ~left->value;
        break;
    /* The arithmetic binary ops. */
    case OP_ADD:
        left->value += right->value;
        break;
    case OP_MUL:
        left->value *= right->value;
        break;
    case OP_OR:
        left->value |= right->value;
        break;
    /* The compare binary ops. */
    case OP_EQ:
        left->value = left->value == right->value ? -1 : 0;
        break;
    case OP_LT:
        left->value = left->value < right->value ? -1 : 0;
        break;
    default:
        /* UNREACHABLE */
        assert(0);
    }
    return left;
}

static struct ast_node *
simplify_unary(int operator, struct ast_node *child)
{
    assert(child != NULL);
    switch (operator) {
    case OP_NEG:
        /* - - expr */
        if (child->operator == OP_NEG) {
            assert(child->kids[0] != NULL);
            return child->kids[0];
        }
        break;
    case OP_NOT:
        /* not not expr */
        if (child->operator == OP_NOT) {
            assert(child->kids[0] != NULL);
            return child->kids[0];
        }
        break;
    default:
        /* UNREACHABLE */
        assert(0);
    }
    return NULL;
}

static struct ast_node *
simplify_binary(int operator, struct ast_node *left, struct ast_node *right)
{
    struct ast_node *tmp;
    assert(left != NULL);
    assert(right != NULL);
    /* The rest require constant values. */
    if (left->operator != OP_CONST && right->operator != OP_CONST) {
        return NULL;
    }
    /* Prefer const on rhs. */
    if (left->operator == OP_CONST) {
        /* Should be folded. */
        assert(right->operator != OP_CONST);
        tmp = left;
        left = right;
        right = tmp;
    }
    switch (operator) {
    case OP_ADD:
        if (right->value == 0) {
            return left;
        }
        if (left->operator == OP_ADD) {
            if (left->kids[0]->operator == OP_CONST) {
                left->kids[0]->value += right->value;
                return left;
            }
            if (left->kids[1]->operator == OP_CONST) {
                left->kids[1]->value += right->value;
                return left;
            }
        }
        break;
    case OP_MUL:
        if (right->value == 0) {
            return right;
        }
        if (right->value == 1) {
            return left;
        }
        if (left->operator == OP_MUL) {
            if (left->kids[0]->operator == OP_CONST) {
                left->kids[0]->value *= right->value;
                return left;
            }
            if (left->kids[1]->operator == OP_CONST) {
                left->kids[1]->value *= right->value;
                return left;
            }
        }
        break;
    case OP_OR:
        if (right->value == 0) {
            return left;
        }
        if (right->value == -1) {
            return right;
        }
        if (left->operator == OP_OR) {
            if (left->kids[0]->operator == OP_CONST) {
                left->kids[0]->value |= right->value;
                return left;
            }
            if (left->kids[1]->operator == OP_CONST) {
                left->kids[1]->value |= right->value;
                return left;
            }
        }
        break;
    default:
        /* UNREACHABLE */
        assert(0);
    }
    return NULL;
}

/* Simplifies an expression. */
static struct ast_node *
simplify(int operator, struct ast_node *left, struct ast_node *right)
{
    switch (operator) {
    case OP_NEG:
    case OP_NOT:
        return simplify_unary(operator, left);
    case OP_ADD:
    case OP_MUL:
    case OP_OR:
        return simplify_binary(operator, left, right);
    default:
        return NULL;
    }
}

struct ast_node *
ast_constant(long value)
{
    struct ast_node *node;
    node = alloc(sizeof(*node));
    node->value = value;
    node->operator = OP_CONST;
    return node;
}

struct ast_node *
ast_function(const char *name, struct ast_node *stats, long registers)
{
    struct ast_node *node;
    node = alloc(sizeof(*node));
    node->kids[0] = stats;
    node->value = registers;
    node->operator = OP_FUNC;
    node->string = name;
    return node;
}

struct ast_node *
ast_operator(int operator, struct ast_node *left, struct ast_node *right)
{
    struct ast_node *node;
    node = fold(operator, left, right);
    if (node != NULL) {
        return node;
    }
    node = simplify(operator, left, right);
    if (node != NULL) {
        return node;
    }
    node = alloc(sizeof(*node));
    node->kids[0] = left;
    node->kids[1] = right;
    node->operator = operator;
    return node;
}

struct ast_node *
ast_var(int reg)
{
    struct ast_node *node;
    node = alloc(sizeof(*node));
    node->reg = reg;
    node->operator = OP_VAR;
    return node;
}
