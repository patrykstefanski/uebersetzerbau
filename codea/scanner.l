%{

#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

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

break         return TK_BREAK;
continue      return TK_CONTINUE;
do            return TK_DO;
end           return TK_END;
not           return TK_NOT;
or            return TK_OR;
return        return TK_RETURN;
var           return TK_VAR;
"("           return '(';
")"           return ')';
"*"           return '*';
"+"           return '+';
","           return ',';
"->"          return TK_ARROW;
"-"           return '-';
":="          return TK_ASSIGNMENT;
":"           return ':';
";"           return ';';
"<"           return '<';
"="           return '=';
"^"           return '^';
{id}          return TK_ID; @{ @TK_ID.string@ = strncpy(alloc(yyleng + 1), yytext, yyleng); @}
{num}         return TK_NUM; @{ @TK_NUM.value@ = strtol(yytext, NULL, 0); @}
{whitespace}+ ;
{comment}     ;
.             { (void) fprintf(stderr, "line %d: lexical error\n", yylineno); exit(1); }
