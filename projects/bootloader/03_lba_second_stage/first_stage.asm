org 0x7C00
bits 16

SECTOR_COUNT equ 64     ; Sectors read per loop iteration.
MEM_SEGMENT equ 0x1000  ; Memory destination segment.
MEM_OFFSET  equ 0x0000  ; Memory destination offset.

; Segments and stack setup.
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00

; Set video mode and clear the screen.
mov ax, 0x0003
int 0x10

; Load second stage.
lea si, [loading_msg]
call print_string

mov dl, 0x80        ; Drive.
lea si, [DAP]

mov cx, (128 / SECTOR_COUNT)
load_loop:
    mov ah, 0x42    ; BIOS Function: Read LBA.
    int 0x13        ; Call BIOS.
    jc disk_error

    ; Update DAP.
    add word [DAP_Segment], ((512 * SECTOR_COUNT) / 16)

    mov bx, [DAP_LBA]
    add bx, SECTOR_COUNT
    mov [DAP_LBA], bx

    loop load_loop

jmp MEM_SEGMENT:MEM_OFFSET

disk_error:
    lea si, [error_msg]
    call print_string

done:
    cli
    hlt

;; VARIABLES
loading_msg db "Loading second stage.", 0
error_msg   db "Read ERROR!!!", 0

DAP:
    db 0x10     ; Packet size.
    db 0        ; Reserved.
    dw SECTOR_COUNT
    dw MEM_OFFSET
DAP_Segment:
    dw MEM_SEGMENT
DAP_LBA:
    dd 1        ; Starting LBA.
    dd 0

;; FUNCTIONS
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

times 510 - ($ - $$) db 0
dw 0xAA55
