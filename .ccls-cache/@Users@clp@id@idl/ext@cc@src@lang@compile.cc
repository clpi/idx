#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "iostream"
#include "token.h"
using namespace std;

static void compile(char *file, char *def) {
    FILE *infile, *ofile;
    std::string opath;
    if (file) {
        if ((infile = fopen(file, "r")) == NULL)
           printf("No such file %s", file);
    }
}
