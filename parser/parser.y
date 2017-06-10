%{
#include <stdio.h>
#include <stdlib.h>
extern void yyerror(const char *message);
extern int yylex(void);
extern int yylineno;
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

%%

program
:
| program funcdef ';'
;

funcdef
: ID '(' pars ')' stats END
;

pars
:
| ID
| ID ',' pars
;

stats
:
| stats stat ';'
;

stat
: RETURN expr
| do_stat
| VAR ID ASSIGNMENT expr
| lexpr ASSIGNMENT expr
| term
;

do_stat
: label_definition DO guarded_list END
;

label_definition
:
| ID ':'
;

guarded_list
:
| guarded_list guarded ';'
;

guarded
: expr ARROW stats control_pass label_use
;

control_pass
: CONTINUE
| BREAK
;

label_use
:
| ID
;

lexpr
: ID
| term '^'
;

expr
: unary_term
| term '^'
| plus_terms
| mul_terms
| or_terms
| term '<' term
| term '=' term
;

unary_term
: NOT unary_term
| '-' unary_term
| term
;

plus_terms
: term '+' term
| plus_terms '+' term
;

mul_terms
: term '*' term
| mul_terms '*' term
;

or_terms
: term OR term
| or_terms OR term
;

args
:
| expr
| expr ',' args
;

term
: '(' expr ')'
| NUM
| ID
| ID '(' args ')'
;

%%

void yyerror(const char *message) {
    (void) fprintf(stderr, "line %d: %s\n", yylineno, message);
    exit(2);
}

int main(void) {
    yyparse();
    return 0;
}
