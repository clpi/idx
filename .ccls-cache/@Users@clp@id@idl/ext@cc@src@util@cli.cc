#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char* USAGE = R"(SUBCOMMANDS:
  run, r                  run file
  new, n                  new workspace
  config, c               edit config

OPTIONS:
  --data=<dir>            set application data path
  -h --help               show this screen
  --version               show version
)";

void usage() {
    printf("\x1b[35;1m[IDLE]\x1b[0m\n");
    printf("%s", USAGE);
}


