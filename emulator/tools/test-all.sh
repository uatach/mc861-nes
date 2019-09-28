#!/usr/bin/env bash

for filepath in emulator/bin/*
do
  echo "-- $filepath"
  bash emulator/tools/test.sh $filepath 2>/dev/null
done
