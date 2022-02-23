#include "util/cli.h"
using namespace std;

int main(int argc, char** argv) {
    pusage();
    for (int i = 0; i < argc; i++) 
        printf("\x1b[32;1mArg %d\x1b[0m = \x1b[34m%s \x1b[0m\n", i, argv[i]);
}
