
#pragma once

#include <stdio.h>

enum noh_type {PROGRAM,
	ASSIGN, SUM, MINUS, MULTI,
	DIVIDE, PRINT, POW,
	IF, AND, OR, WHILE,
	LT, GT, LE, GE, EQ, NE,
	PAREN, STMT, INTEGER, FLOAT,
	IDENT, GENERIC};

static const char *noh_type_names[] = {
	"program", "=", "+", "-", "*",
	"/", "print", "^", "()","stmt",
	"if", "and", "or", "while",
	"<", ">", "<=", ">=", "==", "!=",
	"int", "float", "ident", "generic"
};

typedef struct {
	int intv;
	double dblv;
	char *ident;
} token_args;

struct noh {
	int id;
	enum noh_type type;
	int childcount;

	double dblv;
	int intv;

	char *name;

	struct noh *children[1];
};
typedef struct noh noh;

noh *create_noh(enum noh_type, int children);

void print(noh *root);
void print_rec(FILE *f, noh *root);

