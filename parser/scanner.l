%{
#include <stdio.h>
#include <stdlib.h>
#include "parser.h"
%}

%option noinput
%option nounput
%option noyywrap
%option yylineno

comment    \/\/.*
id         [A-Za-z_][0-9A-Za-z_]*
num_dec    [0-9]+
num_hex    0x[0-9A-Fa-f]+
num        {num_dec}|{num_hex}
whitespace [\n\t ]

%%

break         return BREAK;
continue      return CONTINUE;
do            return DO;
end           return END;
not           return NOT;
or            return OR;
return        return RETURN;
var           return VAR;
"("           return '(';
")"           return ')';
"*"           return '*';
"+"           return '+';
","           return ',';
"->"          return ARROW;
"-"           return '-';
":="          return ASSIGNMENT;
":"           return ':';
";"           return ';';
"<"           return '<';
"="           return '=';
"^"           return '^';
{id}          return ID;
{num}         return NUM;
{whitespace}+ ;
{comment}     ;
.             { (void) fprintf(stderr, "line %d: lexical error\n", yylineno); exit(1); }
