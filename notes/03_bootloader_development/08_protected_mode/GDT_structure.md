# GDT Structure

## Overview

The GDT is a contiguous table of 8-byte entries (on IA-32) placed in memory. The operating system defines it and then loads its address and size into the GDTR (via the LGDT instruction). The structure in memory looks like:

1. Entry 0 (the *null descriptor*): This is always a descriptor of all zeros, reserved and cannot be used.
2. Entry 1: e.g., Kernel code segment descriptor.
3. Entry 2: e.g., Kernel data segment descriptor.
4. (Optionally) Entry 3: User code segment descriptor.
5. (Optionally) Entry 4: User data segment descriptor.
6. (Optionally) Additional entries: TSS descriptor, LDT descriptor, system descriptors, etc.

Thus one might define a minimal GDT for a kernel operating in protected mode with three entries (null + kernel code + kernel data). More advanced OSes will define user segments and system descriptors.

---

## Structure of a Single Segment Descriptor Entry

Each segment descriptor in the GDT is 8 bytes (64 bits) in IA-32 mode. The bits are arranged to provide the segment base address, the segment limit (size), the type and access rights, and flags (granularity, size, etc.). Below is a textual breakdown of the layout, followed by a field-by-field explanation.

**Layout (bits 63-0)**

```
Bits 63-56 | Bits 55-52 | Bits 51-48 | Bits 47-40 | Bits 39-16 | Bits 15-0
Base 31-24 | Flags      | Limit19-16 | AccessByte | Base23-0 + Limit15-0 combined
```

More precisely:

* Bits 0-15: Limit (low 16 bits)
* Bits 16-31: Base (low 16 bits)
* Bits 32-39: Base (bits 16-23)
* Bits 40-47: Access Byte (8 bits)
* Bits 48-51: Limit (bits 16-19)
* Bits 52-55: Flags (4 bits: Granularity, Size, AVL, etc)
* Bits 56-63: Base (bits 24-31)

Now let us explain each component:

### Base Address (32 bits in total)

* Base (bits 0-15): the low 16 bits of the base.
* Base (bits 16-23): the next 8 bits of the base.
* Base (bits 24-31): the high 8 bits of the base.
  **Meaning:** this 32-bit value denotes the linear address at which the segment begins. All offsets in that segment are added to this base to produce a linear address.

### Segment Limit (20 bits in total)

* Limit (bits 0-15): low 16 bits of the segment size limit.
* Limit (bits 16-19): high 4 bits of the limit.
  **Meaning:** this value plus one (depending on granularity) defines the largest offset that may be added to the segment’s base before access faults occur. If granularity = 0, the limit is interpreted in bytes; if granularity = 1, the limit is in 4 KiB units (pages) giving effectively up to 4 GB coverage.

### Access Byte (8 bits)

The **Access Byte** is an 8-bit field within each segment descriptor that defines the segment’s type, privilege level, and presence in memory. It directly controls how the processor interprets and enforces access to that segment. The bits are organized as follows (bit 7 is the most significant):

* **Bit 7; Present (P):** Indicates whether the segment is currently present in physical memory. If cleared, any attempt to access the segment causes a “segment not present” fault.
* **Bits 6-5; Descriptor Privilege Level (DPL):** Specify the privilege level required to access the segment, ranging from 0 (highest privilege, kernel) to 3 (lowest privilege, user).
* **Bit 4; Descriptor Type (S):** Distinguishes between system segments (S = 0) and code/data segments (S = 1). System descriptors include TSS, LDT, and gate descriptors.
* **Bits 3-0; Type Field:** Define the segment’s specific behavior depending on whether it is a code or data segment.

  * Bit 3 (X): This bit indicates whether the descriptor is for a code segment (`1`) or a data segment (`0`).
  * **For data segments:**

    * Bit 2 (E): Expansion direction (0 = expand-up, 1 = expand-down).
    * Bit 1 (W): Writable bit (1 = write allowed).
    * Bit 0 (A): Accessed bit (set by the CPU when the segment is used).
  * **For code segments:**

    * Bit 2 (C): Conforming bit (1 = code can be executed from equal or lower privilege levels).
    * Bit 1 (R): Readable bit (1 = read allowed).
    * Bit 0 (A): Accessed bit (set by the CPU when the segment is used).

