%ifndef INIT_ASM
%define INIT_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]

struc tss_table_info
    .reserved1:      resd 1
    .rsp0:           resq 1
    .rsp1:           resq 1
    .rsp2:           resq 1
    .reserved2:      resq 1
    .ist1:           resq 1
    .ist2:           resq 1
    .ist3:           resq 1
    .ist4:           resq 1
    .ist5:           resq 1
    .ist6:           resq 1
    .ist7:           resq 1
    .reserved3:      resd 1
    .reserved4:      resd 1
    .io_map_base:    resd 1
endstruc
struc tss_descriptor
    .limit_low:      resw 1    ; 段界限的低 16 位
    .base_low:       resw 1    ; 基地址的低 16 位

    .base_mid:       resb 1    ; 基地址的中间 8 位
    .type:           resb 1    ; 类型和属性（包括 P 位、DPL、TYPE）
    .limit_high:     resb 1    ; 段界限的高 4 位和标志（G、AVL 等）
    .base_high:      resb 1    ; 基地址的高 8 位

    .base_upper:     resd 1    ; 基地址的高 32 位（64 位地址支持）
    .reserved:       resd 1    ; 保留字段
endstruc

init_sys_vector:;init system interrupt vector
    prolog 0;
    ; jmp $
    function setup_default_tss
        ; jmp $
    function init_expection
    ; jmp $
    function init_interrupt
    ; jmp $


    epilog
setup_default_tss:;setup tss
    prolog 0;

    mov rbx, GDTPointerUpperAddr
    mov rbx, [rbx + 2]
    add rbx, 0x40

    mov rax, TSSPointerUpperAddr
    mov  dx,word [rax]
    mov rax, [rax + 2]
    ; jmp $
    mov word [rbx + tss_descriptor.limit_low], dx
    mov word [rbx + tss_descriptor.base_low], ax
    shr rax, 16

    mov byte [rbx + tss_descriptor.base_mid], al
    mov byte [rbx + tss_descriptor.type], 0x89
    mov byte [rbx + tss_descriptor.limit_high], 0x00
    shr rax, 8

    mov byte [rbx + tss_descriptor.base_high], al
    shr rax, 8

    mov dword [rbx + tss_descriptor.base_upper], eax
    mov dword [rbx + tss_descriptor.reserved], 0x00


    mov rax, TSSPointerUpperAddr
    mov rbx, [rax + 2]

    mov rax, 0xffff800000007c00
    ; mov qword [rbx + tss_table_info.reserved1], 0x00
    mov qword [rbx + tss_table_info.rsp0], rax
    mov qword [rbx + tss_table_info.rsp1], rax
    mov qword [rbx + tss_table_info.rsp2], rax
    ; mov qword [rbx + tss_table_info.reserved2], 0x00
    mov qword [rbx + tss_table_info.ist1], rax
    mov qword [rbx + tss_table_info.ist2], rax
    mov qword [rbx + tss_table_info.ist3], rax
    mov qword [rbx + tss_table_info.ist4], rax
    mov qword [rbx + tss_table_info.ist5], rax
    mov qword [rbx + tss_table_info.ist6], rax
    mov qword [rbx + tss_table_info.ist7], rax

    ; mov qword [rbx + tss_table_info.reserved3], 0x00
    ; mov qword [rbx + tss_table_info.reserved4], 0x00

    mov dword [rbx + tss_table_info.io_map_base], 104
    
    mov cx, 0x0040
    ltr cx
    
    epilog

%include "../kernel/expection.asm"
%include "../kernel/interrupt.asm"
%endif