%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
int yyerror(char *s);


int IDdebug =1;
char* name;
char* decl_name;
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

%type<n> decls decl tipo init body instrucao algo_to_expr op_step left_value public const
%type<n> parametro op_body parametros body_inst body_param expressao f_args 

%token NIL DECL_PARAM ALLOC PARAMS PARAM LOAD INDEX BODY BODY_PARAMS BODY_INSTS DECLS F_ARGS DECL DECL_OP
%token G_ATR FUNC IF ELSE DO WHILE FOR_IN_EXPR FOR_PARAMS FOR_TO_STEP CALL 
%token FATORIAL NOT OR AND MUL DIV MOD ADD SUBARU LT GT EQ

/*
1 - int
2- real
3- str

1111

4- ptr

8- void
*/
%{
#define INT_T 1
#define REAL_T 2
#define STR_T 256
#define VOID_T 512

#define PTR_T 8
#define CONST_T 16
#define PUBLIC_T 32
#define FUNC_T 64
#define EL_CONST_T 128;

#define checkBit(mask,flag) ((mask & (flag)))
#define getInfoBasic(x) (x & (INT_T|REAL_T|STR_T|VOID_T))
#define removeBit(info,flag) (info & ~(flag))
%} 

%%
file: decls {printNode($1,0,yynames);}
    ;

decls: decls decl   {$$ = binNode(DECLS,$1,$2);   }
     |              {$$ = nilNode(NIL);}
     ;


public: PUBLIC  {$$ = nilNode(PUBLIC); $$->info=PUBLIC_T;}
    |         {$$ = nilNode(NIL);  $$->info=0;}
    ;

const: CONST     {$$ = nilNode(CONST); $$->info=CONST_T;}
    |            {$$ = nilNode(NIL); $$->info=0;}
    ;

decl: public const parametro ';'       {$$ = binNode(DECL,binNode(DECL_OP,$1,$2),binNode(DECL_PARAM,$3,nilNode(NIL))); 
        $$->info = $1->info | $2->info | $3->info; if(IDfind(name,0)!=-1) IDreplace($$->info,name,0); else printf("ERROR in replace type");
        if(checkBit($$->info, CONST_T))yyerror("Const declaration without assigned value");}
    | public const parametro {decl_name=name;} init ';'  {$$ = binNode(DECL,binNode(DECL_OP,$1,$2),binNode(DECL_PARAM,$3,$5)); 
        if(getInfoBasic($3->info) == getInfoBasic($5->info) || checkBit($5->info,FUNC_T)){
            $$->info = $1->info | $2->info | $3->info | $5->info;
            if(IDfind(decl_name,0)!=-1){
                IDreplace($$->info,decl_name,0);
            }

        }else yyerror("Cannot assign different type values on declaration");
        if(checkBit($$->info,FUNC_T)&&checkBit($$->info,CONST_T)) yyerror("Functions should not be const");
        }
    ;


tipo: NUMBER        {$$ = nilNode(NUMBER); $$->info=REAL_T;}
    | STRING        {$$ = nilNode(STRING); $$->info=STR_T;}
    | INTEGER       {$$ = nilNode(INTEGER); $$->info=INT_T;}
    | VOID          {$$ = nilNode(VOID); $$->info=VOID_T;}
    ;

init: ATR INT               { $$ = uniNode(G_ATR, intNode(INT,$2));     $$->info=INT_T;}
    | ATR '-' INT           { $$ = uniNode(G_ATR, intNode(INT,-$3));    $$->info=INT_T;}
    | ATR CONST STR         { $$ = uniNode(G_ATR, strNode(STR,$3));     $$->info=STR_T|EL_CONST_T;}
    | ATR STR                { $$ = uniNode(G_ATR, strNode(STR,$2));    $$->info=STR_T;}
    | ATR REAL               { $$ = uniNode(G_ATR, realNode(REAL,$2));  $$->info=REAL_T;}
    | ATR '-' REAL           { $$ = uniNode(G_ATR, realNode(REAL,-$3)); $$->info=REAL_T;}
    | ATR ID                 { $$ = uniNode(G_ATR, strNode(ID,$2)); int tipo = IDfind($2,0); if(tipo==-1)yyerror("ID is not defined"); $$->info=tipo;}

    | '(' {int tipo=IDfind(decl_name,0); if(tipo!=-1)IDreplace(tipo|FUNC_T,decl_name,0); } ')' op_body               {$$ = binNode(FUNC,nilNode(NIL),$4);   $$->info=FUNC_T;}
    | '(' { int tipo=IDfind(decl_name,0); if(tipo!=-1)IDreplace(tipo|FUNC_T,decl_name,0);    IDpush(); } parametros ')' op_body    {$$ = binNode(FUNC,$3,$5);IDpop(); $$->info=FUNC_T;}
    ;

