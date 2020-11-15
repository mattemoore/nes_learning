#!/bin/bash
set -e
ca65 src/game.asm
ld65 src/*.o -C nes.cfg -o game.nes
java --illegal-access=deny -jar tools/nintaco/bin/Nintaco.jar game.nes 