#!/usr/bin/env bash

emulator/ext/asm6/asm6 emulator/tst/$1.s emulator/bin/$1

result=$(pynesemu emulator/bin/$1)
expected=$(cat emulator/res/$1.r)

diff -y --suppress-common-lines <(echo "$result") <(echo "$expected")