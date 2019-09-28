#!/usr/bin/env bash

name=$(basename -- "$1")
out=$(emulator/ext/asm6/asm6 emulator/tst/$name.s emulator/bin/$name)
result=$(pynesemu -vv emulator/bin/$name)
expected=$(cat emulator/res/$name.r)

diff --suppress-common-lines <(echo "$result") <(echo "$expected") 2>&1
