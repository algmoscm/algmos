format binary as 'img'  ; 输出为二进制格式
use64
; org	0xFFFF800000100000
org	0x100000

head_start:

    ; 设置帧缓冲区地址（假设为 0xB8000，VGA 文本模式）
    mov rdi, 0xB8000+2*2*80
    ; 打印 64 位模式消息
    mov rsi, head_entry_msg
    call print_string_64

    ; jmp	$

    mov ax,0x10
	mov	ds,	ax
    mov	es,	ax
    mov	fs,	ax
    mov	ss,	ax
    mov	esp,0x7E00


    mov rax,line_address_msg
    mov rbx,[GDT_POINTER-0xFFFF800000000000]    
    mov rcx,head_start
    mov rdx,head_end
    ; jmp $

    db	66h
    lgdt [GDT_POINTER-0xFFFF800000000000]
	; lidt	[IDT_POINTER]

jmp $

    mov ax,0x10
	mov	ds,	ax
    jmp $
    mov	es,	ax
    mov	fs,	ax
    mov	gs,	ax
    mov	ss,	ax
    mov	rsp,0x7E00

jmp $

    mov rax,0x101000
    mov cr3,rax

    mov rax,head_end
    mov rbx,head_start
    mov rcx,head_kernel_start
    ; head_end
    ; head_start
    jmp $
    ; jmp qword 0x08:head_kernel_start


    mov	rax,head_kernel_start
	pushq	0x08
	pushq	rax
	retq

print_string_64:
    ; 打印字符串到帧缓冲区
    mov ah, 0x0F ; 白色前景，黑色背景
    .next_char:
        lodsb
        cmp al, 0
        je .done
        stosw        ; 将字符和属性写入帧缓冲区
        jmp .next_char
    .done:
        ret

head_entry_msg db "jump to head entry success!", 0

use64
head_end:
;-------------从线性地址0x100000向地址0xFFFF 8000 0010 0000切换的工作---------------
org	( 0xFFFF800000100000 + ( head_end - head_start ) )
head_kernel:
line_address_msg db "line address switch success!", 0
; macro align value { rb (value-1) - ($ + value-1) mod value }
; align 4
head_kernel_start:
;     dq head_kernel_entry
; head_kernel_entry:
    jmp	$
    mov ax,0x10
	mov	ds,	ax
    mov	es,	ax
    mov	gs,	ax
    mov	ss,	ax
    mov	rsp,0xffff800000007E00

    mov	rax,kernel
	pushq	0x08
	pushq	rax
	retq    
    ; jmp 0x08:kernel

kernel:

    ; 设置帧缓冲区地址（假设为 0xB8000，VGA 文本模式）
    mov rdi, 0xFFFF800000100000+0xB8000+4*2*80

    ; 打印 64 位模式消息
    mov rsi, line_address_msg
    call print_string_64_2

    jmp	$

    ; ; 设置帧缓冲区地址
    ; mov rdi, 0xE0000000  ; 帧缓冲区起始地址

    ; ; 绘制红色矩形
    ; mov ecx, 900         ; 行数
    
    ; .draw_row:
    ;     push rcx
    ;     mov ecx, 1440        ; 每行像素数
        
    ; .draw_pixel:
    ;     mov dword [rdi], 0x00FF0000  ; 红色像素 (ARGB: 0x00FF0000)
    ;     add rdi, 4           ; 移动到下一个像素
    ;     loop .draw_pixel
    ;     pop rcx
    ;     loop .draw_row

    ; jmp	$

print_string_64_2:
    ; 打印字符串到帧缓冲区
    mov ah, 0x0F ; 白色前景，黑色背景
    .next_char:
        lodsb
        cmp al, 0
        je .done
        stosw        ; 将字符和属性写入帧缓冲区
        jmp .next_char
    .done:
        ret

times 1000-($-head_kernel) db 0
;---------------------init page-----------;
align 8	
org	0xFFFF800000101000
PML4E:
	dq	0x102007
    dq  255 dup(0x0000000000000000)
	dq	0x102007		;256索引,比如线性地址0xFFFF 8000 0010 0000(低21位是2MB物理页的页内偏移)映射到的物理地址是0x10 0000
	dq  255 dup(0x0000000000000000)

org	0xFFFF800000102000	;21~29位索引PDT,0~20位为2MB物理页的页内偏移
PDPTE:	;4KB
	
	dq	0x103003		;/* 0x103003 */
	dq  511 dup(0x0000000000000000)

org	0xFFFF800000103000
PDE:		;4KB
	dq	0x000083		;0x00 0000
	dq	0x200083		;0x20 0000
	dq	0x400083		;0x40 0000
	dq	0x600083		;0x60 0000
	dq	0x800083		;0x80 0000
	dq	0xe0000083		;/*0x a00000*/
	dq	0xe0200083
	dq	0xe0400083
	dq	0xe0600083		;/*0x1000000*/;作者说注释放错行了,本来在下一行,修改到这一行
	dq	0xe0800083
	dq	0xe0a00083
	dq	0xe0c00083
	dq	0xe0e00083
	dq  499 dup(0x0000000000000000)
;init page程序段将前10MB物理内存分别映射到线性地址0处和0xFFFF 8000 0000 0000处,接着把物理地址0xE000 0000开始的16MB内存映射到线性地址0xA0 0000处和0xFFFF 8000 00A0 0000处,最后使用伪指令.fill将数值0填充到页表的剩余499个页表项里

;----------------------GDT_Table--------------------;
GDT_Table:
	dq	0x0000000000000000			;/*0	NULL descriptor		       	00*/
	dq	0x0020980000000000			;/*1	KERNEL	Code	64-bit	Segment	08*/
	dq	0x0000920000000000			;/*2	KERNEL	Data	64-bit	Segment	10*/
	dq	0x0020f80000000000			;/*3	USER	Code	64-bit	Segment	18*/
	dq	0x0000f20000000000			;/*4	USER	Data	64-bit	Segment	20*/
	dq	0x00cf9a000000ffff			;/*5	KERNEL	Code	32-bit	Segment	28*/
	dq	0x00cf92000000ffff			;/*6	KERNEL	Data	32-bit	Segment	30*/
    dq  10 dup(0x0000000000000000)  ;/*8 ~ 9	TSS (jmp one segment <7>) in long-mode 128-bit 40*/	
GDT_END:

GDT_POINTER:
GDT_LIMIT:	dw	GDT_END - GDT_Table - 1
GDT_BASE:	dq	GDT_Table

;----------------------IDT_Table--------------------;
IDT_Table:
	dq  512 dup(0x0000000000000000)
IDT_END:

IDT_POINTER:
IDT_LIMIT:	dw	IDT_END - IDT_Table - 1
IDT_BASE:	dq	IDT_Table

;----------------------TSS64_Table--------------------;
TSS64_Table:
	dq  13 dup(0x0000000000000000)
TSS64_END:

TSS64_POINTER:
TSS64_LIMIT:	dw	TSS64_END - TSS64_Table - 1
TSS64_BASE:     dq	TSS64_Table

;以下是注释说明:
;在64位的IA-32e模式下,页表最高可以分为4个等级,而且分页机制除了提供4KB的物理页之外,还提供2MB和1GB的物理页
;对于拥有大量物理内存的操作系统来说,使用4KB物理页可能会导致页颗粒过于零碎,从而造成频繁的页维护工作,而采用2MB的物理页也许会比4KB更合理


; times 512-($-$$) db 0