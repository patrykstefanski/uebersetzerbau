%{
#include <stdio.h>
#include <stdlib.h>
%}

comment    \/\/.*
id         [A-Za-z_][0-9A-Za-z_]*
num_dec    [0-9]+
num_hex    0x[0-9A-Fa-f]+
num        {num_dec}|{num_hex}
whitespace [\n\t ]

%%

break         { (void) puts(yytext); };
continue      { (void) puts(yytext); };
do            { (void) puts(yytext); };
end           { (void) puts(yytext); };
not           { (void) puts(yytext); };
or            { (void) puts(yytext); };
return        { (void) puts(yytext); };
var           { (void) puts(yytext); };
"("           { (void) puts(yytext); };
")"           { (void) puts(yytext); };
"*"           { (void) puts(yytext); };
"+"           { (void) puts(yytext); };
","           { (void) puts(yytext); };
"->"          { (void) puts(yytext); };
"-"           { (void) puts(yytext); };
":="          { (void) puts(yytext); };
":"           { (void) puts(yytext); };
";"           { (void) puts(yytext); };
"<"           { (void) puts(yytext); };
"="           { (void) puts(yytext); };
"^"           { (void) puts(yytext); };
{id}          { (void) printf("id %s\n", yytext); }
{num}         { long num = strtol(yytext, NULL, 0); (void) printf("num %li\n", num); }
{whitespace}+ ;
{comment}     ;
.             { (void) fputs("Lexical error\n", stderr); exit(1); }

%%

int yywrap(void) {
    return 1;
}

int main(void) {
    (void) yylex();
    return 0;
}
