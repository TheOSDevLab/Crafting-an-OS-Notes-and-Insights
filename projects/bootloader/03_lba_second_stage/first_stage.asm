org 0x7C00
bits 16

; Constants.
SECTOR_COUNT equ 16         ; Number of sectors to read at a time.
SEGMENT_ADDRESS equ 0x1000  ; Destination memory segment.
OFFSET_ADDRESS  equ 0x0000  ; Destination memory offset.

; Segment and stack setup.
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00

; Set video mode and clear the screen.
mov ax, 0x0003  ; 80x25 color text mode.
int 0x10

; Print message.
lea si, [loading_msg]
call print_string

; Load the second stage (128KB).
mov ax, SEGMENT_ADDRESS
mov es, ax         ; Destination segment
lea si, [DAP]

.load_loop:
    mov word [DAP + 6], es              ; Segment.

    mov ah, 0x42
    mov dl, 0x80
    int 0x13
    jc disk_error

    ; Update segment position for next chunk.
    mov ax, es
    add ax, (512 * SECTOR_COUNT) / 16
    mov es, ax

    add dword [LBA], SECTOR_COUNT   ; Advance LBA.

    cmp dword [LBA], 128       ; Stop after 256 sectors (128KB)
    jl .load_loop

; jmp SEGMENT_ADDRESS:OFFSET_ADDRESS             ; Jump to loaded kernel
jmp 0x1000:0x0000

; Handle disk errors.
disk_error:
    lea si, [error]
    call print_string
    cli
    hlt

; -----------------------------------------------------
; Print the given string.
; Input: SI = Starting address of the string to print.
; -----------------------------------------------------
print_string:
    lodsb           ; Load byte from SI to AL.
    cmp al, 0
    jz .print_string_return

    call print_char
    jmp print_string

.print_string_return:
    ret

; --------------------------------
; Print the given character.
; Input: AL = Character to print.
; --------------------------------
print_char:
    mov ah, 0x0E    ; BIOS function: Teletype output.
    mov bh, 0
    int 0x10
    ret

; DATA.
loading_msg db "Loading second stage bootloader.", 0
error db "An error occurred."

DAP:
    db 0x10, 0
    dw SECTOR_COUNT     ; Sectors to read
    dw OFFSET_ADDRESS   ; Offset
    dw 0                ; Segment (updated in code)
LBA dd 1                ; Starting LBA
    dd 0

times 510 - ($ - $$) db 0
dw 0xAA55
