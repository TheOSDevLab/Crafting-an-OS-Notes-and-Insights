org 0x7C00
bits 16

start:
    mov ax, 0x0003 ; 80x25 text mode.
    int 0x10

    ; Stack set-up.
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00

say_hello:
    lea si, [string]
    xor ax, ax

.say_hello_loop:
    lodsb
    cmp al, 0
    jz halt

    call print_char
    jmp .say_hello_loop

; -------------------------------
; Print a single ASCII character.
; Input: AL = Character to print.
; -------------------------------
print_char:
    mov ah, 0x0E    ; BIOS Teletype Output.
    mov bh, 0
    int 0x10
    ret

halt:
    cli
    hlt

string db "Hello World!", 0

times 510 - ($ - $$) db 0
dw 0xAA55
