# How to Return a Value from an Assembly Function

Returning a value from an assembly function requires an explicit understanding of how the processor and calling conventions manage data and control flow. Unlike high-level languages, assembly does not automatically handle return values or stack maintenance; the programmer must implement these steps manually.

This tutorial outlines the common and alternative methods of returning values from functions in assembly language, with examples from 32-bit and 64-bit x86 architectures.

---

## Overview

When a function is called in assembly using the `call` instruction, the CPU automatically pushes the **return address** (the address of the next instruction) onto the stack. The callee (the called function) is responsible for performing its task and then executing the `ret` instruction to return control to that address.

While the `ret` instruction handles control flow, it does not specify how a *result* should be passed back. The method for returning a value is defined by a **calling convention**, which specifies:

* Where arguments are passed (registers or stack)
* Which registers are preserved by the callee
* Where the return value is placed

Understanding this convention is crucial to ensuring interoperability and avoiding stack corruption.

---

## Standard Return Methods

### Returning via Registers (Preferred Method)

The most common and efficient way to return a value is by placing it in a designated **return register** before executing `ret`.

#### 32-bit x86

* Integer or pointer results: `EAX`
* 64-bit results: `EDX:EAX` (high and low parts)
* Floating-point results: `ST0` (x87 FPU stack)

Example:

```asm
; int add(int a, int b)
add_numbers:
    mov eax, [esp + 4]   ; first argument
    add eax, [esp + 8]   ; add second argument
    ret
```

Caller:

```asm
push 3
push 4
call add_numbers
; result is now in EAX (value = 7)
```

#### 64-bit x86 (System V / Linux)

* Integer or pointer results: `RAX`
* Floating-point results: `XMM0`

Example:

```asm
; long add(long a, long b)
add_numbers:
    mov rax, rdi          ; first argument
    add rax, rsi          ; add second argument
    ret
```

Here, the System V AMD64 ABI specifies that arguments are passed in registers (`RDI`, `RSI`, etc.), and results are returned in `RAX`.

#### Advantages

* Fast and simple
* Stack remains unmodified
* Compatible with standard compilers and ABIs

#### Disadvantages

* Limited to data that fits within available return registers
* Complex or large data structures must use alternative methods

---

## Returning via Memory

When returning large structures, arrays, or complex data, registers alone are insufficient. Instead, the caller provides a **pointer** to a memory location where the function writes the result.

### Example

```asm
; void get_value(int* dest)
get_value:
    mov eax, [esp + 4]    ; load pointer to destination
    mov dword [eax], 123  ; write result to *dest
    ret
```

Caller:

```asm
section .data
result dd 0

section .text
    lea eax, [result]
    push eax
    call get_value
    ; result now contains 123
```

This method is common in C when returning large structs, as it avoids copying large amounts of data through registers or the stack.

---

## Returning via the Stack

Some custom calling conventions, especially in low-level systems like kernels or bootloaders, may use the stack itself to return values.

However, care must be taken to preserve the **return address** pushed by `call`. If the function pushes the result before returning, `ret` will interpret it as the return address—causing an invalid jump.

### Incorrect Approach

```asm
my_function:
    mov eax, 42
    push eax     ; ❌ pushes result on top of return address
    ret          ; tries to pop result as return address → crash
```

### Corrected Approach

To safely return a value via the stack, the function must temporarily remove the return address, push the result, and then restore the return address:

```asm
my_function:
    mov eax, 42
    pop ebx          ; pop return address
    push eax         ; push result
    push ebx         ; restore return address
    ret
```

Caller:

```asm
call my_function
pop eax              ; retrieve result (42)
```

This sequence ensures that:

* The return address is at the top of the stack when `ret` executes.
* The result remains on the stack after returning.

While unconventional, this technique is occasionally used in tightly controlled systems where the programmer defines both caller and callee behavior.

---

## Returning via Caller-Allocated Stack Space

Another alternative is for the caller to allocate space on its own stack for the return value, which the callee fills directly.

### **Example**

```asm
; void fill_result()
fill_result:
    mov dword [esp], 99   ; write result to caller's reserved space
    ret
```

Caller:

```asm
sub esp, 4                ; allocate space for result
call fill_result
mov eax, [esp]            ; read result (99)
add esp, 4                ; clean up stack
```

This technique allows the callee to return data without modifying the return address or using extra registers.

---

## Floating-Point and Vector Returns

Floating-point and SIMD (vector) values follow separate conventions:

* On x86 with x87 FPU: results are returned in `ST0`.
* On x86-64 with SSE/SSE2: results are returned in `XMM0`.
* On ARM: results use `s0/d0` or `v0` registers depending on precision.

Example (x86-64, returning a double):

```asm
; double add(double a, double b)
add_doubles:
    addsd xmm0, xmm1     ; add arguments
    ret
```

---

## Best Practices

1. **Prefer register-based returns** whenever possible. It is the most efficient and standard method.
2. **Avoid modifying the stack unnecessarily.** Stack-based returns complicate debugging and maintenance.
3. **Follow established ABIs** (e.g., System V, Microsoft x64) if your assembly interacts with C or other compiled languages.
4. **Document your custom conventions** if you are designing an OS or embedded system, ensuring consistency across all modules.
5. **Preserve the return address integrity.** The `ret` instruction depends on it.

---
