# Flag Register

> **Random Quote:** The gap between a dream and reality is closed by showing up.

The **FLAG** register (referred to as **EFLAGS** in 32-bit systems and **RFLAGS** in 64-bit systems) is a special-purpose CPU register that stores status bits. These flags reflect the outcome of operations and also control certain aspects of CPU behavior. The CPU reads and updates this register automatically based on arithmetic, logic, and control operations.

There are three main **categories of flags**:

1. [Status Flags](#status-flags)
2. [Control Flags](#control-flags)
3. [System Flags](#system-flags)

---

### Status Flags

Status flags indicate the outcome of the most recent operation. They are especially useful for conditional logic, such as determining whether to jump, continue, or stop execution.

The key status flags include: `CF`, `PF`, `AF`, `ZF`, `SF`, `OF`.

* **`CF` – Carry Flag (Bit 0):**
  Used in **unsigned arithmetic**. Set when:

  1. An addition operation causes a carry out of the most significant bit.
     *Example: Adding 1 to `0xFF` causes an overflow.*
  2. A subtraction operation requires a borrow.
     *Example: Subtracting 2 from 1.*

* **`PF` – Parity Flag (Bit 2):**
  Set if the lowest byte of the result has an even number of 1s.
  *Example: `0b00001111` has four 1s (even), so `PF` is set. `0b00001110` has three 1s (odd), so `PF` is clear.*
  Rarely used in modern code.

* **`AF` – Auxiliary Carry Flag (Bit 4):**
  Set when there is a carry from bit 3 to bit 4.
  *Example: `0x0F + 0x01 = 0x10`. A carry occurs between bit 3 and 4.*
  Mostly used in Binary-Coded Decimal (BCD) arithmetic.

* **`ZF` – Zero Flag (Bit 6):**
  Set if the result of an operation is exactly zero.
  *Example: `3 - 3 = 0`, so `ZF` is set.*

* **`SF` – Sign Flag (Bit 7):**
  Set if the most significant bit of the result is 1, indicating a **negative** value in **signed arithmetic**.

* **`OF` – Overflow Flag (Bit 11):**
  Used in **signed arithmetic**. Set when the sign bit is incorrect due to overflow.
  *Example: Adding 1 to 127 (`0x7F`) gives 128 (`0x80`), which is interpreted as -128. Overflow occurred, so `OF` is set.*

In practice, you might write code that checks the Zero Flag to determine whether to exit a loop, or the Sign Flag to determine if a number is negative.

> You might not fully understand these concepts right now, and that is completely fine. Focus on what makes sense at the moment. As you gain more context and experience, the rest will naturally fall into place. Keep going.

---

### Control Flags

Control flags enable or disable specific CPU features.

The control flags include: `IF`, `DF`, `TF`.

* **`IF` – Interrupt Flag (Bit 9):**
  Controls whether the CPU responds to maskable hardware interrupts.

  * Set (`IF = 1`): Interrupts are enabled.
  * Clear (`IF = 0`): Interrupts are disabled.
    Use the `CLI` instruction to clear this flag during critical operations that should not be interrupted.

* **`DF` – Direction Flag (Bit 10):**
  Determines the direction for string operations.

  * Clear: String instructions process data **forward** (increment pointer).
  * Set: String instructions process data **backward** (decrement pointer).
    Set using `STD`, clear using `CLD`.

* **`TF` – Trap Flag (Bit 8):**
  Enables single-step mode.

  * When set, the CPU triggers **INT 1** after each instruction.
  * Useful for debugging tools like GDB to walk through code instruction by instruction.

---

### System Flags

System flags control low-level CPU behavior and special processor states. They are mainly used by operating systems, debuggers, and virtualization layers.

System flags include: `RF`, `VM`, `AC`, `VIF`, `VIP`, `ID`.

* **`RF` – Resume Flag (Bit 16):**
  Prevents an instruction from re-triggering a fault after being resumed by `IRET`. Used in debug exception handling.

* **`VM` – Virtual 8086 Mode (Bit 17):**
  Enables real-mode-like execution within protected mode.
  Used to run legacy real-mode applications in a 32-bit environment.

* **`AC` – Alignment Check (Bit 18):**
  When set (and if CR0.AM is also set), misaligned memory accesses (such as reading a word at an odd address) cause an `#AC` exception.
  Useful in debugging but often disabled for performance.

* **`VIF` – Virtual Interrupt Flag (Bit 19):**
  Used by Virtual Machine Monitors (VMMs) to simulate the behavior of `IF` within virtual 8086 mode.
  It allows VMs to behave as if interrupts are enabled without actually granting hardware interrupt access.

* **`VIP` – Virtual Interrupt Pending (Bit 20):**
  Indicates that a virtual interrupt is pending, but `IF` is currently clear.
  Helps the monitor delay interrupt delivery until `IF` is re-enabled.

* **`ID` – ID Flag (Bit 21):**
  Controls access to the `CPUID` instruction.
  If the flag is set, software can execute `CPUID` to query the CPU for features and information.
  You can toggle this bit to check whether `CPUID` is supported.
