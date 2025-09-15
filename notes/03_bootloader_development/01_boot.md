# Boot

## Key Topics

+ [Boot Sequence](#boot-sequence)
+ [Boot Sector and Bootloader Size](#boot-sector-and-bootloader-size)
+ [Boot Signature](#boot-signature)
+ [Where BIOS Loads the Bootloader in Memory](#where-bios-loads-the-bootloader-in-memory)

---

## Boot Sequence

When a computer using a traditional BIOS is powered on or reset, the following sequence takes place:

1. **CPU Reset Vector**
   The processor begins execution at a fixed address defined by the architecture. On x86 machines, this is the physical address **0xFFFF0**, located near the top of the first megabyte of memory. This address maps to BIOS firmware stored in ROM.

2. **Power-On Self Test (POST)**
   The BIOS carries out hardware checks to ensure the CPU, memory, and basic peripherals are functioning. If problems are detected, the BIOS halts the boot process and signals errors, often through beeps or messages.

3. **Hardware Initialization**
   The BIOS sets up essential system components, such as the chipset, timers, video card, and input devices. It also builds low-memory data structures, including the interrupt vector table and the BIOS data area.

4. **Boot Device Selection**
   The BIOS determines which device to attempt to boot from, based on the boot order stored in CMOS configuration. Devices can include hard disks, optical drives, removable media, or even network interfaces.

5. **Loading the Boot Sector**
   Once a boot device is chosen, the BIOS reads the **first sector (512 bytes)** from that device. This sector is called the **boot sector**. For a hard disk, this is typically the **Master Boot Record (MBR)**. The BIOS uses its built-in disk services (INT 13h) to perform this read.

6. **Boot Signature Validation**
   After reading the sector, the BIOS checks the final two bytes of the sector. If they match the expected signature (**0x55AA**), the BIOS considers the sector valid. If not, the BIOS will attempt the next boot device or display an error.

7. **Transfer of Control**
   If the boot signature is valid, the BIOS transfers execution to the bootloader code loaded from the boot sector. The code is placed in memory at physical address **0x7C00**. The CPU begins executing instructions from this address in real mode.

8. **Bootloader Execution**
   The bootloader now takes control. Its tasks vary, but usually involve locating the operating system kernel or loading a second-stage bootloader. For disks with partitions, the bootloader often reads the partition table in the MBR, finds the active partition, and then loads its Volume Boot Record (VBR).

---

## Boot Sector and Bootloader Size

* **Boot sector size**: always **512 bytes** for traditional BIOS / MBR. The BIOS reads exactly one 512-byte sector. That 512 bytes must contain both code (bootloader), partition table (for MBR case), and signature.
* In the **Master Boot Record (MBR)** on a hard drive, the layout is:

  * Bytes 0-445 (0x000-0x1BD): bootstrap code area (446 bytes)
  * Bytes 446-509 (0x1BE-0x1FD): partition table (4 entries × 16 bytes each = 64 bytes)
  * Bytes 510-511 (0x1FE-0x1FF): boot signature (0x55AA)

  So the code area is 446 bytes (for typical MBR bootloader) if using the partition table. If simpler boot sector (like from floppy or non-partitioned medium), more of that area can be used for code.

* **Volume Boot Record (VBR)** (for partitioned disks): Also 512 bytes. The boot code, filesystem data, and possibly reserved area take up parts, plus signature.
* **Second stage loaders**: Because of this 512-byte limit, more complex bootloaders often use a second stage: the first stage (in MBR) loads extra code (from additional sectors) into memory to do more work, like filesystem drivers, etc.

---

## Boot Signature

* The **boot signature**, also called the **magic number** for the boot sector, is the two‐byte pattern **0x55AA** at the end of the boot sector:

  * Byte 510: 0x55
  * Byte 511: 0xAA

* BIOS checks these two bytes after reading the boot sector. If they are not exactly **0x55AA**, BIOS deems the sector invalid (for booting) and moves on (next device, or display error).
* This signature does *not* contain version information or code; it is simply a marker that “this sector is intended to be a boot sector.”

---

## Where BIOS Loads the Bootloader in Memory

* **Real Mode**: On x86 BIOS boot, CPU is in real mode (segmented addressing). The BIOS loads the boot sector into memory at a fixed physical location, which corresponds to a real-mode segment\:offset.
* The common and standard address is **0x0000:0x7C00** (segment 0x000, offset 0x7C00) → physical address **0x7C00**.
* This location is used because it is high enough to provide space for the common bootloader to be placed without clobbering essential areas; yet low enough so that all memory below 1 MB is addressable in real mode.
* After BIOS loads the 512‐byte sector at 0x7C00, it sets the instruction pointer to there (i.e. jumps to that address) to begin executing the bootloader.
* Sometimes, bootloader code will relocate itself (i.e. copy itself to another memory location) if more space or better layout is needed.

---
