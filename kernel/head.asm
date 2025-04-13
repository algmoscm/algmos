%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]
[ORG 0x100000]       ; BIOS 加载引导扇区到 0x100000
ehdr:
    ABI_HEADER ABI_File_CORE, head_start, shdr,1
shdr:
    SECTION_HEADER Section_Type_LOAD, 0, head_start,section_end-section_start
section_start:
head_start:
    mov ax,0x10
	mov	ds,	ax
    mov	es,	ax
    mov	fs,	ax
    mov	ss,	ax
    mov	esp,0x7E00

    lgdt	[GDT_POINTER]
	lidt	[IDT_POINTER]

    mov rax,0x101000
    mov cr3,rax

    mov	rax,head_kernel + 0xFFFF800000000000
    jmp rax
;-------------从线性地址0x100000向地址0xFFFF 8000 0010 0000切换的工作---------------
head_kernel:

    mov ax,0x10
	mov	ds,	ax
    mov	es,	ax
    mov	gs,	ax
    mov	ss,	ax
    mov	rsp,0xffff800000007E00

	mov rdx,0
	mov rax,section_end-section_start+64
		; jmp $
	mov rcx,512
	div rcx

	; jmp $
	add rax,KernelStartSectorNum
	lea rdi,[rel head_end]

	mov rbx, rdi                                 ;起始地址
	; jmp $
	call read_hard_disk_0                        ;以下读取程序的起始部分（一个扇区）

	;以下判断整个程序有多大
	push rdi
	mov rax, [rdi+struct_ABI_HEADER.section_offset]                               ;核心程序尺寸
	add rax,struct_SECTION_HEADER.size
	add rdi,rax
	mov rax,[rdi]
	; jmp $
	add rax,64
	pop rdi
	xor rdx, rdx
	mov rcx, 512                                 ;512字节每扇区
	div rcx

	or rdx, rdx
	jnz @1                                       ;未除尽，因此结果比实际扇区数少1
	dec rax                                      ;已经读了一个扇区，扇区总数减1
@1:
	or rax, rax                                  ;考虑实际长度≤512个字节的情况
	jz pge                                       ;EAX=0 ?

	;读取剩余的扇区
	mov rcx, rax                                 ;32位模式下的LOOP使用ECX
	; jmp $
	push rcx
		mov rdx,0
	mov rax,section_end-section_start+64
		; jmp $
	mov rcx,512
	div rcx
	pop rcx
	add rax, KernelStartSectorNum
	inc rax                                      ;从下一个逻辑扇区接着读
	
@2:
	call read_hard_disk_0
	inc rax
	loop @2                                      ;循环读，直到读完整个内核

pge:
	;  ;回填内核加载的位置信息（物理/线性地址）到内核程序头部
	;  mov dword [CORE_PHY_ADDR + 0x08], CORE_PHY_ADDR
	;  mov dword [CORE_PHY_ADDR + 0x0c], 0


	mov rax,0x100000
	lea rax,[rel head_end]
	mov rbx,[rax+8]
	add rbx,rax
	; jmp $
	jmp	rbx

read_hard_disk_0:                                     ;从硬盘读取一个逻辑扇区
                                                      ;EAX=逻辑扇区号
                                                      ;EBX=目标缓冲区地址
                                                      ;返回：EBX=EBX+512
         push rax
         push rcx
         push rdx

         push rax

         mov dx, SectorReadNumPort
         mov al, 1
         out dx, al                                   ;读取的扇区数

         inc dx                                       ;0x1f3
         pop rax
         out dx, al                                   ;LBA地址7~0

         inc dx                                       ;0x1f4
         mov cl, 8
         shr eax, cl
         out dx, al                                   ;LBA地址15~8

         inc dx                                       ;0x1f5
         shr eax, cl
         out dx, al                                   ;LBA地址23~16

         inc dx                                       ;0x1f6
         shr eax, cl
         or al, 0xe0                                  ;第一硬盘  LBA地址27~24
         out dx, al

         inc dx
                                                      ;0x1f7
         mov al, 0x20                                 ;读命令
         out dx, al

  .waits:
         in al, dx
         test al, 8
         jz .waits                                   ;不忙，且硬盘已准备好数据传输

         mov ecx, 256                                 ;总共要读取的字数
         mov dx, SectorReadPort
  .readw:
         in ax, dx
         mov [rbx], ax
         add rbx, 2
         loop .readw

         pop rdx
         pop rcx
         pop rax

         ret
