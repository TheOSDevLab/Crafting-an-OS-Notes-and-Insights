#!/bin/bash

# Assemble main.asm into a flat binary image (main.img).
nasm -f bin main.asm -o main.img

# Boot the image using QEMU
qemu-system-i386 -fda main.img
