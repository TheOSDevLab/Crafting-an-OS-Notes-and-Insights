# Real Mode Memory Layout

## Key Topics

+ [Overview](#overview)
+ [Key Memory Regions](#key-memory-regions)

---

## Overview

Real mode provides access to the first 1 MB of memory, also known as the **real mode address space**. Understanding this layout is essential for bootloader development, because the bootloader operates entirely in this environment before switching to more advanced modes.

---

## Key Memory Regions

### Interrupt Vector Table (IVT)

The first part of memory, starting at address 0x00000, is reserved for the **Interrupt Vector Table**. This table contains pointers to interrupt service routines used by BIOS and the system. It extends up to address 0x003FF.

### BIOS Data Area (BDA)

Just after the IVT, from about 0x00400 to 0x004FF, lies the **BIOS Data Area**. This region holds information about hardware, such as the number of serial and parallel ports, diskette drive details, and other configuration data set up by the BIOS.

### Conventional Memory

The memory from 0x00500 up to 0x9FBFF is known as **conventional memory**. This is the area available to programs and operating systems in real mode. DOS and early bootloaders typically operate within this range.

### Video Memory

At 0xA0000 and above, parts of memory are mapped to video hardware. For example:

* 0xA0000-0xAFFFF: Graphics modes (VGA).
* 0xB8000-0xBFFFF: Text mode video memory, where characters and colors for the display are stored.

Bootloaders often use this region to display text.

### Option ROMs

From 0xC0000 to 0xEFFFF, memory is reserved for **option ROMs**, such as video BIOS or add-on device firmware. These contain executable code used by the BIOS to initialize hardware.

### System BIOS

At the very top of memory, from 0xF0000 to 0xFFFFF, lies the **system BIOS**. This region contains the firmware code that runs during system startup, including POST (Power-On Self-Test) routines and low-level hardware functions.

---

## Importance for Bootloaders

For bootloader development, some of the most important facts about the real mode memory layout are:

* The bootloader is loaded by the BIOS at the address 0x7C00 in conventional memory.
* The interrupt vector table and BIOS data area must never be overwritten.
* Video memory can be used to display text directly.
* The BIOS provides interrupt routines (through the IVT) that the bootloader can call for input/output.
* Access to hardware is limited to what the BIOS exposes in this 1 MB address space.

---
