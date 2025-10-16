# A20 Line Verification Methods

## Introduction

Verifying the A20 line status is a critical step in system initialization, particularly during the transition from real mode to protected mode. Accurate A20 detection ensures proper memory access above the 1MB boundary and prevents subtle memory corruption issues. This tutorial provides a comprehensive examination of all major A20 verification techniques, from BIOS-assisted queries to low-level memory testing methods.

---

## BIOS Query Method

### INT 15h, AX=2402h - Direct Status Query

The most reliable verification method uses BIOS services to directly query the A20 gate status.

```nasm
check_a20_bios:
    mov ax, 0x2402      ; Function: query A20 status
    int 0x15            ; Call BIOS
    jc .bios_error      ; Carry set indicates unsupported function
    cmp al, 0x01        ; AL=01h: enabled, AL=00h: disabled
    je .enabled
    mov ax, 0x0000      ; Return disabled
    ret
.bios_error:
    stc                 ; Set carry to indicate error
    ret
.enabled:
    mov ax, 0x0001      ; Return enabled
    clc                 ; Clear carry for success
    ret
```

**Advantages:**
- Highest reliability when supported
- Non-destructive to memory
- Fast execution
- No side effects

**Limitations:**
- Not available on all systems
- Some BIOS implementations may report incorrect status

---

## Memory Comparison Methods

### Traditional Wrap-Around Test

This method exploits the address wrap-around behavior by writing to complementary memory locations.

```nasm
check_a20_memory_wraparound:
    push es
    push ds
    push di
    push si
    
    ; Set up segment registers for wrap-around test
    mov ax, 0xFFFF      ; ES:DI = 0xFFFF:0x0010 = 0x100000 (wraps to 0x000000)
    mov es, ax
    mov di, 0x0010
    
    mov ax, 0x0000      ; DS:SI = 0x0000:0x0000 = 0x000000
    mov ds, ax
    mov si, 0x0000
    
    ; Save original values
    mov al, [es:di]
    push ax
    mov al, [ds:si]
    push ax
    
    ; Write complementary patterns
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
    
    ; Test if writes affected same physical memory
    mov al, [es:di]
    cmp al, 0xFF        ; If A20 disabled, both locations point to same memory
    je .disabled
    
.enabled:
    mov ax, 0x0001
    jmp .cleanup

.disabled:
    mov ax, 0x0000

.cleanup:
    ; Restore original memory contents
    pop bx
    mov [ds:si], bl
    pop bx
    mov [es:di], bl
    
    pop si
    pop di
    pop ds
    pop es
    ret
```

---

### Enhanced Signature Test

A more robust version that uses unique signatures to avoid false positives.

```nasm
check_a20_signature:
    push es
    push ds
    
    ; Use specific signature addresses
    mov ax, 0xFFFF
    mov es, ax
    mov bx, 0x0010      ; ES:BX = 0x100000 (wraps to 0x000000)
    
    mov ax, 0x0000
    mov ds, ax
    mov dx, 0x0500      ; DS:DX = 0x00500 (safe low memory location)
    
    ; Save original content
    mov al, [es:bx]
    push ax
    mov al, [ds:dx]
    push ax
    
    ; Write unique signatures
    mov byte [es:bx], 0xA2
    mov byte [ds:dx], 0xB7
    
    ; Compare results
    mov al, [es:bx]
    cmp al, 0xA2        ; If signatures differ, A20 is enabled
    jne .disabled
    
    ; Additional verification
    mov byte [es:bx], 0xC4
    mov al, [ds:dx]
    cmp al, 0xB7        ; Low memory unchanged means A20 enabled
    jne .disabled

.enabled:
    mov ax, 0x0001
    jmp .restore

.disabled:
    mov ax, 0x0000

.restore:
    pop cx
    mov [ds:dx], cl
    pop cx
    mov [es:bx], cl
    
    pop ds
    pop es
    ret
```

---

## Multi-Location Verification

### Comprehensive Memory Scan

For maximum reliability, test multiple memory location pairs.

```nasm
check_a20_comprehensive:
    ; Test multiple address pairs to avoid false results
    mov cx, 3           ; Number of test iterations
    mov bx, 0           ; Success counter
    
.test_loop:
    push cx
    call check_a20_single_test
    pop cx
    jc .test_error
    
    cmp ax, 0x0001
    jne .not_enabled
    inc bx              ; Count successful enabled detections
    
.not_enabled:
    loop .test_loop
    
    ; Require majority consensus
    cmp bx, 2
    jge .confirmed_enabled
    mov ax, 0x0000      ; Disabled
    ret

.confirmed_enabled:
    mov ax, 0x0001      ; Enabled
    ret

.test_error:
    mov ax, 0x0000      ; Default to disabled on error
    ret

check_a20_single_test:
    ; Individual test with different offset pairs
    push es
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x0010      ; First test pair
    
    mov ax, 0x0000
    mov ds, ax
    mov si, 0x0000
    
    ; Quick test with minimal memory disturbance
    mov al, [es:di]
    mov ah, 0x5A        ; Test pattern
    mov [es:di], ah
    mov ah, [ds:si]
    cmp [es:di], ah     ; Compare results
    mov [es:di], al     ; Restore original
    
    je .test_disabled
    mov ax, 0x0001
    jmp .test_done

.test_disabled:
    mov ax, 0x0000

.test_done:
    pop es
    ret
```

