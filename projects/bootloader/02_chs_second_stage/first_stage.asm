org 0x7C00
bits 16

; Initialize segments and stack.
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00

; Set video mode and clear the screen.
mov ax, 0x0003  ; 80x25 text mode.
int 0x10

; Load second stage.
mov ah, 0x02    ; BIOS function: CHS read.
mov al, 1       ; Sector count.
mov ch, 0       ; Cylinder.
mov cl, 2       ; Sector.
mov dh, 0       ; Head.
mov dl, 0x80    ; First HDD.
mov bx, 0x7E00  ; Offset.
int 0x13        ; Call BIOS.

jc disk_error
jmp 0x0000:0x7E00

disk_error:
    ; Print error string.
    lea si, [error_msg]
    call print_string

    ; Print error code.
    mov al, ah
    xor ah, ah
    call print_num
    jmp halt

halt:
    cli
    hlt

; -----------------------------------------------------
; Print the given string.
; Input: SI = Starting address of the string to print.
; Preserves AX.
; -----------------------------------------------------
print_string:
    push ax

.print_string_loop:
    lodsb           ; Load byte from SI to AL.
    cmp al, 0
    jz .print_string_return

    call print_char
    jmp .print_string_loop

.print_string_return:
    pop ax
    ret

; -----------------------------
; Print the given number.
; Input: AX = Number to print.
; -----------------------------
print_num:
    mov bx, 10          ; Divisor.
    mov cx, 0           ; Counter.

.convert_loop:
    xor dx, dx
    div bx

    add dx, '0'       ; Convert remainder to string.
    push dx
    inc cx

    test ax, ax
    jz .print_loop
    jmp .convert_loop

.print_loop:
    pop ax
    call print_char
    loop .print_loop

.return:
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

error_msg db "ERROR!! Couldn't read disk: ", 0

times 510 - ($ - $$) db 0
dw 0xAA55
