org 0x10000
bits 16

; Print the first message.
lea si, [first_msg]
call print_string
jmp second_print

; Fill the first 127 sectors with 0s.
times (512 * 127) - ($ - $$) db 0

; Print the second message.
second_print:
    lea si, [second_msg]
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
first_msg  db "Hello from first sector of second stage bootloader.", 0
second_msg db "Hello from last sector of second stage bootloader.", 0

times (512 * 128) - ($ - $$) db 0