---

## Cache-Aware Verification

### Serializing Memory Test

Ensure results aren't affected by processor caching.

```nasm
check_a20_serialized:
    ; Use serializing instructions to flush caches
    push es
    push ds
    
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x0010
    
    mov ax, 0x0000
    mov ds, ax
    mov si, 0x0000
    
    ; Save originals
    mov al, [es:di]
    push ax
    mov al, [ds:si]
    push ax
    
    ; Serialize execution
    pushf
    cli                 ; Disable interrupts
    
    ; Write test pattern with serialization
    mov byte [es:di], 0xAA
    cpu 0F1h            ; CPUID for serialization (if available)
    
    mov byte [ds:si], 0x55
    cpu 0F1h            ; CPUID for serialization
    
    ; Read back with serialization
    mov bl, [es:di]
    cpu 0F1h
    mov bh, [ds:si]
    cpu 0F1h
    
    popf                ; Restore interrupts
    
    ; Analyze results
    cmp bl, 0xAA
    jne .cache_disabled
    cmp bh, 0x55
    jne .cache_disabled
    
    mov ax, 0x0001      ; Enabled
    jmp .cache_restore

.cache_disabled:
    mov ax, 0x0000      ; Disabled

.cache_restore:
    ; Restore memory
    pop cx
    mov [ds:si], cl
    pop cx
    mov [es:di], cl
    
    pop ds
    pop es
    ret
```

---

## Implementation Strategy

### Robust Verification Framework

```nasm
; Main A20 verification entry point
verify_a20_status:
    ; Attempt BIOS method first (most reliable)
    call check_a20_bios
    jnc .verification_complete  ; Success with BIOS method
    
    ; BIOS failed, use comprehensive memory testing
    call check_a20_comprehensive
    jnc .verification_complete
    
    ; Final fallback to simple test
    call check_a20_signature
    
.verification_complete:
    ret

; Enhanced verification with multiple techniques
verify_a20_enhanced:
    mov cx, 5                   ; Maximum retry attempts
    mov dx, 0                   ; Success counter
    
.retry_loop:
    push cx
    push dx
    
    call verify_a20_status
    jc .retry_failure           ; Carry set indicates verification error
    
    cmp ax, 0x0001
    jne .retry_disabled
    pop dx
    inc dx                      ; Count enabled confirmations
    push dx
    
.retry_disabled:
    pop dx
    pop cx
    
    ; Short delay between attempts
    call short_delay
    loop .retry_loop
    
    ; Require consistent results
    cmp dx, 3                   ; At least 3 enabled confirmations
    jge .consistent_enabled
    mov ax, 0x0000              ; Disabled
    ret

.consistent_enabled:
    mov ax, 0x0001              ; Enabled
    ret

.retry_failure:
    pop dx
    pop cx
    mov ax, 0x0000              ; Default to disabled on persistent failure
    ret

short_delay:
    push cx
    mov cx, 0x1000
.delay_loop:
    nop
    loop .delay_loop
    pop cx
    ret
```

---

## Best Practices and Recommendations

### Verification Strategy

1. **Prefer BIOS Methods**: Always attempt BIOS query first when available
2. **Use Multiple Techniques**: Combine different verification methods for reliability
3. **Test Multiple Locations**: Verify with different memory address pairs
4. **Implement Retry Logic**: Account for potential timing issues
5. **Minimize Memory Disturbance**: Preserve original memory contents

### Error Handling

- Always check for carry flags indicating verification failures
- Implement graceful fallbacks between methods
- Provide clear error reporting for diagnostic purposes
- Consider system-specific quirks and limitations

### Performance Considerations

- BIOS queries are fastest but not universally available
- Memory tests have variable timing depending on system speed
- Cache-aware methods are slowest but most reliable on modern hardware
- Balance between verification thoroughness and boot time requirements

---

## Conclusion

Accurate A20 verification is essential for robust system software. By implementing a multi-layered verification strategy that combines BIOS queries with comprehensive memory testing, developers can ensure reliable A20 status detection across diverse hardware platforms. The methods presented in this tutorial provide a foundation for building production-quality A20 verification routines suitable for bootloaders, operating systems, and system diagnostic tools.

---
