# Switching to Protected Mode

## Preconditions and Preparations

Before enabling protected mode, certain conditions must be met:

* The processor starts in **real mode** (16-bit, segmented, backward-compatibility mode).
* Interrupts should be disabled (including Non-Maskable Interrupts if possible) to avoid unexpected control transfers during the transition.
* The **A20 address line** should be enabled so that the CPU can access beyond the first 1 MB of memory without aliasing.
* A Global Descriptor Table (GDT) must be constructed, containing at minimum:

  1. A null descriptor (entry 0)
  2. A code segment descriptor (for protected mode)
  3. A data segment descriptor (for protected mode)
* The GDT descriptor (base + limit) must be set up so that the processor can be pointed at the GDT.

At this point your system is ready to begin the transition into protected mode.

---

## Load the GDT and Associate Descriptor Table

With your GDT built in memory, the next step is to load its address and size into the processor’s GDTR register. This is done using the `LGDT` instruction. Once the GDTR is set, the processor will use the segment selectors (CS, DS, etc) in protected mode to reference your GDT entries.

In effect:

* Calculate the **limit** = (size of GDT in bytes) - 1
* Compute the **base address** = linear address of the first descriptor
* Place them into the GDT descriptor structure in memory
* Execute `LGDT [descriptor]`

At this moment the CPU knows where your GDT resides but has *not yet* switched modes; the actual real/ protected mode bit is still cleared.

---

## Set the Protection Enable (PE) Bit in CR0

Once the GDT is loaded, the actual mode switch occurs when the PE bit (bit 0) of control register CR0 is set to 1. That is:

* Read CR0
* OR the value with 0x1 (set PE bit)
* Write CR0 back

This puts the processor into *protected mode* conceptually; but not fully functionally until certain things change.

---

## Far Jump to Flush the Prefetch Queue and Load CS Selector

Immediately after setting PE, a **far jump** (with a segment:offset operand) must be executed. This serves two purposes:

* It flushes the CPU’s instruction pre-fetch queue, ensuring that subsequent instructions use the new descriptor semantics.
* It loads the CS register with a protected-mode code segment selector from your GDT, ensuring that execution continues properly under the new mode.

For example:

```asm
jmp 0x08:ProtectedModeEntry
```

where `0x08` is the selector for your code segment descriptor in the GDT.

---

## Reload All Segment Registers (DS, ES, FS, GS, SS)

After the far jump and arrival at your protected-mode entry label, you must reload all other segment registers to appropriate selectors in your GDT (data segment descriptor, stack segment descriptor). This ensures that data and stack accesses use the correct base/limit/privilege semantics of protected mode.

For example:

```asm
mov ax, 0x10   ; selector for data segment
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
```

---

## Enable Additional Features (Paging, Interrupts, etc.)

Once protected mode is active and your segments are established, you can enable further features such as:

* Setting up an Interrupt Descriptor Table (IDT) and loading it with `LIDT`
* Enabling paging (setting up page tables, CR3, then CR0.PG bit)
* Turning on interrupts (`sti`) once your handlers are ready
  But these are beyond the minimal protected-mode switch process outlined here.

---

## Key Considerations and Warnings

* **Interrupts must remain disabled** during the transition to avoid unexpected faults while selectors or mode state are inconsistent.
* **The GDT must be valid** and accessible in memory before setting PE; if not, the processor may fault.
* **The far jump is mandatory**; failing to flush the pre-fetch queue or load CS properly can lead to undefined behavior.
* **Selectors used before the jump must refer to valid GDT entries** (code and data) with correct privilege level and present bits.

---

## Implementation

```assembly
; -----------------------------------------------------------------------------
; Minimal switch to 32-bit Protected Mode (NASM syntax)
; - org 0x7C00 assumes this is a boot sector image for demonstration
; - Builds a simple GDT: null, kernel code, kernel data
; - Loads GDTR with lgdt, sets CR0.PE, far-jumps to protected code
; -----------------------------------------------------------------------------
org 0x7C00

start:
    cli                     ; disable interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ; temporary stack in real mode

    ; Enable the A20 line using BIOS method.
    ; NOTE: This is for demonstraction only. Real implementation includes
    ; using multiple methods and testing the A20 line.
    mov ah, 0x24
    mov al, 0x01
    int 0x15

    ; -----------------------
    ; Prepare GDT in memory
    ; -----------------------
    lgdt_ptr:
        dw gdt_end - gdt_start - 1   ; limit = size - 1
        dd gdt_start                 ; base = linear address of GDT

    ; Load the GDT (makes the table visible to CPU)
    lgdt [lgdt_ptr]

    ; Set PE bit in CR0 to enable protected mode
    mov eax, cr0
    or  eax, 0x1        ; set PE (Protection Enable) bit
    mov cr0, eax

    ; Far jump loads CS with selector for protected-mode code segment
    ; and flushes prefetch queue. Selector 0x08 → GDT entry 1 (index 1).
    jmp 0x08:protected_entry

; ---------------------------------------------------------------------------
; Global Descriptor Table (GDT)
; Layout: each entry = 8 bytes
; Entry 0 = null descriptor
; Entry 1 = kernel code segment (base=0x00000000, limit=0xFFFFF, access=0x9A, flags+limhi=0xCF)
; Entry 2 = kernel data segment (base=0x00000000, limit=0xFFFFF, access=0x92, flags+limhi=0xCF)
; -----------------------------------------------------------------------------
gdt_start:
    ; NULL descriptor (8 bytes)
    dd 0x00000000
    dd 0x00000000

    ; Kernel Code Segment descriptor (index 1 -> selector 0x08)
    ; Format (little-endian fields):
    ;  limit_low (16) | base_low (16) | base_mid (8) | access (8) |
    ;  limit_high(4) + flags(4) | base_high (8)
    dw 0xFFFF              ; limit (low)
    dw 0x0000              ; base (low)
    db 0x00                ; base (mid)
    db 0x9A                ; access: 1 00 1 1010 -> present, DPL=0, code/data, exec/read
    db 0xCF                ; flags+limit_hi: 1100 1111 -> G=1, D/B=1, L=0, AVL=0 ; limit_hi=0xF
    db 0x00                ; base (high)

    ; Kernel Data Segment descriptor (index 2 -> selector 0x10)
    dw 0xFFFF              ; limit (low)
    dw 0x0000              ; base (low)
    db 0x00                ; base (mid)
    db 0x92                ; access: 1 00 1 0010 -> present, DPL=0, data, writable
    db 0xCF                ; flags+limit_hi
    db 0x00                ; base (high)

gdt_end:

; ---------------------------------------------------------------------------
; Protected-mode entry point (32-bit code segment assumed; CS selector 0x08)
; ---------------------------------------------------------------------------
; Use 32-bit code in protected mode
bits 32
protected_entry:
    ; Set up data segments to use GDT data selector (0x10)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; Initialize stack (SS:ESP); use a safe stack area in available memory
    mov ss, ax
    mov esp, 0x9FC00       ; example stack pointer (adjust to your memory map)

    ; At this point the CPU is in protected mode (32-bit). Continue kernel init here.
    ; For demonstration we will hang.
.hang:
    cli
    hlt
    jmp .hang

; ---------------------------------------------------------------------------
; Boot sector padding and signature
; ---------------------------------------------------------------------------
times 510-($-$$) db 0
dw 0xAA55
```

---
