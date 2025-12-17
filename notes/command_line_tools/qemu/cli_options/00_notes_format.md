# `<option>` e.g `-enable-kvm`

* **Alias / Shorthand (if any):** `<alias>`

* **Purpose:** A formal description of the option’s function.
* **Scope:** Indicate whether it applies to the emulator, specific architectures, device models, or guest systems.

---

## Syntax and Parameters

Show the exact CLI syntax with placeholders.

Example:
```
qemu-system-<arch> -cpu <model>[,feature1[,feature2[,...]]]
```

### Parameters

For each parameter:

* **Name**
  Explain what the parameter means.
  * **Type** (string, integer, boolean, enumeration, etc.)
  * **Default value** (if applicable)
  * **Valid values / constraints**
  * **Behavior if omitted**

---

## Runtime Behavior Impact

### On Host
Describe CPU/memory/IO behavior on the host machine.

### On Guest
Describe changes to guest execution, hardware visibility, and performance.

### Emulation vs Passthrough
If applicable, clarify if the option enables hardware passthrough or pure emulation.

### Dependencies
List other options that must/must not be used simultaneously.

---

## Example Usage

* **Minimal Example:** CLI snippet showing basic usage.
* **Advanced Example(s):** Illustrate combined options or complex setups.
* **Expected Outcome:** Explicitly describe what happens during runtime.

---

## Notes and Caveats

* Any implementation quirks or subtle behaviors.
* Platform-specific differences.
* Known issues documented in QEMU or community resources.

---
