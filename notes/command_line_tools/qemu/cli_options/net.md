# `-net`

> **Important:** The `‑net` option is considered **legacy** in modern QEMU and is being phased out in favor of `‑netdev` + `‑device` or `‑nic`.

* **Purpose:**  
  The `‑net` option defines **network interfaces and networking backends** for a QEMU VM, specifying both the guest’s Network Interface Card (NIC) model and, in some forms, the host networking backend. It bundles the configuration of virtual NIC hardware and connection to a host network stack.

* **Scope:**  
  Applies to the **QEMU system emulator** (`qemu‑system‑<arch>`) on all architectures that support networking. It influences the **guest’s virtual network interfaces** and how they connect to the host network, independent of accelerators like KVM. Although supported for now, it is a **legacy interface** and newer CLI forms (`‑netdev`/`‑device` and `‑nic`) are recommended for future‑proof configurations.

---

## Syntax and Parameters

```
qemu-system-<arch> -net <suboption>[,param1=value1][,param2=value2] ...
```

The `‑net` option must be supplied multiple times to define one NIC and one backend (if appropriate).

### Parameters

The exact parameters depend on the `suboption`:

#### `suboption`: `nic`

* **Name:** `nic`  
  * **Type:** Keyword to create a **Network Interface Card** device in the guest  
  * **Default value:** None (implicitly created if any net backend is defined; see notes)  
  * **Valid values / constraints:**  
    * Optional qualifiers:  
      * `vlan=<n>`; VLAN index (integer) this NIC attaches to  
      * `macaddr=<MAC>`; Explicit MAC address  
      * `model=<type>`; Guest NIC model such as `e1000`, `rtl8139`, `virtio`, etc.  
      * `addr=<PCI address>`; PCI address for the NIC  
      * `vectors=<v>`; MSI‑X vectors (affects virtio)  
  * **Behavior if omitted:** No NIC is explicitly defined for that invocation; if no networking is configured, QEMU may still emit defaults.

#### `suboption`: networking backends (e.g., `user`, `tap`, `bridge`, `socket`, `vde`, `l2tpv3`)

* **Name:** `<backend>`  
  * **Type:** Keyword to choose a **host networking backend**  
  * **Default value:** If no `‑net` options are specified at all, QEMU will create a **default single NIC attached to a user‑mode network backend** (`user`).
  * **Valid values / constraints:**  
    * `user`; User‑mode NAT network (no special privileges needed)  
    * `tap`; Linux TAP interface to connect VMs to a bridged/host network  
    * `bridge`; Bridge backend for direct host bridge attachment  
    * `socket`; Create socket‑linked networking  
    * `vde`; VDE virtual switch backend  
    * `l2tpv3`; L2TPv3 tunnel backend  
  * **Behavior if omitted:** No host backend configured for that NIC; combined with `nic` alone it may rely on defaults or yield no connectivity.

* **Common additional parameters** (vary by backend):  
  * `name=`; symbolic name for identifying the network device internally  
  * Backend‑specific configuration such as `script=…` for tap, etc., though detailed options vary and are not standardized across all backends.

---

## Runtime Behavior Impact

### On Host

* **Socket and Interface Binding:**  
  QEMU allocates host network resources based on the selected backend (user mode NAT, Linux TAP interface, bridge device, VDE switch, etc.).  
* **Host Privileges:**  
  Certain backends (e.g., `tap`, `bridge`) often require elevated privileges (CAP_NET_ADMIN) on the host for interface creation and bridging, whereas `user` mode does not.

### On Guest

* **NIC Model Exposure:**  
  The guest OS enumerates the emulated network card specified by the `nic` suboption and driver model. With a matching driver, the guest obtains an active network interface.  
* **Network Topology:**  
  Connectivity depends on backend:  
  * `user`: NAT‑based virtual network with DHCP and outbound connectivity.  
  * `tap`/`bridge`: Direct participation on host network.  
  * `socket`/`vde`: Custom isolated topologies.  
* **DHCP and IP:**  
  Commonly with `user`, QEMU provides a small NAT network with DHCP by default.

### Emulation vs Passthrough

* **Emulated NIC Hardware:**  
  `‑net nic` creates an emulated network adapter within the guest.  
* **Backend Connection:**  
  The host network connection is emulated via backend modules; none of the `‑net` options directly equate to PCI passthrough of a physical NIC.

### Dependencies

* **Backend Modules:**  
  Availability of backends (e.g., `vde`) depends on QEMU being built with that support.  
* **Host Setup:**  
  For bridge/tap, host network infrastructure must be preconfigured.

---

## Example Usage

* **Minimal Example (User NAT):**

```
qemu-system-x86_64 
-net nic,model=rtl8139 
-net user
```

*Expected Outcome:*  
Guest sees a virtual NIC of type `rtl8139` connected to a user‑mode NAT network. The VM will receive an IP via DHCP and can reach the outside network via host NAT.

* **Host Bridged Example:**

```
qemu-system-x86_64 
-net nic,model=e1000 
-net tap,script=/path/to/qemu-ifup,downscript=/path/to/qemu-ifdown
```

*Expected Outcome:*  
Guest NIC `e1000` attaches to a host TAP interface bridged to a real LAN. Requires host scripts to set up TAP and bridge.

---

## Notes and Caveats

* **Legacy Status:**  
  The `‑net` option is documented as legacy and developers are encouraged to use newer networking primitives (`‑netdev`, `‑device`, or the combined `‑nic`) instead.

* **Defaults:**  
  If no networking options are given at all, QEMU automatically uses `‑net nic -net user` (a single NAT‑backed interface).

* **Deprecated Suboptions:**  
  Some variants such as `‑net dump` and other legacy features were removed in prior releases of QEMU and replaced by modern mechanisms (e.g., `‑object filter-dump`).

* **Behavior Variation:**  
  Backend behavior and available NIC models can differ by host build and target architecture. Always consult `‑net nic,model=help` on your QEMU binary for a current list of supported models.

---
