%{
#include <stdio.h>
#include <stdlib.h>
#include "header.h"
#include <string.h>

int yyerror(const char *s) ;
int yylex (void)           ;

extern int yylineno ;
%}

%union {
	token_args args ;
	struct noh *no  ;
}

%define parse.error verbose

%token TOK_ilustre TOK_enquanto TOK_ee TOK_ou TOK_caso TOK_casonao
%token <args> TOK_IDENT TOK_INTEGER TOK_FLOAT

%type <no> program stmts stmt atribuicao aritmetica
%type <no> logical caso enquanto lfactor lterm
%type <no> term term2 factor

%start program

%%
program : stmts

{
			 noh *program = create_noh(PROGRAM, 1) ;
			 program->children[0] = $1                       ;
			 print(program)                                  ;
			 debug()                                         ;

			 // chamada da árvore abstrata
			 // chamada da verificação semântica
			 visitor_leaf_first(&program, check_declared_vars)  ;
			 visitor_leaf_first(&program, check_division_zero)  ;
			 visitor_leaf_first(&program, check_receive_itself) ;
			 // chamada da geração de código
			 //visitor_leaf_first(&program, code_generate)      ;
		 }
;

stmts : stmts stmt {
			noh *n = $1                                                      ;
			n = (noh*)realloc(n, sizeof(noh) + sizeof(noh*) * n->childcount) ;
			n->children[n->childcount] = $2                                  ;
			n->childcount++                                                  ;
			$$ = n                                                           ;
		}
| stmt {
	 		$$ = create_noh(STMT, 1)                              ;
			$$->children[0] = $1                                             ;
		}
	;

stmt : atribuicao {
	 		$$ = $1                               ;
	 }
| TOK_ilustre aritmetica ';'{
	 		$$ = create_noh(ilustre, 1) ;
			$$->children[0] = $2                   ;
	 }

;

atribuicao : TOK_IDENT '=' aritmetica ';'{
	 			$$ = create_noh(ASSIGN, 2)     ;
				noh *aux = create_noh(IDENT, 0) ;
				aux->name = $1.ident                      ;
				$$->children[0] = aux                     ;
				$$->children[1] = $3                      ;
				if (!simbolo_existe($1.ident))
					simbolo_novo($1.ident, TOK_IDENT);
		}
| caso { $$ = $1                              ; }
| enquanto { $$ = $1                          ; }
;

caso : TOK_caso '(' logical ')' '{' stmts '}' {
				$$ = create_noh(caso, 2)                              ;
				$$->children[0] = $3                                            ;
				noh *aux = $6                                                   ;
				if(aux->childcount == 1){
					$$->children[1] = aux->children[0]                             ;
					free(aux)                                                      ;
				}
				else{
					$$->children[1] = aux                                          ;
				}
			}
| TOK_caso '(' logical ')' '{' stmts '}' TOK_casonao caso{
				$$ = create_noh(caso, 3)                              ;
				$$->children[0] = $3                                            ;
				$$->children[2] = $9                                            ;
				noh *aux = $6                                                   ;
				if(aux->childcount == 1){
					$$->children[1] = aux->children[0]                             ;
					free(aux)                                                      ;
				}
				else{
					$$->children[1] = aux                                          ;
				}
				}
| TOK_caso '(' logical ')' '{' stmts '}' TOK_casonao '{' stmts '}'{
				$$ = create_noh(caso, 3)                              ;
				$$->children[0] = $3                                            ;				
				noh *aux = $6                                                   ;
				if(aux->childcount == 1){
					$$->children[1] = aux->children[0]                             ;
					free(aux)                                                      ;
				}
				else{
					$$->children[1] = aux                                          ;
				}
				aux = $10                                                       ;
				if(aux->childcount == 1){
					$$->children[2] = aux->children[0]                             ;
					free(aux)                                                      ;
				}
				else{
					$$->children[2] = aux                                          ;
				}
				}
;

