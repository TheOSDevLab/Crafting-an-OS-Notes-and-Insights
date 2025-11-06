org 0x7E00
bits 16

cli

; Load the GDT.
lgdt [gdt_descriptor]

; Set PE bit.
mov eax, cr0
or eax, 1
mov cr0, eax

jmp 0x08:protected_mode_entry

; GDT
gdt_start:
	; Null descriptor.
	dd 0
	dd 0

; Kernel code segment descriptor.
; Limit=0xFFFFF, Base=0.
; Access byte: present bit set, ring 0, code segment, read allowed.
; Flags: granularity is set, 32-bit segment.
kernel_code:
	dw 0xFFFF 		; Lower limit.
	dw 0 			; Base (0-15).
	db 0 			; Base (16-23).
	db 0b10011010 	; Access byte.
	db 0b11001111	; Flag + higher limit.
	db 0 			; Base (24-31).

; Kernel data segment descriptor.
; Limit=0xFFFFF, Base=0.
; Access byte: present bit set, ring 0, data segment, write allowed.
; Flags: granularity is set, 32-bit segment.
kernel_data:
	dw 0xFFFF 		; Lower limit.
	dw 0 			; Base (0-15).
	db 0 			; Base (16-23).
	db 0b10010010	; Access byte.
	db 0b11001111	; Flag + higher limit.
	db 0 			; Base (24-31).

gdt_end:

gdt_descriptor:
	dw (gdt_end - gdt_start - 1)
	dd gdt_start

; ========== Protected Mode Code ==========
bits 32
protected_mode_entry:
	; Setup segment registers.
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov gs, ax
	mov ss, ax

	; Clear the screen.
	mov edi, 0xB8000	; VGA text buffer.
	mov ecx, (80 * 25)	; Counter.
	mov eax, 0x0720		; 0x20 = ' ', 0x07 = light gray on black.
	rep stosw

	; Print a message.
	lea esi, [success_msg]
	mov edi, 0xB8000
	mov ah, 0x07 		; Attribute: light gray on black.

	.print_loop:
		lodsb
		cmp al, 0
		jz done

		mov [edi], al		; Write character.
		mov [edi + 1], ah	; Write attribute.
		add edi, 2 			; Advance pointer.

		jmp .print_loop

done:
	hlt
	jmp done

;; VARIABLES.
success_msg db "Switched to protected mode successfully.", 0

times 512 - ($ - $$) db 0