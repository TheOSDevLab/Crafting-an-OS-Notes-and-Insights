# `-cdrom`

* **Purpose:**  
  The `‑cdrom` option instructs QEMU to attach a **CD‑ROM device to the virtual machine** and use the specified file (typically an ISO image) or host CD‑ROM device as the media presented to the guest. It is a convenience wrapper around lower‑level drive options for attaching optical media.

* **Scope:**  
  Applies to **system emulation** (`qemu‑system‑<arch>`). It configures a virtual **optical drive** device visible to the guest and is independent of accelerators like KVM.

---

## Syntax and Parameters

```
qemu-system-<arch> -cdrom <file>
```

### Parameters

* **Name:** `file`  
  * **Type:** String (file path or device path)  
  * **Default value:** *None*. This option requires an explicit file or device.  
  * **Valid values / constraints:**  
    * Path to a **CD/DVD ISO image** file, e.g., `ubuntu‑20.04.iso`.  
    * On some hosts, a **host optical drive device** path (e.g., `/dev/cdrom`) may be used.  
    * Cannot be used simultaneously with certain other legacy drive options that map to the same target (e.g., `‑hdc` on x86).
  * **Behavior if omitted:**  
    * The virtual machine will start **without an attached CD‑ROM device or media** using this option; the guest will not see any optical drive unless configured via `‑drive` or other device definitions.

---

## Runtime Behavior Impact

### On Host

* **File access:** QEMU opens the specified ISO file or host device and **maps it to the guest’s virtual CD‑ROM controller**.  
* **I/O:** Reads from the ISO or device are served by the host kernel; physical device access (if using `/dev/cdrom`) requires appropriate host permissions.

### On Guest

* **Device Enumeration:** The guest OS detects the **virtual CD‑ROM device** at boot or hotplug time, depending on machine type and bus.  
* **Bootability:** When combined with appropriate boot order settings (e.g., `‑boot d`), the guest can **boot from the ISO** provided via `‑cdrom`.

### Emulation vs Passthrough

* **Emulation:** The CD‑ROM device is emulated by QEMU and backed by either an ISO image file or physical host device.  
* **Passthrough:** Using a host device path effectively passes the host’s physical optical drive into the VM’s hardware abstraction, limited by QEMU’s access and permissions.

### Dependencies

* **Drive Positioning:** On architectures like x86, the default IDE bus places the CD‑ROM at **IDE1 master** when using `‑cdrom`; this may conflict with legacy options like `‑hdc`.
* **Boot Order:** To boot from the attached CD‑ROM, a corresponding **boot order flag** must be provided (`‑boot d`).

---

## Example Usage

* **Minimal Example:**
```
qemu-system-x86_64 -cdrom ubuntu-22.04-desktop-amd64.iso
```

* **Expected Outcome:**  
  The VM sees a virtual CD‑ROM device with the Ubuntu ISO loaded. With appropriate boot flags (e.g., `‑boot d`), the guest will boot from this ISO.

* **Advanced Example:** Booting with KVM acceleration and specifying the boot device:
```
qemu-system-x86_64 
-enable-kvm 
-cpu host 
-m 4G 
-cdrom fedora‑workstation‑live.iso 
-boot d 
-smp 4
```

* **Expected Outcome:**  
  * KVM acceleration enabled for performance.  
  * Guest perceives the Fedora live ISO as the bootable CD‑ROM.  
  * With `‑boot d`, QEMU attempts to boot from the CD‑ROM first.

---

## Notes and Caveats

* **Mutual Exclusivity with Legacy Drives:**  
  On certain machine configurations (e.g., x86 IDE), specifying `‑cdrom` alongside incompatible legacy drives (like `‑hdc`) can cause conflicts. Use either `‑cdrom` or a descriptive `‑drive` block specifying `media=cdrom`.

* **Modern Alternatives:**  
  The newer `‑drive file=…,media=cdrom` syntax is more flexible, particularly when attaching multiple CD‑ROMs or configuring interfaces explicitly.

* **Host Device Access:**  
  Using a host path (e.g., `/dev/cdrom`) depends on host device permissions and may require elevated privileges.

* **Hotplug Support:**  
  Some machine types and guest OSes support CD‑ROM media insertion/ejection events dynamically; this behavior is tied to the emulated controller rather than `‑cdrom` itself.

---
