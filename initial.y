%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
int yyerror(char *s);
%}
%union {
	int i;			/* integer value */
	double r;		/* real value */
	char *s;		/* symbol name or string literal */
    Node *n;
};
%token <i> INT
%token <r> REAL
%token <s> ID STR
%token DO WHILE IF THEN FOR IN UPTO DOWNTO STEP BREAK CONTINUE
%token VOID INTEGER STRING NUMBER CONST PUBLIC 

%nonassoc '[' '('

%nonassoc INCR DECR '!'

%left '*' '/' '%'
%left '+' '-'

%left '<' '>' GE LE
%left '=' NE
%nonassoc '~' 
%right ATR

%left '&' '|'
%nonassoc ELSE UMINUS ADDR SIMPLE_IF 


%%
file: decls {printf("test");}
    ;

decls: decls decl
     |
     ;


decl: PUBLIC decl_const 
    | decl_const
    ;

decl_const: CONST decl_param 
          | decl_param
          ;

decl_param: parametro ';'
          | parametro init ';'
          ;


tipo: NUMBER
    | STRING
    | INTEGER
    | VOID
    ;

init: ATR INT
    | ATR '-' INT
    | ATR CONST STR
    | ATR STR
    | ATR REAL
    | ATR '-' REAL
    | ATR ID
    | '(' ')' op_body
    | '(' parametros ')' op_body
    ;

op_body:
       | body
       ;

body:'{' body_param body_inst '}'
    ;

body_param: parametro ';' body_param
          |
          ;

body_inst: instrucao body_inst
         |
         ;


instrucao: BREAK ';'
         | BREAK INTEGER ';'
         | CONTINUE ';'
         | CONTINUE INTEGER ';'
         | body
         | expressao ';'
         | IF expressao THEN instrucao %prec SIMPLE_IF
         | IF expressao THEN instrucao ELSE instrucao
         | DO instrucao WHILE expressao ';'
         | left_value '#' expressao ';'
         | FOR left_value IN expressao algo_to expressao op_step DO instrucao
         ;

algo_to: UPTO
       | DOWNTO
       ;

op_step: 
       | STEP expressao
       ;

expressao: left_value
         | INT
         | REAL
         | STR

         | '(' expressao ')'
         
         | '-' expressao %prec UMINUS
         | '!' expressao
         | '&' left_value %prec ADDR
         | INCR left_value
         | DECR left_value
         | left_value INCR
         | left_value DECR
         
         | expressao '*' expressao
         | expressao '/' expressao
         | expressao '%' expressao
         | expressao '+' expressao
         | expressao '-' expressao
         
         | expressao '<' expressao
         | expressao '>' expressao
         | expressao NE expressao
         | expressao '=' expressao
         | expressao GE expressao
         | expressao LE expressao
         
         | '~' expressao
         | expressao '&' expressao
         | expressao '|' expressao
         
         | left_value ATR expressao 
         ;


left_value: ID
          | '*' left_value
          | left_value '[' expressao ']'
          ;

parametros: parametro, parametros
          | parametro
          ;


parametro: tipo ID
         | tipo '*' ID
         ;



%%
char **yynames =
#if YYDEBUG > 0
         (char**)yyname;
#else
         0;
#endif

/*
int yyerror(char *s) { printf("%s\n",s); return 1; }
char *dupstr(const char*s) { return strdup(s); }

/*
int main(int argc, char *argv[]) {
 extern YYSTYPE yylval;
 int tk;
 while ((tk = yylex())) 
  if (tk > YYERRCODE)
   printf("%d:\t%s\n", tk, yyname[tk]);
  else
   printf("%d:\t%c\n", tk, tk);
 return 0;
}*/
