%ifndef INTERRUPT_ASM
%define INTERRUPT_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]
; GDTPointerUpperAddr equ 0xFFFF800000104000
; IDTPointerUpperAddr equ 0xFFFF80000010400a
; TSSPointerUpperAddr equ 0xFFFF800000104004

interrupt_default_message: db 'default interrupt:%x\n', 0
interrupt_div_message: db 'divide interrupt:%x\n', 0
interrupt_keyboard_message: db 'keyboard interrupt:%x\n', 0

global_rtc_time_str: db "00:00:00", 0


interrupt_error_code: dq 0

; ; Descriptor Type
%define INTGATE 0x8E    ; 64位中断门(P=1, DPL=00, 类型=1110)
%define TRAPGATE 0x8F   ; 64位陷阱门(P=1, DPL=00, 类型=1111)


; 8259A PIC ports and commands
%define PIC1_CMD        0x20    ; Master PIC command port
%define PIC1_DATA       0x21    ; Master PIC data port
%define PIC2_CMD        0xA0    ; Slave PIC command port
%define PIC2_DATA       0xA1    ; Slave PIC data port

; PIC initialization commands
%define ICW1_INIT       0x11    ; Initialize PIC
%define ICW4_8086       0x01    ; 8086/88 mode

; Interrupt vector offset
%define MASTER_OFFSET   0x20    ; IRQ 0-7 mapped to interrupts 0x20-0x27
%define SLAVE_OFFSET    0x28    ; IRQ 8-15 mapped to interrupts 0x28-0x2F


%define KEYBOARD_PORT 0x60

%define RTC_ADDR      0x70    ; RTC 地址端口
%define RTC_DATA      0x71    ; RTC 数据端口


key_scan_code_map: db 0x00, 0x1B, '1', '2', '3', '4', '5', '6'  ; 0x00-0x07
        db '7', '8', '9', '0', '-', '=', 0x08, 0x09   ; 0x08-0x0F
        db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'    ; 0x10-0x17
        db 'o', 'p', '[', ']', 0x0A, 0x00, 'a', 's'   ; 0x18-0x1F
        db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'    ; 0x20-0x27
        db "'", '`', 0x00, '\', 'z', 'x', 'c', 'v'    ; 0x28-0x2F
        db 'b', 'n', 'm', ',', '.', '/', 0x00, '*'    ; 0x30-0x37
        db 0x00, ' ', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ; 0x38-0x3F
keymap_end:;end of key map

; Define structure for interrupt stack frame
struc int_frame
    .r15:       resq 1
    .r14:       resq 1
    .r13:       resq 1
    .r12:       resq 1
    .r11:       resq 1
    .r10:       resq 1
    .r9:        resq 1
    .r8:        resq 1
    .rdi:       resq 1
    .rsi:       resq 1
    .rbp:       resq 1
    .rbx:       resq 1
    .rdx:       resq 1
    .rcx:       resq 1
    .rax:       resq 1
    ; Hardware pushes these automatically
    .error:     resq 1  ; Error code (some interrupts only)
    .rip:       resq 1
    .cs:        resq 1
    .rflags:    resq 1
    .rsp:       resq 1
    .ss:        resq 1
endstruc

%macro SAVE_CONTEXT 0
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
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

%macro RESTORE_CONTEXT 0
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
    pop rbp
    pop rbx
    pop rdx
    pop rcx
    pop rax
%endmacro

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
    cli


    lea rsi,[rel default_interrupt_handler]
    function setup_default_interrupt_idt,1,rsi

    lea rsi,[rel irq1_keyboard_interrupt_handler]
    function register_interrupt_idt,1,0x21,1,rsi


    lea rsi,[rel irq8_rtc_interrupt_handler]
    function register_interrupt_idt,1,0x28,1,rsi

    function init_8259a
    function init_rtc_timer
    ;  function enable_irq,1,1
    ;  function enable_irq,1,1
    ;  function enable_irq,1,1
    ;  function enable_irq,1,1

    sti
        mov al, 0x0c
        out 0x70, al
        in al, 0x71                              ;读RTC寄存器C，复位未决的中断状态

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
        mov word [rax + idt_info.selector], KernelCodeSelector

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

