# Calculating Memory Sizes in Linear Addressing

## 1. Introduction

In computer systems, memory is frequently described in terms of address ranges. Each address corresponds to a discrete unit of storage, most commonly a byte. Determining the size of a memory segment therefore requires calculating how many individual addresses exist between a start address and an end address. This tutorial provides a structured method for calculating memory sizes in a **linear memory model**, where addresses increase monotonically without wrap-around.

---

## 2. Fundamental Principle

Given a start address $S$ and an end address $E$, the size of the range (in bytes) is expressed as:

$$
\text{Size} = (E - S) + 1
$$

The $+1$ is necessary because the range includes both endpoints. For example, if a range extends from address 5 to address 7, it covers addresses 5, 6, and 7, resulting in three addresses (7 - 5 + 1).

---

## 3. Example 1: Small Hexadecimal Range

**Range:** $S = 0x00$, $E = 0xFF$

1. Convert to decimal:

   * $0x00 = 0$
   * $0xFF = 255$

2. Compute size:

   $$
   (255 - 0) + 1 = 256
   $$

3. Result:
   The range contains **256 bytes** of memory, equivalent to 0.25 KiB (divide by 1024 bytes).

---

## 4. Example 2: Aligned Range

**Range:** $S = 0x1000$, $E = 0x1FFF$

1. Convert to decimal:

   * $0x1000 = 4096$
   * $0x1FFF = 8191$

2. Compute size:

   $$
   (8191 - 4096) + 1 = 4096
   $$

3. Result:
   The range contains **4096 bytes**, which equals **4 KiB**.

This example demonstrates a range that begins and ends on convenient hexadecimal boundaries, making the result a power of two.

---

## 5. Example 3: Larger Range

**Range:** $S = 0x200000$, $E = 0x2FFFFF$

1. Convert to decimal:

   * $0x200000 = 2,097,152$
   * $0x2FFFFF = 3,145,727$

2. Compute size:

   $$
   (3,145,727 - 2,097,152) + 1 = 1,048,576
   $$

3. Result:
   The range contains **1,048,576 bytes**, which equals **1 MiB**.

This example illustrates how straightforward the calculation remains, even for very large hexadecimal ranges.

---

## 6. Example 4: Non-Aligned Range

**Range:** $S = 0x1234$, $E = 0x2345$

1. Convert to decimal:

   * $0x1234 = 4660$
   * $0x2345 = 9029$

2. Compute size:

   $$
   (9029 - 4660) + 1 = 4370
   $$

3. Result:
   The range contains **4370 bytes**, which equals approximately **4.27 KiB**.

This demonstrates that ranges need not align to powers of two in order to be measured.

---

## 7. Converting Sizes

After calculating the size in bytes, it is often useful to express the result in larger units:

* 1 KiB = 1024 bytes
* 1 MiB = 1024 KiB
* 1 GiB = 1024 MiB

For example, a calculated size of 8192 bytes equals:

$$
\frac{8192}{1024} = 8 \, \text{KiB}
$$

---

## 8. Conclusion

In a **linear memory model**, calculating memory size between two hexadecimal addresses is a straightforward subtraction followed by the addition of one. This method applies consistently to all valid ranges, regardless of whether they align to power-of-two boundaries.

It is important to note, however, that not all architectures employ purely linear addressing. In certain environments, particularly those involving **segmented memory** or constrained address widths (such as 16-bit real mode), ranges may “wrap around” the maximum address value. Such cases require additional considerations that extend beyond the linear method described here.

---
