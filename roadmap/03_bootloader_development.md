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

Covered [here](../projects/bootloader/03_lba_second_stage/README.md)

1. **First Stage Bootloader:**

   - Use BIOS interrupt `INT 13h AH=42h` (Extended Read Sectors) to load the second stage using LBA addressing.
   - Load the full 64 KB second stage into memory at segment `0x1000`, offset `0x0000`.
   - Transfer execution to the second stage via a far jump.

2. **Second Stage Bootloader:**

   - The binary must be structured as a 64 KB image.
   - Execute code from the first sector to print an initial message.
   - Pad the binary to exactly 64 KB such that the second to the second last sectors are 0s.
   - Execute code from the last sector to print a different message.

3. **Disk Image Assembly:**

   - Ensure the first stage's LBA call correctly locates the second stage on disk.
   - For simplicity, load the second stage from the second sector of the disk (LBA=1)

---

## 7. A20 Line

Covered [here](../notes/03_bootloader_development/07_a20_line/README.md).

+ The purpose of the A20 line and its historical context.
+ Methods for enabling A20 (keyboard controller method, BIOS functions, and fast A20 gate).
+ Testing whether A20 has been successfully enabled.

---

## A20 Line Project

## A20 Enablement Second Stage Project

Covered [here](../projects/bootloader/04_a20/README.md)

1. **First Stage Bootloader:**

   - Use BIOS interrupt `INT 13h AH=42h` (Extended Read Sectors) to load the second stage using LBA addressing.
   - Load the second stage into memory at segment `0x0000`, offset `0x7E00`.
   - Transfer execution to the second stage via a far jump to `0x0000:0x7E00`.

2. **Second Stage Bootloader:**

   - Implement a comprehensive A20 enablement routine attempting multiple methods in sequence:
     - BIOS INT 15h AH=2401h method
     - System Control Port A (Fast A20) method
     - Keyboard Controller method (optional)
   - After each enablement attempt, verify A20 status.
   - Display clear status messages indicating:
     - Which enablement method succeeded
     - Verification results
     - Any errors encountered
   - Upon successful A20 enablement, display a confirmation message and halt.

3. **Verification System:**

   - Implement robust A20 verification using multiple memory location pairs.
   - Include both BIOS query (INT 15h AH=2402h) and manual memory wrap-around tests.
   - Add retry logic with delays between verification attempts to ensure reliability (optional).

4. **Error Handling:**

   - Gracefully handle failures in any single enablement method.
   - Continue attempting alternative methods if previous ones fail.
   - Display appropriate error messages for diagnostic purposes.
   - Implement a final fallback strategy if all methods fail.

---

## 8. Switch to Protected Mode

Covered [here](../notes/03_bootloader_development/08_protected_mode/README.md)

+ Introduction to protected mode.
+ Segment models: flag model vs segmented model.
+ GDT:
    - Purpose and structure of the Global Descriptor Table (GDT)
    - GDT format and segment descriptors.
+ `LGDT` assembly instruction.
+ Transition to protected mode:
    - PE (Protection Enable) bit in CR0.
    - Common pitfalls.
    - Loss of BIOS interrupts.

---

## Protected Mode Switch Project

Covered [here](../projects/bootloader/05_protected_mode/README.md)

1. **First Stage Bootloader:**

   - Load the **second stage** into memory at physical address `0x7E00`.
   - Use a simple BIOS `INT 13h` read (CHS or LBA as available).
   - Once the load completes, perform a **far jump** to the second stage entry point at `0x7E00:0000`.

2. **Second Stage Bootloader:**

   - Assume the **A20 line** is already enabled (QEMU enables it by default).
   - The main objective is to **switch from Real Mode to Protected Mode**.

   - Steps:
     1. **Set up the GDT and GDT Descriptor**
        - Create a Global Descriptor Table (GDT) in memory containing:
          - A null descriptor.
          - A 32-bit kernel code segment descriptor.
          - A 32-bit kernel data segment descriptor.
        - Define a GDT descriptor structure that holds:
          - The GDT’s **limit** (size - 1).
          - The GDT’s **base address** (linear address of the GDT).

     2. **Load the GDT**
        - Use the `LGDT` instruction to load the address of the GDT descriptor into the **GDTR** register.

     3. **Enable Protected Mode**
        - Read the **CR0** register into a general-purpose register (e.g., `EAX`).
        - Set the **Protection Enable (PE)** bit (bit 0) in `CR0`.
        - Write the value back to `CR0`.

     4. **Perform a Far Jump**
        - Execute a **far jump** to flush the prefetch queue and load the **CS** register with the protected-mode code segment selector.
        - This jump transfers control to the protected-mode entry label.

     5. **Initialize Segment Registers**
        - Load **DS**, **ES**, **FS**, **GS**, and **SS** with the data segment selector from the GDT.
        - Optionally, initialize a 32-bit stack pointer (`ESP`) for safe stack operations.

     6. **Halt Execution**
        - Once the processor is operating in protected mode and all segment registers are set, halt the CPU using:
          ```asm
          cli
          hlt
          ```

   - **Testing the Switch:**
     - After building and running the bootloader in QEMU, open the **QEMU Monitor** (using `Ctrl + Alt + 2` or `-monitor stdio`).
     - At the monitor prompt, run:
       ```
       info registers
       ```
     - Check the **CR0** register. If the least significant bit (bit 0) is set to **1**, the processor is now in **Protected Mode**.
     - You can then return to the guest console using `Ctrl + Alt + 1`.

---