register_interrupt_idt:;register interrupt_idt:;vector_num,rsp,handler
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
    mov word [rax + idt_info.selector], KernelCodeSelector
    mov byte [rax + idt_info.ist], cl
    mov byte [rax + idt_info.type_attr], INTGATE
    mov word [rax + idt_info.offset_mid], r9w
    mov qword [rax + idt_info.offset_high], r8

    lidt	[rbx]
    epilog

default_interrupt_handler:;

    SAVE_CONTEXT
         mov al, 0x20                             ;中断结束命令EOI
         out 0xa0, al                             ;向从片发送
         out 0x20, al                             ;向主片发送

    ; lea rsi, [rel interrupt_default_message]
    ; lea rdx, [rel interrupt_error_code]
    ; function printk,1,rsi,rdx

    RESTORE_CONTEXT
    iretq

irq1_keyboard_interrupt_handler:;0x21
    SAVE_CONTEXT
    
    mov rax, rsp        ; Pass stack frame pointer as parameter
    mov rdi, rax
    
    xor rax,rax
    in  al, KEYBOARD_PORT 
    cmp al,0x80
    jnbe .ignore_break_code
        xor rbx,rbx
        lea rdx , [rel key_scan_code_map ]
        add rdx, rax
        ; mov [rel interrupt_error_code],rbx
        ; jmp $
        mov al,byte [rdx]
        function print_char,1,rax
        ; lea rsi, [rel interrupt_keyboard_message]
        ; lea rdx, [rel interrupt_error_code]
        ; function printk,1,rsi,rdx
    .ignore_break_code:
    ; Send EOI to PIC
    mov al, 0x20        ; EOI command
    out PIC1_CMD, al    ; Send to master PIC
    
    RESTORE_CONTEXT
    iretq

init_8259a:;init 8259a
    prolog 0

    ; ; ICW1: Start initialization sequence
    ; mov al, ICW1_INIT
    ; out PIC1_CMD, al    ; Initialize master PIC
    ; out PIC2_CMD, al    ; Initialize slave PIC
    
    ; ; ICW2: Vector offset
    ; mov al, MASTER_OFFSET
    ; out PIC1_DATA, al   ; Master PIC vector offset
    ; mov al, SLAVE_OFFSET
    ; out PIC2_DATA, al   ; Slave PIC vector offset
    
    ; ; ICW3: Tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    ; mov al, 4
    ; out PIC1_DATA, al
    ; ; ICW3: Tell Slave PIC its cascade identity (0000 0010)
    ; mov al, 2
    ; out PIC2_DATA, al
    
    ; ; ICW4: Set 8086 mode
    ; mov al, ICW4_8086
    ; out PIC1_DATA, al
    ; out PIC2_DATA, al
    
    ; ; OCW1: Mask all interrupts initially
    ; ; mov al, 0x00
    ; mov al,0xfd
    ; out PIC1_DATA, al
    ; mov al,0xff
    ; out PIC2_DATA, al


    ; ; 发送 ICW1 (初始化命令字 1)
    ; mov al, 0x11         ; ICW1: 边沿触发, 级联, 需要 ICW4
    ; out PIC1_CMD, al
    ; out PIC2_CMD, al

    ; ; 发送 ICW2 (中断向量偏移)
    ; mov al, 0x20         ; 主 PIC 中断向量从 0x20 开始
    ; out PIC1_DATA, al
    ; mov al, 0x28         ; 从 PIC 中断向量从 0x28 开始
    ; out PIC2_DATA, al

    ; ; 发送 ICW3 (级联配置)
    ; mov al, 0x04         ; 主 PIC 的 IRQ2 连接从 PIC
    ; out PIC1_DATA, al
    ; mov al, 0x02         ; 从 PIC 级联到主 PIC 的 IRQ2
    ; out PIC2_DATA, al

    ; ; 发送 ICW4 (8086 模式)
    ; mov al, 0x01         ; 8086 模式
    ; out PIC1_DATA, al
    ; out PIC2_DATA, al

    ; ; 启用 IRQ8 (RTC 中断)
    ; in al, PIC2_DATA     ; 读取从 PIC 的 IMR
    ; jmp $
    ; and al, 0xFE         ; 清除 IRQ8 的屏蔽位 (bit 0)
    ; out PIC2_DATA, al

    ; mov al,0xfd
    ; out PIC1_DATA, al
    ; mov al,0xfe
    ; out PIC2_DATA, al

         mov al, 0x11
         out 0x20, al                    	;ICW1：边沿触发/级联方式
         mov al, 0x20
         out 0x21, al  	                ;ICW2:起始中断向量（避开前31个异常的向量）
         mov al, 0x04
         out 0x21, al  	                ;ICW3:从片级联到IR2
         mov al, 0x01
         out 0x21, al                  	;ICW4:非总线缓冲，全嵌套，正常EOI

         mov al, 0x11
         out 0xa0, al                  	;ICW1：边沿触发/级联方式
         mov al, 0x28
         out 0xa1, al                  	;ICW2:起始中断向量-->0x28
         mov al, 0x02
         out 0xa1, al                  	;ICW3:从片识别标志，级联到主片IR2
         mov al, 0x01
         out 0xa1, al                  	;ICW4:非总线缓冲，全嵌套，正常EOI


    epilog


