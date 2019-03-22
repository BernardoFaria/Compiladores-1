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
%}
REAL [0-9]*\.?[0-9]*([eE][-+]?[0-9]+)?
%x M_COM STR_BLOCK
%%
<M_COM>"=<"     yy_push_state(M_COM);
<M_COM>"=>"     yy_pop_state();
<M_COM>.        ;

"==".*          ;//Comment
"=<"            yy_push_state(M_COM);                 
"for"			return FOR;
"void"          return VOID;
"integer"       return INTEGER;
"string"        return STRING;
"public"        return PUBLIC;
"number"        return NUMBER;
"const"         return CONST;
"if"            return IF;
"then"          return THEN;
"else"          return ELSE;
"while"         return WHILE;
"do"            return DO;
"in"            return IN;
"step"          return STEP;
"upto"          return UPTO;
"downto"        return DOWNTO;
"break"         return BREAK;
"continue"      return CONTINUE;

"++"            return INC;
"--"            return DEC;
"<="            return LE;
">="            return GE;
"="             return EQ;
"<>"            return NE;
":="            return ASSIGN;



[a-zA-Z_\b][a-zA-Z_\b0-9]* yylval.s = dupstr(yytext); return NAME;

\"((\\.)|[^\\"])*\"        printf("start :%d\n",yyleng);yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;
\"                      BEGIN STR_BLOCK;


<STR_BLOCK>\\\"        strcat(yylval.s,yytext+1);
<STR_BLOCK>\"          BEGIN 0; printf("STRING:%s\n",yylval.s); return STR;


<STR_BLOCK>\\[nrt]          strcat(yylval.s, yytext);
<STR_BLOCK>\0|\\0|\\00      yyerror("Invalid escape sequence in string");
<STR_BLOCK>\\([0-9A-Fa-f]{2}|[0-9A-Fa-f]) printf("%s",yytext); 
<STR_BLOCK>\\.              yyerror("Invalid escape sequence in string");
<STR_BLOCK>.|\n             strcat(yylval.s, yytext);



[1-9][0-9]*			yylval.i = diyinteger(yytext,10); return INT;
0[0-9]*             yylval.i = diyinteger(yytext,8); return INT;
0b[0-1]+            yylval.i = diyinteger(yytext+2,2); return INT;

{REAL}              {errno=0;yylval.r = strtod(yytext,NULL);
                    if (errno == ERANGE) yyerror("Real overflow");printf("%lf\n",yylval.r);return REAL;}


[-+*/%!&|~<>();,\[\]{}#] return *yytext;
[ \n\r\t]+      ;
.			yyerror("Unknown character");
\n ;//yylineno flex increment
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