op_body:                    {$$ = nilNode(NIL);}
       | body               {$$ = $1;}
       ;

body:'{' { IDpush(); } body_param body_inst '}'   {$$=binNode(BODY,$3,$4);IDpop();}
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
         | body                             {$$=$1;}
         | expressao ';'                    {$$=$1;}
         | IF expressao THEN instrucao %prec SIMPLE_IF      {$$=binNode(IF,$2,$4);}
         | IF expressao THEN instrucao ELSE instrucao       {$$=binNode(ELSE,binNode(IF,$2,$4),$6);}
         | DO instrucao WHILE expressao ';'                 {$$=binNode(DO,$2,uniNode(WHILE,$4));}
         | left_value '#' expressao ';'                 { $$ = binNode(ALLOC, $3, $1); }
         | FOR left_value IN expressao algo_to_expr op_step DO instrucao   {$$=binNode(FOR,binNode(FOR_PARAMS,binNode(FOR_IN_EXPR,$2,$4),binNode(FOR_TO_STEP,$5,$6)),$8);}
         | ';'				{ $$ = nilNode(NIL); }
         ;


algo_to_expr: UPTO expressao               {$$ = nilNode(UPTO);}
       | DOWNTO expressao             {$$ = nilNode(DOWNTO);}
       ;

op_step:                    {$$ = nilNode(NIL);}
       | STEP expressao     {$$ = uniNode(STEP,$2);}
       ;

