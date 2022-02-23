#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#if !defined (_OS_WINDOWS_) || defined(_COMPILER_GCC_)
#include <getopt.h>
#endif
#include <libgen.h>
#include <signal.h>
#include <grp.h>

int main() {
	char str[100];
	printf("Enter a value...");
	gets(str);
	printf("\nEntered: ");
	puts(str);
	return 0;
}
