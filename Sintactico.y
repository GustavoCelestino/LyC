%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <ctype.h>
#include "y.tab.h"

int yylex();

FILE  *yyin, *tsout;

/*-- Estructura para la tabla de simbolos --*/
typedef struct {
	char nombre[30];
	char tipo[10];
	char valor[30];
	int longitud;
}t_ts;

t_ts tablaSimbolos[5000];

int posicionTabla=0;
int yystopparser=0;

char *yyltext;
extern char yytext[];

char tiposComparados[5000][10];
int cantComparaciones=0;

char tipoActual[10]={""};
char listaVariables[50][2]={""};
int contvariableActual=0;

int validarInt(int entero);
int validarString(char *str);
int validarFloat(float flotante);
int validarID(char *str);
int guardarEnTablaSimbolo(int num, char *yytext, char *valor);
void escribirTablaSimbolo(void);
int buscarEnTablaSimbolo(char *);
void existeEnTablaSimbolo(char *);
void guardarTipo();
int yyerror();

void validarTipos();

%}

%union {
  char *strVal;
}

%token PUNTOCOMA DOSPUNTOS COMA
%token P_A P_C
%token L_A L_C
%token OP_SUMA OP_RESTA OP_MUL OP_DIV
%token OP_ASIGNACION OP_ASIG_ESPECIAL OP_COMPARACION 
%token OP_LOGICO OP_NEGACION
%token DEFVAR ENDDEF
%token DISPLAY GET 
%token INT FLOAT STRING
%token IF ELSE
%token WHILE
%token <strVal>CONST_INT
%token <strVal>CONST_STRING
%token <strVal>CONST_FLOAT
%token <strVal>ID

%%
Inicio:
  {printf("\n\nINICIA COMPILACION\n\n");}  programa {printf("\n\nCOMPILACION EXITOSA!\n\n\n");} 
;

programa:  	   
	{printf("Bloque de declaraciones\n\n");}  bloque_Declaraciones {printf("\n\nBloque de sentencias\n");}  bloque_Sentencias
;  

bloque_Declaraciones:
	DEFVAR declaraciones ENDDEF
;

declaraciones:         	        	
	declaracion
	|declaraciones declaracion
;

declaracion:  
	tipo DOSPUNTOS lista_var 
;

tipo:
	FLOAT {strcpy(tipoActual,"Float");}
	|INT {strcpy(tipoActual,"Int");}
	|STRING {strcpy(tipoActual,"String");}
;

lista_var:  
	ID {printf("Variable: %s Tipo: %s \n",yylval.strVal,tipoActual); validarID(yylval.strVal); contvariableActual++; strcpy(listaVariables[contvariableActual],yylval.strVal); guardarTipo();}
	|lista_var PUNTOCOMA ID {printf("Variable: %s Tipo: %s \n",yylval.strVal,tipoActual); validarID(yylval.strVal); contvariableActual++; strcpy(listaVariables[contvariableActual],yylval.strVal); guardarTipo();}
;

bloque_Sentencias: 
	sentencia
	|bloque_Sentencias sentencia
;

sentencia:
	ciclo
	|if  
	|asignacion
	|asignacionespecial
	|salida
	|entrada
;

ciclo:
	WHILE P_A decision P_C L_A bloque_Sentencias L_C 
;

asignacion: 
	ID OP_ASIGNACION expresion {existeEnTablaSimbolo($1); strcpy(tiposComparados[cantComparaciones],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); cantComparaciones++; validarTipos(); cantComparaciones=0;}
	|ID OP_ASIGNACION ifunario {existeEnTablaSimbolo($1); strcpy(tiposComparados[cantComparaciones],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); cantComparaciones++; validarTipos(); cantComparaciones=0;}
;

asignacionespecial: 
	ID OP_ASIG_ESPECIAL ID {existeEnTablaSimbolo($1); existeEnTablaSimbolo($3); strcpy(tiposComparados[0],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); strcpy(tiposComparados[1],tablaSimbolos[buscarEnTablaSimbolo($3)].tipo); validarTipos(); cantComparaciones=0;}
;

if: 
	IF P_A decision P_C L_A bloque_Sentencias L_C 
	|IF P_A decision P_C L_A bloque_Sentencias L_C ELSE L_A bloque_Sentencias L_C
;

ifunario: 
	IF P_A decision COMA expresion COMA expresion P_C
;

decision:
	condicion
	|condicion OP_LOGICO condicion
	|OP_NEGACION condicion
;

condicion:
	expresion OP_COMPARACION expresion
;

expresion:
	termino
	|expresion OP_SUMA termino 
	|expresion OP_RESTA termino 
;

termino: 
	factor
	|termino OP_MUL factor 
	|termino OP_DIV factor 
;

factor: 
	ID {existeEnTablaSimbolo($1); strcpy(tiposComparados[cantComparaciones],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); cantComparaciones++;}
	| CONST_STRING {validarString(yylval.strVal); strcpy(tiposComparados[cantComparaciones], "String"); cantComparaciones++;}
	| CONST_INT    {validarInt(atoi(yylval.strVal)); strcpy(tiposComparados[cantComparaciones], "Int"); cantComparaciones++;}
	| CONST_FLOAT  {validarFloat(atof(yylval.strVal)); strcpy(tiposComparados[cantComparaciones], "Float"); cantComparaciones++;} 
	| P_A expresion P_C
;


salida:
	DISPLAY CONST_STRING {validarString(yylval.strVal);}
	|DISPLAY ID {existeEnTablaSimbolo($2);}
;

entrada:
	GET ID {existeEnTablaSimbolo($2);}
;

%%
int main(int argc,char *argv[])
{
	if((yyin = fopen(argv[1], "rt")) == NULL){
		fprintf(stderr, "\nNo se puede abrir el archivo: %s\n", argv[1]);
		return 1;
  	}
  	else{
		if( (tsout = fopen("ts.txt", "wt")) == NULL){
			fprintf(stderr,"\nERROR: No se puede abrir o crear el archivo: %s\n", "ts.txt");
			fclose(yyin);
			return 1;
		}

		fprintf(tsout, "NOMBRE                        |   TIPO    |                VALOR                | L |\n");
		fprintf(tsout, "-------------------------------------------------------------------------------------\n");

		yyparse();

		escribirTablaSimbolo();
	}

	fclose(yyin);
	fclose(tsout);
	return 0;
}

int yyerror(void)
{
  fflush(stdout);
  printf("Error de sintaxis\n\n");
  fclose(yyin);
  fclose(tsout);
  system ("Pause");
  exit (1);
}

//Funcion para validar ID 
int validarID(char *str){
	if(contvariableActual>=50){
		printf("\nNo puede declarar mas de 50 variables\n", str);
		yyerror();
	}
	
	int largo=strlen(str);
	if(largo > 20){
		printf("\nERROR: ID \"%s\" demasiado largo (<20)\n", str);
		yyerror();
	}
	
	// Compruebo que ID no exista ya en la tabla de simbolos
	if(buscarEnTablaSimbolo(str) != -1){
		printf("\nERROR: ID \"%s\" duplicado\n", str);
		yyerror();
	}
	guardarEnTablaSimbolo(1, str, str);
	return 1;
}

//Funcion para validar el rango de enteros 
int validarInt(int entero){
	char var[32];
	if(entero < 0 || entero >= 32767){
		printf("\nERROR: Entero fuera de rango (-32768; 32767)\n");
		yyerror();
	}

	sprintf(var, "%d",entero);

	if(buscarEnTablaSimbolo(var) == -1) {
		guardarEnTablaSimbolo(2, var, "");
	}

	return 1;
}


//Funcion para validar string 
int validarString(char *str){
	int a=0,i;
	char *aux = str;
  int largo = strlen(aux);
  char cadenaPura[30];

	if(largo > 30){
		printf("\nERROR: Cadena demasiado larga (<30)\n");
		yyerror();
	}
	
	for(i=1; i<largo-1;i++){
    cadenaPura[a]=str[i];
    a++;
  }

	cadenaPura[a--]='\0'; 

  if(buscarEnTablaSimbolo(cadenaPura) == -1) guardarEnTablaSimbolo(3, cadenaPura, "");

	return 1;
}


//Funcion para validar float 
int validarFloat(float nro){
	char var[32];
	double limiteMin=pow(-1.17549,-38);
	double limiteMax=pow(3.40282,38);
	if(nro < limiteMin || nro > limiteMax){
		printf("\nERROR: Float fuera de rango (-1.17549e-38; 3.40282e38) \n");
		yyerror();
	}

	sprintf(var, "%.2f",nro);

	if(buscarEnTablaSimbolo(var) == -1) guardarEnTablaSimbolo(4, var,"");

	return 1;
}

//Validar que los tipos de datos sean compatibles
void validarTipos(){
	int flgOK=1;
	int flgNumerico=0;
	int x;
	printf("\nComparacion\n");
	for(x=0;x<cantComparaciones;x++){
		printf("TIPO: %s\n",tiposComparados[x]);

		if(x==0){
			if(strcmpi(tiposComparados[x],"String")!=0)
				flgNumerico=1;
		}
		else{
			if((flgNumerico == 0 && (strcmpi(tiposComparados[x],"Int")==0 || strcmpi(tiposComparados[x],"Float")==0)) || (flgNumerico == 1 && strcmpi(tiposComparados[x],"String")==0)){
				//Si (no es numerico pero me vienen enteros o float) ó (si es numerico y me viene un string) = ERROR
				flgOK=0;
				break;
			}
		}
	}

	if(flgOK==1){
		printf("Comparacion OK\n");
	}
	else{
		printf("\nERROR: Tipos de dato incompatibles\n");
		yyerror();
	}
}

/* -- FUNCIONES TABLA DE SIMBOLOS -- */

//Funcion para guardar en la Tabla de Simbolos
int guardarEnTablaSimbolo(int num, char *str, char *valor ) {
	switch(num){
		case 1:  // ID
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				posicionTabla++;
				break;
				
		case 2: // INT
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteInt");
				posicionTabla++;
				break;
				
		case 3: // STRING
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				tablaSimbolos[posicionTabla].longitud=strlen(str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteStr");
				posicionTabla++;
				break;
				
		case 4: // FLOAT
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteFloat");
				posicionTabla++;
				break;
		
		default:
				break;
	}
}

//Funcion para actualizar el tipo de una variable en la tabla de simbolos
void guardarTipo(){
    int pos=buscarEnTablaSimbolo(listaVariables[contvariableActual]);
    if(pos!=-1) strcpy(tablaSimbolos[pos].tipo,tipoActual); 
}

//Funcion para buscar la posicion de un simbolo en la tabla de simbolos
int buscarEnTablaSimbolo(char *id){
	int i;
	for(i=0; i<5000; i++){
		if(strcmpi(id,tablaSimbolos[i].nombre)==0)
			return i;
	}
	return -1;
}

//Funcion para comprobar que un simbolo existe en la tabla de simbolos
void existeEnTablaSimbolo(char *id){
	if(buscarEnTablaSimbolo(id)==-1){
		printf("\nERROR: ID \"%s\" no declarado\n", id);
		yyerror();
	}
}

//Funcion para crear la ts de simbolos en un archivo, en base a la Tabla declarada 
void escribirTablaSimbolo(){
	int i;
	for(i=0; i<posicionTabla; i++){
		if( strcmpi(tablaSimbolos[i].tipo,"") != 0 && 
			strcmpi(tablaSimbolos[i].tipo,"Cte") != 0 &&
			strcmpi(tablaSimbolos[i].tipo,"CteFloat") !=0 &&
			strcmpi(tablaSimbolos[i].tipo,"CteInt") != 0 && 
			strcmpi(tablaSimbolos[i].tipo,"CteStr")!= 0 ){  
			//si es ID
			fprintf(tsout, "%-30s|  %-7s  |                  -               	| - |\n", tablaSimbolos[i].nombre, tablaSimbolos[i].tipo);
		}else{ //Si es cte
			if(tablaSimbolos[i].longitud>0){
				fprintf(tsout, "_%-29s|           |              %-16s	|%03d|\n", tablaSimbolos[i].nombre, tablaSimbolos[i].valor, tablaSimbolos[i].longitud);
			}else{
				fprintf(tsout, "_%-29s|           |              %-16s	| - |\n", tablaSimbolos[i].nombre, tablaSimbolos[i].valor);
			}
		}
	}
}


