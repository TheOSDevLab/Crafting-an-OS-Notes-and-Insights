# QEMU Introduction

## What is QEMU?

QEMU (Quick Emulator) is a generic, open-source machine emulator and virtualizer. For operating system developers, its primary value lies in its **system emulation** mode, where it can simulate a complete computer system, including the CPU, memory, storage, and various peripherals. This provides a self-contained, controllable, and debuggable environment in which to develop and test a new OS without needing dedicated physical hardware.

---

## Core Features for OS Development

Several key features make QEMU exceptionally well-suited for OS development:

* **Full System Emulation:** It can emulate an entire machine, allowing you to boot an operating system from a disk image or kernel file as if it were running on real hardware.
* **Multiple Architectures:** QEMU supports a wide range of CPU architectures (e.g., x86, ARM, RISC-V), enabling cross-platform OS development.
* **Integrated Debugging Support:** This is arguably QEMU's most powerful feature. It includes a built-in GDB stub, allowing you to connect the GNU debugger directly to the emulated machine. This enables you to set breakpoints, single-step through kernel code, and inspect registers and memory.
* **Hardware Acceleration (KVM):** On Linux systems, QEMU can leverage KVM (Kernel-based Virtual Machine) for near-native performance, significantly speeding up the development and testing cycle.
* **Flexible Output and Control:** Output from the guest system's serial port can be redirected to your host terminal, which is often the simplest way to receive debug messages from a new kernel. The QEMU Monitor provides a powerful text-based interface to control the virtual machine, inspect its state, and manage virtual devices.

---

## Essential Command-Line Switches and Options

* **`-kernel <file>`**: Directly loads a specified kernel image file into memory, bypassing the need for a bootloader. This is the quickest way to start testing your kernel.
* **`-drive file=<img>`**: Defines a drive for the guest system, such as a hard disk or CD-ROM image. You can specify additional parameters like `format=raw` and `media=cdrom`.
* **`-m <size>`**: Sets the amount of RAM allocated to the guest machine (e.g., `-m 128M` for 128 Megabytes).
* **`-serial <dev>`**: Redirects the guest's serial port output. Using `-serial stdio` sends this output directly to your terminal, which is crucial for receiving text-based output from your OS.
* **`-s`**: A shorthand that launches a GDB server on TCP port 1234. This allows a debugger to connect to the running virtual machine.
* **`-S`**: Freezes the CPU at startup, waiting for a "continue" command from a connected debugger. This is used in combination with `-s` to start in a paused state for debugging.
* **`-monitor <dev>`**: Provides access to the QEMU Monitor control console. Using `-monitor stdio` integrates it with your terminal, allowing you to type monitor commands.
* **`-cpu <model>`**: Selects a specific CPU model to emulate (e.g., `-cpu core2duo`).
* **`-no-reboot` / `-no-shutdown`**: Prevents the virtual machine from rebooting or shutting down automatically upon a system crash or triple fault, allowing you to inspect the final state.
* **`-d <item>`**: Enables various detailed debug logs. For example, `-d int` is particularly helpful for tracing interrupts and exceptions.

---

## A Practical Debugging Workflow

The most effective way to develop an OS with QEMU is to integrate debugging from the very beginning. Here is a typical workflow:

1.  **Start QEMU in a Paused State:** Launch your OS kernel with debugging flags enabled.
    ```bash
    qemu-system-i386 -kernel mykernel.elf -m 128 -serial stdio -no-reboot -s -S
    ```
    This command loads `mykernel.elf`, allocates 128MB of RAM, redirects serial output to the terminal, and starts the machine in a paused state (`-S`) with a GDB server listening (`-s`).

2.  **Connect with GDB:** In a separate terminal, start your cross-platform GDB debugger and connect to the waiting QEMU instance.
    ```bash
    $ gdb mykernel.elf
    (gdb) target remote localhost:1234
    ```

3.  **Set Breakpoints and Debug:** You can now set breakpoints at key functions, such as your kernel's main entry point.
    ```bash
    (gdb) b kmain
    (gdb) c
    ```
    The VM will run until it hits the breakpoint, at which point you can step through code, examine memory, and inspect CPU registers using commands like `(gdb) info registers`.

---
