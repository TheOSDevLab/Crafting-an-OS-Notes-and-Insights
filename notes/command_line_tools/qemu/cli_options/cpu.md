# `-cpu`

* **Purpose:** The `-cpu` option in QEMU allows the user to **explicitly select and configure the virtual CPU model and its feature set** that will be presented to the guest. It determines what kind of CPU the guest perceives, including instruction set extensions, feature flags, and overall CPU topology when combined with other options.

* **Scope:** Applies to the **QEMU system emulator** (`qemu-system-<arch>`), across architectures such as x86, ARM, RISC‑V, PowerPC, etc. It influences both pure emulation (TCG) and hardware‑accelerated runs (e.g., under KVM), and interacts with the host’s capabilities.

---

## Syntax and Parameters

```
qemu-system-<arch> -cpu <model>[,<feature1>[,<feature2>[,...]]]
```

### Parameters

* **Name:** `model`  
  * **Type:** Enumeration / string  
  * **Default value:** Implicit default CPU model for the target architecture (e.g., `qemu64` for x86_64) if `-cpu` is omitted; exact default may vary by architecture and QEMU version.
  * **Valid values / constraints:**  
    * **Named models:** Predefined CPU models such as `Westmere`, `Skylake-Server`, `qemu64`, etc., which encapsulate specific combinations of capabilities.
    * **Special mode `host`:** Pass‑through of the host’s CPU features to the guest (commonly used with KVM).
    * **Feature modifiers:** Additional flags like `pcid=on`, `vmx=off`, etc., to explicitly enable/disable specific architectural features on a per‑model basis.
  * **Behavior if omitted:** QEMU falls back to a **default CPU model** that is compatible with most hosts and guest operating systems; this model typically defines a basic and portable feature set.

---

## Runtime Behavior Impact

### On Host

* When using **host pass‑through** (`-cpu host`), QEMU may expose the host’s CPU features through KVM to the guest, enabling direct usage of hardware extensions and minimizing emulation overhead.
* With named models or feature filters, the host still executes guest workloads, but the CPU feature set presented to the guest is constrained to the model’s definition, which can impact how much work the QEMU/KVM stack will route directly to the hardware versus handling in software.

### On Guest

* Defines which **virtual CPU features and instructions** are visible to the guest OS and applications. This determines capabilities like virtualization extensions, vector instruction support, performance mitigations, and other ISA features.
* The guest’s kernel uses CPUID or equivalent mechanisms to query these capabilities; mismatches between expected and presented features can influence boot success or OS behavior.

### Emulation vs Passthrough

* With **TCG (software emulation)**, `-cpu` entirely controls the *software‑emulated* CPU behavior.  
* With **KVM acceleration**, `-cpu host` typically maps guest capabilities to the host CPU; other named models offer a controlled subset of host features for migration compatibility or isolation.

### Dependencies

* Works in concert with **`-enable-kvm`**: certain models (e.g., `host`) depend on hardware virtualization support to be meaningful.
* Feature modifiers depend on both the base model and whether the host supports the queried capabilities; unsupported combinations may be ignored or cause QEMU to adjust the presented feature set.

---

## Example Usage

* **Minimal Example:**

```
qemu-system-x86_64 -cpu qemu64 -m 2G -hda linux.img
```

*Expected Outcome:* A guest sees the generic `qemu64` CPU model with basic x86_64 features; suitable for broad compatibility.

* **Advanced Examples:**

```
qemu-system-x86_64 
-enable-kvm 
-cpu host,vmx=off,pcid=on 
-smp cores=4,threads=2 
-m 8G 
-drive file=win11.qcow2,format=qcow2
```

*Expected Outcome:*  
* Guest is presented with the host’s CPU capabilities via KVM, with virtualization extensions `vmx` disabled and PCID enabled.  
* CPU topology configured with 4 cores and 2 threads each.  
* Ideal for scenarios with fine‑grained feature control or performance tuning.

---

## Notes and Caveats

* **Host Pass‑Through Risk:** Using `host` may reduce live‑migration portability since guest CPU features closely mirror host hardware.
* **Feature Limitations:** Certain CPU features are only effective under specific accelerators (e.g., some ARM features require KVM enabled).
* **Version Variation:** The set of available named CPU models evolves with QEMU releases; always consult `-cpu help` for the specific QEMU binary in use.

---
