%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 16]          ; 16位实模式
[ORG 0x10000]       ; BIOS 加载引导扇区到 0x10000

loader_Start:

	jmp loader_code_Start

; tttp: db 0x55,0xaa,55,0xaa,55,0xaa,55,0xaa,55,0xaa,55,0xaa,55,0xaa,55,0xaa

GDT32_START:
LABEL_GDT:			dd	0,0
LABEL_DESC_CODE32:	dd	0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:	dd	0x0000FFFF,0x00CF9200
GDT32_END:


GdtPtr:	dw	GDT32_END - GDT32_START - 1
		dd	GDT32_START

SelectorCode32	equ	(LABEL_DESC_CODE32 - LABEL_GDT)
SelectorData32	equ	(LABEL_DESC_DATA32 - LABEL_GDT)


GDT64_START:
LABEL_GDT64:		dq	0x0000000000000000
LABEL_DESC_CODE64:	dq	0x0020980000000000
LABEL_DESC_DATA64:	dq	0x0000920000000000
GDT64_END:

GdtPtr64:	dw	GDT64_END - GDT64_START - 1
			dd	GDT64_START


SelectorCode64	equ	(LABEL_DESC_CODE64 - LABEL_GDT64)
SelectorData64	equ	(LABEL_DESC_DATA64 - LABEL_GDT64)


loader_code_Start:
; jmp $
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax	;10000:0000
	mov	sp,	0x8000


	mov	ax, 0B800h
	mov	gs, ax

;--------display on screen : Start Loader-----------;
;---------------------------------------------------;
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	000fh
	; mov	dx,	0100h		;row 2
	mov	cx,	12
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartLoaderMessage
	int	10h


;-----------------open address A20------------------;
	push	ax
	in	al,	92h
	or	al,	00000010b
	out	92h,	al
	pop	ax

	cli

	lgdt	[GdtPtr]

	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax

	mov	ax,	SelectorData32
	mov	fs,	ax
	mov	eax,	cr0
	and	al,	11111110b
	mov	cr0,	eax

	sti
	; jmp $
;     ; 设置目标地址为 0x9000
;     mov ax, BaseTmpOfKernelAddr
;     mov es, ax     ; ES = 0x9000
;     xor bx, bx     ; BX = 0x0000

;     ; 设置 int 0x13 参数
;     mov ah, 0x02   ; 功能号：读取扇区
;     mov al, 52      ; 读取 1 个扇区
;     mov ch, 0      ; 柱面号 0
;     mov cl, 17      ; 扇区号 1（LBA 0）
;     mov dh, 0      ; 磁头号 0
;     mov dl, 0x80   ; 驱动器号：第一个硬盘
;     int 0x13       ; 调用 BIOS 中断

; 	push	cx
; 	push	eax
; 	push	edi
; 	push	ds
; 	push	esi

; 	mov	cx,	512*52

; 	mov	edi,OffsetOfKernelFile

; 	mov	ax,	BaseTmpOfKernelAddr
; 	mov	ds,	ax
; 	mov	esi,OffsetTmpOfKernelFile

; Label_Mov_Kernel:

; 	mov	al,	byte	[ds:esi]
; 	mov	byte	[fs:edi],	al

; 	mov	byte	[ds:esi],	0

; 	inc	esi
; 	inc	edi

; 	loop	Label_Mov_Kernel

; 	pop	esi
; 	pop	ds
; 	pop	edi
; 	pop	eax
; 	pop	cx