ttt:

times 0x1000-($-ehdr) db 0

;---------------------init page-----------;
align 8
Page_Start:;init page程序段将前10MB物理内存分别映射到线性地址0处和0xFFFF 8000 0000 0000处,接着把物理地址0xE000 0000开始的16MB内存映射到线性地址0xA0 0000处和0xFFFF 8000 00A0 0000处,最后使用伪指令.fill将数值0填充到页表的剩余499个页表项里
PML4E:; [ORG  0xFFFF800000101000]
	dq	0x102007		;0索引,索引出来后低12位补0
    dq  255 dup(0x0000000000000000)
	dq	0x102007		;256索引,比如线性地址0xFFFF 8000 0010 0000(低21位是2MB物理页的页内偏移)映射到的物理地址是0x10 0000
	dq  255 dup(0x0000000000000000)
PDPTE:; [ORG  0xFFFF800000102000]	;21~29位索引PDT,0~20位为2MB物理页的页内偏移
	
	dq	0x103003		;/* 0x103003 */
	dq  511 dup(0x0000000000000000)


PDE:  ; [ORG  0xFFFF800000103000]
	dq	0x000083		;0x00 0000
	dq	0x200083		;0x20 0000
	dq	0x400083		;0x40 0000
	dq	0x600083		;0x60 0000
	dq	0x800083		;0x80 0000
    dq  0xa00083
    dq  0xc00083
    dq  0xe00083
    dq  0x1000083
    dq  0x1200083
    dq  0x1400083
    dq  0x1600083
    dq  0x1800083
    dq  0x1a00083
    dq  0x1c00083
    dq  0x1e00083
    dq  0x2000083
    dq  0x2200083
    dq  0x2400083
    dq  0x2600083
    dq  0x2800083
    dq  0x2a00083
    dq  0x2c00083
    dq  0x2e00083

	%if DEBUG_PLATFORM == PLATFORM_QEMU_X64
		dq	0xfd000083		;/*0x 300 0000*/ 115 mode vbe qemu 800*600
		dq	0xfd200083
		dq	0xfd400083
		dq	0xfd600083
		dq	0xfd800083
		dq	0xfda00083
		dq	0xfdc00083
		dq	0xfde00083
		dq  480 dup(0x0000000000000000)
	%else
		dq	0xa0000083		;/*0x 300 0000*/ 115 mode vbe physics 800*600 4byte
		dq	0xa0200083
		dq	0xa0400083
		dq	0xa0600083
		dq	0xa0800083
		dq	0xa0a00083
		dq	0xa0c00083
		dq	0xa0e00083
		dq  480 dup(0x0000000000000000)
	%endif



GDT_POINTER:; [ORG  0xFFFF800000104000]
	GDT_LIMIT:	dw	GDT_END - GDT_Table - 1
	GDT_BASE:	dq	GDT_Table + 0xFFFF800000000000
IDT_POINTER:; [ORG  0xFFFF80000010400a]
	IDT_LIMIT:	dw	IDT_END - IDT_Table - 1
	IDT_BASE:	dq	IDT_Table + 0xFFFF800000000000
TSS_POINTER:; [ORG  0xFFFF800000104014]
	; TSS_LIMIT:	dw	TSS_END - TSS_Table - 1
	TSS_LIMIT:	dw	TSS_END - TSS_Table
	TSS_BASE:     dq	TSS_Table + 0xFFFF800000000000
