# `-drive`

* **Purpose:**  
  Defines and attaches a **storage drive** to the virtual machine by specifying both the **block backend** (image or device) and associated options in a single directive. This replaces older device shortcuts (e.g., `‑hda`) and offers fine‑grained control over drive behavior, interface, media type, caching, and snapshot semantics.

* **Scope:**  
  Applies to the **QEMU system emulator** (`qemu‑system‑<arch>`). It influences how guest block devices (hard disks, SSDs, CD‑ROMs, flash, etc.) are instantiated and backed by host resources. It operates independently of accelerators like KVM and interacts with virtual bus topologies (IDE, SCSI, VirtIO, etc.).

---

## Syntax and Parameters

```
qemu-system-<arch> -drive option[,option[,option[,...]]]
```

### Parameters

* **Name:** `file`  
  * **Type:** string (file path or device URL)  
  * **Default value:** none (must be provided unless referencing an existing block node)  
  * **Valid values / constraints:** Path to an image file (e.g., QCOW2, RAW) or protocol‑specific URL; if the filename contains commas they must be doubled.
  * **Behavior if omitted:** Without a backing file or node reference, the drive is undefined and will not function as a usable device.

* **Name:** `if`  
  * **Type:** enumeration  
  * **Default value:** depends on architecture/machine (often IDE on legacy PC, or none if manually defining)  
  * **Valid values:** ide, scsi, sd, mtd, floppy, pflash, virtio, none.
  * **Behavior if omitted:** QEMU attaches the drive using a default interface appropriate for the target machine.

* **Name:** `media`  
  * **Type:** enumeration  
  * **Default value:** disk  
  * **Valid values:** `disk` (block drive), `cdrom` (optical media).
  * **Behavior if omitted:** Treated as a regular disk unless overridden.

* **Name:** `index`  
  * **Type:** integer  
  * **Default value:** driver/controller dependent  
  * **Valid values / constraints:** Index within the list of connectors for the chosen interface type.
  * **Behavior if omitted:** QEMU automatically assigns an index.

* **Name:** `snapshot`  
  * **Type:** boolean (`on`/`off`)  
  * **Default value:** off  
  * **Valid values:** `on`, `off`  
  * **Behavior if omitted:** Normal persistent disk mode. With `on`, writes are cached and not propagated to the image file.

* **Name:** `cache`  
  * **Type:** enumeration  
  * **Default value:** implementation dependent  
  * **Valid values:** none, writeback, unsafe, directsync, writethrough.
  * **Behavior if omitted:** QEMU defaults to a sensible cache mode; explicit control affects performance and host cache semantics.

* **Name:** `format`  
  * **Type:** string  
  * **Default value:** auto (QEMU will attempt format detection)  
  * **Valid values:** raw, qcow2, vdi, vmdk, vhdx, etc. (depending on supported drivers).
  * **Behavior if omitted:** QEMU probes image contents to determine format.

* …and other block options supported by `‑blockdev` such as `aio`, `discard`, etc.

---

## Runtime Behavior Impact

### On Host

* **Resource Mapping:**  
  The `‑drive` parameter causes QEMU to open and manage the underlying **block backend** (file or device). This can trigger host file I/O, caching behavior, and OS level resource allocation.

* **I/O Semantics:**  
  Host block I/O behavior (sync vs asynchronous, cache mode) is shaped by parameters like `cache` and `aio`, which can influence latency, throughput, and consistency.

### On Guest

* **Device Visibility:**  
  Defines how the guest OS perceives and enumerates storage hardware (e.g., as a VirtIO block, SCSI disk, IDE HDD, or CD‑ROM), based on `if` and `media`.

* **Boot Behavior:**  
  Drives defined with `‑drive` become candidates for firmware/BIOS boot selection when combined with `‑boot`. The interface and bus topology influence bootability.

### Emulation vs Passthrough

* **Emulated Block Devices:**  
  `‑drive` constructs virtual device paths that guest drivers interact with; these are emulated via QEMU or KVM’s block layer.

* **Passthrough Considerations:**  
  While `‑drive` itself does not enable PCI Passthrough, it *can* refer to host block devices (e.g., `/dev/sdX`) which are then presented as guest storage; often subject to permissions and caching semantics.

### Dependencies

* **Machine/Bus Support:**  
  Valid `if` values and controller assignment depend on the machine type and supported device models.

* **Image Format Drivers:**  
  Formats specified must be supported by the QEMU build (e.g., qcow2 support).

---

## Example Usage

* **Minimal Example:** Hard Disk Image
```
qemu-system-x86_64 
-drive file=disk0.qcow2,format=qcow2,if=virtio
```

* **Expected Outcome:**  
  The guest sees a VirtIO block device backed by a QCOW2 image file.

* **Optical Media Example:**
```
qemu-system-x86_64 
-drive file=ubuntu.iso,media=cdrom,format=raw,if=ide
```

* **Expected Outcome:**  
  A virtual CD‑ROM drive backed by an ISO is visible to the guest; suitable for installation media.

* **Advanced Example: Cache and Snapshot**
```
qemu-system-x86_64 
-drive file=disk.img,format=raw,if=virtio,cache=writeback,snapshot=on
```

* **Expected Outcome:**  
  A VirtIO disk using writeback caching; writes are kept separate from the underlying image due to snapshot mode.

---

## Notes and Caveats

* **Legacy vs Modern:**  
  The `‑drive` interface combines backend and device specification for convenience, but the **blockdev + device** model offers clearer semantics and stability guarantees.

* **Legacy Shortcuts:**  
  Older options like `‑hda`, `‑hdb`, etc., expand into `‑drive` equivalents and are retained for backwards compatibility but are not recommended.

* **Order Sensitivity:**  
  When specifying multiple drives, order and indexes influence device enumeration and boot priorities; use `index` when precise placement is required.

* **Host Permissions:**  
  Using raw host devices via `file=/dev/sdX` requires appropriate host permissions and may pose data safety risks.

* **Performance Tradeoffs:**  
  Parameters like `cache` have significant performance and data consistency implications; defaults differ by host OS and QEMU build.

---
