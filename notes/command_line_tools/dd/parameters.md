# `dd` Parameters

## Key Topics

+ [Block Size (`bs`)](#block-size-bs)
+ [`count`](#count)
+ [`skip`](#skip)
+ [`seek`](#seek)
+ [Conversion (`conv`)](#conversion-conv)
+ [`status`](#status)
+ [Other Parameters](#other-parameters)
+ [Parameter Integration](#parameter-integration)

---

## Block Size (`bs`)

The `bs` parameter defines the block size; the amount of data read and written in a single operation. It serves as the fundamental unit for all transfer calculations and significantly impacts both performance and precision. When set, `bs` establishes identical block sizes for both input and output operations, optimizing throughput for large transfers while maintaining data integrity.

### Example

```bash
dd if=input.iso of=/dev/sdb bs=4M
```

This command processes data in 4-megabyte chunks, dramatically improving transfer speed compared to default smaller block sizes, making it ideal for creating bootable media from large ISO files.

---

## `count`

The `count` parameter specifies the exact number of blocks to copy from the input to the output. This enables precise control over the operation's scope, allowing developers to work with specific portions of a disk or file without processing the entire data source. It's particularly valuable for operations targeting defined disk regions like boot sectors or partition tables.

### Example

```bash
dd if=/dev/sda of=mbr_backup.img bs=512 count=1
```

This command copies exactly one 512-byte block, capturing only the Master Boot Record while ignoring the rest of the disk; essential for bootloader development and backup operations.

---

## `skip`

The `skip` parameter instructs `dd` to bypass a specified number of blocks at the beginning of the input file before starting the copy operation. This allows targeted access to specific data regions without processing preceding sections, making it crucial for extracting data from particular disk sectors or file offsets.

### Example

```bash
dd if=disk_image.img of=second_sector.bin bs=512 skip=1 count=1
```

This command skips the first 512-byte block and copies only the second sector, enabling precise examination of specific disk regions during filesystem development.

---

## `seek`

The `seek` parameter moves the output file pointer forward by the specified number of blocks before writing data. This preserves existing content on the target by creating a gap at the beginning, preventing overwrite of critical structures like partition tables or boot sectors when adding data to specific locations.

### Example

```bash
dd if=kernel.bin of=/dev/sdb1 bs=512 seek=1
```

This command writes the kernel image starting from the second sector of the partition, protecting the first sector which may contain boot information or other critical data.

---

## Conversion (`conv`)

The `conv` parameter applies one or more data transformations during the copy process, enabling sophisticated data manipulation and error handling. Multiple conversion options can be combined in a comma-separated list to achieve complex behavioral requirements.

### Available Values

- **ascii, ebcidc, ibm, block, unblock:** Character set and record format conversions
- **lcase, ucase:** Case conversion for text data
- **swab:** Swaps every pair of input bytes
- **noerror:** Continues processing after read errors (treats errors as zero-filled blocks)
- **sync:** Pads every input block to the input buffer size
- **excl:** Fails if the output file already exists
- **nocreat:** Does not create the output file
- **notrunc:** Does not truncate the output file, preserving existing content
- **fdatasync:** Physically writes output file data before completing
- **fsync:** Synchronizes both data and metadata before completion

### Example

```bash
dd if=/dev/cdrom of=disk_image.iso conv=noerror,sync
```

This combination continues reading despite media errors, padding bad sectors to maintain file structure integrity; essential for recovering data from damaged optical media during system restoration.

---

## `status`

The `status` parameter controls the verbosity of progress reporting during operation. It provides crucial feedback for long-running operations, allowing developers to monitor transfer progress, estimate completion times, and verify that operations are proceeding as expected.

### Available Values

- **none:** Suppresses all output except error messages
- **noxfer:** Suppresses final transfer statistics but shows periodic progress
- **progress:** Displays periodic transfer statistics including bytes copied, transfer rate, and time elapsed

### Example

```bash
dd if=/dev/sda of=backup.img bs=1M status=progress
```

This command provides real-time feedback showing the amount of data transferred, current transfer rate, and time elapsed; invaluable for monitoring large disk imaging operations that may take hours to complete.

---

## Other Parameters

These parameters will be explained in more detail when the need arises.

### Primary Data Transfer Parameters

- **ibs**: Input block size - specifies the read block size separately from the output block size
- **obs**: Output block size - specifies the write block size separately from the input block size  
- **cbs**: Convert block size - used for character-based conversions when using `conv` options like `ascii`, `ebcdic`, `block`, or `unblock`

### Specialized Control Parameters

- **iflag**: Input flags - modifies input behavior with options like `direct` (bypasses buffer cache), `fullblock` (accumulates full input blocks), and `sync` (pads input blocks)
- **oflag**: Output flags - modifies output behavior with options like `direct` (direct I/O), `dsync**` (synchronous data writes), and `sync**` (synchronous metadata and data writes)

## Examples

```bash
# Using separate input and output block sizes
dd if=source.img of=dest.img ibs=1K obs=4K

# Using direct I/O to bypass system cache
dd if=/dev/sda of=backup.img iflag=direct oflag=direct bs=1M

# Using character conversion with specific convert block size
dd if=textfile.txt of=converted.txt cbs=80 conv=ascii,ucase
```

These parameters provide finer-grained control when the unified `bs` parameter or default behaviors don't meet specific requirements, particularly in advanced storage operations or when working with legacy data formats.

---

## Parameter Integration

These parameters work synergistically to provide precise control over data operations. For instance, combining `bs`, `skip`, and `count` enables surgical extraction of specific disk regions, while `conv` options handle edge cases and error conditions. Understanding their individual functions and collective interactions is essential for effective low-level system development and maintenance.

---
