%ifndef STDDEF_ASM
%define STDDEF_ASM

;-----------Calling Conventions Standard------------;
%define USE_CC_STANDARD
%ifdef USE_CC_STANDARD
;caller maintain the stack balance 


; -------------------------------
; 栈帧结构定义
; -------------------------------
; 调用后的栈布局:
; [rsp+0x00] 返回地址 (8字节)
; [rsp+0x08] 旧RBP     (8字节) <- rbp指向这里
; [rsp+0x10] 参数1     (8字节)
; [rsp+0x18] 参数2
; ...
; [rsp+X]    局部变量区
; -------------------------------

%define PARAM_OFFSET   16      ; 第一个参数的偏移量(返回地址8 + 旧RBP8)
%macro prolog 1;local var size(bytes)
    push rbp
    mov rbp, rsp

    mov rax, %1
    add rax, 15
    and rax, ~15
    sub rsp, rax

    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax
    
    ; 调试信息可以放在这里
    ; %ifdef DEBUG
    ;     mov [rbp-8], rdi    ; 保存第一个参数用于调试
    ; %endif
%endmacro

%macro epilog 0
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15

    mov rsp, rbp
    pop rbp
    ret
%endmacro

%macro get_param 2;1=register, 2=param index(from 1)
    mov %1, [rbp + PARAM_OFFSET + 8*(%2-1)]
%endmacro

%macro set_ret_param 2;1=register, 2=param index(from 1)
    mov [rbp + PARAM_OFFSET + 8*(%2-1)], %1
%endmacro

%macro prepare_call 2;1=param count, 2=return param count
    %assign total_space ((%1 + %2) * 8)
    
    %if (total_space % 16) != 0
        %assign total_space total_space + 8  ; 添加填充
    %endif
    
    sub rsp, total_space
%endmacro

%macro cleanup_call 2;1=param count, 2=return param count
    %assign total_space ((%1 + %2) * 8)
    %if (total_space % 16) != 0
        %assign total_space total_space + 8
    %endif
    add rsp, total_space
%endmacro


; %macro function 1-*;1=function entry offset
;     prepare_call %0-2,1

;     %assign i %0
;     %rep i-1
;         %rotate -1
;         push %1
;     %endrep
;     call %1

;     cleanup_call %0-2,1
;     ; mov rax,[rsp-8]
; %endmacro

%endif
;---------------------ABI Standard------------------;
%define USE_ABI_STANDARD
%ifdef USE_ABI_STANDARD


    %define ABI_File_None   0       ; 无文件类型
    %define ABI_File_REL    1       ; 可重定位文件
    %define ABI_File_EXEC   2       ; 可执行文件
    %define ABI_File_DYN    3       ; 共享目标文件
    %define ABI_File_CORE   4       ; 核心文件

    %define Section_Type_NULL    0      ; 未使用
    %define Section_Type_LOAD    1      ; 可加载段
    %define Section_Type_DYNAMIC 2      ; 动态链接信息
    %define Section_Type_INTERP  3      ; 解释器路径
    %define Section_Type_NOTE    4      ; 辅助信息
    %define Section_Type_SHLIB   5      ; 保留

    %macro ABI_HEADER 4 ;1=File Type, 2=Entry Point Address, 3=Section Header Offset, 4=Section Header Count
        db 0xA5, 'A', 'B', 'I'     ; ABI Magic Number
        db 1                       ; Encode Type
        db 1                       ; ABI Version

        dw %1                      ; ABI File Type
        dq %2                      ; Entry Point Address
        dw 32                      ; ABI Headers Size

        dq %3                      ; Section Header Offset
        dw 32                      ; Section Header Size
        dw %4                      ; Section Header Count
        dw 0                       ; Symble Table Entry Size
    %endmacro
    STRUC struct_ABI_HEADER
        .magic:         resb 4    ; ABI Magic Number (4 bytes)
        .encode_type:   resb 1    ; Encode Type (1 byte)
        .abi_version:   resb 1    ; ABI Version (1 byte)
        .file_type:     resw 1    ; ABI File Type (2 bytes)
        .entry_point:   resq 1    ; Entry Point Address (8 bytes)
        .header_size:   resw 1    ; ABI Headers Size (2 bytes)
        .section_offset: resq 1   ; Section Header Offset (8 bytes)
        .section_size:  resw 1    ; Section Header Size (2 bytes)
        .section_count: resw 1    ; Section Header Count (2 bytes)
        .sym_table_size: resw 1   ; Symbol Table Entry Size (2 bytes)
    ENDSTRUC

    %macro SECTION_HEADER 4 ;1=Section Type, 2=Virtual Address, 3=Section Offset, 4=Section Size
        dq %1                  ; Section Type
        dq %2                  ; Virtual Address
        dq %3                  ; Section Offset
        dq %4                  ; Section Size
    %endmacro
    STRUC struct_SECTION_HEADER
        .type:      resq 1    ; Section Type (8 bytes)
        .vaddr:     resq 1    ; Virtual Address (8 bytes)
        .offset:    resq 1    ; Section Offset (8 bytes)
        .size:      resq 1    ; Section Size (8 bytes)
    ENDSTRUC
%endif

%endif