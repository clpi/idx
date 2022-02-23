#include <stdio.h>

const extern char* USAGE;

void pusage() {
    printf("\n\x1b[34;1mIDLE\x1b[33;1m+ \x1b[34;1mCLI\x1b[34;1m\x1b[0m v0.0.1\n\n");
    printf("\x1b[32;1mSUBCOMMANDS:\x1b[0m%s\n\x1b[33;1mOPTIONS:\x1b[0m%s",
        R"(
  run, r                  run file
  new, n                  new workspace
  config, c               edit config
        )",
        R"(
  --data=<dir>            set application data path
  -h --help               show this screen
  --version               show version
        )"
   );
}


