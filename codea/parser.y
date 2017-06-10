%{

#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *message);
int yylex(void);
extern int yylineno;

%}

%start program

%token TK_ARROW
%token TK_ASSIGNMENT
%token TK_BREAK
%token TK_CONTINUE
%token TK_DO
%token TK_END
%token TK_ID
%token TK_NOT
%token TK_NUM
%token TK_OR
%token TK_RETURN
%token TK_VAR

@traversal @preorder check
@traversal @preorder codegen

@attributes { char *string; } TK_ID label_definition pars_last
@attributes { long value; } TK_NUM
@attributes { struct symbol *symbols; } args do_stat guarded guarded_list label_use lexpr pars pars_rec
@attributes { struct ast_node *node; struct symbol *symbols; } expr mul_terms or_terms plus_terms stats term unary_term

%%

program
:
| funcdef ';' program
;

funcdef
: TK_ID '(' pars ')' stats TK_END @{ @codegen generate_function(ast_function(@TK_ID.string@, @stats.node@, sym_needed_registers(@pars.symbols@)));
                                     @i @stats.symbols@ = @pars.symbols@; @}
;

pars
: pars_rec pars_last @{ @i @pars.symbols@ = sym_add_var(@pars_rec.symbols@, @pars_last.string@); @}
;

pars_rec
:                    @{ @i @pars_rec.symbols@ = NULL; @}
| pars_rec TK_ID ',' @{ @i @pars_rec.0.symbols@ = sym_add_var(@pars_rec.1.symbols@, @TK_ID.string@); @}
;

pars_last
:       @{ @i @pars_last.string@ = NULL; @}
| TK_ID @{ @i @pars_last.string@ = @TK_ID.string@; @}
;

