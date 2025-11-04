# Global Descriptor Table (GDT)

This chapter explains what the GDT is, why it exists, how it is structured, how the processor uses it in protected mode, and the practical considerations required when creating and using a GDT in an operating system.

---

## Overview

The Global Descriptor Table (GDT) is a processor-visible data structure that describes memory segments and certain system descriptors for x86 processors. Each 8-byte entry in the GDT (a *descriptor*) encodes a segment’s base address, size (limit), and a set of access and attribute bits that define type, privilege, and behaviour. The CPU consults the GDT whenever code uses a segment selector (for CS, DS, ES, SS, FS, GS) or when it references system descriptors (for example, the Task State Segment). In protected mode the GDT is central to memory protection, privilege enforcement, and hardware support structures.

---

## Roles of the GDT

1. **Define segments used by the system.** Code, data and stack segments are described by GDT entries; each descriptor provides a base, limit and access rights which the CPU enforces.
2. **Provide system descriptors.** The GDT may also hold TSS descriptors (Task State Segment), LDT descriptors, and gate descriptors used by interrupts and calls.
3. **Facilitate privilege levels.** Descriptors encode Descriptor Privilege Level (DPL) and the CPU compares DPL and selector RPL/Current Privilege Level to permit or deny access. This enforces kernel/user separation and other protection rules.
4. **Required for entering protected mode.** Before enabling protected mode, the OS must establish a valid GDT and load its location into the processor (via the LGDT instruction). The GDT remains in use while the CPU operates in protected mode.

---

## Descriptor structure

A standard segment descriptor (IA-32) occupies 8 bytes (64 bits) and is usually described in these logical fields:

* **Limit (15:0)** and **Limit (19:16)**; combined gives 20-bit limit (when granularity = 0 the unit is bytes; when granularity = 1 the limit is in 4 KiB pages).
* **Base (15:0), Base (23:16), Base (31:24)**; combined give the 32-bit segment base.
* **Access Byte** (type, S bit, DPL, Present): indicates whether the descriptor is code/data/system, readability/writability/execute behavior, descriptor privilege level (DPL), and present bit.
* **Flags (4 bits)**: typically includes Granularity (G), Default operand size / 32-bit (D/B), and available bit (AVL). G controls whether the limit is interpreted in bytes or 4 KiB pages. D/B selects 16/32-bit default operand/address size.

**Important notes:**

* The GDT limit value loaded into the GDTR is the table size in bytes **minus one** (so a GDT of 3 descriptors = 3×8 bytes → limit = 24 − 1 = 23). The processor expects the limit to be one less than an integral multiple of eight for alignment reasons.

---

## Descriptor types

* **Code descriptor**; marks a segment containing executable instructions. It encodes whether code is conforming/non-conforming and whether it is readable.
* **Data descriptor**; marks a data/stack segment and encodes read/write and expand-up/expand-down behaviour.
* **System descriptors**; TSS descriptors, LDT descriptors, call and interrupt gates; these are used by privileged software and for task/interrupt control. TSS descriptors are used to reference a Task State Segment and are present in the GDT (not LDT).

---

## Segment selectors; how software names descriptors

A segment selector is a 16-bit value loaded into segment registers; its format is:

* **Index (bits 3..15):** index into the descriptor table (GDT or LDT); effectively selects which descriptor.
* **TI (bit 2):** Table Indicator; 0 for GDT, 1 for LDT.
* **RPL (bits 0..1):** Requested Privilege Level; a small privilege value supplied by the selector that participates in access checks.

When a selector is loaded into a segment register the CPU locates the descriptor (GDT or LDT), validates it (present bit, limit, privilege checks), and copies descriptor fields into internal hidden registers (descriptor cache). Later memory references using that segment use the cached base & limit, not a repeated table lookup. If validation fails, the CPU raises an appropriate fault.

---

## GDT and protected mode

