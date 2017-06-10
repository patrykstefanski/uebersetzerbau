%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"

void yyerror(const char *message);
int yylex(void);
extern int yylineno;

enum type {
    LABEL    = 1,
    VARIABLE = 2,
};

struct symbol {
    struct symbol *next;
    const char    *string;
    enum type     type;
};

void
must_exist(struct symbol *symbols, const char *string, int type);

struct symbol *
add_unique(struct symbol *symbols, const char *string, enum type type);

%}

%start program

%token ARROW
%token ASSIGNMENT
%token BREAK
%token CONTINUE
%token DO
%token END
%token ID
%token NOT
%token NUM
%token OR
%token RETURN
%token VAR

@traversal @preorder check

@attributes { char *string; } ID label_definition
@attributes { struct symbol *symbols; } args do_stat expr guarded guarded_list label_use lexpr mul_terms or_terms pars plus_terms stats term unary_term

%%

program
:
| program funcdef ';'
;

funcdef
: ID '(' pars ')' stats END @{ @i @stats.symbols@ = @pars.symbols@; @}
;

pars
:             @{ @i @pars.symbols@ = NULL; @}
| ID          @{ @i @pars.symbols@ = add_unique(NULL, @ID.string@, VARIABLE); @}
| ID ',' pars @{ @i @pars.0.symbols@ = add_unique(@pars.1.symbols@, @ID.string@, VARIABLE); @}
;

stats
:
| RETURN expr ';' stats            @{ @i @expr.symbols@ = @stats.0.symbols@;
                                      @i @stats.1.symbols@ =  @stats.0.symbols@; @}
| do_stat ';' stats                @{ @i @do_stat.symbols@ = @stats.0.symbols@;
                                      @i @stats.1.symbols@ = @stats.0.symbols@; @}
| VAR ID ASSIGNMENT expr ';' stats @{ @i @expr.symbols@ = @stats.0.symbols@;
                                      @i @stats.1.symbols@ = add_unique(@stats.0.symbols@, @ID.string@, VARIABLE); @}
| lexpr ASSIGNMENT expr ';' stats  @{ @i @lexpr.symbols@ = @stats.0.symbols@;
                                      @i @expr.symbols@ = @stats.0.symbols@;
                                      @i @stats.1.symbols@ = @stats.0.symbols@; @}
| term ';' stats                   @{ @i @term.symbols@ = @stats.0.symbols@;
                                      @i @stats.1.symbols@ = @stats.0.symbols@; @}
;

do_stat
: label_definition DO guarded_list END @{ @i @guarded_list.symbols@ = add_unique(@do_stat.symbols@, @label_definition.string@, LABEL); @}
;

label_definition
:        @{ @i @label_definition.string@ = NULL; @}
| ID ':' @{ @i @label_definition.string@ = @ID.string@; @}
;

guarded_list
:
| guarded_list guarded ';' @{ @i @guarded_list.1.symbols@ = @guarded_list.0.symbols@;
                              @i @guarded.symbols@ = @guarded_list.0.symbols@; @}
;

guarded
: expr ARROW stats control_pass label_use @{ @i @expr.symbols@ = @guarded.symbols@;
                                             @i @stats.symbols@ = @guarded.symbols@;
                                             @i @label_use.symbols@ = @guarded.symbols@; @}
;

control_pass
: CONTINUE
| BREAK
;

label_use
:
| ID @{ @check must_exist(@label_use.symbols@, @ID.string@, LABEL); @}
;

lexpr
: ID       @{ @check must_exist(@lexpr.symbols@, @ID.string@, VARIABLE); @}
| term '^' @{ @i @term.symbols@ = @lexpr.symbols@; @}
;

