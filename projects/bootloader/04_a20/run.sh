#!/bin/bash

# Compile assembly code to binary.
nasm -f bin first_stage.asm -o first_stage.bin
nasm -f bin second_stage.asm -o second_stage.bin

# Creat disk image.
dd if=/dev/zero of=disk.img bs=512 count=2
dd if=first_stage.bin of=disk.img conv=notrunc
dd if=second_stage.bin of=disk.img seek=1

# Run in QEMU.
qemu-system-i386 -drive file=disk.img,format=raw

# Cleanup.
rm first_stage.bin second_stage.bin disk.img
