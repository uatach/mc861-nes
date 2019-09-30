#!/usr/bin/env bash

mkdir -p emulator/bin

for filepath in emulator/tst/*
do
  filename=$(basename -- "$filepath")
  name="${filename%.*}"
  out=$(emulator/ext/asm6/asm6 emulator/tst/$filename emulator/bin/$name 2>&1)
  case "$out" in
    *"nothing to do"*)
      echo "File is empty - $filename"
      ;;
  esac
done
