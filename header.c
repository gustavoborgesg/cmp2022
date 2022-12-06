// header.c
#include <stdlib.h>
#include "header.h"

noh *create_noh(enum noh_type nt, int children)
{
	static int IDCOUNT = 0;
	noh *newn = (noh *)calloc(1, sizeof(noh) + sizeof(noh *) * (children - 1));
	newn->type = nt;
	newn->childcount = children;
	newn->id = IDCOUNT++;
	newn->line = yylineno;
	return newn;
}

void print(noh *root)
{
	FILE *f = fopen("output.dot", "w");

	fprintf(f, "graph {\n");
	print_rec(f, root);
	fprintf(f, "}\n");

	fclose(f);
}

const char *get_label(noh *no)
{
	static char aux[100];
	switch (no->type)
	{
	case INTEGER:
		sprintf(aux, "%d", no->intv);
		return aux;
	case FLOAT:
		sprintf(aux, "%f", no->dblv);
		return aux;
	case IDENT:
		return no->name;
	default:
		return noh_type_names[no->type];
	}
}

void print_rec(FILE *f, noh *root)
{
	fprintf(f, "N%d[label=\"%s\"];\n",
					root->id, get_label(root));
	for (int i = 0; i < root->childcount; i++)
	{
		print_rec(f, root->children[i]);
		fprintf(f, "N%d -- N%d;\n",
						root->id, root->children[i]->id);
	}
}

int search_symbol(char *nome)
{
	// busca linear, não eficiente
	for (int i = 0; i < simbolo_qtd; i++)
	{
		if (strcmp(tsimbolos[i].nome, nome) == 0)
		{
			return i;
		}
	}
	return -1;
}

void check_declared_vars(noh **root, noh *no)
{
	noh *nr = *root;

	if (no->type == ASSIGN)
	{
		int s = search_symbol(no->children[0]->name);
		if (s != -1)
			tsimbolos[s].exists = true;
	}
	else if (no->type == IDENT && nr->type != ASSIGN)
	{
		if (nr->type == ASSIGN && no == nr->children[0])
			return;
		int s = search_symbol(no->name);
		if (s == -1 || !tsimbolos[s].exists)
		{
			error_count++;
			printf("Erro (%d) Linha [%d]: Símbolo %s não declarado.\n", error_count, no->line, no->name);
		}
	}
}

void check_division_zero(noh **root, noh *no)
{
	if (no->type == DIVIDE)
	{
		noh *aux = no->children[1];
		if ((aux->type == INTEGER && aux->intv == 0) || (aux->type == FLOAT && aux->dblv == 0))
		{
			error_count++;
			printf("Erro (%d) Linha [%d]: Não é possível realizar divisão por zero.\n", error_count, no->line);
		}
	}
}

void check_receive_itself(noh **root, noh *no)
{
	if (no->type == ASSIGN)
	{
		noh *aux = no->children[0];
		noh *aux2 = no->children[1];
		if (aux->type == IDENT)
		{
			if (aux2->type == IDENT && ((aux->intv == aux2->intv) || (aux->dblv == aux2->dblv)))
			{
				warning_count++;
				printf("Warning (%d) Linha [%d]: Variável '%s' recebendo conteúdo igual à ela mesma.\n", warning_count, no->line, aux->name);
			}
		}
	}
}

void visitor_leaf_first(noh **root, visitor_action act)
{
	noh *r = *root;
	for (int i = 0; i < r->childcount; i++)
	{
		visitor_leaf_first(&r->children[i], act);
		if (act != NULL)
			act(root, r->children[i]);
	}
}

/*void visitor_leaf_root(noh **root, visitor_action act)
{
	noh *r = *root;

	visitor_leaf_root(&r->children[0], act);
	act(root, r);
	for (int i = 0; i < r->childcount; i++)
	{
		if (act != NULL)
			act(root, r->children[i]);
	}
}*/

simbolo *simbolo_novo(char *nome, int token)
{
	tsimbolos[simbolo_qtd].nome = nome;
	tsimbolos[simbolo_qtd].token = token;
	tsimbolos[simbolo_qtd].exists = false;
	simbolo *result = &tsimbolos[simbolo_qtd];
	simbolo_qtd++;
	return result;
}

bool simbolo_existe(char *nome)
{
	// busca linear, não eficiente
	for (int i = 0; i < simbolo_qtd; i++)
	{
		if (strcmp(tsimbolos[i].nome, nome) == 0)
			return true;
	}
	return false;
}

void debug()
{
	printf("Simbolos:\n");
	for (int i = 0; i < simbolo_qtd; i++)
	{
		printf("\t%s\n", tsimbolos[i].nome);
	}
}

/*void code_generate(noh **root, noh *no)
{
	if (no->type == IDENT)
		printf("%s\n", no->name);
	else if (no->type == ASSIGN)
		printf(" = ");
	else if (no->type == INTEGER)
		printf("%i", no->intv);
	else if (no->type == FLOAT)
		printf("%f", no->dblv);
}*/