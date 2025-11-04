# `info` Command

## Overview

The `info` command in the QEMU monitor is used to retrieve information about various subsystems of the virtual machine (VM). It provides a structured way to query the current state of devices, memory mappings, registers, snapshots, and other runtime aspects. The command accepts an option (sub-command) which specifies which part of the VM to inspect.

---

## How It Works

When you execute `info <option>` at the monitor prompt, QEMU examines the relevant internal data structures for the specified subsystem, generates a text-formatted report, and outputs it to the monitor. It does *not* alter VM state (unless you combine it with other commands); its purpose is diagnostic. For example, using `info registers` causes QEMU to read the CPU state (general purpose registers, control registers, segment selectors, etc.) and display them. The command works synchronously: you type it, QEMU processes it, and you get the output before the prompt returns.

---

## Syntax

```text
info <option>
```

* `<option>` is a keyword that identifies the subsystem you want information about.
* If `info` is used without any `<option>`, QEMU displays a list of available options (i.e., subsystems you can query).
* Example options include: `registers`, `block`, `mem`, `pci`, `snapshots`, `version`, etc.

---

## Practical Use Cases

* Inspecting CPU registers mid-execution (e.g., to verify control register flags).
* Viewing what block (disk) devices are currently attached to the VM.
* Dumping active memory mappings or TLB state, useful in OS development and debugging.
* Checking active VM snapshots or version information of QEMU.
* Confirming what devices (USB, PCI, etc.) are present in the guest environment.

---

## Best Practices

* Use `info` commands *before* modifying VM state (for example before a mode switch or just after) to capture baseline status.
* Pause the VM when querying time-sensitive subsystems to avoid race conditions where state changes between query and output.
* If scripting VM inspection (e.g., for automated tests), use `info` with output capture and parse the results. Using monitors redirected to sockets can help with this.
* Familiarize yourself with the full list of `info` options (via `info` alone) so you know what subsystems you can query.

---

## Common Pitfalls

* Expecting `info` to work with custom or non-enabled subsystems. Some options may report nothing if the subsystem is disabled or not compiled in.
* Interpreting `info mem` or `info mtree` as process-specific mappings: these commands show *guest-level or MMU-level* mappings, not necessarily per-process data.
* Trying to issue `info` while the monitor is embedded in a context (such as via libvirt) where direct monitor access is restricted. In such cases you may need special forwarding or use of the QEMU machine protocol (QMP).
* Misreading output because the VM is still running and state may change between viewing and analysis; consider stopping the VM or freezing state when consistent snapshots are needed.

---
