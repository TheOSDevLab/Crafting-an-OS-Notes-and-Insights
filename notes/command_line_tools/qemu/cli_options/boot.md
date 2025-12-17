# `-boot`

* **Purpose:**  
  The `‑boot` option in QEMU specifies the **boot order and behavior** that the firmware or BIOS in the virtual machine should use to select a boot device. It allows explicit control over which types of devices (disk, CD‑ROM, network, etc.) are considered during boot and in what order, and can also control one‑time boot attempts and boot UI behavior.

* **Scope:**  
  Applies to **system emulation** (`qemu‑system‑<arch>`). It influences how the virtual firmware/BIOS selects a bootable device. Behavior may vary by architecture and firmware implementation (e.g., PC BIOS vs UEFI).

---

## Syntax and Parameters

```
qemu-system-<arch> -boot [order=<drives>][,once=<drives>][,menu=on|off][,splash=<file>][,splash-time=<ms>][,reboot-timeout=<ms>][,strict=on|off]
```

### Parameters

* **Name:** `order`  
  * **Type:** String  
  * **Default value:** Firmware’s default boot priority when unspecified.  
  * **Valid values / constraints:** A string of **drive letters** that represent boot devices (e.g., `c` for hard disk, `d` for CD‑ROM, `n` for network). Valid letters depend on architecture (x86 uses `a, b, c, d, n‑p`).  
  * **Behavior if omitted:** Uses default built‑in firmware/BIOS boot order.

* **Name:** `once`  
  * **Type:** String  
  * **Default value:** None  
  * **Valid values / constraints:** Same as `order`; defines a **one‑time boot order** for the next boot only.  
  * **Behavior if omitted:** One‑time override is disabled.

* **Name:** `menu`  
  * **Type:** Enumeration (`on`/`off`)  
  * **Default value:** `off`  
  * **Valid values / constraints:** `on` enables an interactive boot menu (if the firmware supports it); `off` uses non‑interactive boot.  
  * **Behavior if omitted:** Non‑interactive.

* **Name:** `splash`  
  * **Type:** String (file path)  
  * **Default value:** None  
  * **Valid values / constraints:** Path to an image file shown during boot if `menu=on` and firmware supports splash graphics.  
  * **Behavior if omitted:** No splash image is displayed.

* **Name:** `splash-time`  
  * **Type:** Integer (milliseconds)  
  * **Default value:** Undefined (depends on firmware)  
  * **Valid values / constraints:** Positive integer; duration the splash is shown.  
  * **Behavior if omitted:** No timeout override.

* **Name:** `reboot-timeout`  
  * **Type:** Integer (milliseconds)  
  * **Default value:** Firmware default (often no reboot)  
  * **Valid values / constraints:** Positive integer or `‑1` to disable reboot.  
  * **Behavior if omitted:** Firmware default.

* **Name:** `strict`  
  * **Type:** Enumeration (`on`/`off`)  
  * **Default value:** `off`  
  * **Valid values / constraints:** `on` enforces strict boot priority where supported; `off` relaxes enforcement.  
  * **Behavior if omitted:** Non‑strict mode.

---

## Runtime Behavior Impact

### On Host

The `‑boot` option does not directly affect host resources such as CPU or memory. It informs the virtual firmware how to order devices in the boot sequence; actual device access and I/O happen when the guest firmware/OS performs operations on the selected device.

### On Guest

* Controls **which device the firmware/BIOS attempts to boot from** and in what sequence.  
* `order` determines persistent priority for devices.  
* `once` affects only the next boot attempt.  
* `menu=on` may expose a firmware boot selection UI.  
* Misconfiguration (e.g., no valid boot device in the specified list) can result in **“No bootable device found”** behavior at guest startup.

### Emulation vs Passthrough

`‑boot` is a **virtual firmware directive** and does not in itself enable passthrough or hardware acceleration. It influences virtual boot logic irrespective of whether QEMU uses software emulation or hardware acceleration like KVM.

### Dependencies

* For architectures that **do not support the `order` parameter**, `bootindex` properties on devices may be required instead (e.g., s390x). Mixing `‑boot order` with `bootindex` is discouraged as firmware may not support both simultaneously.

---

## Example Usage

* **Minimal Example:**
```
qemu-system-x86_64 -boot order=dc
```

*Expected Outcome:* BIOSS attempts to boot from CD‑ROM (`d`) before hard disk (`c`).

* **One‑time Boot Example:**
```
qemu-system-x86_64 -boot once=d -cdrom live.iso -hda disk.qcow2
```

*Expected Outcome:* On the next start, QEMU boot attempts from CD‑ROM once; thereafter, default boot order resumes.

* **Interactive Boot with Splash:**
```
qemu-system-x86_64 
-boot order=cd 
,menu=on 
,splash=/root/boot.bmp 
,splash-time=5000 
,strict=on 
-cdrom installer.iso
```

*Expected Outcome:* Virtual firmware displays a splash screen with menu on boot, attempts CD‑ROM first, and enforces strict ordering.

---

## Notes and Caveats

* **Legacy Syntax:** A legacy form `‑boot <drives>` is still supported but **discouraged** and may be removed in future versions.
* **Firmware Support:** Not all firmware (e.g., some UEFI implementations) honor all parameters; behavior can vary by architecture and machine type.  
* **Interaction with `bootindex`:** Do not mix `‑boot order`/`once` with `bootindex` on devices, as firmware generally supports one or the other.

---
