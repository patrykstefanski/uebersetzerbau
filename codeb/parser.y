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

@traversal @preorder codegen

@attributes { char *string; } TK_ID funcdef_end label_definition pars_last
@attributes { long value; } TK_NUM
@attributes { struct symbol *symbols; } args pars pars_rec;
@attributes { struct symbol *symbols; struct symbol *label; } label_use;
@attributes { struct symbol *label; size_t depth; } do_end;
@attributes { struct symbol *symbols; size_t depth; bool has_label; } do_stat;
@attributes { struct symbol *symbols; size_t depth; } control_pass do_statement guarded guarded_list stats;
@attributes { struct ast_node *node; struct symbol *symbols; } expr mul_terms or_terms plus_terms term unary_term

%%

program
:
| funcdef ';' program
;

funcdef
: TK_ID '(' pars ')' stats funcdef_end @{ @codegen generate_function_begin(@TK_ID.string@);
                                          @i @stats.depth@ = 0;
                                          @i @stats.symbols@ = @pars.symbols@;
                                          @i @funcdef_end.string@ = @TK_ID.string@; @}
;

funcdef_end
: TK_END @{ @codegen generate_function_end(@funcdef_end.string@); @}
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
:
| TK_RETURN expr ';' stats                  @{ @codegen generate_return(@expr.node@, sym_needed_registers(@stats.0.symbols@));
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| do_statement ';' stats                    @{ @i @do_statement.depth@ = @stats.0.depth@;
                                               @i @do_statement.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| TK_VAR TK_ID TK_ASSIGNMENT expr ';' stats @{ @codegen generate_var_definition(@expr.node@, sym_needed_registers(@stats.0.symbols@));
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = sym_add_var(@stats.0.symbols@, @TK_ID.string@); @}
| TK_ID TK_ASSIGNMENT expr ';' stats        @{ @codegen generate_var_assignment(@expr.node@, sym_lookup_var(@stats.0.symbols@, @TK_ID.string@)->reg, sym_needed_registers(@stats.0.symbols@));
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| term '^' TK_ASSIGNMENT expr ';' stats     @{ @codegen generate_write(@term.node@, @expr.node@, sym_needed_registers(@stats.0.symbols@));
                                               @i @term.symbols@ = @stats.0.symbols@;
                                               @i @expr.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
| term ';' stats                            @{ @i @term.symbols@ = @stats.0.symbols@;
                                               @i @stats.1.depth@ = @stats.0.depth@;
                                               @i @stats.1.symbols@ = @stats.0.symbols@; @}
;

do_statement
:           do_stat @{ @i @do_stat.depth@ = @do_statement.depth@;
                       @i @do_stat.has_label@ = false;
                       @i @do_stat.symbols@ = @do_statement.symbols@; @}
| TK_ID ':' do_stat @{ @i @do_stat.depth@ = @do_statement.depth@;
                       @i @do_stat.has_label@ = true;
                       @i @do_stat.symbols@ = sym_add_label(@do_statement.symbols@, @TK_ID.string@); @}
;

do_stat
: TK_DO guarded_list do_end @{ @codegen generate_do_begin(@do_stat.has_label@ ? @do_stat.symbols@ : NULL, @do_stat.depth@);
                               @i @guarded_list.depth@ = @do_stat.depth@ + 1;
                               @i @guarded_list.symbols@ = @do_stat.symbols@;
                               @i @do_end.depth@ = @do_stat.depth@;
                               @i @do_end.label@ = @do_stat.has_label@ ? @do_stat.symbols@ : NULL; @}
;

do_end
: TK_END @{ @codegen generate_do_end(@do_end.label@, @do_end.depth@); @}
;

guarded_list
:
| guarded_list guarded ';' @{ @i @guarded_list.1.depth@ = @guarded_list.0.depth@;
                              @i @guarded_list.1.symbols@ = @guarded_list.0.symbols@;
                              @i @guarded.depth@ = @guarded_list.0.depth@;
                              @i @guarded.symbols@ = @guarded_list.0.symbols@; @}
;

guarded
: expr TK_ARROW stats control_pass @{ @codegen generate_guarded(@expr.node@, @guarded.depth@, sym_needed_registers(@guarded.symbols@));
                                      @i @expr.symbols@ = @guarded.symbols@;
                                      @i @stats.depth@ = @guarded.depth@;
                                      @i @stats.symbols@ = @guarded.symbols@;
                                      @i @control_pass.depth@ = @guarded.depth@;
                                      @i @control_pass.symbols@ = @guarded.symbols@; @}
;

control_pass
: TK_BREAK    label_use @{ @codegen generate_control_pass(@label_use.label@, @control_pass.depth@, true);
                           @i @label_use.symbols@ = @control_pass.symbols@; @}
| TK_CONTINUE label_use @{ @codegen generate_control_pass(@label_use.label@, @control_pass.depth@, false);
                           @i @label_use.symbols@ = @control_pass.symbols@; @}
;

label_use
:       @{ @i @label_use.label@ = NULL; @}
| TK_ID @{ @i @label_use.label@ = sym_lookup_label(@label_use.symbols@, @TK_ID.string@); @}
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
    fprintf(stderr, "line %d: %s\n", yylineno, message);
    exit(2);
}

int
main(void)
{
    puts(".text");
    puts(".const_1:    .quad 1");
    puts(".const_neg1: .quad -1");
    puts("");
    yyparse();
    return 0;
}
