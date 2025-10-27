# Enabling the A20 Line (Two-Stage Bootloader)

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

This project demonstrates how to implement a **two-stage bootloader** designed to **enable the A20 line** on x86 systems.  

The **first stage bootloader** is responsible for loading the **second stage** from disk into memory.  
The **second stage bootloader** then tests whether the A20 line is enabled and, if not, attempts to enable it using multiple hardware methods.

The project provides a foundational understanding of early bootloading processes, BIOS interrupt usage, and low-level hardware control.

### Objectives

+ Develop a minimal two-stage bootloader architecture.  
+ Load the second stage into memory using BIOS interrupt `INT 13h` (Extended Read).  
+ Detect and enable the A20 line through BIOS and hardware methods.  
+ Verify the A20 state using both BIOS and memory wraparound tests.  
+ Display clear on-screen feedback for each step of the process.

---

## How It Works

1. **Stage 1 (Bootloader at 0x7C00):**
   - Initializes the CPU to real mode and sets up segment registers and stack.  
   - Clears the screen using BIOS video interrupt `INT 10h`.  
   - Loads one disk sector (the second stage) into memory address `0x0000:0x7E00` using BIOS interrupt `INT 13h`, function `AH=42h` (LBA Read).  
   - On success, prints a confirmation message and jumps to the loaded second stage.

2. **Stage 2 (Loaded at 0x7E00):**
   - Tests whether the A20 line is currently enabled using BIOS subfunction `INT 15h, AX=2402h`.  
   - If the A20 line is already enabled, halts execution.  
   - If disabled, attempts to enable it through the following sequence:
     1. **BIOS Method:**  
        Uses `INT 15h, AX=2401h` to request A20 enablement.
     2. **Fast A20 Method:**  
        Sets bit 1 on I/O port `0x92` (System Control Port A).
     3. *(Optional future expansion)* **Keyboard Controller Method:**  
        Manipulates port `0x64` (8042 controller) to toggle the A20 gate.

   - After each method, the program re-tests the A20 line to verify success.  
   - If all methods fail, it reports that the A20 line could not be enabled and halts.

---

## Practice Areas

+ Understanding the **x86 boot process** and BIOS bootloader conventions.  
+ Using **BIOS interrupts** (`INT 10h`, `INT 13h`, `INT 15h`) for I/O and hardware control.  
+ Implementing a **Disk Address Packet (DAP)** for LBA disk access.  
+ Writing **multi-stage bootloaders** that pass execution between memory segments.  
+ Testing and enabling the **A20 line** using both software (BIOS) and hardware (port I/O) techniques.  
+ Using **real-mode assembly** and maintaining a consistent memory map.  
+ Implementing **screen output routines** using BIOS teletype services.

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
   Compiles both `first_stage.asm` and `second_stage.asm` into flat binary images using NASM, producing `first_stage.bin` and `second_stage.bin`.
2. **Disk Image Creation:**  
   Creates a minimal raw disk image (`disk.img`) of **2 sectors** (1024 bytes) filled with zeros using `dd`.  
   This ensures the disk has enough space to hold both stages sequentially.
3. **Sector Placement:**  
   - Writes `first_stage.bin` to **sector 0** (the Master Boot Record (MBR)) which is loaded by the BIOS at address `0x7C00`.  
   - Writes `second_stage.bin` to **sector 1**, immediately following the first stage, matching the address (`0x0000:0x7E00`) that the bootloader expects when it reads from disk.
4. **Emulation:**  
   Launches **QEMU (i386)** with the created disk image, simulating a real x86 boot process to test the two-stage loader and A20 enablement sequence.
5. **Cleanup:**  
   Deletes all generated files (`first_stage.bin`, `second_stage.bin`, and `disk.img`) after execution, keeping the workspace clean.

This script fully automates the build, disk assembly, and test run of the bootloader; making it easy to iterate quickly while ensuring both stages are properly placed and booted in a virtual environment.


---

## Output and Explanation

Example screen output:

```
Loading second stage.
Second stage loaded.
Attempting to enable the A20 line using BIOS.
A20 enabled.
```

This output confirms that:

1. The first stage successfully loaded and executed the second stage.
2. The second stage tested the A20 state.
3. The BIOS method successfully enabled the A20 line.

If the BIOS method is not supported, the output may continue to show:

```
Attempting to enable the A20 line using BIOS.
Attempting to enable the A20 line using fast A20 method.
A20 enabled.
```

If all methods fail:

```
Attempting to enable the A20 line using BIOS.
Attempting to enable the A20 line using fast A20 method.
A20 disabled.
```

---

## Notes

* The **A20 line** allows access to memory beyond 1 MB by enabling address bit 20, which is disabled on legacy x86 systems for compatibility with 8086 software.
* Some BIOS implementations delay the propagation of the A20 enable bit; retry loops or verification steps are advisable.
* Future improvements may include:

  * Implementing the **keyboard controller (8042)** method as a final fallback.
  * Adding a **delay or verification loop** after enabling A20.
  * Integrating a **protected mode transition** after A20 activation.
* The project follows a modular design, making it a strong foundation for a more complete bootloader or OS kernel loader.

---
