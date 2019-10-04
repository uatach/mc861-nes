#!/bin/bash

FILES=emulator/bin/*
for file in $FILES
do
    echo $(basename $file)
    bash make all
    bash pynesemu emulator/bin/$(basename $file) >> emulator/lixo/$(basename $file.r) 
done

