#!/bin/bash
set -e
ca65 helloworld.asm
ca65 reset.asm
ld65 *.o -t nes -o helloworld.nes
java --illegal-access=deny -jar nintaco/bin/Nintaco.jar helloworld.nes 