;-----------------Get VBE Info Block------------------;
Get_VBE_Info_Block:
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	000Fh

	mov	cx,	23
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartGetSVGAVBEInfoMessage
	int	10h


	mov	ax,	0x00
	mov	es,	ax
	mov	di,	VBEStructBufferAddr
	mov	ax,	4F00h

	int	10h

	cmp	ax,	004Fh

	jz	.KO
	
	.Fail:
		mov	ax,	0300h
		mov	bx,	0000h
		int	10h
		add dh,1
		mov dl,0

		mov	ax,	1301h
		mov	bx,	008Ch
		mov	cx,	23
		push	ax
		mov	ax,	ds
		mov	es,	ax
		pop	ax
		mov	bp,	GetSVGAVBEInfoErrMessage
		int	10h

		jmp	$

	.KO:
		mov	ax,	0300h
		mov	bx,	0000h
		int	10h
		add dh,1
		mov dl,0

		mov	ax,	1301h
		mov	bx,	000Fh
		mov	cx,	29
		push	ax
		mov	ax,	ds
		mov	es,	ax
		pop	ax
		mov	bp,	GetSVGAVBEInfoOKMessage
		int	10h

		
;-----------------Get Mdoes Info Block------------------;
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	000Fh
	mov	cx,	24
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartGetSVGAModeInfoMessage
	int	10h


	mov	ax,	0x00
	mov	es,	ax

	call detect_max_resolution



	mov	ax,	0x00
	mov	es,	ax
	mov	di,	0x8200
	mov	ax,	4F01h
	mov cx,	word [best_mode]	;========================mode : 0x115 800*600 4byte
	int	10h
	cmp	ax,	004Fh
	jnz	Label_SVGA_Mode_Info_FAIL
	jz	Label_SVGA_Mode_Info_Finish



; 检测最大分辨率函数
detect_max_resolution:
    pusha
	mov cx,100h

	.loop:
		mov bx, 0x4100
		add bx,cx

		call test_vga_mode
		loop .loop
			; jmp	$
    popa
    ret

; 测试特定VGA模式是否可用
; 输入: Bx = 模式号
test_vga_mode:
    pusha

	mov	ax,	0x00
	mov	es,	ax
	mov	di,	VBEModeStructBufferAddr

	mov	ax,	4F01h;get vbe mode info block to 0x8200
	mov cx,	bx	
	int	10h

	cmp	ax,	004Fh
    jne .mode_failed

    
    ; 3. 检查分辨率是否比当前最佳模式更高
    mov ax, word [es:VBEModeStructBufferAddr + vbe_mode_info_block.x_resolution]  ; X分辨率
    mov bx, word [es:VBEModeStructBufferAddr + vbe_mode_info_block.y_resolution]  ; Y分辨率
	xor dx,dx
	mov dl, byte [es:VBEModeStructBufferAddr + vbe_mode_info_block.bits_per_pixel]  ; pixel byte 

%if DEBUG_PLATFORM == PLATFORM_QEMU_X64
	cmp ax, 0x780
    jnz .mode_failed
%else
    cmp ax, word [max_width]
    jb .mode_failed
%endif

    cmp bx, word [max_height]
    jb .mode_failed
	cmp dl, byte [byte_per_pixel]
    jb .mode_failed
    ;  jmp	$   
    ; 更新最佳模式
    mov word [max_width], ax
    mov word [max_height], bx
	mov word [best_mode], cx
	mov byte [byte_per_pixel], dl
    ; mov dword [liner_address],
	.mode_failed:
		popa
		ret







		
Label_SVGA_Mode_Info_FAIL:

	mov	ax,	1301h
	mov	bx,	008Ch
	mov	dx,	0D00h		;row 13
	mov	cx,	24
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetSVGAModeInfoErrMessage
	int	10h

Label_SET_SVGA_Mode_VESA_VBE_FAIL:

	jmp	$

Label_SVGA_Mode_Info_Finish:
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	000Fh
	mov	cx,	30
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetSVGAModeInfoOKMessage
	int	10h



;-----------------get memory address size type------------------;
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0
	mov	ax,	1301h
	mov	bx,	000Fh
	mov	cx,	44

	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartGetMemStructMessage
	int	10h
	mov	ebx,	0
	mov	ax,	0x00
	mov	es,	ax
	mov	di,	MemoryStructBufferAddr	

Label_Get_Mem_Struct:

	mov	eax,	0x0E820
	mov	ecx,	20
	mov	edx,	0x534D4150
	int	15h
	jc	Label_Get_Mem_Fail
	add	di,	20
	inc	dword	[MemStructNumber]

	cmp	ebx,	0
	jne	Label_Get_Mem_Struct
	jmp	Label_Get_Mem_OK

