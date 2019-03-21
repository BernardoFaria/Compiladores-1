%option yylineno stack
%{
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"
void yyerror(char *s);

%}

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


\"((\\.)|[^\\"])*\"        printf("start :%d\n",yyleng);yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;
\"                      BEGIN STR_BLOCK;



<STR_BLOCK>\\\"        strcat(yylval.s,yytext+1);
<STR_BLOCK>\"          BEGIN 0; printf("STRING:%s\n",yylval.s); return STR;


<STR_BLOCK>\\[nrt]          strcat(yylval.s, yytext);
<STR_BLOCK>\0|\\0|\\00      yyerror("Invalid escape sequence in string");
<STR_BLOCK>\\([0-9A-Fa-f]{2}|[0-9A-Fa-f]) printf("%s",yytext); 
<STR_BLOCK>\\.              yyerror("Invalid escape sequence in string");
<STR_BLOCK>.|\n             strcat(yylval.s, yytext);



[0-9]+			yylval.i = strtol(yytext, 0, 10); return INT;


[-+*/%!&|~<>();,\[\]{}#] return *yytext;
[ \n\r\t]+      ;
.			yyerror("Unknown character");
\n ;//yylineno flex increment
\0 printf("bye");
%%
int yywrap(void) { return 1; }
char *getyytext() { return yytext; }
