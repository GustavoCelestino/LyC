%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <float.h>
#include <math.h>
#include "y.tab.h"

char *ptr;
long ret;
FILE  *yyin, *tsout;
%}

%option noyywrap  
%option yylineno 

DIGITO	        [0-9]
LETRA			[a-zA-Z]
CARACTER        [@,%,-,_]
ID			    {LETRA}({LETRA}|{DIGITO}|_)*
CONST_STRING    [\"]({LETRA}|{DIGITO}|{CARACTER}|" ")*[\"]
CONST_INT       {DIGITO}+
CONST_FLOAT     {DIGITO}*["."]{DIGITO}*

%%
";"			{ return PUNTOCOMA;}
":"			{ return DOSPUNTOS;}
","			{ return COMA;}
"("			{ return P_A;}
")"			{ return P_C;}
"{"			{ return L_A;}
"}"			{ return L_C;}

"+"			{ return OP_SUMA;}
"-"			{ return OP_RESTA;}
"*"			{ return OP_MUL;}
"/"			{ return OP_DIV;}

"+=" 		{return OP_ASIG_ESPECIAL;} 
"-=" 		{return OP_ASIG_ESPECIAL;} 
"*=" 		{return OP_ASIG_ESPECIAL;}
"/=" 		{return OP_ASIG_ESPECIAL;}

":="		{ return OP_ASIGNACION;}

"<"			{ return OP_COMPARACION;}
">"			{ return OP_COMPARACION;}
">="		{ return OP_COMPARACION;}
"<="		{ return OP_COMPARACION;}
"=="		{ return OP_COMPARACION;}
"!="		{ return OP_COMPARACION;}

"AND"		{ return OP_LOGICO;}
"OR"		{ return OP_LOGICO;}
"NOT"		{ return OP_NEGACION;}

"DEFVAR"	{ return DEFVAR;}
"ENDDEF"	{ return ENDDEF;}

"DISPLAY"	{ return DISPLAY;}
"GET"		{ return GET;}

"INT"		{ return INT;}
"FLOAT"		{ return FLOAT;}
"STRING"	{ return STRING;}

"IF"		{ return IF;}
"ELSE"		{ return ELSE;}
"WHILE"		{ return WHILE;}


{CONST_INT}    			{
							yylval.strVal = strdup(yytext);
							return CONST_INT;
						}

{CONST_FLOAT}      		{
							yylval.strVal = strdup(yytext);
							return CONST_FLOAT;
						}

{CONST_STRING}    		{	
							yylval.strVal = strdup(yytext);
							return CONST_STRING;	
						}

{ID}			{ yylval.strVal = strdup(yytext); return ID;}

\*\*\*\/(\\.|[^"\\])*\/\*\*\*   { 
									char * comentarios;
									char * segundonivel;
									comentarios = (strstr(yytext,"/***"));
									//printf("Comentario: %s\n", comentarios);
									segundonivel = strstr(comentarios +4, "/***");
									//printf("Comentario segundonivel: %s\n", segundonivel);
									if(segundonivel != NULL){
										if(strstr(segundonivel+4,"/***") != NULL){
											fprintf(stderr, "ERROR Lexico - No se permite un segundo nivel de comentarios\n");
											exit (1);
										}
									}
								}

\n                                      /* ignore end of line */;
[ \t]+                                  /* ignore whitespace */;	
%%

