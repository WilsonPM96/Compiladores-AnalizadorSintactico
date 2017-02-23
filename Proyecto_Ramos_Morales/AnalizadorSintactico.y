%{	
	#include <stdio.h>
	#include "tablasimbolos.h"
	extern int errors, lines, chars;
	
	#define TABLE_FILE "tablasimbolos"
	
	#define ERROR 0
	#define WARNING 1
	#define NOTE 2
	#define KEY_TYPE -100
	FILE *yyin;
	char *filename;
	int yylex();
	void yyerror();
	int install(const char *lexeme, int type);
	void install_keywords(char* keywords[], int n);
	void install_id(char *name, int type);
	void print_table(table_t table);
	char *strbuild(int option, const char *str1, const char *str2);
	void print_cursor();
	void get_line(char *line);
	#define YYDEBUG 1
%}


%token MAIN
%token IF ELSE DO WHILE FOR BREAK PRINT RETURN
%token INT_TYPE FLOAT_TYPE LETRA_TYPE STRING_TYPE BOOL_TYPE
%token CARACTER STRING ENTERO FLOTANTE BOOLEANO
%token ID
%token INCREMENTO DECREMENTO
%token IGUAL_IGUAL MENOR_QUE MAYOR_QUE AND OR NOT
%token KEYOLlave KEYCLlave OP CP BracketO BracketC
%token IGUAL

%union {
	char *lexeme;
	char *string;
	char *letra;
	int entero;
	float flotante;
	float booleano;
	

}

%type<lexeme> ID
%type<entero> ENTERO l_expr l_factor
%type<flotante> FLOTANTE g_expr g_term g_factor 
%type<string> STRING t_expr 
%type<letra> CARACTER c_expr 




%left KEYOLlave
%right KEYCLlave
%left OP
%right CP
%left BracketO
%right BracketC
%token ASIGNACION
%left  COMA
%right FinCommand

%left '+' '-'
%left '*' '/'
%left INCREMENTO DECREMENTO
%left IGUAL_IGUAL MENOR_QUE MAYOR_QUE AND OR
%right IGUAL
%right NOT

%glr-parser

%%

 /*******************************************
 CUERPO DEL PROGRAMA
 *******************************************/


program:
	MAIN OP CP  KEYOLlave comandos KEYCLlave metodo
	|MAIN OP declaration CP KEYOLlave comandos KEYCLlave metodo
	|MAIN OP CP KEYOLlave comandos metodo comandos KEYCLlave metodo
	|MAIN OP declaration CP KEYOLlave comandos metodo comandos KEYCLlave metodo
        | error {yyerror("formato de 'main' invalido", ERROR);} 
	;

metodo: 
	 %empty
	| lista_tipo ID OP CP KEYOLlave comandos KEYCLlave metodo
	| lista_tipo ID OP CP KEYOLlave comandos metodo comandos KEYCLlave metodo
	| lista_tipo ID OP declaration CP KEYOLlave comandos KEYCLlave metodo
	
        | error {yyerror("formato de cuerpo invalido", ERROR);}
	;



lista_tipo:
	INT_TYPE 
	|FLOAT_TYPE 
	|STRING_TYPE 
	|LETRA_TYPE 
	|BOOL_TYPE
	;

 /*******************************************
 COMANDOS
 *******************************************/

comandos: 
	command_list
	;

command_list: 
	KEYOLlave command_list KEYCLlave
	| command  command_list
        | %empty
        ;

command:
	comando_simple FinCommand
        | bucle
        | error { yyerror("Instruccion no reconocida, erronea o ';' faltante", ERROR); }
        ;
	
bucle: 
	controlF
	| controlFor
        | controlWhile 
        | controlDo
        | controlWhileDo
        ;

comando_simple: 
	PRINT STRING
        | RETURN
        | attrib
        | declaration
        ;

 /*******************************************
 IF ELSE
 *******************************************/
controlF: 
	IF OP l_expr CP KEYOLlave comandos KEYCLlave controlElse
	;

controlElse: 
	%empty
        | ELSE KEYOLlave comandos KEYCLlave
	;


/*******************************************
 FOR
 *******************************************/
controlFor: 
	FOR OP ffirst FinCommand l_expr FinCommand fthird CP KEYOLlave comandos KEYCLlave
	;

ffirst: 
	%empty
	| attrib_list
	;


fthird: 
	%empty
        | comando_simple COMA fthird
        | comando_simple
	;


 /*******************************************
 WHILE
 *******************************************/
controlWhile: 
	WHILE OP l_expr CP KEYOLlave comandos KEYCLlave
	;


 /*******************************************
 DO WHILE
 *******************************************/
controlDo: 
	DO KEYOLlave comandos KEYCLlave WHILE OP l_expr CP FinCommand
	;

/*******************************************
 WHILE DO
 *******************************************/
controlWhileDo:
WHILE OP l_expr CP DO KEYOLlave comandos KEYCLlave 
	;

 /*******************************************
 DECLARACION
 *******************************************/
