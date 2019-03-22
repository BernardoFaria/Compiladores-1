%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
extern int yylineno;

#ifndef YYERRCODE
#define YYERRCODE 256
#endif
#define YYDEBUG 1
%}

%union {
	int i;			/* integer value */
    char* s;        /* string value*/
    double r;       /* (real) number value*/
};

%token <i> INT
%token <s> NAME STR
%token <r> REAL


%token FOR VOID INTEGER STRING PUBLIC NUMBER CONST IF THEN ELSE WHILE DO IN STEP UPTO DOWNTO BREAK CONTINUE

%nonassoc '[' '('

%nonassoc INC DEC

%left '*' '/' '%'
%left '+' '-'

%left '<' '>' GE LE
%left EQ NE
%nonassoc '~'
%left '&' '|' 
%right ASSIGN






%%
file	:
	;
%%
char **yynames =
#if YYDEBUG > 0
		 (char**)yyname;
#else
		 0;
#endif
int yyerror(char *s) { printf("%d:%s\n",yylineno,s); return 1; }
char *dupstr(const char*s) { return strdup(s); }

int main(int argc, char *argv[]) {
	extern YYSTYPE yylval;
	int tk;
	while ((tk = yylex()))
		if (tk > YYERRCODE)
			printf("%d:\t%s\n", tk, yyname[tk]);
		else
			printf("%d:\t%c\n", tk, tk);
	return 0;
}
