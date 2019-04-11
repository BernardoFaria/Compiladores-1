%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
int yyerror(char *s);

int yydebug = 1;
%}
%union {
	int i;			/* integer value */
	double r;		/* real value */
	char *s;		/* symbol name or string literal */
    Node *n;        /* tree node */
};
%token <i> INT
%token <r> REAL
%token <s> ID STR
%token DO WHILE IF THEN FOR IN UPTO DOWNTO STEP BREAK CONTINUE
%token VOID INTEGER STRING NUMBER CONST PUBLIC 

%nonassoc SIMPLE_IF
%nonassoc ELSE 



%right ATR
%left '&' '|'
%nonassoc '~'
%left '=' NE

%left '<' '>' GE LE
%left '+' '-'

%left '*' '/' '%'


%nonassoc INCR DECR ADDR UMINUS '!'
%nonassoc '[' '('

%type<n> decls decl decl_const decl_param tipo init body instrucao algo_to_expr op_step left_value 
%type<n> parametro op_body parametros body_inst body_param expressao f_args 

%token NIL DECL_PARAM ALLOC PARAMS PARAM LOAD INDEX BODY BODY_PARAMS BODY_INSTS DECLS
%token G_ATR FUNC IF ELSE DO WHILE FOR_IN_EXPR FOR_PARAMS FOR_TO_STEP

/*
1 - int
2- real
3- str
4- ptr

8- void
*/
%{

#define INT_T 1
#define REAL_T 2
#define STR_T 3
#define PTR_T 4
#define VOID_T 8
%} 

%%
file: decls {printNode($1,0,yynames);}
    ;

decls: decls decl   {$$ = binNode(DECLS,$1,$2);}
     |              {$$ = nilNode(NIL);}
     ;


decl: PUBLIC decl_const {$$ = uniNode(PUBLIC,$2);}
    | decl_const        {$$ = $1;}
    ;

decl_const: CONST decl_param    {$$ = uniNode(CONST,$2);}
          | decl_param         
          ;

decl_param: parametro ';'       {$$ = binNode(DECL_PARAM,$1,nilNode(NIL));}
          | parametro init ';'  {$$ = binNode(DECL_PARAM,$1,$2);}
          ;


tipo: NUMBER        {$$ = nilNode(NUMBER);}
    | STRING        {$$ = nilNode(STRING);}
    | INTEGER       {$$ = nilNode(INTEGER);}
    | VOID          {$$ = nilNode(VOID);}
    ;

init: ATR INT               { $$ = uniNode(G_ATR, intNode(INT,$2)); }
    | ATR '-' INT           { $$ = uniNode(G_ATR, intNode(INT,-$3)); }
    | ATR CONST STR
    | ATR STR                { $$ = uniNode(G_ATR, strNode(STR,$2)); }
    | ATR REAL               { $$ = uniNode(G_ATR, realNode(REAL,$2)); }
    | ATR '-' REAL           { $$ = uniNode(G_ATR, realNode(REAL,-$3)); }
    | ATR ID                 { $$ = uniNode(G_ATR, strNode(ID,$2)); }
    | '(' ')' op_body               {$$ = binNode(FUNC,nilNode(NIL),$3);}
    | '(' parametros ')' op_body    {$$ = binNode(FUNC,$2,$4);}
    ;

op_body:                    {$$ = nilNode(NIL);}
       | body               {$$ = $1;}
       ;

body:'{' body_param body_inst '}'   {$$=binNode(BODY,$2,$3);}
    ;

body_param: body_param parametro ';' {$$=binNode(BODY_PARAMS,$1,$2);}
          |                          {$$=nilNode(NIL);}
          ;

body_inst: body_inst instrucao          {$$=binNode(BODY_INSTS,$1,$2);}
         |                               {$$=nilNode(NIL);}
         ;


instrucao: BREAK ';'                            {$$ = uniNode(BREAK,nilNode(NIL));}
         | BREAK INT ';'                    {$$ = uniNode(BREAK,intNode(INT,$2));}
         | CONTINUE ';'                     {$$ = uniNode(CONTINUE,nilNode(NIL));}
         | CONTINUE INT ';'                 {$$ = uniNode(CONTINUE,intNode(INT,$2));}
         | body                             {$$=$1}
         | expressao ';'                    {$$=$1}
         | IF expressao THEN instrucao %prec SIMPLE_IF      {$$=binNode(IF,$2,$4);}
         | IF expressao THEN instrucao ELSE instrucao       {$$=binNode(ELSE,binNode(IF,$2,$4),$6);}
         | DO instrucao WHILE expressao ';'                 {$$=binNode(DO,$2,uniNode(WHILE,$4));}
         | left_value '#' expressao ';'                 { $$ = binNode(ALLOC, $3, $1); }
         | FOR left_value IN expressao algo_to_expr op_step DO instrucao   {$$=binNode(FOR,binNode(FOR_PARAMS,binNode(FOR_IN_EXPR,$2,$4),binNode(FOR_TO_STEP,$5,$6)),$8);}
         ;

//FIXFROMHERE

algo_to_expr: UPTO expressao               {$$ = nilNode(UPTO);}
       | DOWNTO expressao             {$$ = nilNode(DOWNTO);}
       ;

op_step:                    {$$ = nilNode(NIL);}
       | STEP expressao     {$$ = uniNode(STEP,$2);}
       ;

expressao: left_value                       
         | INT  {$$ = intNode(INT,$1);}
         | REAL {$$ = realNode(REAL,$1);}
         | STR  {$$ = strNode(STR,$1);}

         | '(' expressao ')'                { $$ = $2; }

         | expressao '(' f_args ')'
         | expressao '(' ')'
         
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
         
         | left_value ATR expressao { $$ = binNode(ATR, $3, $1); }
         ;

f_args: f_args ',' expressao
      | expressao
      ;

left_value: ID                              {$$=strNode(ID,$1);}
          | '*' left_value                  {$$= uniNode(LOAD,$2); $$->info=PTR_T;}
          | left_value '[' expressao ']'    {$$= binNode(INDEX,$1,$3);$$->info = PTR_T;}
          ;

parametros: parametros ',' parametro    {$$=binNode(PARAMS,$3,$1);}
          | parametro                   {$$=binNode(PARAMS,$1,nilNode(NIL));}
          ;


parametro: tipo ID          {$$ = binNode(PARAM,$1,strNode(ID,$2));}
         | tipo '*' ID      {$$ = binNode(PARAM,$1,uniNode(LOAD,strNode(ID,$3)));}
         ;



%%
char **yynames =
#if YYDEBUG > 0
         (char**)yyname;
#else
         0;
#endif
// int yyerror(char *s) { printf("%s\n", s); return 0; }
// int main() { return yyparse(); }
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
