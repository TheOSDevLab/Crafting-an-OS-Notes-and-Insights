# Memory Models

## Key Topics

+ [Segmented Memory Model](#segmented-memory-model)
+ [Flat Memory Model](#flat-memory-model)
+ [Hybrid Model](#hybrid-model)

---

## Segmented Memory Model

The segmented memory model organises the address space into discrete segments. A logical address typically consists of a *segment selector* and an *offset*. The segment selector indicates a memory region (base + limit + attributes) and the offset gives a position within that region.
In the context of x86 architecture (for example), early processors used a segment:offset scheme in real mode and then extended segmentation in protected mode via descriptor tables.
Thus each segment may have its own base address, size limit, access privileges, and type (code, data, stack).

### Advantages

* Fine‐grained compartmentalisation: memory regions can be defined with distinct limits and privileges, allowing stronger isolation (e.g., different segments for code vs data vs stack).
* Useful in constrained hardware: when registers were narrow, segmentation enabled addressing beyond what a simple offset alone could handle.
* Supports hierarchical protection: on architectures like x86, segments can enforce privilege levels (rings) and boundaries between modules.

### Disadvantages

* Complexity for programmers and compilers: managing multiple segments and offsets increases programming difficulty, pointer arithmetic becomes harder to reason about.
* Overhead and less flexibility: in modern systems the use of segmentation tends to interfere with the simpler linear (flat) view of memory; segments may overlap and address translations become more complex.
* Redundancy when paging is present: In systems with paging, segmentation may add little extra protection that paging cannot provide, yet still adds complexity.

### Modern Usage

In modern mainstream operating systems (e.g., 32-bit and 64-bit x86), full use of distinct segments is rare. Often segmentation hardware is still present but configured so that segments cover the entire address space (or large parts thereof) rendering segmentation invisible to software. For example, in x86 protected mode many OSes set all segment bases to zero and limits to the full 4 GB so the memory appears flat.
In 64-bit “long mode” segmentation is largely deprecated (except for some per-thread data via FS/GS in x86-64).

---

## Flat Memory Model

The flat memory model treats memory as one contiguous linear address space. From the programmer’s perspective, there is a single base (typically address 0) and addresses increase in a linear fashion. There is no need (or very minimal need) for segment registers or having to specify “segment + offset”.
In practice on segmented architectures this is often implemented by configuring the segment hardware so that all segments have base = 0 and limit = maximum (or nearly so), thus rendering them equivalent to flat.

### Advantages

* Simplicity: Easier for programmers and compilers to reason about pointers (just treat them as linear addresses) and manage memory allocation.
* Compatibility with modern OS designs: Virtual memory, paging, and process isolation are easier to implement when addressing is linear.
* Performance: Fewer complexities in address translation from segment:offset calculations.

### Disadvantages

* Without additional mechanisms (e.g., paging), a flat model provides less built-in compartmentalisation of memory. All code/data may exist in the same address space unless isolation is enforced by other means.
* Flat model by itself does not imply protection: you still need hardware support (paging, MMU) for memory protection and process isolation.

### Modern Usage

Today, most modern operating systems (including on x86) use a flat memory model from the programmer’s point of view. For example, most user‐space processes assume a single linear address space, thanks to segments being configured to span the full range. Embedded systems, microcontrollers, or simple single‐task systems often adopt flat models because of their simplicity.

---

## Hybrid Model

The minimal-segmentation or hybrid segmentation model is a compromise: only a small number of segments are used (typically one for kernel code, one for kernel data, one for user code, one for user data), and each of those spans a large or entire address space, so that within each segment the memory appears flat. In other words, segmentation is used primarily to distinguish protection domains (kernel vs user) rather than to subdivide memory finely.
On architectures like x86, this is often how modern OSes configure segmentation: segments all start at base = 0, limit = full range, and rely principally on paging for fine‐grained memory protection.

### Advantages

* Balance of protection and simplicity: You maintain hardware support for privilege separation (via segments) while avoiding the complexity of many fine‐grained segments.
* Easier to implement than full segmented model, yet provides more domain separation than a simple flat model without any segmentation.
* Compatible with modern paging and virtual memory systems: segmentation handles coarse domain separation, paging handles granular access control.

### Disadvantages

* Still some complexity: Although fewer segments, you still must configure and manage segment descriptors, base/limit, privilege levels.
* Not as fine-grained as full segmented model: You cannot subdivide segments arbitrarily for each object or buffer unless you create many segments; which defeats the simplicity goal.
* Some hardware inefficiencies: On architectures where segmentation is legacy, the hardware may not optimise for segment switching or limit enforcement as much as paging-based protection.

### Modern Usage

This hybrid approach is common in modern 32-bit x86 operating systems: for instance, kernel code and data segments and user code/data segments are set up so that segmentation remains but does not interfere with linear addressing.

---
