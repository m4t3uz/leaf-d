; Copyright (C) 2021 Mateus de Lima Oliveira
[bits 32]
global WritePortByte
global ReadPortByte
global WritePortLong
global ReadPortLong
global FlushTLB
global ReadEIP
global CopyPagePhysical

WritePortByte:
	mov edx, [esp + 4] ; port
	mov eax, [esp + 8] ; value
	out dx, al
	ret

ReadPortByte:
	mov edx, [esp + 4] ; port
	in al, dx
	ret

WritePortLong:
	mov edx, [esp + 4] ; port
	mov eax, [esp + 8] ; value
	out dx, eax
	ret

ReadPortLong:
	mov edx, [esp + 4] ; port
	in eax, dx
	ret

FlushTLB:
	mov eax, cr3
	mov cr3, eax
	ret

ReadEIP:
	mov eax, [esp]
	ret

CopyPagePhysical:
    push ebx              ; According to __cdecl, we must preserve the contents of EBX.
    pushf                 ; push EFLAGS, so we can pop it and reenable interrupts
                          ; later, if they were enabled anyway.
    cli                   ; Disable interrupts, so we aren't interrupted.
                          ; Load these in BEFORE we disable paging!
    mov ebx, [esp+12]     ; Source address
    mov ecx, [esp+16]     ; Destination address

    mov edx, cr0          ; Get the control register...
    and edx, 0x7fffffff   ; and...
    mov cr0, edx          ; Disable paging.
  
    mov edx, 1024         ; 1024*4bytes = 4096 bytes

.loop:
    mov eax, [ebx]        ; Get the word at the source address
    mov [ecx], eax        ; Store it at the dest address
    add ebx, 4            ; Source address += sizeof(word)
    add ecx, 4            ; Dest address += sizeof(word)
    dec edx               ; One less word to do
    jnz .loop             
  
    mov edx, cr0          ; Get the control register again
    or  edx, 0x80000000   ; and...
    mov cr0, edx          ; Enable paging.
  
    popf                  ; Pop EFLAGS back.
    pop ebx               ; Get the original value of EBX back.
    ret