declaration: 
	INT_TYPE ASIGNACION ID {install_id($3, INT_TYPE);}
	|FLOAT_TYPE ASIGNACION ID {install_id($3, FLOAT_TYPE);}
	|STRING_TYPE ASIGNACION ID {install_id($3, STRING_TYPE);}
	|LETRA_TYPE ASIGNACION ID {install_id($3, LETRA_TYPE);}	
	|BOOL_TYPE ASIGNACION ID {install_id($3, BOOL_TYPE);}
	;


 /*******************************************
 ASIGNACIONES
 *******************************************/
attrib_list: 
	attrib ',' attrib_list 
        | attrib
        ;

attrib:
	i_attrib
	| ID INCREMENTO {if(get_entry($1)){set_value($1, get_value($1)+1);}
		      else{char *str=(char *)strbuild(1,"declaracion de '%s' no encontrada", $1);yyerror(str, ERROR);}}
	| ID DECREMENTO {if(get_entry($1)){set_value($1, get_value($1)-1);}
		      else{char *str=(char *)strbuild(1,"declaracion de '%s' no encontrada", $1);yyerror(str, ERROR);}}                      
	| ID '=' ID {char *str;if(get_entry($1)!=NULL) {
			// if there's entry gets its value
			if(get_entry($3)!=NULL){if(get_type($1)==get_type($3)){set_value($1, get_value($3));}
			else{str=(char *)strbuild(0,(char *)strbuild(1, "tipos de datos incompatibles en '%s' ", $1),
			(char *)strbuild(1, "y '%s'", $3));}}
		        else{str=(char *)strbuild(1, "declaracion de '%s' no encontrada", $1);yyerror(str, ERROR);}}
			else{str=(char *)strbuild(1, "declaracion de '%s' no encontrada", $1);yyerror(str, ERROR);}}
	| error { yyerror("formato de atribucion invalido", ERROR); }
	;	

i_attrib: 
	ID '=' g_expr {if(get_entry($1)) {
			
			if(get_type($1) == INT_TYPE) {
			
			set_value($1,(int) $3);}
			else if(get_type($1) == FLOAT_TYPE) {
			
			set_value($1,(float) $3);}
			else if(get_type($1) == BOOL_TYPE) {
			
			if($3>0&&$3<1){set_value($1,0);}
			else if($3>1&&$3<2){set_value($1,1);};}
			else {yyerror("tipos de datos incompatibles", WARNING);}}
			else {char *str = (char *)strbuild(1, "declaracion de '%s' no encontrada", $1);
			yyerror(str, ERROR);}}
	|ID '=' t_expr {if(get_entry($1)) {
			
			if(get_type($1)==STRING_TYPE) {
			
			set_value($1,(char)($3));}
			else {yyerror("tipos de datos incompatibles", WARNING);}}
			else {char *str = (char *)strbuild(1, "declaracion de '%s' no encontrada", $1);
			yyerror(str, ERROR);}}
	|ID '=' c_expr {if(get_entry($1)) {
			
			if(get_type($1)==LETRA_TYPE) {
			
			set_value($1, (char)($3));}
			else {yyerror("tipos de datos incompatibles", WARNING);}}
			else {char *str = (char *)strbuild(1, "declaracion de '%s' no encontrada", $1);
			yyerror(str, ERROR);}}

	;



 /*******************************************
 Expresiones Logicas y Matematicas
 *******************************************/
t_expr:
	STRING	{$$=$1;}

	;

c_expr:
	CARACTER 	{$$=$1;}
	;


l_expr: 
	l_expr IGUAL_IGUAL l_factor { $$=$1==$3; }
      | l_expr AND l_factor { $$=$1&&$3; }
      | l_expr OR l_factor { $$=$1||$3; }
      | l_expr MAYOR_QUE l_factor { $$=$1>$3; }
      | l_expr MENOR_QUE l_factor { $$=$1<$3; }
      | NOT l_expr { $$ = !$2; }
      | l_factor
      ;

l_factor: 
	OP l_expr OP { $$ = $2; }
	| ENTERO { $$ = $1; }
	| FLOTANTE { $$ = $1; }
	| ID 	{
		if(get_entry($1)) {$$ = (int) get_value($1);}
		else {char *str = (char *)strbuild(1, "declaracion de '%s' no encontrada", $1);
		yyerror(str, ERROR);}}
	;

g_expr: 
	g_expr '+' g_term { $$ = $1 + $3; }
      | g_expr '-' g_term { $$ = $1 - $3; } 
      | g_term { $$ = $1; }
      ;



g_term: 
	g_term '*' g_factor { $$ = $1 * $3; } 
      | g_term '/' g_factor { $$ = $1 / $3; } 
      | g_factor { $$ = $1; }
      ;


      

g_factor: 
	OP g_expr OP { $$ = $2; }
        | ENTERO { $$ = $1; }
	| FLOTANTE { $$ = $1; }
        ;



%%

