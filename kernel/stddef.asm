
;-----------Calling Conventions Standard------------;
;---------------------------------------------------;
%define USE_CC_STANDARD 1
%ifdef USE_CC_STANDARD
    ;caller maintain the stack balance 

    ; 开始函数宏（设置栈帧）
    %macro FUNCTION_BEGIN 0
        push rbp
        mov rbp, rsp
    %endmacro

    ; 结束函数宏（恢复栈帧）
    %macro FUNCTION_END 0
        mov rsp, rbp
        pop rbp
        ret
    %endmacro

%endif


;---------------------ABI Standard------------------;
;---------------------------------------------------;
%define USE_ABI_STANDARD 1
%ifdef USE_ABI_STANDARD

    ; ELF 类型常量
    %define ET_NONE   0       ; 无文件类型
    %define ET_REL    1       ; 可重定位文件
    %define ET_EXEC   2       ; 可执行文件
    %define ET_DYN    3       ; 共享目标文件
    %define ET_CORE   4       ; 核心文件

    ; 机器类型常量
    %define EM_NONE   0       ; 无机器
    %define EM_386    3       ; Intel 80386
    %define EM_X86_64 62      ; AMD x86-64

    ; 程序头类型常量
    %define PT_NULL    0      ; 未使用
    %define PT_LOAD    1      ; 可加载段
    %define PT_DYNAMIC 2      ; 动态链接信息
    %define PT_INTERP  3      ; 解释器路径
    %define PT_NOTE    4      ; 辅助信息
    %define PT_SHLIB   5      ; 保留
    %define PT_PHDR    6      ; 程序头表自身
    %define PT_TLS     7      ; 线程局部存储

    ; 段标志常量
    %define PF_X 0x1          ; 可执行
    %define PF_W 0x2          ; 可写
    %define PF_R 0x4          ; 可读


    ; 定义 ELF 头宏
    ; 参数: 1=类别(1=32位,2=64位), 2=类型, 3=机器类型, 4=入口地址, 5=程序头偏移, 6=节头偏移
    %macro ELF_HEADER 6
        ; ELF 标识
        db 0x7F, 'E', 'L', 'F'     ; ELF 魔数
        db %1                      ; 类别 (1=32位, 2=64位)
        db 1                       ; 数据编码 (1=LSB)
        db 1                       ; ELF 版本
        db 0                       ; 操作系统ABI
        db 0                       ; ABI版本
        times 7 db 0               ; 填充字节
        
        %if %1 == 1
            ; 32位ELF头
            dw %2                  ; 类型
            dw %3                  ; 机器类型
            dd 1                   ; ELF版本
            dd %4                  ; 入口地址
            dd %5                  ; 程序头表偏移
            dd %6                  ; 节头表偏移
            dd 0                   ; 标志
            dw 52                  ; ELF头大小
            dw 32                  ; 程序头表项大小
            dw 1                   ; 程序头数量
            dw 40                  ; 节头表项大小
            dw 0                   ; 节头数量
            dw 0                   ; 节名字符串表索引
        %elif %1 == 2
            ; 64位ELF头
            dw %2                  ; 类型
            dw %3                  ; 机器类型
            dd 1                   ; ELF版本
            dq %4                  ; 入口地址
            dq %5                  ; 程序头表偏移
            dq %6                  ; 节头表偏移
            dd 0                   ; 标志
            dw 64                  ; ELF头大小
            dw 56                  ; 程序头表项大小
            dw 1                   ; 程序头数量
            dw 64                  ; 节头表项大小
            dw 0                   ; 节头数量
            dw 0                   ; 节名字符串表索引
        %endif
    %endmacro

    ; 定义程序头宏
    ; 参数: 1=类别(1=32位,2=64位), 2=类型, 3=标志, 4=文件偏移, 5=虚拟地址, 6=物理地址, 7=文件大小, 8=内存大小, 9=对齐
    %macro PROGRAM_HEADER 9
        %if %1 == 1
            ; 32位程序头
            dd %2                  ; 段类型
            dd %4                  ; 文件偏移
            dd %5                  ; 虚拟地址
            dd %6                  ; 物理地址
            dd %7                  ; 文件中的段大小
            dd %8                  ; 内存中的段大小
            dd %3                  ; 段标志
            dd %9                  ; 对齐
        %elif %1 == 2
            ; 64位程序头
            dd %2                  ; 段类型
            dd %3                  ; 段标志
            dq %4                  ; 文件偏移
            dq %5                  ; 虚拟地址
            dq %6                  ; 物理地址
            dq %7                  ; 文件中的段大小
            dq %8                  ; 内存中的段大小
            dq %9                  ; 对齐
        %endif
    %endmacro

    ; 定义节头宏
    ; 参数: 1=类别(1=32位,2=64位), 2=节名偏移, 3=节类型, 4=节标志, 5=虚拟地址, 6=文件偏移, 7=大小, 8=链接, 9=信息, 10=对齐, 11=条目大小
    %macro SECTION_HEADER 11
        %if %1 == 1
            ; 32位节头
            dd %2                  ; 节名偏移
            dd %3                  ; 节类型
            dd %4                  ; 节标志
            dd %5                  ; 虚拟地址
            dd %6                  ; 文件偏移
            dd %7                  ; 节大小
            dd %8                  ; 链接
            dd %9                  ; 信息
            dd %10                 ; 对齐
            dd %11                 ; 条目大小
        %elif %1 == 2
            ; 64位节头
            dd %2                  ; 节名偏移
            dd %3                  ; 节类型
            dq %4                  ; 节标志
            dq %5                  ; 虚拟地址
            dq %6                  ; 文件偏移
            dq %7                  ; 节大小
            dd %8                  ; 链接
            dd %9                  ; 信息
            dq %10                 ; 对齐
            dq %11                 ; 条目大小
        %endif
    %endmacro


    %macro ELF_SAMPLE
        ; 复杂 ELF 示例 (64位)
        bits 64
        org 0x400000

        ; ELF 文件头
        ehdr:
            ELF_HEADER 2, ET_EXEC, EM_X86_64, _start, phdr - $$, shdr - $$

        ; 程序头表
        phdr:
            ; 文本段
            PROGRAM_HEADER 2, PT_LOAD, PF_X|PF_R, 0, 0x400000, 0x400000, text_size, text_size, 0x200000
            
            ; 数据段
            PROGRAM_HEADER 2, PT_LOAD, PF_R|PF_W, text_size, 0x600000, 0x600000, data_size, data_size, 0x200000
            
            ; 程序头表自身
            PROGRAM_HEADER 2, PT_PHDR, PF_R, phdr - $$, phdr, phdr, phdr_size, phdr_size, 8

        phdr_size equ $ - phdr

        ; 文本段
        section .text
        global _start
        _start:
            mov rax, 1                ; sys_write
            mov rdi, 1                ; stdout
            lea rsi, [rel msg]        ; 使用相对地址
            mov rdx, msg_len
            syscall
            
            mov rax, 60               ; sys_exit
            xor rdi, rdi
            syscall

        text_size equ $ - _start

        ; 数据段
        section .data
        msg db "Hello, Complex ELF!", 0xA
        msg_len equ $ - msg

        data_size equ $ - msg

        ; 节头字符串表
        shstrtab:
            db 0                      ; 第一个字节为0
            .text db ".text", 0
            .data db ".data", 0
            .shstrtab db ".shstrtab", 0

        ; 节头表
        shdr:
            ; 空节头 (索引0)
            SECTION_HEADER 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            
            ; .text 节
            SECTION_HEADER 2, shstrtab.text - shstrtab, 1, 6, _start, _start - $$, text_size, 0, 0, 16, 0
            
            ; .data 节
            SECTION_HEADER 2, shstrtab.data - shstrtab, 1, 3, msg, msg - $$, data_size, 0, 0, 16, 0
            
            ; .shstrtab 节
            SECTION_HEADER 2, shstrtab.shstrtab - shstrtab, 3, 0, 0, shstrtab - $$, shstrtab_size, 0, 0, 1, 0

        shstrtab_size equ $ - shstrtab
    %endmacro

%endif