### Flags (4 bits)

Within the high-order part of the descriptor are bits for:

* **Bit 3 (G: Granularity)**; When set (1), the segment limit is interpreted in 4 KiB (4096-byte) blocks (“pages”). When clear (0), the limit is interpreted in 1-byte units.
* **Bit 2 (D/B: Default operation size / Big bit)**; When set (1) for a code or data segment in protected mode, it indicates a 32-bit segment (default operand/address size = 32 bits). When clear (0), it indicates a 16-bit segment.
* **Bit 1 (L: Long-mode code segment flag)**; In IA-32e (x86-64) mode, when set (1) this bit marks a 64-bit code segment. In 32-bit protected mode it should be clear.
* **Bit 0 (AVL: Available for use by system software)**; This bit is ignored by the hardware and may be used by operating system software for custom purposes.

### Hidden / cached portion

When a segment selector (that references this descriptor) is loaded into a segment register (CS, DS, etc), the base, limit and flags are loaded into a hidden “descriptor cache”. Subsequent memory references use these cached values rather than walking the GDT each time.

---

## Example

Below is a simple assembly example (Intel syntax, NASM-style) that defines a GDT with three descriptors: the null descriptor, a kernel code segment, and a kernel data segment. Then it defines the GDTR and loads the GDT.

```asm
; --- GDT table ---
gdt_start:
    dd 0x00000000       ; Null descriptor (low 4 bytes)
    dd 0x00000000       ; Null descriptor (high 4 bytes)

; Kernel Code Segment descriptor
; Base = 0x00000000, Limit = 0xFFFFF (4 GiB with granularity = 4K), 
; Access = 0x9A (Present=1, DPL=0, Code segment, Executable=1, Readable=1), 
; Flags = 0xCF (Gran=1, Size=1 (32-bit), AVL=0, LimitHigh=0xF)
gdt_code:
    dw 0xFFFF           ; Limit low (bits 0-15)
    dw 0x0000           ; Base low (bits 0-15)
    db 0x00             ; Base bits 16-23
    db 0x9A             ; Access byte
    db 0xCF             ; Flags (Granularity+Size etc) + Limit high (bits 16-19)
    db 0x00             ; Base bits 24-31

; Kernel Data Segment descriptor
; Base = 0x00000000, Limit = 0xFFFFF, Access = 0x92 (Present=1, DPL=0, Data segment, Writable=1), Flags = 0xCF
gdt_data:
    dw 0xFFFF           ; Limit low
    dw 0x0000           ; Base low
    db 0x00             ; Base bits 16-23
    db 0x92             ; Access byte
    db 0xCF             ; Flags
    db 0x00             ; Base bits 24-31

gdt_end:

; GDTR structure (6 bytes)
gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; Limit = size of GDT in bytes minus one
    dd gdt_start                 ; Base = address of gdt_start

; Loading GDT (in protected mode setup code)
    lgdt [gdt_descriptor]
    ; then load segment registers with selectors:
    ; mov ax, 0x10   ; selector for data segment (entry 2)
    ; mov ds, ax
    ; mov es, ax
    ; mov fs, ax
    ; mov gs, ax
    ; mov ss, ax
    ; jmp 0x08:flush   ; far jump to code segment (entry 1)
```

In this snippet:

* Selector `0x08` refers to GDT entry index 1 (kernel code segment) because selector = index × 8 + RPL + TI; index=1 → value=1×8=0x08.
* Selector `0x10` refers to GDT entry index 2 (kernel data segment).
* The null descriptor is at index 0 (selector 0x00) and must remain unused.

---
