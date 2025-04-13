%ifndef INTERRUPT_ASM
%define INTERRUPT_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]
; GDTPointerUpperAddr equ 0xFFFF800000104000
; IDTPointerUpperAddr equ 0xFFFF80000010400a
; TSSPointerUpperAddr equ 0xFFFF800000104004


; ; 描述符类型常量
%define INTGATE 0x8E    ; 64位中断门(P=1, DPL=00, 类型=1110)
%define TRAPGATE 0x8F   ; 64位陷阱门(P=1, DPL=00, 类型=1111)

; ; 64位IDT条目结构(16字节)
struc idt_info
    .offset_low:   resw 1  ; 偏移低16位(0..15)
    .selector:     resw 1  ; 代码段选择子

    .ist:          resb 1  ; IST索引(0表示不使用)
    .type_attr:    resb 1  ; 类型属性

    .offset_mid:   resw 1  ; 偏移中16位(16..31)

    .offset_high:  resd 1  ; 偏移高32位(32..63)

    .reserved:     resd 1  ; 保留
endstruc
init_interrupt:;init expection idt
    prolog 0;
    lea rsi,[rel default_interrupt_handler]
    function setup_default_interrupt_idt,0,rsi
    epilog
    
setup_default_interrupt_idt:;setup expection idt 0~31
    prolog 0;
    get_param rsi, 1
    mov r8,rsi
    shr r8,32
    mov r9,rsi
    shr r9,16
    and r9,0xFFFF

    mov rcx,32
    mov rbx,IDTPointerUpperAddr
    mov rax,[rbx + 2]
    
    mov rdx,32
    shl rdx, 4
    add rax, rdx

    .expection_idt:
        mov word [rax + idt_info.offset_low], si
        mov word [rax + idt_info.selector], 0x08

        mov byte [rax + idt_info.ist], 0x00
        mov byte [rax + idt_info.type_attr], INTGATE

        mov word [rax + idt_info.offset_mid], r9w

        mov qword [rax + idt_info.offset_high], r8

        add rax, 16
        inc rcx
        cmp rcx, 256
        jle .expection_idt

    lidt	[rbx]
    epilog


default_interrupt_handler:;
    mov rax,0xaaaaaaaaaaab
    jmp $
    iretq

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
%endif