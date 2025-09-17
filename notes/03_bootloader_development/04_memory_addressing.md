# Segment\:Offset addressing in 16-bit bootloader code

* In real mode the CPU forms a 20-bit linear physical address from a 16-bit segment value and a 16-bit offset value using this rule:

  ```
  physical_address = (segment << 4) + offset
  ```

  In other words, the segment value is shifted left by 4 bits (equivalently multiplied by 16) to produce the segment base; the 16-bit offset is then added to that base. This yields a 20-bit address space (0x00000 through 0xFFFFF) when the A20 line is enabled.

* Consequence: the same physical address can be represented by many different segment\:offset pairs. For example, the linear address `0x08124` can be written as `06EF:1234`, `0812:0004`, or `0000:8124`. Use this property deliberately when designing stack or data locations.

---

## Registers used for segment\:offset addressing

* Code segment register `CS` pairs with the instruction pointer `IP` for fetches (`CS:IP`).
* Data segment register `DS` is used for most data references when instructions use a non-explicit segment.
* Extra segment register `ES` is commonly used for string and video memory operations (for example with `movs`, `stos`, `cmps`).
* Stack segment `SS` pairs with `SP`/`BP` for stack accesses (`SS:SP`, `SS:BP`).
* You must explicitly load segment registers with 16-bit values (usually by `mov ax, segvalue` then `mov ds, ax`). Many instructions that access memory implicitly use `DS` or `SS` depending on addressing mode.

---

## Practical limits and important caveats

* Each segment covers at most 64 KiB of offsets (offset 0x0000 through 0xFFFF). Therefore a single segment cannot address more than 64 KiB at a time in real mode.
* Real mode uses 20 physical address bits. Historically the A20 gate could disable the 21st bit and cause wraparound at 1 MiB. On modern systems A20 is typically enabled but be aware of historical behavior if you target very old environments or report behavior around 0xFFFFF.
* Since many segment\:offset pairs alias the same physical address, using the wrong segment register can lead to subtle bugs where your code reads or writes a different physical byte than you intend. Always set DS/ES/SS explicitly when you rely on precise addresses.

---

## The assembler `ORG` directive and its relation to segments

* `ORG` is an assembler directive that tells NASM the load address offset that the assembler should assume when calculating label offsets. For a BIOS boot sector, the BIOS loads the sector at physical address `0x7C00`. Common practice is to write `org 0x7C00` so that labels and data offsets are assembled as if they start at offset `0x7C00`. This is a convenience for generating correct offsets in your binary.

* Important conceptual point: `ORG` affects how the assembler computes label values; it does not itself change the CPU registers at runtime. You are still responsible for loading the correct segment registers at runtime so that the CPU's segment\:offset arithmetic matches the assumption used by the assembler. For example, if `org 0x7C00` and you expect labels to be reachable by `ds:offset`, you must arrange that `DS:offset` points to the physical address `0x7C00 + offset`.

---

## Example 1: Minimal boot sector using `org 0x7C00` and DS = 0

* Purpose: show how `org` and segments combine in practice. This example uses `DS = 0x0000` and relies on offsets being in the 0x7C00 region.

```asm
; boot.asm
BITS 16
org 0x7C00

start:
    cli                 ; disable interrupts while we set segment registers
    xor ax, ax
    mov ds, ax          ; DS = 0x0000
    mov es, ax          ; ES = 0x0000
    sti

    ; Example: print characters by writing to VGA text buffer at 0xB8000.
    ; Compute address: 0xB8000 == 0xB800:0x0000 or 0x0000:0xB8000 (only first is valid offset)
    ; Here we will set ES to 0xB800 and write to ES:0x0000
    mov ax, 0xB800
    mov es, ax
    mov di, 0x0000
    mov al, 'A'
    mov ah, 0x07
    stosw               ; write 'A' with attribute to video memory

hang:
    hlt
    jmp hang

times 510-($-$$) db 0
dw 0xAA55
```