**Before switching to protected mode:** the software must build a GDT in memory that defines at least the descriptors the kernel will use (commonly a null descriptor, kernel code, kernel data, user code, user data, and often a TSS descriptor). The address and size of the GDT are loaded into the GDTR with the LGDT instruction. After LGDT the GDT is present for the CPU to consult immediately when segment selectors are used. Only then is it safe to set the Protection Enable (PE) bit in CR0 to enter protected mode.

**After entering protected mode:** the CPU uses the GDT for all subsequent segment operations. Typical runtime responsibilities of the OS include:

* Ensuring the GDT remains present and valid in memory.
* Loading segment registers with selectors that reference appropriate descriptors (for kernel/user, code/data, per-CPU or per-task selectors).
* Providing and maintaining a TSS descriptor in the GDT if the OS uses the TSS for stack switching on privilege changes or for hardware task switching.
* Using LDT entries when per-task segment tables are required (optional; most modern OSes avoid LDTs).

---

## Typical GDT Layout

A minimal GDT used by many 32-bit kernels looks like:

1. **Null descriptor** (selector 0x00). The first descriptor must be null: loading selector 0 would fault otherwise.
2. **Kernel code segment** (selector 0x08); base = 0, limit = 0xFFFFF, access = execute/read, DPL = 0 (ring 0), flags = granularity=4KiB, 32-bit.
3. **Kernel data segment** (selector 0x10); base = 0, limit = 0xFFFFF, access = read/write, DPL = 0.
4. **User code segment** (selector 0x18); same limits but DPL = 3 (ring 3).
5. **User data segment** (selector 0x20); DPL = 3.
6. **TSS descriptor** (optional); points to a memory region containing the Task State Segment; usually used to provide stack pointers for privilege transitions.

This layout implements a *flat memory model* (bases = 0, large limits) while still using segmentation for privilege separation.

---

## The Task State Segment (TSS) and the GDT

The TSS is a special system data structure referenced by a TSS descriptor in the GDT. It holds information the CPU can use for certain operations:

* Stack pointers for privilege level changes (the CPU can automatically load SS:ESP for ring 0 on an interrupt).
* Previous TSS link and I/O map base address (for I/O port permission maps).
* Optional hardware task switching state (older mechanism; most modern kernels perform task switching in software but still use the TSS for stack switching).

If a kernel requires automatic stack switching on interrupts that cross privilege levels, it must set up a TSS and load the Task Register (LTR) with a selector pointing at the TSS descriptor in the GDT.

---

## How the processor enforces GDT descriptors

When a selector is loaded, or when gate descriptors are used for calls/interrupts, the CPU performs validation steps:

* Check that the descriptor’s **Present** bit is set.
* Check **DPL** and RPL vs current CPL (current privilege level) to decide if access is permitted.
* Check the **limit** against the requested offset to prevent out-of-bounds access.
* Check descriptor type (code, data, system) for allowed operations.

Violations cause exceptions such as General Protection Faults, Segment Not Present faults, or Stack Faults depending on the condition. The OS must provide exception handlers for these conditions.

---

## Common pitfalls and best practices

* **Never omit the null descriptor.** The first GDT entry must be zero.
* **Ensure GDTR limit is correct** (size - 1) and that the table memory is accessible (present) before enabling protected mode.
* **Set correct DPLs** for user vs kernel descriptors to enforce privilege separation. Misconfigured DPLs can permit user code to access kernel segments.
* **Initialize a TSS if using stack switching on interrupts.** Without it, privilege transitions that expect a kernel stack will fault.
* **Prefer a small, well-documented GDT layout.** For most kernels a flat layout plus a TSS entry is sufficient and avoids unnecessary complexity.

---

## Relationship to modern systems

Although segmentation remains part of the architecture, most modern 32- and 64-bit operating systems use a flat logical memory model implemented by configuring GDT descriptors with base = 0 and large limits, and rely primarily on paging for fine-grained protection and virtual memory. In x86-64 (long mode) segmentation is largely disabled for linear addressing (with a few exceptions such as FS/GS base usage for thread-local data), but the GDT and descriptors remain relevant for system tasks such as defining TSS entries and legacy compatibility.

---
