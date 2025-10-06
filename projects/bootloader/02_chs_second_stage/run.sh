# Compile the two bootloader stages.
nasm -f bin first_stage.asm -o first_stage.bin
nasm -f bin second_stage.asm -o second_stage.bin

# Create disk image.
dd if=/dev/zero of=disk.img bs=512 count=2
dd if=first_stage.bin of=disk.img conv=notrunc
dd if=second_stage.bin of=disk.img bs=512 seek=1

# Boot the image using QEMU
qemu-system-i386 -drive file=disk.img,format=raw
# qemu-system-i386 -fda disk.img # Removing the comment on this line and commenting the line above will cause read failure. ERROR CODE 1.

# Cleanup.
rm first_stage.bin second_stage.bin disk.img
