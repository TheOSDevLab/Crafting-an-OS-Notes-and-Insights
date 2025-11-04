# Protected Mode

This directory contains information on protected mode. Below are the files in this directory together with a summary of their contents.

## Introduction

[introduction.md](./introduction.md)

+ Contains an introduction to protected mode.
+ Covers what protected mode is, its characteristics, among other things.

---

## Memory Models

[memory_models.md](./memory_models.md)

+ Covers the 3 different memory models:
    - Segmented memory model
    - Flat memory model
    - Hybrid model

+ It explains what they are, their advantages and disadvantages, and their usage in modern operating systems.

---

## GDT

This is covered across 3 files.

[GDT.md](./GDT.md)

This file covers a lot about the GDT:

+ What it is.
+ Its roles.
+ Its relations with protected mode and long mode.
+ Common pitfalls.

Among other things.

[GDT_structure.md]

This file covers the structure of the GDT in detail.

[GDT_descriptor_structure.md]

This file covers the structure of the GDT descriptor in detail.

---

## Switching to Protected Mode

[process.md](./process.md)

+ This file contains the full process of switching to protected mode.
+ It includes an assembly snippet implementing the steps discussed.

---