stats
:                                           @{ @i @stats.0.node@ = NULL; @}
| TK_RETURN expr ';' stats                  @{ @i @stats.0.node@ = ast_operator(OP_RETURN, @expr.node@, NULL);
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.symbols@ =  @stats.0.symbols@; @}
| do_stat ';' stats                         @{ @i @stats.0.node@ = NULL;
                                               @i @do_stat.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| TK_VAR TK_ID TK_ASSIGNMENT expr ';' stats @{ @i @stats.0.node@ = NULL;
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.symbols@ = sym_add_var(@stats.0.symbols@, @TK_ID.string@); @}
| lexpr TK_ASSIGNMENT expr ';' stats        @{ @i @stats.0.node@ = NULL;
                                               @i @lexpr.symbols@ = @stats.0.symbols@;
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| term ';' stats                            @{ @i @stats.0.node@ = NULL;
                                               @i @term.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
;

do_stat
: label_definition TK_DO guarded_list TK_END @{ @i @guarded_list.symbols@ = sym_add_label(@do_stat.symbols@, @label_definition.string@); @}
;

label_definition
:           @{ @i @label_definition.string@ = NULL; @}
| TK_ID ':' @{ @i @label_definition.string@ = @TK_ID.string@; @}
;

guarded_list
:
| guarded_list guarded ';' @{ @i @guarded_list.1.symbols@ = @guarded_list.0.symbols@;
                              @i @guarded.symbols@ = @guarded_list.0.symbols@; @}
;

guarded
: expr TK_ARROW stats control_pass label_use @{ @i @expr.symbols@ = @guarded.symbols@;
                                                @i @stats.symbols@ = @guarded.symbols@;
                                                @i @label_use.symbols@ = @guarded.symbols@; @}
;

control_pass
: TK_CONTINUE
| TK_BREAK
;

label_use
:
| TK_ID @{ @check sym_lookup_label(@label_use.symbols@, @TK_ID.string@); @}
;

lexpr
: TK_ID    @{ @check sym_lookup_var(@lexpr.symbols@, @TK_ID.string@); @}
| term '^' @{ @i @term.symbols@ = @lexpr.symbols@; @}
;

expr
: unary_term    @{ @i @expr.node@ = @unary_term.node@;
                   @i @unary_term.symbols@ = @expr.symbols@; @}
| term '^'      @{ @i @expr.node@ = ast_operator(OP_READ, @term.node@, NULL);
                   @i @term.symbols@ = @expr.symbols@; @}
| plus_terms    @{ @i @expr.node@ = @plus_terms.node@;
                   @i @plus_terms.symbols@ = @expr.symbols@; @}
| mul_terms     @{ @i @expr.node@ = @mul_terms.node@;
                   @i @mul_terms.symbols@ = @expr.symbols@; @}
| or_terms      @{ @i @expr.node@ = @or_terms.node@;
                   @i @or_terms.symbols@ = @expr.symbols@; @}
| term '<' term @{ @i @expr.node@ = ast_operator(OP_LT, @term.0.node@, @term.1.node@);
                   @i @term.0.symbols@ = @expr.symbols@;
                   @i @term.1.symbols@ = @expr.symbols@; @}
| term '=' term @{ @i @expr.node@ = ast_operator(OP_EQ, @term.0.node@, @term.1.node@);
                   @i @term.0.symbols@ = @expr.symbols@;
                   @i @term.1.symbols@ = @expr.symbols@; @}
;

unary_term
: TK_NOT unary_term @{ @i @unary_term.0.node@ = ast_operator(OP_NOT, @unary_term.1.node@, NULL);
                       @i @unary_term.1.symbols@ = @unary_term.0.symbols@; @}
| '-' unary_term    @{ @i @unary_term.0.node@ = ast_operator(OP_NEG, @unary_term.1.node@, NULL);
                       @i @unary_term.1.symbols@ = @unary_term.0.symbols@; @}
| term              @{ @i @unary_term.node@ = @term.node@;
                       @i @term.symbols@ = @unary_term.symbols@; @}
;

plus_terms
: term '+' term       @{ @i @plus_terms.node@ = ast_operator(OP_ADD, @term.0.node@, @term.1.node@);
                         @i @term.0.symbols@ = @plus_terms.symbols@;
                         @i @term.1.symbols@ = @plus_terms.symbols@; @}
| plus_terms '+' term @{ @i @plus_terms.0.node@ = ast_operator(OP_ADD, @plus_terms.1.node@, @term.node@);
                         @i @plus_terms.1.symbols@ = @plus_terms.0.symbols@;
                         @i @term.symbols@ = @plus_terms.0.symbols@; @}
;

mul_terms
: term '*' term      @{ @i @mul_terms.node@ = ast_operator(OP_MUL, @term.0.node@, @term.1.node@);
                        @i @term.0.symbols@ = @mul_terms.symbols@;
                        @i @term.1.symbols@ = @mul_terms.symbols@; @}
| mul_terms '*' term @{ @i @mul_terms.0.node@ = ast_operator(OP_MUL, @mul_terms.1.node@, @term.node@);
                        @i @mul_terms.1.symbols@ = @mul_terms.0.symbols@;
                        @i @term.symbols@ = @mul_terms.0.symbols@; @}
;

or_terms
: term TK_OR term     @{ @i @or_terms.node@ = ast_operator(OP_OR, @term.0.node@, @term.1.node@);
                         @i @term.0.symbols@ = @or_terms.symbols@;
                         @i @term.1.symbols@ = @or_terms.symbols@; @}
| or_terms TK_OR term @{ @i @or_terms.0.node@ = ast_operator(OP_OR, @or_terms.1.node@, @term.node@);
                         @i @or_terms.1.symbols@ = @or_terms.0.symbols@;
                         @i @term.symbols@ = @or_terms.0.symbols@; @}
;

args
:
| expr          @{ @i @expr.symbols@ = @args.symbols@; @}
| expr ',' args @{ @i @expr.symbols@ = @args.0.symbols@;
                   @i @args.1.symbols@ = @args.0.symbols@; @}
;

term
: '(' expr ')'       @{ @i @term.node@ = @expr.node@;
                        @i @expr.symbols@ = @term.symbols@; @}
| TK_NUM             @{ @i @term.node@ = ast_constant(@TK_NUM.value@); @}
| TK_ID              @{ @i @term.node@ = ast_var(sym_lookup_var(@term.symbols@, @TK_ID.string@)->reg); @}
| TK_ID '(' args ')' @{ @i @term.node@ = NULL;
                        @i @args.symbols@ = @term.symbols@; @}
;

%%

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
