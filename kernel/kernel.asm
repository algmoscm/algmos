%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]          ; 0xFFFF800000106200
ehdr:
    ABI_HEADER ABI_File_CORE, kernel_start, shdr,1
shdr:
    SECTION_HEADER Section_Type_LOAD, 0, kernel_start,section_end-section_start
section_start:
kernel_start:

    lea rax, [rel kernel_end]
    function system_init,1,rax


    function test_std,1,0
    mov rbx,[rsp-8]
    mov r8,[rsp]
    mov rax,0x9999

    .endofkernel:
        jmp $

test_std:;
    prolog 2
    get_param rdi, 1   ; x

    mov rcx,0x99
    mov rdx,0x88

    mov rax,0x11
    ; lalloc
    
    set_ret_param rax,2
    ; jmp $
    epilog

%include "../kernel/init.asm"


kernel_end:
times 32768 - (($ - $$) % 32768) db 0
init_pcb_ptr:;init process pcb

times 32768 - (($ - $$) % 32768) db 0
init_stack:;init stack
section_end: