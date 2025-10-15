# Keyboard Controller Method (8042)

The keyboard controller method was the original IBM-compatible approach and offers the highest compatibility with legacy hardware.

## Implementation Steps

**Step 1: Disable Keyboard Interface**

```
; Wait until the input buffer is empty
wait_in1:
    in al, 0x64
    test al, 0x02
    jnz wait_in1

; Disable keyboard
mov al, 0xAD
out 0x64, al
```

**Step 2: Read Current Output Port**

```
; Command to read output port
mov al, 0xD0
out 0x64, al

; Wait for output buffer full
wait_out:
    in al, 0x64
    test al, 0x01
    jz wait_out

; Read output port
in al, 0x60
mov bl, al
```

**Step 3: Write Modified Output Port**

```
; Command to write output port
mov al, 0xD1
out 0x64, al

; Wait for input buffer empty
wait_in2:
    in al, 0x64
    test al, 0x02
    jnz wait_in2

; Write output port with A20 bit set
mov al, bl
or al, 0x02
out 0x60, al
```

**Step 4: Re-enable Keyboard**

```
; Wait for input buffer empty
wait_in3:
    in al, 0x64
    test al, 0x02
    jnz wait_in3

; Re-enable keyboard
mov al, 0xAE
out 0x64, al
```

---

## Advantages and Limitations

**Advantages:**

- Universal compatibility with IBM PC/AT and early compatibles
- Guaranteed to work on virtually all pre-2000 hardware

**Limitations:**

- Extremely slow due to keyboard controller delays
- Complex implementation requiring precise timing
- Potential to disrupt keyboard functionality if improperly implemented

---
