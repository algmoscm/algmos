%ifndef EXPECTION_ASM
%define EXPECTION_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]
; GDTPointerUpperAddr equ 0xFFFF800000104000
; IDTPointerUpperAddr equ 0xFFFF80000010400a
; TSSPointerUpperAddr equ 0xFFFF800000104004
expection_default_message: db 'default expection:%x\n', 0
expection_div_message: db 'divide expection:%x\n', 0
expection_debug_message: db 'debug expection:%x\n', 0

expection_error_code: dq 0



; ; 描述符类型常量
%define INTGATE 0x8E    ; 64位中断门(P=1, DPL=00, 类型=1110)
%define TRAPGATE 0x8F   ; 64位陷阱门(P=1, DPL=00, 类型=1111)

; ; 64位IDT条目结构(16字节)
struc idt_info
    .offset_low:   resw 1  ; 0  偏移低16位(0..15)
    .selector:     resw 1  ; 16 代码段选择子

    .ist:          resb 1  ; 32 IST索引(0表示不使用)
    .type_attr:    resb 1  ; 40 类型属性

    .offset_mid:   resw 1  ; 48 偏移中16位(16..31)

    .offset_high:  resd 1  ; 64 偏移高32位(32..63)

    .reserved:     resd 1  ; 96 保留
    endstruc
init_expection:;init expection idt
    prolog 0;
    lea rsi,[rel default_exception_handler]
    function setup_default_expection_idt,1,rsi
    ; jmp $
    lea rsi,[rel div0_exception_handler]
    function register_expection_idt,1,0,1,rsi

    lea rsi,[rel debug_exception_handler]
    function register_expection_idt,1,1,1,rsi

    ; mov rax,0x123123
    ; jmp $

    epilog
register_expection_idt:;vector_num,rsp,handler
    prolog 0;
    get_param rsi, 1
    get_param r15, 2
    get_param rdi, 3
    mov rbx,IDTPointerUpperAddr
    mov rax,[rbx + 2]

    mov r8,rsi
    shl r8, 4
    add rax, r8

    ; jmp $

    mov r8,rdi
    shr r8,32

    mov r9,rdi
    shr r9,16
    and r9,0xFFFF

    mov rcx,0
    mov rcx, r15
    ; jmp $
    mov word [rax + idt_info.offset_low], di
        ; mov ax,di
    ; jmp $
    mov word [rax + idt_info.selector], 0x08
    mov byte [rax + idt_info.ist], cl
    mov byte [rax + idt_info.type_attr], TRAPGATE
    mov word [rax + idt_info.offset_mid], r9w
    mov qword [rax + idt_info.offset_high], r8

    lidt	[rbx]
    epilog

setup_default_expection_idt:;setup expection idt 0~31
    prolog 0;
    get_param rsi, 1
    mov r8,rsi
    shr r8,32
    mov r9,rsi
    shr r9,16
    and r9,0xFFFF

    mov rcx,0
    mov rbx,IDTPointerUpperAddr
    mov rax,[rbx + 2]

    .expection_idt:
        mov word [rax + idt_info.offset_low], si
        mov word [rax + idt_info.selector], 0x08

        mov byte [rax + idt_info.ist], 0x01
        mov byte [rax + idt_info.type_attr], TRAPGATE

        mov word [rax + idt_info.offset_mid], r9w

        mov qword [rax + idt_info.offset_high], r8

        add rax, 16
        inc rcx
        cmp rcx, 32
        jle .expection_idt

    lidt	[rbx]
    epilog


default_exception_handler:;
    ; mov rax,0xffff
    lea rsi, [rel expection_default_message]
    lea rdx, [rel expection_error_code]
    function printk,1,rsi,rdx

    jmp $
    iretq
