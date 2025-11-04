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
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov gs, ax
	mov ss, ax

	jmp done

done:
	hlt
	jmp done


times 512 - ($ - $$) db 0