int main( int argc, char **argv )
{
	char* keywords[] = {"main", "if", "else", "do", "while", "for", "break", "print",
						"return", "int", "float"};

	 
	++argv, --argc;
	yyin = fopen( argv[0], "r" );
	if ( !ftell(yyin) ) {
		filename = strdup(argv[0]);	
	}
	else {
		filename = strdup("stdin");
		yyin = stdin;
	}
	
	init_table();

	
	install_keywords(keywords, 11);

	
	yyparse();

	if(errors==0) {
		printf("Análisis finalizado correctamente\n");
	}
	else {
		printf("Se han encontrado %d errores\n", errors);
	}

	
	print_table(table);

	return 0;
}


int install(const char *lexeme, int type) {
	int success = 1;
	entry_t *e;

	e = (entry_t *)get_entry(lexeme);
	if(e == 0) {
		put_entry((entry_t *)create_entry(type, lexeme, 0));
	}
	else {
		success = 0;
	}
	return success;
}


void install_keywords(char* keywords[], int n) {
	int i;
	for(i = 0; i < n; i++) {
		install(keywords[i], KEY_TYPE);
	}
}


void print_table(table_t table) {
	FILE *f = fopen (TABLE_FILE, "w");
	int i;
	entry_t *cur;
	
	fprintf(f, "TABLA DE SÍMBOLOS\n"
		"%d entries\n\n", table.t_size);

	fprintf(f, "+-------+---------+------------------------------+\n"); 
	fprintf(f, "|   -   |  TIPO   |        TOKEN = VALOR         |\n");
	fprintf(f, "+-------+---------+------------------------------+\n"); 

	for(i = 1, cur = table.t_head;
	    cur != NULL;
	    cur = cur->next, i++) {
		if(cur->type == INT_TYPE) {
			fprintf(f, "| %-5d | ENTERO  |  %s = %d\n", i, cur->lexeme, (int) cur->value);
		} 
		else if(cur->type == FLOAT_TYPE) {
			fprintf(f, "| %-5d |FLOTANTE |  %s = %f\n", i, cur->lexeme, (float) cur->value);
		}
		else if(cur->type == LETRA_TYPE) {
			fprintf(f, "| %-5d | CARACTER    |  %s = %f\n", i, cur->lexeme, cur->value);
		}		
		else if(cur->type==BOOL_TYPE) {
			fprintf(f, "| %-5d |BOOLEANO |  %s = %f\n", i, cur->lexeme,  cur->value);
		} 
		
		else if(cur->type == STRING_TYPE) {
			fprintf(f, "| %-5d | STRING  |  %s = %f\n", i, cur->lexeme, cur->value);	
		} 
		else if(cur->type == KEY_TYPE) {
			fprintf(f, "| %-5d | PALABRA |  %s\n", i, cur->lexeme);
		}
	}

	fprintf(f, "+-------+---------+------------------------------+\n"); 
}

void yyerror(const char *msg, int type) {
	if(strcmp(msg, "syntax error") == 0) {
		printf("Error Sintactico\n");
	}
	else {
		
		switch(type) {
			case ERROR:
				printf("%s:%d:%d: Error: %s\n", filename, lines, chars, msg);
				break;

			case WARNING:
				printf("%s:%d:%d: Advertencia: %s\n", filename, lines, chars, msg);
				break;

			case NOTE:
				printf("%s:%d:%d: Nota: %s\n", filename, lines, chars, msg);
				break;

			default:
				printf("%s:%d:%d: Error: %s\n", filename, lines, chars, msg);
		}

		errors++;
		print_cursor();
	}
}

void install_id(char *name, int type) {

	if(install(name, type)) {
	}
	else {
		int t = get_type(name);
		char *str;
		if(t == type) {
			str = (char *)strbuild(1, "Redeclaracion de '%s'", name);
		}
		else {
			str = (char *)strbuild(1, "Tipos conflictivos para '%s'", name);
		}
		yyerror(str, NOTE);
	}
}

char *strbuild(int option, const char *str1, const char *str2) {
	char *full_str;

	if(option == 1) {
		int size;

		size = snprintf(NULL, 0, str1, str2);
		full_str = (char *)malloc(size+1);


		if(full_str != NULL) {
			snprintf(full_str, size+1, str1, str2);
		}

		else {
			full_str = (char *)strdup(str1);
		}
	}
	else {

		full_str = (char *)malloc((strlen(str1) + strlen(str2)) * sizeof(char));
                if(full_str != NULL) {
			strcat(full_str, str1);
			strcat(full_str, str2);
		}
	}

	return full_str;
}

void print_cursor() {
	int i;
	char line[256];

	get_line(line);
	printf("%s", line);

	for(i=0; i<chars-1; i++) {
		if(line[i] == '\t') {
			printf("\t");
		}
		else {
			printf(" ");
		}
	}
	printf("^^\n");
}

void get_line(char *line) {
	int i;
	fpos_t position;


	fgetpos(yyin, &position);


	rewind(yyin);
	for(i=0; i<lines; i++) {
		fgets(line, 256, yyin);
	}


	fsetpos(yyin, &position);
}
