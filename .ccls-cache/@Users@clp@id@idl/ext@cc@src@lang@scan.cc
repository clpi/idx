#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "iostream"
#include "token.h"
using namespace std;

static int skip(void) {
    int c;
    return c;
}
static int next(void) {
    int c;
    return (c);
}
static int scanint(int c) {
    int k, val = 0;
    // while (())
    return k;
}

int scan(struct token *t) {
    int c; 
    c = skip();
    switch (c) {
        case EOF: return 0;
        case '+': t->token = t_add; break;
        case '-': t->token = t_sub; break;
        case '/': t->token = t_div; break;
        case '*': t->token = t_mul; break;
        case '|': t->token = t_or;  break;
        case '&': t->token = t_and; break;
        case '^': t->token = t_xor; break;
        default: 
            if (isdigit(c)) {
                t->intval = scanint(c);
                t->token = t_litint;
                break;
            }
    }
    return 1;
}

int main() {
    cout << "hi";
}
