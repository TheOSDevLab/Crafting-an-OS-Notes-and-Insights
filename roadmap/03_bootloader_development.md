# Bootloader Development

> **Random Quote**: The oak fought the wind and was broken, the willow bent when it must and survived.

## 1. Boot

Covered here: [Boot](../notes/03_bootloader_development/01_boot.md)

+ Boot sequence.
+ Boot sector and bootloader size.
+ Boot signature.
+ Where the BIOS loads the bootloader in memory.

---

## 2. Memory Layout

Covered here: [Memory Layout](../notes/03_bootloader_development/02_memory_layout.md)

+ Memory layout in Real Mode.
+ Key memory regions.

---

## 3. Calculating Memory Sizes

Covered here: [Calculating Memory Sizes](../notes/03_bootloader_development/03_memory_size_calculation.md)

+ Methods for determining the size of memory ranges (e.g., from `0x7C00` to `0x7CFF`).  
+ Binary interpretation of storage units, such as 1 KiB = 1024 bytes, 1 MiB = 1024 KiB, etc.  

---

## 4. Memory Addressing

Covered here: [Memory Addressing](../notes/03_bootloader_development/04_memory_addressing.md)

+ Principles of segment:offset addressing in real mode.  
+ Classification of memory regions (e.g., `0x0000`-`0xFFFF`).  
+ Determination of the maximum addressable memory range.  

---

## 5. Stack

Covered here: [Stack](../notes/03_bootloader_development/05_stack.md)

+ What the stack is.
+ What it is used for.
+ How to set up a stack properly.

---

## Hello World Project

Covered here: [Hello World Project](../projects/bootloader/01_hello_world/README.md)

+ Write a basic bootloader that:

    - Initialize the stack in a secure memory region.  
    - Use BIOS interrupts to display the message "Hello World!".  
    - Ensure the program size is exactly 512 bytes.  
    - Include the standard boot signature.  
    - Specify to the assembler the memory address where the bootloader will be loaded.  

**Note**: The assembly concepts required for this task were explained in the previous section of the roadmap. If you are not familiar with these concepts, please review [this roadmap](./02_assembly.md).

---

## 6. Second Stage Bootloader

+ [Second stage bootloader introduction](../notes/03_bootloader_development/06_second_stage_bootloader/README.md)
+ [CHS addressing](../notes/03_bootloader_development/06_second_stage_bootloader/chs.md)
+ [LBA addressing](../notes/03_bootloader_development/06_second_stage_bootloader/lba.md)
+ [Basics of the `dd` command.](../notes/command_line_tools/dd/README.md)
+ [BIOS INT 13h introduction](https://github.com/TheOSDevLab/Bare-Metal-Assembly/tree/main/notes/05_bios_interrupts/int13h)
+ [Read sectors using CHS addressing (BIOS INT 13h AH=02h)](https://github.com/TheOSDevLab/Bare-Metal-Assembly/blob/main/notes/05_bios_interrupts/int13h/02h.md)
+ [Read sectors using LBA addressing (BIOS INT 13H AH=42h)](https://github.com/TheOSDevLab/Bare-Metal-Assembly/blob/main/notes/05_bios_interrupts/int13h/42h.md)
+ [QEMU basics](../notes/command_line_tools/qemu/introduction.md)

---

## CHS Second Stage Project

Covered [here](../projects/bootloader/02_chs_second_stage/README.md)

1. **First Stage Bootloader:**

   - Use BIOS interrupt `INT 13h AH=02h` (Read Sectors From Drive using CHS addressing) to load the second stage bootloader
   - Read starting from sector 2 into memory at address `0x7E00`
   - Transfer execution to the second stage via a far jump

   *Note: This implementation assumes a 512-byte second stage located immediately after the boot sector.*

2. **Second Stage Bootloader:**

   - Display a boot message confirming successful handoff (e.g., "Second Stage Loaded!")
   - Execute a safe termination (halt loop or software interrupt)

3. **Disk Image Assembly:**

   - Use `dd` to create a disk image with correct sector alignment
   - Write the first stage to the master boot record (sector 0)
   - Write the second stage to the subsequent sector (sector 1)

---

## LBA Second Stage Project

+ First stage will load the second stage using LBA addressing.
+ The second stage should be 128 KB in size.
+ In the first sector of the second stage, print something.
+ Pad with zeros until the last sector.
+ In the last sector of the second stage, print something different.
+ Load the second stage at `0x1000:0x0000`.

---
