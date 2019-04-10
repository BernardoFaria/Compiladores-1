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
%token VOID INTEGER STRING NUMBER CONST PUBLIC INCR DECR
%token ATR NE GE LE ELSE

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
    | ATR CONST STR
    | ATR STR
    | ATR REAL
    | ATR ID
    | '(' ')' op_body
    | '(' args ')' op_body
    ;


inst:


expressao: ID
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
         
         | expressao '~' expressao
         | expressao '&' expressao
         | expressao '|' expressao
         | expressao ATR expressao
         
         | left_value ATR expressao


left_value: ID
          | '*' left_value
          | left_value '[' expressao ']'
          ;


parametro: tipo ID
         | tipo '*' ID
         ;

body: '{}'
    |needs an empty
    ;


%%
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
