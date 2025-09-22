# Second Stage Bootloader

## Key Topics

+ [Purpose and Role of the Second Stage Bootloader](#purpose-and-role-of-the-second-stage-bootloader)
+ [Memory Placement Strategies for the Second Stage](#memory-placement-strategies-for-the-second-stage)
+ [Disk Addressing Methods](#disk-addressing-methods)
+ [From CHS to LBA: Historical Context and Transition](#from-chs-to-lba-historical-context-and-transition)

---

## Purpose and Role of the Second Stage Bootloader

* The second stage compensates for the strict size and capability limits of the first stage.
* It can implement **filesystem access**, allowing the kernel to be located and loaded by name rather than raw disk sectors.
* It is capable of **loading the full kernel image** along with supplementary files such as initrd or initramfs.
* It often provides a **user interface or boot menu**, enabling users to choose kernels, operating systems, or pass boot parameters.
* It can perform **additional hardware and environment setup**, such as switching the CPU to protected or long mode and preparing memory maps.
* It **passes information** (e.g., boot arguments, memory details) to the operating system to ensure a proper runtime environment.
* By extending these capabilities, it offers **flexibility and extensibility**, such as supporting multi-boot systems and simplifying updates without rewriting firmware.

---

## Memory Placement Strategies for the Second Stage

* The second stage must reside in **low memory (below 1 MB)** because real mode and BIOS services cannot address higher memory during early boot.
* A traditional choice is **0x7C00**, the address where the BIOS loads the first stage. The first stage may relocate itself so that the second stage can occupy this region.
* The range **0x0600-0x7BFF** is another common area, as it is unused by BIOS/system data and lies safely below the first stage.
* Some loaders use **0x7E00**, leaving a gap after the first stage to avoid overlap and corruption.
* For larger bootloaders, higher addresses such as **0x90000** (just below the 640 KB boundary) are used, giving more space while still staying below 1 MB.
* In all cases, careful placement ensures that the loader does not overwrite the interrupt vector table, BIOS data structures, or video memory regions.

---

## Disk Addressing Methods

The first stage bootloader uses BIOS services, specifically **INT 13h** (BIOS disk services) to read from disk. The addressing mode used by INT 13h depends on what the BIOS supports; historically CHS (Cylinder-Head-Sector) was standard; later extensions allowed for LBA (Logical Block Addressing).

Thus:

* If BIOS supports **INT 13h extensions** (for LBA), then the first stage may ask using those extension functions to read sectors by LBA.
* If BIOS does *not* support LBA or if compatibility is required, the loader may compute CHS addresses (mapping from logical block numbers to cylinder, head, sector) and use the older INT 13h calls.

After having loaded the second stage (via whichever method), the second stage may itself also use disk access via either CHS or LBA (if BIOS is still in real mode), unless it includes its own drivers or switches mode.

---

## From CHS to LBA: Historical Context and Transition

### CHS: The original

* Early disk geometry was naturally described in terms of **Cylinders, Heads, and Sectors**. Physical disks had platters (heads), tracks (cylinders), and sectors on those tracks. It was intuitive and matched the physical characteristics of disk hardware.
* The BIOS and interface standards (e.g. early INT 13h functions) exposed CHS parameters. Operating systems worked with this geometry.
* For small disks, CHS was sufficient, and its limitations were not problematic.

Read more about CHS addressing [here](./chs.md)

### Limitations of CHS

* As disk capacity increased, the CHS scheme ran into boundaries: maximum number of cylinders, heads, sectors per track (int 13h had limits), which put an upper bound on addressable sectors.
* Physical geometry became decoupled from logical/virtual geometry: manufacturers started to “fake” or remap HEAD, CYL, SECTOR values so that CHS values reported by BIOS / drive didn’t correspond to real physical geometry. This made CHS less meaningful.
* For example, beyond certain capacity, you might hit limits like HEADs = 16, sectors per track = 63, etc., and cylinder count still is constrained. These limits cap the total disk size addressable via CHS.

### Introduction and adoption of LBA

* To break CHS limits, drive manufacturers introduced **Logical Block Addressing (LBA)**, which, instead of referencing a triple (cylinder, head, sector), treats the disk as a linear sequence of sectors numbered 0,1,2,3… This removes the multi‐dimension addressing and many limits.
* BIOS extensions were added (INT 13h extensions) to support LBA reads. OS bootloaders gradually adopted LBA because of its simplicity and ability to address larger disks.
* Eventually, LBA (not CHS) is the standard way to address disks in nearly all modern systems.

Read more about LBA addressing [here](./lba.md)

### Why transition took time / backward compatibility concerns

* Many BIOSes, bootloaders, partition tables, OS tools expected CHS; so full replacement required compatibility layers.
* Some disks and BIOSes did not support the newer INT 13h LBA calls, so bootloaders often had to detect support and possibly fall back to CHS or emulate CHS via conversion.
* Partitioning schemes (especially MBR) had CHS‐based entries; bootloaders historically expected CHS in partition table, etc.

---
