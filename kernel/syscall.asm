%ifndef SYSCALL_ASM
%define SYSCALL_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]

struc syscall_table
    .sys_write:   resq 1
    .sys_exit:    resq 1
    .sys_getpid:  resq 1
    .reserved:    resq 253
endstruc

syscall_table_ptr:;syscall table ptr
    istruc syscall_table
    at syscall_table_t.sys_write,   dq sys_write
    at syscall_table_t.sys_exit,    dq sys_exit
    at syscall_table_t.sys_getpid,  dq sys_getpid
    at syscall_table_t.reserved,    times 253 dq 0
    iend

syscall_init:;syscall init
    prolog 0

    mov ecx, 0xC0000080         ; IA32_EFER MSR
    rdmsr
    or eax, 1                   ; 使能SYSCALL/SYSRET
    wrmsr

    mov ecx, 0xC0000081         ; IA32_STAR MSR
    mov eax, (KernelCodeSelector << 16) | UserCodeSelector
    mov edx, (KernelDataSelector << 16) | UserDataSelector
    wrmsr

    mov ecx, 0xC0000082         ; IA32_LSTAR MSR
    mov rax, syscall_entry
    shr rax, 0x0                ; 64位地址
    mov edx, rax >> 32
    mov eax, rax & 0xFFFFFFFF
    wrmsr

    mov ecx, 0xC0000084         ; IA32_FMASK MSR
    xor eax, eax
    xor edx, edx
    wrmsr


    epilog


syscall_entry: ; syscall entry point

         mov rbp, rsp
         mov r15, [rel tss_ptr]
         mov rsp, [r15 + 4]                       ;使用TSS的RSP0作为安全栈

         sti

        ;  mov r15, [rel position]
        ;  add r15, [r15 + rax * 8 + sys_entry]
        ;  call r15

         cli
         mov rsp, rbp                             ;还原到用户程序的栈
    
        sysretq


; creat_thread:;creat process syscall
;     ret
; 示例系统调用实现
sys_write:
    ; ...实现代码...
    ret

sys_exit:
    ; ...实现代码...
    ret

sys_getpid:
    ; ...实现代码...
    ret

%endif