div0_exception_handler:;
    ; mov rbx,0x1111
    ; jmp $
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15


    lea rsi, [rel expection_div_message]
    lea rdx, [rel expection_error_code]
    function printk,1,rsi,rdx


    jmp $
    ; hlt

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    iretq
debug_exception_handler:;
    ; mov rbx,0x2222
    ; jmp $
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15


    lea rsi, [rel expection_debug_message]
    lea rdx, [rel expection_error_code]
    function printk,1,rsi,rdx
    jmp $

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    iretq
    ; function draw_screen,0,0x00000000
    ;  jmp $
    ; lea rsi,[rel expection_div_messige]
    ; function draw_string,1,0,0,rsi
    ; jmp $
    ; iretq
; make_call_gate:                          	;创建64位的调用门
;                                           	;输入：RAX=例程的线性地址
;                                           	;输出：RDI:RSI=调用门
;          mov rdi, rax
;          shr rdi, 32                     	;得到门的高64位，在RDI中

;          push rax                        	;构造数据结构，并预置线性地址的位15~0
;          mov word [rsp + 2], CORE_CODE64_SEL	;预置段选择子部分
;          mov [rsp + 4], eax                  	;预置线性地址的位31~16
;          mov word [rsp + 4], 0x8c00         	;添加P=1，TYPE=64位调用门
;          pop rsi

;          ret

; ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; make_interrupt_gate:                      	;创建64位的中断门
;                                             	;输入：RAX=例程的线性地址
;                                             	;输出：RDI:RSI=中断门
;          mov rdi, rax
;          shr rdi, 32                       	;得到门的高64位，在RDI中

;          push rax                          	;构造数据结构，并预置线性地址的位15~0
;          mov word [rsp + 2], CORE_CODE64_SEL	;预置段选择子部分
;          mov [rsp + 4], eax                  	;预置线性地址的位31~16
;          mov word [rsp + 4], 0x8e00         	;添加P=1，TYPE=64位中断门
;          pop rsi

;          ret

; ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; make_trap_gate:                             	;创建64位的陷阱门
;                                              	;输入：RAX=例程的线性地址
;                                              	;输出：RDI:RSI=陷阱门
;          mov rdi, rax
;          shr rdi, 32                        	;得到门的高64位，在RDI中

;          push rax                           	;构造数据结构，并预置线性地址的位15~0
;          mov word [rsp + 2], CORE_CODE64_SEL	;预置段选择子部分
;          mov [rsp + 4], eax                  	;预置线性地址的位31~16
;          mov word [rsp + 4], 0x8f00         	;添加P=1，TYPE=64位陷阱门
;          pop rsi

;          ret

; ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; make_tss_descriptor:                    	;创建64位的TSS描述符
;                                           	;输入：RAX=TSS的线性地址
;                                           	;输出：RDI:RSI=TSS描述符
;          push rax

;          mov rdi, rax
;          shr rdi, 32                    	;得到门的高64位，在RDI中

;          push rax                       	;先将部分线性地址移到适当位置
;          shl qword [rsp], 16           	;将线性地址的位23~00移到正确位置
;          mov word [rsp], 104           	;段界限的标准长度
;          mov al, [rsp + 5]
;          mov [rsp + 7], al             	;将线性地址的位31~24移到正确位置
;          mov byte [rsp + 5], 0x89     	;P=1，DPL=00，TYPE=1001（64位TSS）
;          mov byte [rsp + 6], 0        	;G、0、0、AVL和limit
;          pop rsi                       	;门的低64位

;          pop rax

;          ret

; ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; mount_idt_entry:                     	;在中断描述符表IDT中安装门描述符
;                                        	;R8=中断向量
;                                        	;RDI:RSI=门描述符
;          push r8
;          push r9

;          shl r8, 4                         	;中断号乘以16，得到表内偏移
;          mov r9, UPPER_IDT_LINEAR        	;中断描述符表的高端线性地址
;          mov [r9 + r8], rsi
;          mov [r9 + r8 + 8], rdi

;          pop r9
;          pop r8

;          ret
%include "../kernel/printk.asm"
%endif