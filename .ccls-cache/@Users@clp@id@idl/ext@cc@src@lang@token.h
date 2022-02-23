
struct token {
    int token;
    char charval;
    char* strval;
    int intval;
};

enum {
    t_add, t_sub, t_mul, t_div, t_or, t_and, t_not, t_xor, 
    t_litint,
    t_unknown, t_eof,
} tokenVal;
