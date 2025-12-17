# `-m`

* **Purpose:**  
  Specifies the **guest’s initial RAM allocation** (size of the memory presented to the virtual machine) and optionally configures memory hotplug parameters. This option directly influences the amount of physical memory the guest OS perceives at startup.

* **Scope:**  
  Applies to the **QEMU system emulator** (`qemu-system-<arch>`). It affects **guest physical memory** configuration regardless of whether the guest is run using pure emulation (TCG) or with a hardware accelerator like KVM.

---

## Syntax and Parameters

```
qemu-system-<arch> -m [size=]<megs>[,slots=<n>,maxmem=<size>]
```

### Parameters

* **Name:** `size`  
  * **Type:** Quantity with unit suffix (numeric memory size)  
  * **Default value:** Host‑dependent default (historically 128 MiB if unspecified; may vary by QEMU version).
  * **Valid values / constraints:** Must specify a **positive memory amount**; suffixes like `M`, `G` are valid (e.g., `512M`, `4G`). Memory size must be within the host’s available physical memory limits.
  * **Behavior if omitted:** QEMU will apply a built‑in **default memory size** for the VM; explicit allocation is recommended for determinism.

* **Name:** `slots`  
  * **Type:** Integer  
  * **Default value:** Not set (hotplug disabled if absent)  
  * **Valid values / constraints:** Positive integer representing available memory hotplug slots. Must accompany `maxmem` for memory hotplug features.
  * **Behavior if omitted:** Memory hotplug is disabled; guest memory remains fixed at initial size.

* **Name:** `maxmem`  
  * **Type:** Quantity with unit suffix  
  * **Default value:** Not set (no dynamic growth permitted)  
  * **Valid values / constraints:** Must be **aligned to page size**; must be equal or greater than initial `size`.
  * **Behavior if omitted:** Guest memory remains fixed at the initial allocation; no dynamic expansion.

---

## Runtime Behavior Impact

### On Host

* **Host Memory Usage:**  
  The `‑m` option triggers allocation of host RAM to back guest physical memory. QEMU reserves this memory either immediately at startup or via configured memory backends. Excessively large `‑m` values can impact host performance or cause out‑of‑memory conditions if the host cannot satisfy allocation requests.

* **Allocation Semantics:**  
  Memory may be backed by anonymous host memory or configured backends (`memory‑backend‑ram`, `memfd`, etc.) when combined with relevant `‑object` options.

### On Guest

* **Visible Memory:**  
  Guest OS sees the amount of RAM specified by `‑m` as its **initial physical memory**, and it uses this for kernel allocations, application memory, page caches, etc. Guest behavior, such as swap usage and application performance, is directly tied to this allocation.

* **Dynamic Memory (Hotplug):**  
  When `slots` and `maxmem` are specified, the guest can **hotplug additional memory** up to `maxmem` at runtime (if the guest OS supports memory hotplug).

### Emulation vs Passthrough

* **Emulation (TCG):**  
  `‑m` drives software memory allocation within QEMU’s emulated environment; no hardware acceleration is implied solely by `‑m`.  
* **Hardware‑Assisted (KVM):**  
  Under KVM acceleration, `‑m` informs the KVM hypervisor of the memory footprint; actual memory management involves KVM APIs to map guest memory into host physical memory.

### Dependencies

* **Host Resources:**  
  Must ensure sufficient **host RAM** is available; oversubscription can degrade performance or lead to allocation failures.  
* **Memory Backends:**  
  Use of advanced backends (e.g., `‑object memory‑backend‑ram`) may improve control over memory allocation, NUMA behavior, and preallocation, but requires additional options.

---

## Example Usage

* **Minimal Example:**

```
qemu-system-x86_64 -m 2G -hda ubuntu.img
```

*Expected Outcome:*  
Guest is configured with **2 GiB of RAM**. The host allocates memory accordingly; the guest OS sees 2 GiB of usable physical memory.

* **Advanced Example: Memory Hotplug**

```
qemu-system-x86_64 
-m 1G,slots=3,maxmem=4G 
-enable-kvm 
-cpu host 
-smp 4 
-drive file=server.qcow2,format=qcow2
```

*Expected Outcome:*  
Initial RAM is **1 GiB**. Memory hotplug is enabled with **3 additional slots**, permitting guest memory expansion up to **4 GiB** if the guest OS initiates hotplug events.

---

## Notes and Caveats

* **Default Behavior Warning:**  
  If `‑m` is not explicitly specified, QEMU relies on a default value which may vary by build or frontend; always set `‑m` for predictable VM configurations.

* **Host Constraints:**  
  Setting `‑m` larger than host capacity can cause startup failures or host instability. Monitor host memory usage and consider cgroup limits if operating in resource‑constrained environments.

* **Memory Backends vs Legacy:**  
  Modern QEMU supports **memory backends** (`memory‑backend‑ram`, etc.) that offer more control than the legacy `‑m` option alone; consider these for advanced memory management.

* **NUMA Considerations:**  
  When working with NUMA or performance‑critical workloads on multi‑socket hosts, allocate memory with backends and NUMA node assignments for optimal performance.

---