Label_Get_Mem_Fail:

	mov	dword	[MemStructNumber],	0

	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	008Ch
	mov	cx,	23
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetMemStructErrMessage
	int	10h

Label_Get_Mem_OK:
	mov	ax,	0300h
	mov	bx,	0000h
	int	10h
	add dh,1
	mov dl,0

	mov	ax,	1301h
	mov	bx,	000Fh
	mov	cx,	29
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetMemStructOKMessage
	int	10h	


;-----------------------set VESA VBE mode------------------------;
;=======	clear screen

	mov	ax,	0600h
	mov	bx,	0700h
	mov	cx,	0
	mov	dx,	0184fh
	int	10h

;=======	set focus

	mov	ax,	0200h
	mov	bx,	0000h
	mov	dx,	0000h
	int	10h
	

	push es
	mov ax,0
	mov es,ax

	mov	ax,	4F02h
	mov	bx,	[best_mode]	;========================mode : 4115 800*600 4byte 103
	int 	10h
	pop es
	cmp	ax,	004Fh
	jnz	Label_SET_SVGA_Mode_VESA_VBE_FAIL

;=======	init IDT GDT goto protect mode 

	mov	ax,	cs
	mov	ds,	ax
	mov	fs,	ax
	mov	es,	ax

	cli

	; db	66h	
	; lidt	[cs:IDT_POINTER]	

	db	66h
	lgdt	[cs:GdtPtr]

	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax	


	jmp	dword SelectorCode32:GO_TO_TMP_Protect

Label_DispAL:

	push	ecx
	push	edx
	push	edi
	
	mov	edi,	[DisplayPosition]
	mov	ah,	0Fh
	mov	dl,	al
	shr	al,	4
	mov	ecx,	2
	.begin:

		and	al,	0Fh
		cmp	al,	9
		ja	.1
		add	al,	'0'
		jmp	.2
	.1:

		sub	al,	0Ah
		add	al,	'A'
	.2:

		mov	[gs:edi],	ax
		add	edi,	2
		
		mov	al,	dl
		loop	.begin

		mov	[DisplayPosition],	edi

		pop	edi
		pop	edx
		pop	ecx
		
		ret
;-----------------------Protect Mode-------------------------;

[BITS 32]
GO_TO_TMP_Protect:
;=======	go to tmp long mode

	mov	ax,	0x10
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax

	mov	ss,	ax


	mov	esp,	7E00h

	call	support_long_mode
	test	eax,	eax

	jz	no_support

;=======	init template page table 0x90000 make sure there is not dirty data

	mov	dword	[0x90000],	0x91007
	mov	dword	[0x90800],	0x91007		

	mov	dword	[0x91000],	0x92007

	mov	dword	[0x92000],	0x000083

	mov	dword	[0x92008],	0x200083

	mov	dword	[0x92010],	0x400083

	mov	dword	[0x92018],	0x600083

	mov	dword	[0x92020],	0x800083

	mov	dword	[0x92028],	0xa00083
;=======	load GDTR

	db	66h
	lgdt	[GdtPtr64]

	mov	ax,	0x10
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax
	mov	gs,	ax
	mov	ss,	ax

	mov	esp,	7E00h

;=======	open PAE
	
	mov	eax,	cr4
	bts	eax,	5
	mov	cr4,	eax

;=======	load	cr3
	
	mov	eax,	0x90000
	mov	cr3,	eax
	
;=======	enable long-mode

	mov	ecx,	0C0000080h		;IA32_EFER
	rdmsr

	bts	eax,	8
	wrmsr

;=======	open PE and paging
		; jmp $
	mov	eax,	cr0
	bts	eax,	0
	bts	eax,	31
	mov	cr0,	eax
	; jmp $
	jmp	SelectorCode64:long_mode




;=======	test support long mode or not

