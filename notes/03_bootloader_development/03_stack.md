# Stack

## Key Topics

+ [Introduction](#introduction)
+ [Uses in Bootloader Development](#uses-in-bootloader-development)
+ [Common Pitfalls](#common-pitfalls)
+ [How to Position and Initialize the Stack Appropriately](#how-to-position-and-initialize-the-stack-appropriately)
+ [Common Real Mode Stack Locations](#common-real-mode-stack-locations)
+ [Additional Relevant Information](#additional-relevant-information)
+ [Sample Initialization Pattern](#sample-initialization-pattern)

---

## Introduction

The **stack** is a contiguous region of memory used to store temporary data: return addresses (from `CALL`/`RET`), local variables, pushed registers, saved flags, etc. In real mode, the CPU uses a stack via the **Stack Segment (SS)** register and the **Stack Pointer (SP)** register (sometimes also using Base Pointer BP for frames).

* The stack in x86 grows **downwards**: pushing data decreases SP; popping increases SP.
* The stack operations use the `SS:SP` combination to determine where in physical memory the top of the stack resides.
* Real mode has 16-bit segment registers, so SS holds a 16-bit segment; SP is a 16-bit offset. Physical address = `SS * 16 + SP`.

Because both **SS** (stack segment) and **SP** (stack pointer) are 16-bit registers, the stack can only exist within one 64 KB segment. In other words, SP can only move between offsets `0x0000` and `0xFFFF` inside the segment defined by SS.

Since the stack grows downward, if you keep pushing values when SP is already near the bottom (`0x0000`), it will **wrap around** back to `0xFFFF`. This wrap is allowed by the hardware, but in practice it means the stack will overwrite memory in the same segment - almost always leading to corrupted data or unpredictable behavior.

---

## Uses in Bootloader Development

The stack is critical in bootloader code for things like:

* **Function calls**: procedure invocations (`CALL`) push the return address onto the stack, `RET` pops it.
* **Interrupts**: when an interrupt (hardware or software via `INT`) occurs, the CPU pushes certain registers (Flags, CS, IP) to the stack so it can restore them afterwards.
* **Saving and restoring registers**: using `PUSH`, `POP`, or `PUSHA`/`POPA` to preserve registers across routines.
* **Local storage**: very limited local needs like temporary values during computations.

Without a correctly set up stack, calls/interrupts stack frames may overwrite wrong memory, return addresses can get corrupted, and unpredictable behavior follows.

---

## Common Pitfalls

1. **Not initializing SS\:SP explicitly**
   The BIOS does not guarantee that SS\:SP is in a safe or meaningful state when your bootloader begins. If you rely on it being set, you risk using an unpredictable or very small stack.
2. **Overlapping stack with other data or with the bootloader code**
   If stack grows downwards into code or data segments (or into the bootloader's own code), pushes/pops or interrupts can overwrite your code or data.
3. **Setting SS and SP in the wrong order**
   Changing SP before SS (or vice versa in a bad way) can lead to transient periods where SS\:SP points to unintended memory. Also, interrupts may occur in those periods, causing corruption. Setting SS first then SP is often recommended to avoid problems.
4. **Stack overflow**
   If too much push/pop happens (or nested interrupts, or long CALL chains) beyond the space allocated, the stack will underflow (wrap) or overwrite other memory.
5. **Ignoring segment limits**
   Because SP is only 16 bits, you’re confined within one SS segment. If you try to go past offset 0, it wraps around (within that segment), possibly corrupting other data.
6. **Interrupts occurring before stack setup**
   If interrupts are enabled before you have a valid stack, an interrupt handler will try to push CS\:IP etc onto whatever SS\:SP exists - which may be invalid or pointing into sensitive memory.

---

## How to Position and Initialize the Stack Appropriately

1. **Choose a safe stack location**
   Pick a memory region that is:

   * Free (not used by BIOS data structures, IVT, bootloader code, or buffer areas you need).
   * Aligned to avoid crossing into dangerous regions.
   * Sufficiently large for your needs (calls, interrupts, local pushes).

   Common choice: somewhere in conventional memory (below 640 KiB), away from the bootloader load area (usually 0x7C00) and interrupt data.
2. **Set SS then SP**
   When you begin your code in real mode, explicitly load SS register to the segment containing the stack, then set SP to point to the top (end) of that stack region. Because the stack grows downward, “top” means the highest offset you allow.
3. **Disable interrupts until the stack is ready**
   If possible, mask or disable interrupts (CLI) while you set SS\:SP, to prevent an interrupt occurring with unusable stack. Once the stack is valid, you can allow interrupts if needed.
4. **Reserve enough stack space**
   Even though bootloader is small, ensure you allow space for worst‐case: nested calls, pushed registers, interrupts, perhaps temporary buffer usage (for example when calling BIOS functions).
5. **Wrap detection or guard region** (optional but useful)
   If you know your code will push many items, you might leave a few unused bytes just below your specified stack bottom, or detect when SP goes too low (this can be via software, not automatic in real mode).
6. **Document & maintain segment\:offset assumptions**
   If you assume specific values for SS, segments, etc., make sure that all parts of your code honor that. Changing DS, ES, etc., may affect addressing of data on stack.

---

## Common Real Mode Stack Locations
### BIOS Default Stack (near 0x400)

* **Why**: By default, the BIOS initializes the stack pointer within the memory area immediately above the BIOS Data Area, typically around 0x400. This allows early boot processes to function without requiring explicit stack configuration by the bootloader.
* **Risk**: The stack is located adjacent to critical system structures such as the Interrupt Vector Table (0x0000-0x03FF) and the BIOS Data Area. As a result, stack growth in this region may corrupt these structures, leading to instability or system crashes.

### 0x7C00 Region

* **Why**: This location coincides with the memory address at which the BIOS loads the boot sector. Some developers initialize the stack pointer near this region for simplicity.
* **Risk**: The stack may overwrite BIOS data structures or reserved memory areas if its growth is not carefully controlled. Nevertheless, this approach is generally considered safer than relying on the default BIOS stack location.

### 0x7000 Region

* **Why**: This region is situated safely above the Interrupt Vector Table (0x0000-0x03FF) and the BIOS Data Area, while remaining below the bootloader code at 0x7C00. It provides a practical balance between safety and available memory.
* **Risk**: If the stack grows excessively, it may still extend into the bootloader code or reserved BIOS regions. This can be considered less safe than 0x7C00 because it has a shorter distance before colliding with critical BIOS data structures.

### Top of Conventional Memory (0x9FC00-0xA0000)

* **Why**: Initializing the stack near the upper boundary of conventional memory, just below the Extended BIOS Data Area (EBDA), maximizes available lower memory for the bootloader and associated data structures.
* **Risk**: This placement assumes a predictable EBDA location. On systems with different BIOS configurations, overlap with the EBDA or other reserved areas is possible.

---

## Additional Relevant Information

* **BP (Base Pointer)**: often used to reference “frame” bases in functions. You can set BP to SP at entry of a function to help access arguments or locals, but you must also preserve it.
* **Interrupts & BIOS calls**: many BIOS interrupts will push registers automatically. If your stack is too small or incorrectly set, these pushes may corrupt memory.
* **Stack versus buffers & data sections**: buffer areas for disk loading, kernel loading, etc., must be placed so that they don’t overlap with your stack.
* **Using Virtually “High” Stack**: Some bootloader developers set stack in high memory, still within 1 MB but near the top of usable conventional memory, to leave room below for code and data. Sometimes stack is placed just below 1 MB (taking care not to overflow into reserved video/BIOS ROM areas).
* **A20 line and High Memory Area (HMA)**: if you enable A20, you might access memory just past 1 MB. But stack should not assume A20 unless you have enabled it and accounted for wrap behavior.

---

## Sample Initialization Pattern

```asm
; assume assembler with NASM syntax
[org 0x7C00]

    cli                 ; disable interrupts
    xor ax, ax
    mov ss, ax          ; stack segment = 0x0000

    mov sp, 0x7C00      ; set stack pointer just below bootloader load if you want stack below code
    ; or: mov sp, 0x9000 if you placed safe region

    ; Optionally set BP if using it
    mov bp, sp

    sti                 ; optionally enable interrupts after safe stack

; continue with bootloader code
```

In this example, SS = 0, SP = `0x7C00`, so stack grows downward from physical address `0x0000 * 16 + 0x7C00 = 0x7C00`. Make sure SP does not push into `0x0000` region or disrupt IVT or BDA.

---
