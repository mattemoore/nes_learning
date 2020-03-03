#!/bin/bash
set -e
ca65 src/helloworld.asm
ca65 src/reset.asm
ld65 src/*.o -C nes.cfg -o helloworld.nes
java --illegal-access=deny -jar tools/nintaco/bin/Nintaco.jar helloworld.nes 