* Explanation: `org 0x7C00` makes labels reference offsets relative to 0x7C00. At runtime we explicitly set `DS` and `ES` to the segment values required for the memory we wish to use. The code writes to VGA memory by setting `ES=0xB800` and using `stosw` at offset zero. Note that `mov es, 0xB800` is done via `mov ax, 0xB800` then `mov es, ax` because segment registers are written from general registers.

---

## Example 2: Placing stack safely with an alternative segment

* Problem: you want the stack to be located safely away from code and data. Because the stack uses `SS:SP`, set `SS` to a segment where the offset SP you choose maps to a physical location that does not overlap your code.

```asm
BITS 16
org 0x7C00

start:
    ; set up a stack at physical address 0x9000 (example)
    mov ax, 0x9000    ; segment 0x9000 corresponds to physical 0x90000 when shifted
    mov ss, ax
    mov sp, 0xFFFF    ; top of that 64KiB segment

    ; Pushes and interrupts will use SS:SP
    ; ...
    jmp $

times 510-($-$$) db 0
dw 0xAA55
```

* Explanation: segment `0x9000` multiplied by 16 gives base 0x90000. With `sp=0xFFFF` the first stack word will be at physical `0x9000 + 0xFFFF = 0x9FFFF`.

---

## Example 3: Different segment\:offset pairs mapping to the same physical address

* Demonstration that multiple segment\:offset pairs can reference the same byte:

```
physical = 0x7C00

0x0000:0x7C00  -> (0x0000 << 4) + 0x7C00 = 0x7C00
0x07C0:0x0000  -> (0x07C0 << 4) + 0x0000 = 0x7C00
0x07BF:0x0010  -> (0x07BF << 4) + 0x0010 = 0x7B F0 + 0x10 = 0x7C00
```

* `org 0x7C00` plus explicitly setting `DS` and `SS` makes your code robust regardless of the initial segment values left by the BIOS.

---

## Example 4: Addressing data in your boot sector (labels and `ORG`)

* If your data label `message` is assembled at offset `0x7C10` because of `org 0x7C00`, then at runtime you can refer to it by loading `DS` so that `DS:message - 0x7C00` reaches it.

```asm
BITS 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax          ; choose DS such that offset matches assembled addresses
    sti

    ; assume 'message' label is at assemble-time offset 0x7C10
    mov si, message     ; NASM assembles 'message' as the immediate offset 0x7C10
    ; if DS=0x0000 then DS:SI = 0x0000:0x7C10 = physical 0x7C10

message db 'Boot here', 0

times 510-($-$$) db 0
dw 0xAA55
```

* Note: NASM emits the numeric offset for `message` based on `org`. If instead you prefer to place your code at `0x0000` offset and adjust CS at runtime, you may omit `org` but then you must adjust segment registers accordingly. Many examples use `org 0x7C00` because it simplifies label arithmetic.

---

## Typical idioms and best practices

* Always set `DS`, `ES`, and `SS` consciously early in boot code. Do not rely on BIOS preserved values.
* Use `org 0x7C00` for one-sector bootloaders to make label offsets intuitive. Remember `ORG` is an assembler assumption and does not change CPU segment registers.
* Keep the stack within well chosen segments; do not place `SS:SP` where it can collide with your code or data unless you manage offsets carefully.
* When doing video or BIOS calls, set the segment registers expected by those operations (`ES` for many string operations; for direct VGA writes use `ES:DI` with `ES=0xB800`).

---

## Common Pitfalls

* Mistaking `ORG` for runtime segment setup. `ORG` only affects assembly-time offsets. Verify runtime segments match your offset assumptions.
* Overlapping segments leading to accidental aliasing. Because segment pairs overlap, reading/writing through different segment registers can touch the same physical memory. Use explicit segment loads when necessary.
* Forgetting the 64 KiB limit of a segment. Offsets cannot exceed 0xFFFF; use multiple segments if you need more than 64 KiB in a single logical region.

---
