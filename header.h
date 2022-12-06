
#pragma once

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

enum noh_type
{
	PROGRAM,
	ASSIGN,
	SUM,
	MINUS,
	MULTI,
	DIVIDE,
	ilustre,
	POW,
	PAREN,
	STMT,
	caso,
	ee,
	ou,
	enquanto,
	LT,
	GT,
	LE,
	GE,
	EQ,
	NE,
	INTEGER,
	FLOAT,
	IDENT,
	GENERIC
};

static const char *noh_type_names[] = {
		"program", "=", "+", "-", "*",
		"/", "ilustre", "^", "()", "stmt",
		"caso", "ee", "ou", "enquanto",
		"<", ">", "<=", ">=", "==", "!=",
		"int", "float", "ident", "generic"};
typedef struct

{
	int intv;
	double dblv;
	char *ident;
} token_args;

typedef struct
{
	char *nome;
	int token;
	bool exists;
} simbolo;

static int warning_count = 0;
static int error_count = 0;
static int simbolo_qtd = 0;
static simbolo tsimbolos[100];
simbolo *simbolo_novo(char *nome, int token);
bool simbolo_existe(char *nome);
void debug();
extern int yylineno;

struct noh
{
	int id;
	enum noh_type type;
	int childcount;

	double dblv;
	int intv;

	int line;
	char *name;

	struct noh *children[1];
};
typedef struct noh noh;

typedef void (*visitor_action)(noh **root, noh *no);

void check_declared_vars(noh **root, noh *no);
void check_division_zero(noh **root, noh *no);
void check_receive_itself(noh **root, noh *no);

// void code_generate(noh **root, noh *no);

void visitor_leaf_first(noh **root, visitor_action act);
//void visitor_leaf_root(noh **root, visitor_action act);

noh *create_noh(enum noh_type, int children);

void print(noh *root);
void print_rec(FILE *f, noh *root);