alias r := run
alias b := build
alias c := clean
alias w := wasm
alias t := test
alias br := brun

src := "src/"
out := "dist/"
bin := "dist/bin/"
obj := "dist/obj/"
nam := "idcc"

default: clean brun

clean:
    @echo "\x1b[33;1m[CLEAN] \x1b[0m\x1b[33m{{nam}} \x1b[33;1m::\x1b[0m {{out}}..."
    @rm -rf {{out}} && mkdir -p {{out}}{{bin}} {{out}}{{obj}}

build +file="main.zig": clean
    @echo "\x1b[33;1m[BUILD] \x1b[0m\x1b[33m{{nam}} \x1b[33;1m::\x1b[0m {{src}}{{file}}..."
    @zig build-exe {{src}}{{file}} -o {{bin}}{{nam}}

test file="src/main.zig" +args="":
    @echo "\x1b[33;1m[TEST]  \x1b[0m\x1b[33m{{nam}} \x1b[33;1m::\x1b[0m {{bin}}{{nam}}..."
    zig test {{file}}

brun +ARGS="":
    @echo "\x1b[32;1m[BRUN]  \x1b[0m\x1b[32m{{nam}} \x1b[32;1m::\x1b[0m {{bin}}{{nam}}..."
    zig build run -- {{ARGS}}

run file="src/main.zig" +args="":
    @echo "\x1b[32;1m[RUN]   \x1b[0m\x1b[32m{{nam}} \x1b[32;1m::\x1b[0m {{bin}}{{nam}}..."
    @zig run {{file}} -- {{args}}
# build-exe -o {{bin}}{{nam}} {{src}}{{file}} && {{bin}}{{nam}} {{args}}

wasm:
    @echo "\x1b[33;1m[WASM]  \x1b[0m\x1b[33m{{nam}} \x1b[39;1m::\x1b[0m {{bin}}{{nam}}..."
    @wasm3 {{out}}{{bin}}{{nam}}.wasm

fmt:
    @echo "\x1b[33;1m[FMT]   \x1b[0m\x1b[33m{{nam}} \x1b[39;1m::\x1b[0m {{bin}}{{nam}}..."

install:
    @echo "\x1b[33;1m[INSTALL]\x1b[0m\x1b[33m{{nam}} \x1b[39;1m::\x1b[0m {{bin}}{{nam}}..."

ls:
    @just --list

notify:
    @osascript -e 'display notification \
        "{{nam}} ran successfully" \
        with title "{{nam}} OK"\
        subtitle "from justfile"'

lsf +ext="":
    #!/usr/bin/env zsh
    echo "\x1b[33;1mFILES\x1b[0m in \x1b[39;1m{{src}}\x1b[0m"
    for file in `ls {{src}}`; do
        echo " - \x1b[33;1mF:\x1b[0m {{src}}\x1b[39;1m$file\x1b[0m"
    done

push +MESSAGE="":
    git add --a
    git commit -m {{MESSAGE}}
    git push gh master