enquanto	: TOK_enquanto '(' logical ')' '{' stmts '}'{
							$$ = create_noh(enquanto, 2)          ;
							$$->children[0] = $3                            ;
							noh *aux = $6                                   ;
							if(aux->childcount == 1){
								$$->children[1] = aux->children[0]             ;
								free(aux)                                      ;
							}
							else{
								$$->children[1] = aux                          ;
							}
							}
		;

logical : logical TOK_ou lterm	{
							$$ = create_noh(ou, 2) ;
							$$->children[0] = $1             ;
							$$->children[1] = $3             ;
							}
		| lterm				{
			$$ = $1                              ;
		}
		;

lterm	: lterm TOK_ee lfactor	{
								$$ = create_noh(ee, 2) ;
							 $$->children[0] = $1             ;
							 $$->children[1] = $3             ;
							}
		| lfactor	{
			$$ = $1                               ;
		}
		;

lfactor : '(' logical ')'	{
								$$ = $2                          ;
		}
		| aritmetica '>' aritmetica		{
								$$ = create_noh(GT, 2) ;
							 $$->children[0] = $1             ;
							 $$->children[1] = $3             ;
							}
		| aritmetica '<' aritmetica		{
								$$ = create_noh(LT, 2) ;
							 $$->children[0]= $1              ;
							 $$->children[1] = $3             ;
							}
		| aritmetica '=''=' aritmetica	{
								$$ = create_noh(EQ, 2) ;
							 $$->children[0] = $1             ;
							 $$->children[1] = $4             ;
							}
		| aritmetica '>''=' aritmetica	{
								$$ = create_noh(GE, 2) ;
							 $$->children[0] = $1             ;
							 $$->children[1] = $4             ;
							}
		| aritmetica '<''=' aritmetica	{
								$$ = create_noh(LE, 2) ;
							 $$->children[0] = $1             ;
							 $$->children[1] = $4             ;
							}
		| aritmetica '!''=' aritmetica {
								$$ = create_noh(NE, 2)         ;
								$$->children[0] = $1                     ;
								$$->children[1] = $4                     ;
}
		;

aritmetica : aritmetica '+' term {
	 			$$ = create_noh(SUM, 2)   ;
				$$->children[0] = $1                 ;
				$$->children[1] = $3                 ;
	 		}
		 | aritmetica '-' term {
	 			$$ = create_noh(MINUS, 2) ;
				$$->children[0] = $1                 ;
				$$->children[1] = $3                 ;
	 		}
| term {
		 		$$ = $1                             ;
	 		}
		;

term : term '*' term2 {
	 		$$ = create_noh(MULTI, 2)  ;
			$$->children[0] = $1                  ;
			$$->children[1] = $3                  ;	
	 }
| term '/' term2 {
	 		$$ = create_noh(DIVIDE, 2) ;
			$$->children[0] = $1                  ;
			$$->children[1] = $3                  ;	
	 }
| term2 {
	 		$$ = $1                              ;
	 }
	;

term2 : term2 '^' factor {
	 		$$ = create_noh(POW, 2) ;
			$$->children[0] = $1               ;
			$$->children[1] = $3               ;
		}
| factor {
	 		$$ = $1                           ;
	 	}
	;

factor : '(' aritmetica ')' {
			$$ = $2                                ;
		 }
| TOK_IDENT {
	 		$$ = create_noh(IDENT, 0)   ;
			$$->name = $1.ident                    ;
			if (!simbolo_existe($1.ident))
				simbolo_novo($1.ident, TOK_IDENT)     ;
	 }
	 | TOK_INTEGER {
	 		$$ = create_noh(INTEGER, 0) ;
			$$->intv = $1.intv                     ;
	 	 }
	 | TOK_FLOAT {
	 		$$ = create_noh(FLOAT, 0)   ;
			$$->dblv = $1.dblv                     ;
	 	 }
	;

%%

int yyerror(const char *s) {
printf("Erro na linha %d: %s\n", yylineno, s) ;
	return 1                                     ;
}
