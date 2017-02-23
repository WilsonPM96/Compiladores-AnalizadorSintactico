%{
#include <string.h>
#include <stdlib.h>	
#include "AnalizadorSintactico.tab.h"
	
int lines=1, chars=0, errors=0;

	void count_lb(char *str, int leng, int *c, int *l);
%}

asignacion	("=")
tab		[" "\t]
findelinea	\n|\v\r
comentarios	"/*"({findelinea}*{tab}*)?[^}\n]*({findelinea}*{tab}*)?"*/"|"//"[^}\n]*
%option noyywrap
%option noinput
%option nounput

%% 
"main"	{ chars += yyleng; return (MAIN); }
"if"	{ chars += yyleng; return (IF); }
"else"	{ chars += yyleng; return (ELSE); }
"do"	{ chars += yyleng; return (DO); }
"while"	{ chars += yyleng; return (WHILE); }
"for"	{ chars += yyleng; return (FOR); }
"return"	{ chars += yyleng; return (RETURN); }

{comentarios} { lines++; }

int {chars+=yyleng;return (INT_TYPE);}
float {chars+=yyleng;return (FLOAT_TYPE);}
char {chars+=yyleng;return (LETRA_TYPE);}
string {chars+=yyleng;return (STRING_TYPE);}
bool  {chars+=yyleng;return (BOOL_TYPE);}

[0-9]+  {yylval.entero=(int)atoi(yytext);chars += yyleng;return (ENTERO);}
[0-9]*\.[0-9]+ {yylval.flotante=(float)atof(yytext);chars += yyleng;return (FLOTANTE);}

"true"	{yylval.booleano=(float)atoi(yytext);chars += yyleng;return (BOOLEANO);}
"false" {yylval.booleano=(float)atoi(yytext);chars += yyleng;return (BOOLEANO);}

[a-z][a-zA-Z0-9]*   {yylval.lexeme=(char *)strdup(yytext);chars+=yyleng;return (ID);}
('.')   {yylval.letra=(char *)strdup(yytext);chars+=yyleng;return CARACTER;}
(\".*\")  {yylval.string=(char *)strdup(yytext);chars+=yyleng;return STRING;}

"+"|"-"|"*"|"/" 	{ chars++; return yytext[0]; }

"++" {chars+=yyleng; return INCREMENTO; }
"--" { chars+=yyleng; return DECREMENTO; }
"<"  { chars+=yyleng; return MENOR_QUE; } 
">"  { chars+=yyleng; return MAYOR_QUE; } 
"==" { chars+=yyleng; return IGUAL_IGUAL; } 
"&&" { chars+=yyleng; return AND; } 
"||" { chars+=yyleng; return OR; } 
"!"  { chars+=yyleng; return NOT; } 


{asignacion} { chars++; return (yytext[0]); }

"="                 {chars+=yyleng;return IGUAL;}
";"                 {chars+=yyleng;return FinCommand;}
","                       {chars+=yyleng;return COMA;}
":"                       {chars+=yyleng;return ASIGNACION;}
"{"                      {chars+=yyleng;return KEYOLlave;}
"}"                      {chars+=yyleng;return KEYCLlave;}
"("                        {chars+=yyleng;return OP;}
")"                       {chars+=yyleng;return CP;}
"["                        {chars+=yyleng;return BracketO;}
"]"                      {chars+=yyleng;return BracketC;}



{tab} { chars++; }

{findelinea} {
	chars = 0;
	lines++;
}
. {	printf("( %3d : %-3d ) No se reconoce el token\n", lines, chars);
	chars++;
	errors++;}

%%

void count_lb(char *str, int leng, int *c, int *l) {
	int i;

	for(i=0; i<leng; i++) {
		(*c)++;
		if(str[i] == '\n') {
			(*l)++;
			*c = 0;
		}
	}
}
