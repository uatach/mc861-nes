#!/usr/bin/env bash
cd game
asm6f rom.asm rom.nes
mednafen rom.nes