enable_irq:;enable irq; Helper function to enable specific IRQ
    prolog 1
    get_param rax, 1    ; Get IRQ number parameter
    
    cmp rax, 8
    jb .master_pic
    
    .slave_pic:
        sub rax, 8
        mov rcx, PIC2_DATA
        jmp .continue
        
    .master_pic:
        mov rcx, PIC1_DATA
        
    .continue:
        push rax
        in al, dx           ; Get current mask
        mov ah, 1
        mov cl, bl
        shl ah, cl          ; Create mask for this IRQ
        not ah              ; Invert mask
        and al, ah          ; Clear bit for this IRQ
        out dx, al          ; Write new mask
        pop rax
    
    epilog

init_rtc_timer:;init rtc
    prolog 0
    ;     ;设置和时钟中断相关的硬件
    mov al, 0x0b                             ;RTC寄存器B
    or al, 0x80                              ;阻断NMI
    out 0x70, al
    mov al, 0x12                             ;设置寄存器B，禁止周期性中断，开放更
    out 0x71, al                             ;新结束后中断，BCD码，24小时制

    ; 设置 RTC 频率 (默认 1024 Hz, 改为 1 Hz)
    mov al, 0x8A         ; 再次选择寄存器 B
    out RTC_ADDR, al
    in al, RTC_DATA
    and al, 0xF0         ; 清除低 4 位 (频率设置)
    or al, 0x0F          ; 设置频率为 2 Hz (0x0F = 2 Hz, 0x0E = 4 Hz, ...)
    out RTC_DATA, al


    in al, 0xa1                              ;读8259从片的IMR寄存器

    and al, 0xfe                             ;清除bit 0(此位连接RTC)
    out 0xa1, al                             ;写回此寄存器




    ; ; 禁用 NMI (Non-Maskable Interrupt)
    ; mov al, 0x8A         ; 选择寄存器 B (0x8A = NMI 禁用 + 寄存器 B)
    ; out RTC_ADDR, al

    ; ; 读取当前寄存器 B 的值
    ; in al, RTC_DATA
    ; or al, 0x40          ; 启用 Periodic Interrupt (bit 6)
    ; mov bl, al

    ; ; 写回寄存器 B
    ; mov al, 0x8A
    ; out RTC_ADDR, al
    ; mov al, bl
    ; out RTC_DATA, al

    ; ; 设置 RTC 频率 (默认 1024 Hz, 改为 1 Hz)
    ; mov al, 0x8A         ; 再次选择寄存器 B
    ; out RTC_ADDR, al
    ; in al, RTC_DATA
    ; and al, 0xF0         ; 清除低 4 位 (频率设置)
    ; or al, 0x0F          ; 设置频率为 2 Hz (0x0F = 2 Hz, 0x0E = 4 Hz, ...)
    ; out RTC_DATA, al

    ; ; 启用 NMI
    ; mov al, 0x8B         ; 选择寄存器 B (NMI 启用)
    ; out RTC_ADDR, al
    ; in al, RTC_DATA      ; 读取当前值
    ; and al, 0x7F         ; 清除 NMI 禁用位 (bit 7)
    ; out RTC_DATA, al

    ; sti

    ; mov al, 0x0c
    ; out 0x70, al
    ; in al, 0x71                              ;读RTC寄存器C，复位未决的中断状态




    ; mov r8,0x12345678
    ; jmp $


    ; ; 1. 允许IRQ8
    ; in   al, 0xA1
    ; and  al, 0xFE
    ; out  0xA1, al

    ; ; 2. 设置寄存器B，启用周期性中断
    ; mov  al, 0x8B         ; 选择寄存器B，禁止NMI
    ; out  0x70, al
    ; in   al, 0x71         ; 读出原值
    ; and  al, 0x0F         ; 保留低4位
    ; or   al, 0x40         ; 设置bit6 (Periodic Interrupt Enable)
    ; out  0x71, al         ; 写回寄存器B

    ; ; 3. 设置寄存器A，分频器=0x0F（2Hz），如需1Hz可用0x0F
    ; mov  al, 0x8A         ; 选择寄存器A，禁止NMI
    ; out  0x70, al
    ; in   al, 0x71         ; 读出原值
    ; and  al, 0xF0         ; 保留高4位
    ; or   al, 0x0F         ; 设置低4位为0x0F（2Hz），0x0F=2Hz, 0x0E=4Hz, 0x0D=8Hz, 0x0C=16Hz
    ; out  0x71, al         ; 写回寄存器A


    epilog
