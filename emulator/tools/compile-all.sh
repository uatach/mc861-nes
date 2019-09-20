#!/usr/bin/env bash

for filepath in emulator/tst/*
do
  filename=$(basename -- "$filepath")
  name="${filename%.*}"
  out=$(emulator/ext/asm6/asm6 emulator/tst/$filename emulator/bin/$name)
done
