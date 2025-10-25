org 0x7E00
bits 16

; Test A20.
call test_a20
cmp al, 1
je done         ; If enabled.
jb bios_enable  ; If disabled.
ja done         ; If an error occurred.

bios_enable:
    lea si, [bios_attempt_msg]
    call print_string

    mov ah, 0x24
    mov al, 0x01
    int 0x15
    jc bios_fail

    call test_a20
    cmp al, 1
    je done
    jmp fast_a20_enable

fast_a20_enable:
    lea si, [fast_a20_attempt_msg]
    call print_string

    in al, 0x92
    or al, 0x02
    out 0x92, al

    call test_a20
    jmp done

done:
    cli
    hlt

;; VARIABLES
bios_attempt_msg        db "Attempting to enable the A20 line using BIOS.", 0
bios_fail_msg           db "BIOS failed to enable the a20 line.", 0
test_fail_msg           db "Failed to test the A20 line.", 0
a20_enabled_msg         db "A20 enabled.", 0
a20_disabled_msg        db "A20 disabled.", 0
fast_a20_attempt_msg    db "Attempting to enable the A20 line using fast A20 method.", 0

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

; ----------------------------------------------------------------------
; Test if A20 is enabled using BIOS subfunction 02h.
; Return value: Places the current A20 state in the AL register.
;   0: Disabled
;   1: Enabled
;   2: Error
; It also prints different messages depending on the current A20 state.
; ----------------------------------------------------------------------
test_a20:
    mov ah, 0x24
    mov al, 0x02
    int 0x15
    jc .test_fail

    cmp al, 1
    je .a20_enabled
    jmp .a20_disabled

.a20_enabled:
    lea si, [a20_enabled_msg]
    call print_string

    mov al, 1
    jmp .test_return

.a20_disabled:
    lea si, [a20_disabled_msg]
    call print_string

    mov al, 0
    jmp .test_return

.test_fail:
    lea si, [test_fail_msg]
    call print_string

    mov al, 2
    jmp .test_return

.test_return:
    ret

times 512 - ($ - $$) db 0
