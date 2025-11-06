# Protected Mode Switch Project

## Sections

+ [Overview](#overview)
    - [Objectives](#objectives)
+ [How It Works](#how-it-works)
+ [Practice Areas](#practice-areas)
+ [Running the Project](#running-the-project)
+ [Output and Explanation](#output-and-explanation)
+ [Notes](#notes)

---

## Overview

This project demonstrates the transition of the CPU from **Real Mode** to **Protected Mode** using a two-stage bootloader.  
The first stage is responsible for loading the second stage into memory using BIOS interrupts, while the second stage sets up a **Global Descriptor Table (GDT)**, enables **Protected Mode**, and verifies the transition by printing a message directly to VGA memory.

### Objectives

+ Load a second-stage bootloader from disk into memory.
+ Set up and load a valid Global Descriptor Table (GDT).
+ Enable Protected Mode by setting the **Protection Enable (PE)** bit in the **CR0** register.
+ Perform a far jump to enter 32-bit mode.
+ Display a success message using VGA text mode to confirm a successful mode switch.

---

## How It Works

1. **First Stage Bootloader**
   - Initializes segment registers and the stack.
   - Uses BIOS interrupt `INT 10h` to set video mode and clear the screen.
   - Displays a “Loading” message using `INT 10h` teletype output.
   - Loads the second stage (one sector) from disk using BIOS interrupt `INT 13h` (function `AH=42h`).
   - Prints a success message upon loading completion.
   - Jumps to the second stage entry point at `0x7E00:0000`.

2. **Second Stage Bootloader**
   - Executes with the assumption that the A20 line is already enabled (QEMU provides this by default).
   - Defines a **Global Descriptor Table (GDT)** with:
     - A null descriptor.
     - A kernel code segment descriptor.
     - A kernel data segment descriptor.
   - Loads the GDT using the `LGDT` instruction.
   - Sets the **PE** bit in the **CR0** register to enable Protected Mode.
   - Performs a **far jump** to flush the instruction queue and load the new code segment selector.
   - Re-initializes segment registers (`DS`, `ES`, `GS`, `SS`) with the data segment selector.
   - Clears the VGA text buffer by writing directly to memory at `0xB8000`.
   - Writes a confirmation message, “Switched to protected mode successfully.”, to the screen.
   - Halts the CPU.

3. **Verification**
   - After the message is displayed, the system halts.
   - Using the **QEMU monitor**, you may confirm the mode switch by executing:
     ```
     info registers
     ```
     and verifying that the **CR0** register has its lowest bit (PE bit) set to `1`.

---

## Practice Areas

+ Disk sector reading using BIOS interrupt `INT 13h`.
+ Text output via BIOS interrupt `INT 10h`.
+ GDT structure definition and descriptor formatting.
+ Using `LGDT` and enabling Protected Mode via control registers.
+ Direct memory-mapped VGA text output in 32-bit mode.
+ Assembly organization across multi-stage bootloaders.

---

## Running the Project

Execute the provided build script to assemble the bootloaders and launch the emulator:

```bash
chmod +x run.sh
./run.sh

# Alternative if execute permissions are unavailable:
bash run.sh
```

The script performs the following automated steps:

1. **Assembly:**
   Uses **NASM** to compile both assembly source files into raw binary format:

   * `first_stage.asm` → `first_stage.bin`
   * `second_stage.asm` → `second_stage.bin`
     Each file is assembled as a **flat binary image** suitable for direct loading by the BIOS, with no headers or relocations.

2. **Disk Image Creation:**
   Uses the `dd` utility to create a **2-sector (1024 bytes)** raw disk image named `disk.img`.
   This zero-filled image acts as a blank storage device for the bootloader.

3. **Sector Placement:**

   * Writes `first_stage.bin` directly to **sector 0** of `disk.img`. This sector serves as the **Master Boot Record (MBR)** and is automatically loaded by the BIOS to memory at address `0x7C00`.
   * Writes `second_stage.bin` to **sector 1** (the next 512 bytes) using the `seek=1` option.
     This matches the design of the first stage, which reads the second stage from LBA 1 into address `0x7E00`.

4. **Emulation:**
   Launches **QEMU** in **i386 mode** with the raw disk image using the command:

   ```bash
   qemu-system-i386 -drive file=disk.img,format=raw -monitor stdio
   ```

   * The `-monitor stdio` option opens the **QEMU monitor interface** in the same terminal, allowing you to interact directly with the emulator (for example, to run `info registers`).

5. **Cleanup:**
   Once QEMU exits, the script removes all generated artifacts (`first_stage.bin`, `second_stage.bin`, and `disk.img`) to maintain a clean working directory.

This build script automates the entire workflow: assembling both bootloader stages, constructing the disk image, launching QEMU for testing, and cleaning up afterward.
It provides a reliable and repeatable environment for developing and debugging the **Protected Mode Switch Project**.

---

## Output and Explanation

Upon execution, QEMU should display:

```
Loading second stage.
Second stage loaded.
```

Then, after a short moment, the screen clears and displays:

```
Switched to protected mode successfully.
```

This message confirms that:

* The second stage was correctly loaded and executed.
* The GDT was properly initialized.
* The **CR0** register’s PE bit was set.
* The processor is now executing in **Protected Mode**.

---

## Notes

* This project assumes the A20 line is already enabled (true in most emulators).
* BIOS interrupts (`INT 10h`, `INT 13h`) are no longer available once Protected Mode is enabled.
* All screen output in Protected Mode is handled by direct VGA memory access.
* The structure and layout of the GDT are critical; an incorrect descriptor or limit will prevent a successful switch.
* Use `info registers` in the QEMU monitor to verify the Protected Mode state by checking the **CR0** register.

---