irq8_rtc_interrupt_handler:;timer handler
    SAVE_CONTEXT

    ; mov r9,0x123456
    ; jmp $
    ; 1. 读取 RTC 寄存器 C（清除中断标志）
    mov al, 0x0C
    out 0x70, al
    in al, 0x71           ; 读取后自动清除中断

    ; 2. 发送 EOI（Legacy PIC）
    mov al, 0x20
    out 0xA0, al          ; 从 PIC
    out 0x20, al          ; 主 PIC

    ; 3. 读取 CMOS 时间（秒、分、时）
    mov al, 0x00          ; 秒
    out 0x70, al
    in al, 0x71
    mov bl, al

    mov al, 0x02          ; 分
    out 0x70, al
    in al, 0x71
    mov bh, al

    mov al, 0x04          ; 时
    out 0x70, al
    in al, 0x71
    mov cl, al

    ; 4. 转换为 ASCII（BCD 格式）
    ; 小时
    .utc8:
        xor rax,0

        mov al, cl
        shr al, 4
        mov dl,10
        mul dl

        mov ah,cl
        and ah, 0x0F   
        add al,ah
        add al,8

        cmp al,24
        jl .hours24
        sub al,24
        .hours24:
        mov cl,al

    mov al, cl
    shr al, 4
    add al, '0'
    mov [rel global_rtc_time_str], al
    mov al, cl
    and al, 0x0F
    add al, '0'
    mov [rel global_rtc_time_str + 1], al

    ; 分钟
    mov al, bh
    shr al, 4
    add al, '0'
    mov [rel global_rtc_time_str + 3], al
    mov al, bh
    and al, 0x0F
    add al, '0'
    mov [rel global_rtc_time_str + 4], al

    ; 秒
    mov al, bl
    shr al, 4
    add al, '0'
    mov [rel global_rtc_time_str + 6], al
    mov al, bl
    and al, 0x0F
    add al, '0'
    mov [rel global_rtc_time_str + 7], al

        lea rsi,[rel global_rtc_time_str]    
       function draw_string,1,1500,0,rsi


    RESTORE_CONTEXT
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