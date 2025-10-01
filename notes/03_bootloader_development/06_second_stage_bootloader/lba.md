# LBA (Logic block Addressing)

## What Is LBA?

* **Logical Block Addressing (LBA)** is a method for addressing the sectors (or blocks) of a storage device (e.g. HDD, SSD, USB) using a single linear index, rather than a multi-coordinate scheme like CHS (Cylinder-Head-Sector).
* In LBA, each block (sector) is assigned an integer address starting from 0, 1, 2, 3, …; the first block is LBA 0.
* The device’s controller (or firmware) handles mapping from this linear index to the internal physical layout (whatever that may be). The operating system, drivers, and bootloaders don’t need to know the physical geometry.

Because modern storage devices often don’t have a fixed, simple geometry (they use zones, remapping, wear leveling, etc.), LBA abstracts away those details and presents a clean contiguous address space.

---

## Variants and Address Sizes (LBA-28, LBA-48, etc.)

* Early ATA/IDE systems introduced **22-bit LBA**, but that was soon upgraded.
* The **LBA-28** mode uses 28 bits for the address. This allows addressing up to 2²⁸ sectors. With standard 512-byte sectors, that gives a maximum capacity of 128 GiB (detailing: 2²⁸ × 512 bytes = 137,438,953,472 bytes ≈ 128 GiB).
* To support much larger disks, **LBA-48** was introduced in the ATA-6 standard. This extends the address space to 48 bits, allowing addressing up to 2⁴⁸ sectors. With 512-byte sectors, that corresponds to a theoretical maximum of 128 PiB (petabytes) of addressable storage (2⁴⁸ × 512 bytes).
* In practice, most modern OSes and disk controllers support wide LBA variants or further extensions (e.g. 64-bit LBA (~8 zettabytes), especially for SCSI/NVMe) to future-proof against enormous storage media.

---

## LBA Addressing Logic, Conversions, and Relations to CHS

### Basic Addressing Model

* Under LBA, each sector is addressed by a single integer, say `LBA`, which corresponds to the `LBA`-th block (sector) on the device, counting from zero.
* The device or firmware translates that LBA into whichever internal mapping is appropriate (which might involve converting to CHS, or some internal logical mapping, or remapping, etc.). The OS/bootloader typically does not need to worry about it.

### CHS ↔ LBA Conversion (for compatibility or translation)

Even though LBA is the preferred interface, conversion formulas exist (and are used by BIOS or bootloaders) to map between CHS and LBA when necessary:

* **CHS to LBA:**
  [
  \text{LBA} = (C \times \text{HPC} + H) \times \text{SPT} + (S - 1)
  ]
  Here:

  * C* = cylinder number
  * H* = head number
  * S* = sector number (1-based)
  * HPC* = number of heads per cylinder
  * SPT* = sectors per track

* **LBA to CHS:**
  [
  C = \left\lfloor \frac{\text{LBA}}{\text{HPC} \times \text{SPT}} \right\rfloor
  ]
  [
  H = \left( \left\lfloor \frac{\text{LBA}}{\text{SPT}} \right\rfloor \bmod \text{HPC} \right)
  ]
  [
  S = (\text{LBA} \bmod \text{SPT}) + 1
  ]

These equations let programs translate back and forth between the two addressing schemes when needed (e.g. in legacy BIOS systems).

However, note that the CHS values often reported in BIOS or partition tables are not “real geometry” but emulated or translated geometry for compatibility.

---

## Use of LBA in BIOS / Bootloaders / Firmware

* Modern BIOSes provide **INT 13h Extensions**, which allow use of LBA instead of CHS for disk access during boot. This removes many of the size constraints imposed by CHS.
* When LBA is used, the BIOS exposes disk reads/writes via functions that take a linear block address (or block descriptor) rather than cylinder/head/sector parameters.
* Some BIOS implementations use **LBA-assisted translation**: internally, the BIOS uses LBA to access the hardware, but still presents a translated CHS geometry through legacy interfaces (for backward compatibility).
* During early boot, a first-stage bootloader may detect if the BIOS supports LBA via the INT 13h extension interface; if so, it will use LBA calls, otherwise fall back to CHS.
* Once the second-stage loader or OS kernel takes over, it usually bypasses BIOS entirely and uses its own block device drivers (which inherently use LBA in modern hardware) to access the disk.

---

## Advantages of LBA Over CHS

* **Simplicity & abstraction:** LBA presents storage as a single linear array of blocks, eliminating the need to understand device geometry.
* **Scalability to large disks:** Because it uses linear indexing, LBA scales much more easily to very large capacities, especially when extended to 48-bit or beyond.
* **Device agnosticism:** Even storage media that don’t map cleanly to cylinders/heads/sectors (e.g. SSDs, flash, RAID, virtual volumes) can be addressed uniformly via LBA without worrying about physical layout.
* **Avoids geometry inconsistencies:** Modern drives frequently use zone bit recording (more sectors per track on outer cylinders, fewer on inner), internal remapping, reallocation. The physical geometry exposed to software does not necessarily reflect the real internal layout; LBA hides that mismatch.

Because of these, LBA is effectively the universal addressing scheme for block devices in modern systems.

---

## Limitations & Considerations

* Although LBA removes most geometry constraints, it still depends on the bit width of the address in the interface. For example, older BIOS / ATA interfaces limited to 28 bits can only address ~128 GiB (with 512-byte blocks).
* Some older systems or firmware may not support LBA or LBA-48, necessitating fallback to CHS or other translation schemes.
* Partitioning schemes (like MBR) and BIOS boot limits (e.g. MBR’s 32-bit sector count field) may impose additional caps; modern systems often use GPT to avoid those caps.
* In bootloader/BIOS environments, you may still encounter CHS fields (in partition table, for compatibility), even though they are often synthetic or derived rather than reflecting actual geometry.

---
