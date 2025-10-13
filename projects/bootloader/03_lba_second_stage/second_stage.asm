org 0x10000
bits 16

; `second_stage.bin` memory layout.
; First_sector: 0x0000 - 0x01FF (512 bytes)
; Zeroes pad  : 0x0200 - 0xFDFF (63 kilobytes)
; Last sector : 0xFE00 - 0xFFFF (512 bytes)

; Segments and stack setup.
xor ax, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00
mov ax, 0x1000
mov ds, ax

first_sector_print:
    call print_line
    lea si, [first_sector_message]
    call print_string

    jmp last_sector_print

times (512 * 127) - ($ - $$) db 0

last_sector_print:
    call print_line
    lea si, [last_sector_message]
    call print_string

    jmp done

done:
    cli
    hlt

;; VARIABLES
first_sector_message  db "Hello from first sector.", 0
last_sector_message   db "Hello from last sector.", 0

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

times (512 * 128) - ($ - $$) db 0