expr
: unary_term    @{ @i @unary_term.symbols@ = @expr.symbols@; @}
| term '^'      @{ @i @term.symbols@ = @expr.symbols@; @}
| plus_terms    @{ @i @plus_terms.symbols@ = @expr.symbols@; @}
| mul_terms     @{ @i @mul_terms.symbols@ = @expr.symbols@; @}
| or_terms      @{ @i @or_terms.symbols@ = @expr.symbols@; @}
| term '<' term @{ @i @term.0.symbols@ = @expr.symbols@;
                   @i @term.1.symbols@ = @expr.symbols@; @}
| term '=' term @{ @i @term.0.symbols@ = @expr.symbols@;
                   @i @term.1.symbols@ = @expr.symbols@; @}
;

unary_term
: NOT unary_term @{ @i @unary_term.1.symbols@ = @unary_term.0.symbols@; @}
| '-' unary_term @{ @i @unary_term.1.symbols@ = @unary_term.0.symbols@; @}
| term           @{ @i @term.symbols@ = @unary_term.symbols@; @}
;

plus_terms
: term '+' term       @{ @i @term.0.symbols@ = @plus_terms.symbols@;
                         @i @term.1.symbols@ = @plus_terms.symbols@; @}
| plus_terms '+' term @{ @i @plus_terms.1.symbols@ = @plus_terms.0.symbols@;
                         @i @term.symbols@ = @plus_terms.0.symbols@; @}
;

mul_terms
: term '*' term      @{ @i @term.0.symbols@ = @mul_terms.symbols@;
                        @i @term.1.symbols@ = @mul_terms.symbols@; @}
| mul_terms '*' term @{ @i @mul_terms.1.symbols@ = @mul_terms.0.symbols@;
                        @i @term.symbols@ = @mul_terms.0.symbols@; @}
;

or_terms
: term OR term     @{ @i @term.0.symbols@ = @or_terms.symbols@;
                      @i @term.1.symbols@ = @or_terms.symbols@; @}
| or_terms OR term @{ @i @or_terms.1.symbols@ = @or_terms.0.symbols@;
                      @i @term.symbols@ = @or_terms.0.symbols@; @}
;

args
:
| expr          @{ @i @expr.symbols@ = @args.symbols@; @}
| expr ',' args @{ @i @expr.symbols@ = @args.0.symbols@;
                   @i @args.1.symbols@ = @args.0.symbols@; @}
;

term
: '(' expr ')'    @{ @i @expr.symbols@ = @term.symbols@; @}
| NUM
| ID              @{ @check must_exist(@term.symbols@, @ID.string@, VARIABLE); @}
| ID '(' args ')' @{ @i @args.symbols@ = @term.symbols@; @}
;

%%

static int
exists(struct symbol *symbols, const char *string, int type)
{
    while (symbols != NULL) {
        if ((type == 0 || symbols->type == type) &&
                strcmp(symbols->string, string) == 0) {
            return 1;
        }
        symbols = symbols->next;
    }
    return 0;
}

void
must_exist(struct symbol *symbols, const char *string, int type)
{
    if (exists(symbols, string, type) == 0) {
        (void) fprintf(stderr, "symbol %s doesn't exist in the scope\n", string);
        exit(3);
    }
}

#if 0
void
dump_symbols(struct symbol *symbols)
{
    (void) printf("Symbols:");
    while (symbols != NULL) {
        (void) printf(" %s", symbols->string);
        symbols = symbols->next;
    }
    (void) putchar('\n');
}
#endif

struct symbol *
add_unique(struct symbol *symbols, const char *string, enum type type)
{
    struct symbol *node;
    if (string == NULL) {
        return symbols;
    }
    if (exists(symbols, string, 0) != 0) {
        (void) fprintf(stderr, "symbol %s is already defined\n", string);
        exit(3);
    }
    node = xalloc(sizeof(*node));
    node->next = symbols;
    node->string = string;
    node->type = type;
    /* dump_symbols(node); */
    return node;
}

void
yyerror(const char *message)
{
    (void) fprintf(stderr, "line %d: %s\n", yylineno, message);
    exit(2);
}

int
main(void)
{
    yyparse();
    return 0;
}
