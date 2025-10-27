# Introduction to Protected Mode

## Overview

Protected mode is an operational state of the Intel x86 family of processors that enables advanced features such as memory protection, multitasking, and extended addressing. It was first introduced with the Intel 80286 processor in 1982 and significantly expanded with the Intel 80386 in 1985.

In protected mode, the processor operates under a controlled environment designed to support modern operating systems. It provides mechanisms that prevent unauthorized access to memory and system resources, allowing multiple programs to execute safely and efficiently.

When a processor is powered on, it begins execution in *real mode* for backward compatibility with early x86 software. Transitioning to protected mode unlocks the processor’s full feature set, including 32-bit addressing, privilege enforcement, and virtual memory.

---

## Key Characteristics

### Extended Address Space

In real mode, the processor can address only 1 MB of memory through a 20-bit segmented address space. Protected mode extends this capability substantially:

* The 80286 supports 24-bit addressing, allowing access to 16 MB of physical memory.
* The 80386 and later processors expand this to 32-bit addressing, enabling up to 4 GB of linear address space.

This larger address space allows operating systems to load more programs into memory, support complex data structures, and implement virtual memory systems.

### Segmentation and Descriptor Tables

Protected mode introduces a more structured and flexible memory segmentation model. Instead of fixed segment registers with implicit base addresses, each segment is defined by a *descriptor*.

Descriptors are stored in two types of tables:

* **Global Descriptor Table (GDT):** Contains system-wide segment definitions.
* **Local Descriptor Table (LDT):** Contains segment definitions specific to individual tasks.

Each segment descriptor includes the following key elements:

* **Base Address:** The starting address of the segment.
* **Limit:** The segment’s size in bytes.
* **Access Rights and Attributes:** Information defining the segment type (code, data, stack) and its privilege level.

When a segment selector is loaded into a segment register, the processor retrieves the corresponding descriptor from the table, validates it, and caches its properties internally. This mechanism provides both flexibility and protection against invalid memory access.

### Memory Protection and Privilege Levels

A defining feature of protected mode is its built-in protection model. The processor enforces access restrictions through *privilege levels* and descriptor validation.

The x86 architecture defines **four privilege levels**, known as *rings*:

* **Ring 0:** Highest privilege, typically reserved for the operating system kernel.
* **Rings 1-2:** Optional intermediate levels, rarely used in modern software.
* **Ring 3:** Lowest privilege, used for user-mode applications.

The processor checks privilege levels whenever a program attempts to access memory, execute code, or use system instructions. If a program attempts an operation outside its privilege, the CPU generates a protection fault. This hardware-enforced isolation prevents user programs from interfering with the kernel or with each other.

### Multitasking Support

Protected mode supports hardware features that facilitate multitasking. Each task can be assigned its own address space and segment descriptors, allowing multiple programs to execute concurrently without interfering with one another.

The processor provides mechanisms for task management, including the **Task State Segment (TSS)**, which stores information such as register values and stack pointers for each task. Although many modern operating systems implement task switching in software, the hardware support remains an integral part of the protected mode architecture.

### Paging and Virtual Memory

Starting with the Intel 80386, protected mode introduced **paging**, a mechanism for translating linear addresses into physical addresses. Paging allows the processor to divide memory into fixed-size blocks called *pages*, which can be mapped to any location in physical memory or on disk.

Paging enables several essential features:

* **Virtual memory:** Expands available memory by using disk space as an extension of RAM.
* **Memory isolation:** Ensures that each process accesses only its assigned memory region.
* **Efficient memory allocation:** Enables sharing of common code and data pages among processes.

Together, segmentation and paging form the basis of the x86 memory management model. While segmentation defines logical regions of memory, paging provides finer control over physical storage and protection.

### Compatibility and Legacy Support

One of the design goals of protected mode was backward compatibility with existing software. Early x86 processors introduced **Virtual 8086 (VM86) mode**, a sub-mode of protected mode that allows execution of real-mode programs within a protected environment.

Even when operating in protected mode, processors maintain the ability to emulate real-mode behavior when necessary. This ensures that legacy software, BIOS routines, and older operating systems can still function under modern systems.

---

## Protection Mechanisms and Fault Handling

The processor continuously validates memory and instruction access in protected mode. When an invalid operation occurs (such as loading a segment selector with insufficient privilege or accessing memory beyond a segment limit) the CPU generates a *fault* or *exception*.

Common examples include:

* **General Protection Fault (GPF):** Triggered by privilege or limit violations.
* **Stack Fault:** Caused by invalid stack segment access.
* **Page Fault:** Raised when a required page is not present in memory.

These exceptions enable the operating system to handle errors gracefully and maintain system stability.

---

## Significance of Protected Mode

Protected mode fundamentally transformed how operating systems interact with hardware. It provides the architectural foundation for:

* **Process isolation and system stability.**
* **Memory protection and error containment.**
* **Efficient multitasking and context switching.**
* **Implementation of virtual memory systems.**

Every modern operating system running on x86 (such as Windows, Linux, and the various BSD variants) depends on protected mode (or its 64-bit successor, long mode) to ensure robust operation and security.

---
