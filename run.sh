#!/bin/bash
ca65 helloworld.asm && ld65 helloworld.o -t nes -o helloworld.nes && java --illegal-access=deny -jar nintaco/bin/Nintaco.jar helloworld.nes 