# `-enable-kvm`

* **Purpose:** The `-enable-kvm` option directs QEMU to use the Linux **Kernel-based Virtual Machine (KVM)** accelerator for full hardware‑assisted virtualization. This replaces pure emulation with hypervisor‑backed execution of guest code on the host CPU when supported, dramatically improving performance compared to software emulation alone.

* **Scope:** Applies at the **QEMU emulator level** on hosts with KVM support. It is relevant to **system emulation** (`qemu-system-*`) invocations on architectures where KVM is supported (e.g., x86_64, ARM64, PPC, RISC‑V).

---

## Syntax and Parameters

```
qemu-system-<arch> -enable-kvm [other QEMU options]
```

### Parameters

* **Name:** `-enable-kvm`  
* **Type:** Boolean flag (presence enables the feature)  
* **Default value:** *Omitted*; default operation uses TCG software emulation if KVM is unavailable or not requested.
* **Valid values / constraints:** Must be present on the command line to request KVM. No explicit parameter value is passed. If KVM is not compiled into QEMU or not operational on the host, QEMU may fail when this flag is given.
* **Behavior if omitted:** QEMU runs in TCG mode (software emulation) by default; on hosts where KVM is available, it **will not** automatically fallback to using hardware virtualization unless explicitly requested or configured by front‑end tooling.

---

## Runtime Behavior Impact

### On Host

**CPU:**  
* Transitions guest code execution from QEMU’s Tiny Code Generator (TCG) to **native execution in ring 0/host privileged context via KVM**, reducing dynamic translation overhead. This yields near‑native performance on host CPU.

**Memory:**  
* Guest memory regions are **mapped directly** using KVM APIs and `mmap` into host address space; machine‑specific MMU behavior is offloaded to KVM.

**I/O:**  
* I/O exits (from the guest) to host space occur through KVM exit reasons; fewer exits generally improve throughput for I/O intensive workloads.

### On Guest

* Enables the guest to execute privileged instructions and access virtual CPUs with **hardware support** rather than software interpretation.  
* Guest CPU registers, features, and virtualization extensions are handled via KVM.  
* Performance of compute workloads improves significantly relative to TCG.

### Emulation vs Passthrough

* `-enable-kvm` enables **hardware‑assisted virtualization**, not direct I/O *passthrough* of PCI devices or similar resources. Device passthrough (e.g., VFIO) requires additional explicit configuration.  
* KVM accelerates CPU and memory virtualization; device models remain controlled by QEMU unless passthrough is separately configured.

### Dependencies

* Requires host **KVM kernel modules** loaded (e.g., `kvm`, `kvm_intel` or `kvm_amd` on x86).
* Host CPU **virtualization extensions** must be enabled in firmware (VT‑x / AMD‑V).
* If KVM support is *not* compiled into the QEMU binary or not present in the host kernel, QEMU may exit with error when this flag is passed.

---

## Example Usage

```
qemu-system-x86_64 -enable-kvm -m 2G -hda ubuntu.img -boot c
```

*Expected Outcome:* QEMU initializes a 64‑bit x86 guest using KVM acceleration; the guest boots from `ubuntu.img` with 2 GB of RAM. KVM is engaged for CPU and memory virtualization.

---

## Notes and Caveats

* **Implementation Quirk:** Some distributions compile QEMU with KVM support disabled by default; in these cases, `‑enable‑kvm` is ignored or triggers a startup failure.
* **Fallback Behavior:** Without `‑enable‑kvm`, QEMU historically defaults to TCG; modern front‑ends (libvirt/virt‑manager) may auto‑inject the KVM accelerator flag based on configuration.
* **Platform Differences:**  
  * On Linux hosts, KVM is available.  
  * On non‑Linux (e.g., macOS), KVM is not present; analogous accelerators like HVF or WHPX may be used instead.
* **Error Conditions:** If KVM modules are unavailable or `/dev/kvm` is not accessible by the user, QEMU may report failure when attempting to start with `‑enable‑kvm`. Tools like `kvm-ok` on Ubuntu help verify support prior to invocation.

---

