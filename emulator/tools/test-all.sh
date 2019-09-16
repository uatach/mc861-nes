#!/usr/bin/env bash

for filepath in emulator/tst/*
do
  filename=$(basename -- "$filepath")
  name="${filename%.*}"

  out=$(emulator/ext/asm6/asm6 emulator/tst/$filename emulator/bin/$name)

  result=$(pynesemu emulator/bin/$name 2>/dev/null)
  expected=$(cat emulator/res/$name.r)

  diff -y --suppress-common-lines <(echo "$result") <(echo "$expected")
done