expressao: left_value                           
         | INT  {$$ = intNode(INT,$1);      $$->info=INT_T;}
         | REAL {$$ = realNode(REAL,$1);    $$->info=REAL_T;}
         | STR  {$$ = strNode(STR,$1);      $$->info=STR_T;}

         | '(' expressao ')'                { $$ = $2; }

         | expressao '(' f_args ')'         { $$ = binNode(CALL,$1,$3); if(!checkBit($1->info,FUNC_T))yyerror("Not callable type"); $$->info=getInfoBasic($1->info);}
         | expressao '(' ')'                { $$ = binNode(CALL,$1,nilNode(NIL)); if(!checkBit($1->info,FUNC_T)){yyerror("Not callable type");} $$->info=getInfoBasic($1->info);}
         
         | '-' expressao %prec UMINUS       {$$ = uniNode(UMINUS,$2); $$->info=$2->info;        if(!((checkBit($2->info,INT_T)||checkBit($2->info,REAL_T))&&!checkBit($2->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real");}
         | expressao '!'                    {$$ = uniNode(FATORIAL,$1); if(!(checkBit($1->info,INT_T)&&!checkBit($1->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         | '&' left_value %prec ADDR        {$$ = uniNode(ADDR,$2); $$->info=$2->info | PTR_T|FUNC_T;}
         | INCR left_value                  {$$ = uniNode(INCR,$2); if(!(checkBit($2->info,INT_T)&&!checkBit($2->info,PTR_T|FUNC_T)))yyerror("Only Integer");  $$->info=INT_T; }
         | DECR left_value                  {$$ = uniNode(DECR,$2); if(!(checkBit($2->info,INT_T)&&!checkBit($2->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         | left_value INCR                  {$$ = uniNode(INCR,$1); if(!(checkBit($1->info,INT_T)&&!checkBit($1->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         | left_value DECR                  {$$ = uniNode(DECR,$1); if(!(checkBit($1->info,INT_T)&&!checkBit($1->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         
         | expressao '*' expressao          { $$ = binNode(MUL, $1, $3);   if(!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real");  if(checkBit($1->info,REAL_T)||checkBit($3->info,REAL_T)){$$->info=REAL_T;}else{$$->info=INT_T;}   }
         | expressao '/' expressao          { $$ = binNode(DIV, $1, $3); if(!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real"); if(checkBit($1->info,REAL_T)||checkBit($3->info,REAL_T)){$$->info=REAL_T;}else{$$->info=INT_T;}}
         | expressao '%' expressao          { $$ = binNode(MOD, $1, $3); if(!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real"); if(checkBit($1->info,REAL_T)||checkBit($3->info,REAL_T)){$$->info=REAL_T;}else{$$->info=INT_T;}}
         | expressao '+' expressao          { $$ = binNode(ADD, $1, $3); if(!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real"); if(checkBit($1->info,REAL_T)||checkBit($3->info,REAL_T)){$$->info=REAL_T;}else{$$->info=INT_T;}}  
         | expressao '-' expressao          { $$ = binNode(SUBARU, $1, $3); if(!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer or Real"); if(checkBit($1->info,REAL_T)||checkBit($3->info,REAL_T)){$$->info=REAL_T;}else{$$->info=INT_T;}}
         
         | expressao '<' expressao          { $$ = binNode(LT, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T; }
         | expressao '>' expressao          { $$ = binNode(GT, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T;}
         | expressao NE expressao           { $$ = binNode(NE, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T;}
         | expressao '=' expressao          { $$ = binNode(EQ, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T;}
         | expressao GE expressao           { $$ = binNode(GE, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T;}
         | expressao LE expressao           { $$ = binNode(LE, $1, $3); if((!((checkBit($1->info,INT_T)||checkBit($1->info,REAL_T))&&!checkBit($1->info,PTR_T|FUNC_T)) || !((checkBit($3->info,INT_T)||checkBit($3->info,REAL_T))&&!checkBit($3->info,PTR_T|FUNC_T))) && (!(checkBit($1->info,STR_T)&&!checkBit($1->info,PTR_T|FUNC_T)&&checkBit($3->info,STR_T)&&!checkBit($3->info,PTR_T|FUNC_T))))yyerror("Only Integer or Real or 2 strings");$$->info=INT_T;}
         
         | '~' expressao                    {$$ = uniNode(NOT,$2);      if(!(checkBit($2->info,INT_T)&&!checkBit($2->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         | expressao '&' expressao          { $$ = binNode(AND, $1, $3); if(!(checkBit($1->info,INT_T)&&!checkBit($1->info,PTR_T|FUNC_T)) || !(checkBit($3->info,INT_T)&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         | expressao '|' expressao          { $$ = binNode(OR, $1, $3);     if(!(checkBit($1->info,INT_T)&&!checkBit($1->info,PTR_T|FUNC_T)) || !(checkBit($3->info,INT_T)&&!checkBit($3->info,PTR_T|FUNC_T)))yyerror("Only Integer");$$->info=INT_T;}
         
         | left_value ATR expressao { $$ = binNode(ATR, $3, $1); $$->info=$3->info; }
         ;

f_args: f_args ',' expressao                {$$=binNode(F_ARGS,$3,$1);}
      | expressao                           {$$=binNode(F_ARGS,$1,nilNode(NIL));}
      ;

left_value: ID                              {$$=strNode(ID,$1);     int tipo = IDfind($1,0); $$->info=tipo;}
          | '*' left_value                  {$$= uniNode(LOAD,$2); $$->info=PTR_T|$2->info;/*FIXME only on type of pointer*/}
          | left_value '[' expressao ']'    {$$= binNode(INDEX,$1,$3);if(checkBit($1->info,PTR_T)){ $$->info=removeBit($1->info,PTR_T);}else if(checkBit($1->info,STR_T)){$$->info=removeBit($1->info,STR_T)|INT_T;}}
          ;

parametros: parametros ',' parametro    {$$=binNode(PARAMS,$3,$1);}
          | parametro                   {$$=binNode(PARAMS,$1,nilNode(NIL));}
          ;


parametro: tipo ID          {$$ = binNode(PARAM,$1,strNode(ID,$2)); 
            $$->info = $1->info; IDnew($$->info,$$->CHILD(1)->value.s,0);  name=$$->CHILD(1)->value.s;}
         | tipo '*' ID      {$$ = binNode(PARAM,$1,uniNode(LOAD,strNode(ID,$3))); 
            $$->info = $1->info+PTR_T; IDnew($$->info,$$->CHILD(1)->CHILD(0)->value.s,0); name=$$->CHILD(1)->CHILD(0)->value.s; }
         ;



%%
char **yynames =
#if YYDEBUG > 0
         (char**)yyname;
#else
         0;
#endif

// static Node increasePtrLevel(Node* n){

// }
// static Node decreasePtrLevel(Node* n){
    
// }
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