support_long_mode:

	mov	eax,	0x80000000
	cpuid
	cmp	eax,	0x80000001
	setnb	al	
	jb	support_long_mode_done
	mov	eax,	0x80000001
	cpuid
	bt	edx,	29
	setc	al
support_long_mode_done:
	
	movzx	eax,	al
	ret

;=======	no support

no_support:
	jmp	$


[BITS 64]
long_mode:
; jmp $
         ;以下加载系统核心程序
         mov edi, OffsetOfKernelFile

         mov eax, KernelStartSectorNum
         mov ebx, edi                                 ;起始地址
         call read_hard_disk_0                        ;以下读取程序的起始部分（一个扇区）

         ;以下判断整个程序有多大
		 push rdi
         mov eax, [edi+struct_ABI_HEADER.section_offset]                               ;核心程序尺寸
		;  jmp $
		 add eax,struct_SECTION_HEADER.size
		;  jmp $
		 mov edi,eax
		 mov eax,[edi]
		 add eax,64
		;  jmp $
		 pop rdi
         xor edx, edx
         mov ecx, 512                                 ;512字节每扇区
		;  jmp $
         div ecx
; jmp $
         or edx, edx
         jnz @1                                       ;未除尽，因此结果比实际扇区数少1
         dec eax                                      ;已经读了一个扇区，扇区总数减1
   @1:
         or eax, eax                                  ;考虑实际长度≤512个字节的情况
         jz pge                                       ;EAX=0 ?

         ;读取剩余的扇区
         mov ecx, eax                                 ;32位模式下的LOOP使用ECX
         mov eax, 16
         inc eax                                      ;从下一个逻辑扇区接着读
   @2:
         call read_hard_disk_0
         inc eax
         loop @2                                      ;循环读，直到读完整个内核

   pge:
        ;  ;回填内核加载的位置信息（物理/线性地址）到内核程序头部
        ;  mov dword [CORE_PHY_ADDR + 0x08], CORE_PHY_ADDR
        ;  mov dword [CORE_PHY_ADDR + 0x0c], 0

; jmp $
	mov rax,0x100000
	; lea rax,[rel head_end]
	mov rbx,[0x100000+8]
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
         mov [ebx], ax
         add ebx, 2
         loop .readw

         pop rdx
         pop rcx
         pop rax

         ret

;=======	tmp IDT

IDT:
	times	0x50	dq	0
IDT_END:

IDT_POINTER:
		dw	IDT_END - IDT - 1
		dd	IDT

;=======	tmp variable


SectorNo		dw	0
Odd			db	0
OffsetOfKernelFileCount	dd	OffsetOfKernelFile

MemStructNumber		dd	0

SVGAModeCounter		dd	0

DisplayPosition		dd	0

current_mode dw 0
max_width dw 0
max_height dw 0
best_mode dw 0  ; 存储找到的最佳模式
byte_per_pixel db 0

liner_address dd 0  ; 存储找到的最佳模式
;=======	display messages

StartLoaderMessage:	db	"Start Loader"

NoLoaderMessage:	db	"ERROR:No KERNEL Found"

StartGetMemStructMessage:	db	"Start Get Memory Struct (address,size,type)."
GetMemStructErrMessage:	db	"Get Memory Struct ERROR"
GetMemStructOKMessage:	db	"Get Memory Struct SUCCESSFUL!"

StartGetSVGAVBEInfoMessage:	db	"Start Get SVGA VBE Info"
GetSVGAVBEInfoErrMessage:	db	"Get SVGA VBE Info ERROR"
GetSVGAVBEInfoOKMessage:	db	"Get SVGA VBE Info SUCCESSFUL!"

StartGetSVGAModeInfoMessage:	db	"Start Get SVGA Mode Info"
GetSVGAModeInfoOKMessage:	db	"Get SVGA Mode Info SUCCESSFUL!"
GetSVGAModeInfoErrMessage:	db	"Get SVGA Mode Info ERROR"
SetSVGAModeInfoVBAVESAMessage:	db	"Set SVGA Mode VBE VESA Fail"
