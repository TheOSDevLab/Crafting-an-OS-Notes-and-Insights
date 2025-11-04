# GDT Descriptor

The GDT descriptor is a small data structure (6 bytes in 32-bit mode, 10 bytes in 64-bit mode) that describes for the processor where the Global Descriptor Table (GDT) resides in memory and how large it is. It is **not** part of the GDT itself; instead it is loaded into the processor’s GDTR register via the LGDT instruction. Once loaded, the processor uses the base address and limit from the descriptor to locate and validate segment descriptors in the table.

---

## Layout of the GDT Descriptor

In 32-bit protected mode the descriptor has the following structure (in memory, little-endian):

* A 16-bit field **Limit**: holds the size in bytes of the GDT **minus one**. This value defines the maximum valid offset within the table.
* A 32-bit field **Base**: holds the linear (or physical for no paging) address of the start of the GDT in memory.

Thus the descriptor occupies 6 bytes:

```
Offset 0-1: Limit (16 bits)  
Offset 2-5: Base  (32 bits)  
```

In 64-bit mode (IA-32e) the descriptor is extended: the Limit remains 16 bits, but the Base becomes 64 bits (so the descriptor occupies 10 bytes).

### Important Details

* The **Limit** is stored as *(size of GDT in bytes) - 1*. That is, if the GDT is 24 bytes long, the limit must be 23. This convention ensures that a zero value cannot represent an empty table.
* The **Base** is the address where the first descriptor (entry 0) of the GDT resides. The processor will treat segment selectors as indices into that table (via Base + (selector index × size of descriptor)).
* The LGDT instruction loads these two fields into the GDTR register. After the load, the CPU uses the fields for all subsequent descriptor lookups.

---
