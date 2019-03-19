%{
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"
void yyerror(char *s);
%}
%%



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






[0-9]+			yylval.i = strtol(yytext, 0, 10); return INT;
.			yyerror("Unknown character");
%%
int yywrap(void) { return 1; }
char *getyytext() { return yytext; }