GDT_Table:;----------------------GDT_Table--------------------;
	dq	0x0000000000000000			;/*0	NULL descriptor		       	00*/
	dq	0x0020980000000000			;/*1	KERNEL	Code	64-bit	Segment	08*/
	dq	0x0000920000000000			;/*2	KERNEL	Data	64-bit	Segment	10*/
	dq	0x0020f80000000000			;/*3	USER	Code	64-bit	Segment	18*/
	dq	0x0000f20000000000			;/*4	USER	Data	64-bit	Segment	20*/
	dq	0x00cf9a000000ffff			;/*5	KERNEL	Code	32-bit	Segment	28*/
	dq	0x00cf92000000ffff			;/*6	KERNEL	Data	32-bit	Segment	30*/
    dq  20 dup(0x0000000000000000)  ;/*8 ~ 9	TSS (jmp one segment <7>) in long-mode 128-bit 40*/	
	GDT_END:

IDT_Table:;----------------------IDT_Table--------------------;
	dq  512 dup(0x0000000000000000)
	IDT_END:

TSS_Table:;----------------------TSS64_Table--------------------;
	dq  13 dup(0x0000000000000000)
	TSS_END:

kernel_end:
times 41*512-($-$$) db 0

;----------------------ASCII_Font_Table--------------------;
font_start:

    ; 	/*	0000	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0010	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0020	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0030	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x00,0x00,0x10,0x10,0x00,0x00;	    33	'!'
	db 0x28,0x28,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;     	'"'
	db 0x00,0x44,0x44,0x44,0xfe,0x44,0x44,0x44,0x44,0x44,0xfe,0x44,0x44,0x44,0x00,0x00;     	'#'
	db 0x10,0x3a,0x56,0x92,0x92,0x90,0x50,0x38,0x14,0x12,0x92,0x92,0xd4,0xb8,0x10,0x10;     	'$'
	db 0x62,0x92,0x94,0x94,0x68,0x08,0x10,0x10,0x20,0x2c,0x52,0x52,0x92,0x8c,0x00,0x00;     	'%'
	db 0x00,0x70,0x88,0x88,0x88,0x90,0x60,0x47,0xa2,0x92,0x8a,0x84,0x46,0x39,0x00,0x00;	        '&'
	db 0x04,0x08,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;     	'''

	; /*	0040	*/
	db 0x02,0x04,0x08,0x08,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x08,0x08,0x04,0x02,0x00;     	'('
	db 0x80,0x40,0x20,0x20,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x20,0x20,0x40,0x80,0x00;     	')'
	db 0x00,0x00,0x00,0x00,0x00,0x10,0x92,0x54,0x38,0x54,0x92,0x10,0x00,0x00,0x00,0x00;     	'*'
	db 0x00,0x00,0x00,0x00,0x00,0x10,0x10,0x10,0xfe,0x10,0x10,0x10,0x00,0x00,0x00,0x00;     	'+'
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x08,0x08,0x10;     	','
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,0x00;     	'-'
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00,0x00;     	'.'
	db 0x02,0x02,0x04,0x04,0x08,0x08,0x08,0x10,0x10,0x20,0x20,0x40,0x40,0x40,0x80,0x80;     	'/'
	db 0x00,0x18,0x24,0x24,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x24,0x24,0x18,0x00,0x00;     48	'0'
	db 0x00,0x08,0x18,0x28,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x3e,0x00,0x00;     	'1'

	; /*	0050	*/
	db 0x00,0x18,0x24,0x42,0x42,0x02,0x04,0x08,0x10,0x20,0x20,0x40,0x40,0x7e,0x00,0x00;     	'2'
	db 0x00,0x18,0x24,0x42,0x02,0x02,0x04,0x18,0x04,0x02,0x02,0x42,0x24,0x18,0x00,0x00;     	'3'
	db 0x00,0x0c,0x0c,0x0c,0x14,0x14,0x14,0x24,0x24,0x44,0x7e,0x04,0x04,0x1e,0x00,0x00;     	'4'
	db 0x00,0x7c,0x40,0x40,0x40,0x58,0x64,0x02,0x02,0x02,0x02,0x42,0x24,0x18,0x00,0x00;     	'5'
	db 0x00,0x18,0x24,0x42,0x40,0x58,0x64,0x42,0x42,0x42,0x42,0x42,0x24,0x18,0x00,0x00;     	'6'
	db 0x00,0x7e,0x42,0x42,0x04,0x04,0x08,0x08,0x08,0x10,0x10,0x10,0x10,0x38,0x00,0x00;     	'7'
	db 0x00,0x18,0x24,0x42,0x42,0x42,0x24,0x18,0x24,0x42,0x42,0x42,0x24,0x18,0x00,0x00;     	'8'
	db 0x00,0x18,0x24,0x42,0x42,0x42,0x42,0x42,0x26,0x1a,0x02,0x42,0x24,0x18,0x00,0x00;     	'9'
	db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00,0x00;     58	':'
	db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00,0x00,0x00,0x00,0x18,0x18,0x08,0x08,0x10;     	';'

	; /*	0060	*/
	db 0x00,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x00;     	'<'
	db 0x00,0x00,0x00,0x00,0x00,0x00,0xfe,0x00,0x00,0xfe,0x00,0x00,0x00,0x00,0x00,0x00;     	'='
	db 0x00,0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x00;     	'>'
	db 0x00,0x38,0x44,0x82,0x82,0x82,0x04,0x08,0x10,0x10,0x00,0x00,0x18,0x18,0x00,0x00;     	'?'
	db 0x00,0x38,0x44,0x82,0x9a,0xaa,0xaa,0xaa,0xaa,0xaa,0x9c,0x80,0x46,0x38,0x00,0x00;     	'@'
	db 0x00,0x18,0x18,0x18,0x18,0x24,0x24,0x24,0x24,0x7e,0x42,0x42,0x42,0xe7,0x00,0x00;     65	'A'
	db 0x00,0xf0,0x48,0x44,0x44,0x44,0x48,0x78,0x44,0x42,0x42,0x42,0x44,0xf8,0x00,0x00;     	'B'
	db 0x00,0x3a,0x46,0x42,0x82,0x80,0x80,0x80,0x80,0x80,0x82,0x42,0x44,0x38,0x00,0x00;     	'C'
	db 0x00,0xf8,0x44,0x44,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x44,0x44,0xf8,0x00,0x00;     	'D'
	db 0x00,0xfe,0x42,0x42,0x40,0x40,0x44,0x7c,0x44,0x40,0x40,0x42,0x42,0xfe,0x00,0x00;     	'E'

	; /*	0070	*/
	db 0x00,0xfe,0x42,0x42,0x40,0x40,0x44,0x7c,0x44,0x44,0x40,0x40,0x40,0xf0,0x00,0x00;     	'F'
	db 0x00,0x3a,0x46,0x42,0x82,0x80,0x80,0x9e,0x82,0x82,0x82,0x42,0x46,0x38,0x00,0x00;     	'G'
	db 0x00,0xe7,0x42,0x42,0x42,0x42,0x42,0x7e,0x42,0x42,0x42,0x42,0x42,0xe7,0x00,0x00;     	'H'
	db 0x00,0x7c,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x7c,0x00,0x00;     	'I'
	db 0x00,0x1f,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x84,0x48,0x30,0x00;     	'J'
	db 0x00,0xe7,0x42,0x44,0x48,0x50,0x50,0x60,0x50,0x50,0x48,0x44,0x42,0xe7,0x00,0x00;     	'K'
	db 0x00,0xf0,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x42,0x42,0xfe,0x00,0x00;     	'L'
	db 0x00,0xc3,0x42,0x66,0x66,0x66,0x5a,0x5a,0x5a,0x42,0x42,0x42,0x42,0xe7,0x00,0x00;     	'M'
	db 0x00,0xc7,0x42,0x62,0x62,0x52,0x52,0x52,0x4a,0x4a,0x4a,0x46,0x46,0xe2,0x00,0x00;     	'N'
	db 0x00,0x38,0x44,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x44,0x38,0x00,0x00;     	'O'

	; /*	0080	*/
	db 0x00,0xf8,0x44,0x42,0x42,0x42,0x44,0x78,0x40,0x40,0x40,0x40,0x40,0xf0,0x00,0x00;     	'P'
	db 0x00,0x38,0x44,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x92,0x8a,0x44,0x3a,0x00,0x00;     	'Q'
	db 0x00,0xfc,0x42,0x42,0x42,0x42,0x7c,0x44,0x42,0x42,0x42,0x42,0x42,0xe7,0x00,0x00;     	'R'
	db 0x00,0x3a,0x46,0x82,0x82,0x80,0x40,0x38,0x04,0x02,0x82,0x82,0xc4,0xb8,0x00,0x00;     	'S'
	db 0x00,0xfe,0x92,0x92,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x7c,0x00,0x00;     	'T'
	db 0x00,0xe7,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x24,0x3c,0x00,0x00;     	'U'
	db 0x00,0xe7,0x42,0x42,0x42,0x42,0x24,0x24,0x24,0x24,0x18,0x18,0x18,0x18,0x00,0x00;     	'V'
	db 0x00,0xe7,0x42,0x42,0x42,0x5a,0x5a,0x5a,0x5a,0x24,0x24,0x24,0x24,0x24,0x00,0x00;     	'W'
	db 0x00,0xe7,0x42,0x42,0x24,0x24,0x24,0x18,0x24,0x24,0x24,0x42,0x42,0xe7,0x00,0x00;	        'X'
	db 0x00,0xee,0x44,0x44,0x44,0x28,0x28,0x28,0x10,0x10,0x10,0x10,0x10,0x7c,0x00,0x00;	        'Y'

	; /*	0090	*/
	db 0x00,0xfe,0x84,0x84,0x08,0x08,0x10,0x10,0x20,0x20,0x40,0x42,0x82,0xfe,0x00,0x00;     	'Z'
	db 0x00,0x3e,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x3e,0x00;     91	'['
	db 0x80,0x80,0x40,0x40,0x20,0x20,0x20,0x10,0x10,0x08,0x08,0x04,0x04,0x04,0x02,0x02;         '\'
	db 0x00,0x7c,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x7c,0x00;	        ']'
	db 0x00,0x10,0x28,0x44,0x82,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;	        '^'
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xfe,0x00;	        '_'
	db 0x10,0x08,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;	        '`'
	db 0x00,0x00,0x00,0x00,0x00,0x70,0x08,0x04,0x3c,0x44,0x84,0x84,0x8c,0x76,0x00,0x00;     97	'a'
	db 0xc0,0x40,0x40,0x40,0x40,0x58,0x64,0x42,0x42,0x42,0x42,0x42,0x64,0x58,0x00,0x00;         'b'
	db 0x00,0x00,0x00,0x00,0x00,0x30,0x4c,0x84,0x84,0x80,0x80,0x82,0x44,0x38,0x00,0x00;     	'c'

	; /*	0100	*/
	db 0x0c,0x04,0x04,0x04,0x04,0x34,0x4c,0x84,0x84,0x84,0x84,0x84,0x4c,0x36,0x00,0x00;     	'd'
	db 0x00,0x00,0x00,0x00,0x00,0x38,0x44,0x82,0x82,0xfc,0x80,0x82,0x42,0x3c,0x00,0x00;     	'e'
	db 0x0e,0x10,0x10,0x10,0x10,0x7c,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x7c,0x00,0x00;	        'f'
	db 0x00,0x00,0x00,0x00,0x00,0x36,0x4c,0x84,0x84,0x84,0x84,0x4c,0x34,0x04,0x04,0x38;	        'g'
	db 0xc0,0x40,0x40,0x40,0x40,0x58,0x64,0x42,0x42,0x42,0x42,0x42,0x42,0xe3,0x00,0x00;	        'h'
	db 0x00,0x10,0x10,0x00,0x00,0x30,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x38,0x00,0x00;	        'i'
	db 0x00,0x04,0x04,0x00,0x00,0x0c,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x08,0x08,0x30;	        'j'
	db 0xc0,0x40,0x40,0x40,0x40,0x4e,0x44,0x48,0x50,0x60,0x50,0x48,0x44,0xe6,0x00,0x00;	        'k'
	db 0x30,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x38,0x00,0x00;	        'l'
	db 0x00,0x00,0x00,0x00,0x00,0xf6,0x49,0x49,0x49,0x49,0x49,0x49,0x49,0xdb,0x00,0x00;	        'm'

	; /*	0110	*/
	db 0x00,0x00,0x00,0x00,0x00,0xd8,0x64,0x42,0x42,0x42,0x42,0x42,0x42,0xe3,0x00,0x00;	        'n'
	db 0x00,0x00,0x00,0x00,0x00,0x38,0x44,0x82,0x82,0x82,0x82,0x82,0x44,0x38,0x00,0x00;	        'o'
	db 0x00,0x00,0x00,0x00,0xd8,0x64,0x42,0x42,0x42,0x42,0x42,0x64,0x58,0x40,0x40,0xe0;	        'p'
	db 0x00,0x00,0x00,0x00,0x34,0x4c,0x84,0x84,0x84,0x84,0x84,0x4c,0x34,0x04,0x04,0x0e;	        'q'
	db 0x00,0x00,0x00,0x00,0x00,0xdc,0x62,0x42,0x40,0x40,0x40,0x40,0x40,0xe0,0x00,0x00;	        'r'
	db 0x00,0x00,0x00,0x00,0x00,0x7a,0x86,0x82,0xc0,0x38,0x06,0x82,0xc2,0xbc,0x00,0x00;     	's'
	db 0x00,0x00,0x10,0x10,0x10,0x7c,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x0e,0x00,0x00;	        't'
	db 0x00,0x00,0x00,0x00,0x00,0xc6,0x42,0x42,0x42,0x42,0x42,0x42,0x46,0x3b,0x00,0x00;	        'u'
	db 0x00,0x00,0x00,0x00,0x00,0xe7,0x42,0x42,0x42,0x24,0x24,0x24,0x18,0x18,0x00,0x00;	        'v'
	db 0x00,0x00,0x00,0x00,0x00,0xe7,0x42,0x42,0x5a,0x5a,0x5a,0x24,0x24,0x24,0x00,0x00;	        'w'

	; /*	0120	*/
	db 0x00,0x00,0x00,0x00,0x00,0xc6,0x44,0x28,0x28,0x10,0x28,0x28,0x44,0xc6,0x00,0x00;	        'x'
	db 0x00,0x00,0x00,0x00,0x00,0xe7,0x42,0x42,0x24,0x24,0x24,0x18,0x18,0x10,0x10,0x60;	        'y'
	db 0x00,0x00,0x00,0x00,0x00,0xfe,0x82,0x84,0x08,0x10,0x20,0x42,0x82,0xfe,0x00,0x00;	        'z'
	db 0x00,0x06,0x08,0x10,0x10,0x10,0x10,0x60,0x10,0x10,0x10,0x10,0x08,0x06,0x00,0x00;	        '{'
	db 0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10;	        '|'
	db 0x00,0x60,0x10,0x08,0x08,0x08,0x08,0x06,0x08,0x08,0x08,0x08,0x10,0x60,0x00,0x00;	        '}'
	db 0x00,0x72,0x8c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;     	'~'
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0130	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;


	; /*	0140	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0150	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0160	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0170	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0180	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0190	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0200	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0210	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0220	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0230	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0240	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;

	; /*	0250~0255	*/
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
head_end:
section_end:
; times 42*512-($-$$) db 0