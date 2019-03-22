%option yylineno stack
%{
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"
void yyerror(char *s);
char *dupstr(const char *s);
int diyinteger(char *s,int base);
int f(int token); //funcao para processar insercao ;
%}

REAL [0-9]*\.?[0-9]*([eE][-+]?[0-9]+)?
S_SYMBOLS [-+*/%!&|~<>();,\[\]{}#]
STR_HEX \\([0-9A-Fa-f]{2}|[0-9A-Fa-f])
%x M_COM STR_BLOCK

%%
<M_COM>"=<"     yy_push_state(M_COM);
<M_COM>"=>"     yy_pop_state();
<M_COM>.        ;

"==".*          ;//Comment
"=<"            yy_push_state(M_COM);                 
"for"           return f(FOR);
"void"          return f(VOID);
"integer"       return f(INTEGER);
"string"        return f(STRING);
"public"        return f(PUBLIC);
"number"        return f(NUMBER);
"const"         return f(CONST);
"if"            return f(IF);
"then"          return f(THEN);
"else"          return f(ELSE);
"while"         return f(WHILE);
"do"            return f(DO);
"in"            return f(IN);
"step"          return f(STEP);
"upto"          return f(UPTO);
"downto"        return f(DOWNTO);
"break"         return f(BREAK);
"continue"      return f(CONTINUE);

"++"            return f(INC);
"--"            return f(DEC);
"<="            return f(LE);
">="            return f(GE);
"="             return f(EQ);
"<>"            return f(NE);
":="            return f(ASSIGN);



[a-zA-Z_\b][a-zA-Z_\b0-9]*  yylval.s = dupstr(yytext); return f(NAME);

\"((\\.)|[^\\"])*\"         yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;
\"                          BEGIN STR_BLOCK;


<STR_BLOCK>\\\"             strcat(yylval.s,yytext+1);
<STR_BLOCK>\"               BEGIN 0; printf("STRING:%s\n",yylval.s); return f(STR);


<STR_BLOCK>\\n              strcat(yylval.s, "\n");
<STR_BLOCK>\\r              strcat(yylval.s, "\r");
<STR_BLOCK>\\t              strcat(yylval.s, "\t");

<STR_BLOCK>\0|\\0|\\00      yyerror("Invalid escape sequence in string");
<STR_BLOCK>{STR_HEX}        sprintf(yylval.s + strlen(yylval.s),"%c",(int)strtol(yytext+1,0,16)); 

<STR_BLOCK>\\.              yyerror("Invalid escape sequence in string");
<STR_BLOCK>.|\n             strcat(yylval.s, yytext);



[1-9][0-9]*			yylval.i = diyinteger(yytext,10); return f(INT);
0[0-9]*             yylval.i = diyinteger(yytext,8); return f(INT);
0b[0-1]+            yylval.i = diyinteger(yytext+2,2); return f(INT);

{REAL}              {errno=0;yylval.r = strtod(yytext,NULL);
                    if (errno == ERANGE) yyerror("Real overflow");printf("%lf\n",yylval.r);return f(REAL);}


{S_SYMBOLS} return f(*yytext);
[ \r\t]+    ;

.			yyerror("Unknown character");
\n          {int token = f(*yytext); if(token !='\n') return token;}
%%
int yywrap(void) {
    if (YYSTATE == M_COM) yyerror("unterminated comment");
    if (YYSTATE == STR_BLOCK) yyerror("unterminated string");
    return 1; 
}

int diyinteger(char *s,int base){
  int i, a = 0, b = 0;

  for (i = 0; i < strlen(s); i++) {
    if (s[i] < '0' || s[i] > '9') break;
    b = b * base + s[i] - '0';
    if (b < a) {
      yyerror("integer overflow");
      break;
    }
    a = b;
  }
  printf("%d",a);
  return a;
}

int insert=0;

int f(int token){
    if(insert && token == '\n'){
        unput('\n');
        insert = 0;
        return ';';
    }else{
        if(token==NAME || token==')' || token=='!' || token==REAL ||
            token==INT || token==STR){
            insert=1;
        }else{
            insert=0;
        }
        return token;
    }
}
