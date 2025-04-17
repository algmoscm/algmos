%ifndef STDDEF_ASM
%define STDDEF_ASM

;-----------Data Type Standard------------;
%define USE_DT_STANDARD
%ifdef USE_DT_STANDARD
    %macro gbyte 1 ; 参数1：变量名, 参数2：初始值(1字节)
        %1: db %2
        %endmacro

    %macro g2byte 1 ; 参数1：变量名, 参数2：初始值(4字节)
        %1: dw %2
        %endmacro

    %macro g4byte 1 ; 参数1：变量名, 参数2：初始值(4字节)
        %1: dd %2
        %endmacro

    %macro g8byte 1 ; 参数1：变量名, 参数2：初始值(8字节)
        %1: dq %2
        %endmacro


    ; %macro lvar 1
    ;     %define %1 qword [rbp - 112-(__local_offset + 8)]

    ;     %assign __local_offset  __local_offset + 8

    ;     sub rsp, 8
    ;     %endmacro

    ; 初始化局部变量追踪
    %macro LOCAL_BEGIN 0
        %push local_ctx              ; 创建新的局部上下文
        %assign %$local_offset 0     ; 初始化局部偏移计数器
    %endmacro

    ; 定义局部变量
    ; %1 - 变量名
    ; %2 - 变量大小(字节)
    %macro lvar 1
        %assign %$local_offset %$local_offset+8   ; 累加偏移
        %define %$var_%1 %$local_offset               ; 定义变量偏移
        %define %1 qword [rbp - %$var_%1]
        sub rsp,8
    %endmacro

    %macro lstr 1
        %assign %$local_offset %$local_offset+8   ; 累加偏移
        %define %$str_%1 %$local_offset               ; 定义变量偏移
        %define %1  rbp - %$str_%1
        %define %1.size 5
        sub rsp,%1.size
    %endmacro

    %macro lstruct 1
        %assign %$local_offset %$local_offset+8   ; 累加偏移
        %define %$str_%1 %$local_offset               ; 定义变量偏移
        %define %1  rbp - %$str_%1
        %define %1.size 5
        sub rsp,%1.size
    %endmacro

    ; 分配栈空间并保存寄存器
    %macro lalloc 0
        %if %$local_offset > 0
            ; 16字节对齐
            %assign pad (16 - (%$local_offset % 16))
            %if pad < 16
                %assign %$local_offset %$local_offset + pad
            %endif
            sub rsp, %$local_offset
        %endif
    %endmacro


    ; ; 获取局部变量的访问表达式
    ; %macro locvar 1-*
    ;     ; [rbp - %$var_%1 ]

    ;     %ifctx local_ctx
    ;         ; %ifidn %2, ""
    ;             qword [rbp - %$var_%1]
    ;         ; %else
    ;         ;     [rbp - %$var_%1 - %2]
    ;         ; %endif
    ;     %endif
    ; %endmacro

    ;     %macro locvar 1-2
    ;     ; [rbp - %$var_%1 ]

    ;     %ifctx local_ctx
    ;         %ifidn %2, ""
    ;             [rbp - %$var_%1]
    ;         %else
    ;             [rbp - %$var_%1 - %2]
    ;         %endif
    ;     %endif
    ; %endmacro


%endif

;-----------Calling Conventions Standard------------;
%define USE_CC_STANDARD
%ifdef USE_CC_STANDARD

    ;caller maintain the stack balance 
        ; debug_times: db 0
        ; cmp byte [rel debug_times],3
        ; je debug_stop
        ; add byte [rel debug_times],1
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
    %macro function 1-* ; 1=函数名, 2=返回参数数量, 3=参数列表
        %assign param_count %0 - 2 ; 参数数量
        
        %if param_count < 0
            %assign param_count 0 ; 如果没有参数，设置为 0
        %endif
        %if param_count < 1
            %assign ret_param_count 0 ; 返回参数数量
        %else
            %assign ret_param_count %2 ; 返回参数数量
        %endif

        ; 准备调用
        prepare_call param_count, ret_param_count

        ; 如果有参数，将参数压入栈
        %if param_count > 0
            %assign i 0
            mov [rsp-8], rax ; 保存返回地址
            %rep param_count
                %rotate 1
                mov rax, %2
                mov [rsp + 8*i], rax ; 将参数压入栈
                %assign i i+1
            %endrep
            %rotate 1
            %rotate 1
            mov rax,[rsp-8]; 保存返回地址
        %endif

        ; 调用函数
        call %1

        ; 清理栈空间
        cleanup_call param_count, ret_param_count

    %endmacro

    %macro align_stack_16 0
        test rsp, 0xF
        jz %%skip_align
        sub rsp,8
        %%skip_align:
    %endmacro

    %macro prologue 0;local var size(bytes)
        push rbp
        mov rbp, rsp


        pushallq
        LOCAL_BEGIN
        

        ; 调试信息可以放在这里
        ; %ifdef DEBUG
        ;     mov [rbp-8], rdi    ; 保存第一个参数用于调试
        ; %endif
    %endmacro
    %macro epilogue 0
        %pop
        mov rax, rbp
        sub rax, 8*14
        mov rsp, rax

        popallq

        mov rsp, rbp
        pop rbp
        ret
    %endmacro

    %macro prolog 1;local var size(bytes)
        push rbp
        mov rbp, rsp


        mov [rbp-8],rax
        mov rax, %1
        add rax, 15
        and rax, ~15
        sub rsp, rax
        mov rax,[rbp-8]

        pushallq
        
        ; 调试信息可以放在这里
        ; %ifdef DEBUG
        ;     mov [rbp-8], rdi    ; 保存第一个参数用于调试
        ; %endif
    %endmacro

    %macro epilog 0
        popallq

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

    %macro pushallq 0
        push rax
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
    %endmacro

    %macro popallq 0
        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
    %endmacro

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