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

    mov rax,1
    mov rbx,2
    mov rcx,3
    mov rdx,4
    ; mov r10,5

    mov r11,6
    mov r12,7
    mov r13,8
    mov r14,9
    mov r15,10
    mov r8,4
    mov r9,2
    function test_std,1,rax
    mov r9,qword[rsp-8]
    mov r10,qword[rsp-16]


    .endofkernel:
        jmp $

test_std:;
    prologue
    get_param rdi, 1   ; x

    mov rcx,0x99
    mov rdx,0x88

    lvar defresult
    lalloc

    ; lstr str
    ; mov rax,str.size
    ; jmp $

    cmp rdi,1
    je .1return
    cmp rdi,0
    je .2return


    mov defresult,rdi
    dec rdi
    function test_std,1,rdi
    mov rax,qword[rsp-8]
    imul defresult
    jmp .done

    .1return:
        mov rax,1
        jmp .done
    .2return:
        mov rax,0
    .done:
    set_ret_param rax,2
    ; jmp $
    epilogue
%include "../kernel/init.asm"


kernel_end:
section_end: