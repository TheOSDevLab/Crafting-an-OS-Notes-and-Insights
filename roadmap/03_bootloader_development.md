# Bootloader Development

> **Random Quote:** Pride goes before destruction, and a haughty spirit before a fall.

A bootloader is a small program located in the boot sector, typically the first 512 bytes of a bootable storage device. It is the first code that the BIOS loads into memory and executes during the system startup process.

## Boilerplate

+ What is the boot sector.
+ What is the boot signature and why is it useful.
+ Where the BIOS loads the bootloader in memory.

## Memory Layout in real mode

+ 1 MiB addressable space.
+ Overview of conventional memory, upper memory, and BIOS regions.
+ Bootloader size and memory location.

## Memory Addressing

+ Segment and offset addressing.
+ Memory regions (e.g., `0x0000` - `0xFFFF`).

## Calculating Memory Sizes

+ How to calculate the size of memory ranges (e.g. from `0x7C00` to `0x7CFF`).
+ Understanding kilobytes, megabytes, etc., in binary terms (e.g. 1 KiB = 1024 bytes.

## Memory-Mapped I/O (MMIO)

+ Why some hardware devices appear as memory addresses.
+ Why `0xB8000` maps to video memory in text mode.
+ How the screen and keyboard can be accessed early through memory.

## Reading the kernel

+ Review how to use BIOS interrupt `INT 0x13` to read the kernel from disk into memory.
+ You are not required to understand filesystems at this stage, but you may explore them if you wish.

## A20 Line

+ What is the A20 line?
+ Why do we need to enable the A20 line?
+ Different methods of enabling the A20 line (understand all, but use the most practical one).

## GDT (Global Descriptor Table)

+ What is the GDT?
+ What's its function in transitioning to protected mode?

## Switching to Protected Mode

+ Disabling interrupts.
+ Loading the GDT.
+ Setting the PE (Protection Enable) bit in the `CR0` register.
+ Performing a far jump to 32-bit code.

## Bootloader Stages

+ Understand first-stage and second-stage bootloaders.
+ Find out why multiple stages are used.
+ Get the roles of each stage.
