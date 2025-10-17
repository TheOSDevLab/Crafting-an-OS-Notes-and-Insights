# BIOS Interrupt Service

For comprehensive documentation regarding BIOS INT 15h Function 24h, consult [this file](https://github.com/TheOSDevLab/Bare-Metal-Assembly/blob/main/notes/05_bios_interrupts/int15h/README.md).

The BIOS method provides a standardized interface abstracting hardware differences.

---

## Implementation Steps

**Step 1: Check BIOS Support**

```
mov ax, 0x2403
int 0x15
jc bios_unsupported
```

**Step 2: Enable A20 Line**

```
mov ax, 0x2401
int 0x15
```

---

## Return Code Handling

- **Carry flag clear**: Success
- **Carry flag set**: Error (AH contains error code)
- **AH=0x86**: Function not supported
- **AH=0x01**: Keyboard controller locked

---

## Advantages and Limitations

**Advantages:**

- Hardware abstraction
- Clean, simple interface
- No risk of system reset

**Limitations:**

- Inconsistent BIOS implementation
- May not be available on all systems
- Some BIOS implementations are buggy

---
