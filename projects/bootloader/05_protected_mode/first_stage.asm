org 0x7C00
bits 16

; Constants
SECTOR_COUNT equ 1
LBA_INDEX    equ 1
MEM_SEGMENT  equ 0x0000
MEM_OFFSET   equ 0x7E00

; Segment and stack setup.
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00

; Set video mode and clear the screen.
mov ax, 0x0003  ; 80x25 color text mode.
int 0x10

; Load second stage
lea si, [loading_msg]
call print_string

mov ah, 0x42    ; BIOS Function: Read LBA.
mov dl, 0x80    ; First HDD.
lea si, [DAP]
int 0x13
jc read_error

lea si, [loaded_msg]
call print_string
jmp 0x0000:0x7E00

read_error:
    lea si, [error_msg]
    call print_string

done:
    cli
    hlt

;; VARIABLES
loading_msg db "Loading second stage.", 0
loaded_msg  db "Second stage loaded.", 0
error_msg   db "ERROR!!! Read failed.", 0

; Disk Address Packet Structure.
DAP:
    db 0x10, 0
    dw SECTOR_COUNT
    dw MEM_OFFSET
    dw MEM_SEGMENT
    dd LBA_INDEX
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
    call print_line
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

; --------------------------------------------------------
; Print a new line (i.e move the cursor to the next line).
; Input: NONE
; --------------------------------------------------------
print_line:
    mov ah, 0x0E
    mov al, 0x0D    ; Carriage return.
    int 0x10

    mov al, 0x0A    ; Line feed.
    int 0x10
    ret

times 510 - ($ - $$) db 0
dw 0xAA55
