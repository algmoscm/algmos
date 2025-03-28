
;|----------------------|
;|	100000 ~ END	|
;|	   KERNEL	|
;|----------------------|
;|	E0000 ~ 100000	|
;| Extended System BIOS |
;|----------------------|
;|	C0000 ~ Dffff	|
;|     Expansion Area   |
;|----------------------|
;|	A0000 ~ bffff	|
;|   Legacy Video Area  |
;|----------------------|
;|	9F000 ~ A0000	|
;|	 BIOS reserve	|
;|----------------------|
;|	90000 ~ 9F000	|
;|	 kernel tmpbuf	|
;|----------------------|
;|	10000 ~ 90000	|
;|	   LOADER	|
;|----------------------|
;|	8000 ~ 10000	|
;|	  VBE info	|
;|----------------------|
;|	7E00 ~ 8000	|
;|	  mem info	|
;|----------------------|
;|	7C00 ~ 7E00	|
;|	 MBR (BOOT)	|
;|----------------------|
;|	0000 ~ 7C00	|
;|	 BIOS Code	|
;|----------------------|

org	10000h
	jmp	Label_Start


BaseOfKernelFile	equ	0x00
OffsetOfKernelFile	equ	0x100000

BaseTmpOfKernelAddr	equ	0x9000
OffsetTmpOfKernelFile	equ	0x0000

MemoryStructBufferAddr	equ	0x7E00

LABEL_ttt:			dd	0xFFFFFFFF,0xFFFFFFFF

[SECTION gdt]

LABEL_GDT:		dd	0,0
LABEL_DESC_CODE32:	dd	0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:	dd	0x0000FFFF,0x00CF9200

GdtLen	equ	$ - LABEL_GDT
GdtPtr	dw	GdtLen - 1
	dd	LABEL_GDT	;be carefull the address(after use org)!!!!!!

SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32	equ	LABEL_DESC_DATA32 - LABEL_GDT

[SECTION gdt64]

LABEL_GDT64:		dq	0x0000000000000000
LABEL_DESC_CODE64:	dq	0x0020980000000000
LABEL_DESC_DATA64:	dq	0x0000920000000000

GdtLen64	equ	$ - LABEL_GDT64
GdtPtr64	dw	GdtLen64 - 1
		dd	LABEL_GDT64

SelectorCode64	equ	LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64	equ	LABEL_DESC_DATA64 - LABEL_GDT64

StartLoaderMessage:	db	"Start Loader"

[SECTION .s16]
[BITS 16]

Label_Start:

	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax	;10000:0000
	mov	sp,	0x00


	mov	ax, 0B800h
	mov	gs, ax

;=======	display on screen : Start Loader......

	mov	ax,	1301h
	mov	bx,	000fh
	mov	dx,	0200h		;row 2
	mov	cx,	12
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartLoaderMessage
	int	10h

;=======	open address A20
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


    ; 设置目标地址为 0x7E00
    mov ax, BaseTmpOfKernelAddr
    mov es, ax     ; ES = 0x7E00
    xor bx, bx     ; BX = 0x0000

    ; 设置 int 0x13 参数
    mov ah, 0x02   ; 功能号：读取扇区
    mov al, 1      ; 读取 1 个扇区
    mov ch, 0      ; 柱面号 0
    mov cl, 17      ; 扇区号 1（LBA 0）
    mov dh, 0      ; 磁头号 0
    mov dl, 0x80   ; 驱动器号：第一个硬盘
    int 0x13       ; 调用 BIOS 中断

	push	cx
	push	eax
	push	edi
	push	ds
	push	esi

	mov	cx,	512

	mov	edi,OffsetOfKernelFile

	mov	ax,	BaseTmpOfKernelAddr
	mov	ds,	ax
	mov	esi,OffsetTmpOfKernelFile

Label_Mov_Kernel:

	mov	al,	byte	[ds:esi]
	mov	byte	[fs:edi],	al
	mov	byte	[ds:esi],	0

	inc	esi
	inc	edi

	loop	Label_Mov_Kernel
; jmp $
	pop	esi
	pop	ds
	pop	edi
	pop	eax
	pop	cx

;=======	init IDT GDT goto protect mode 

	mov	ax,	cs
	mov	ds,	ax
	mov	fs,	ax
	mov	es,	ax

	cli

	db	66h	
	lidt	[IDT_POINTER]	

	db	66h
	lgdt	[GdtPtr]
; jmp $
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax	

	jmp	dword SelectorCode32:GO_TO_TMP_Protect

[SECTION .s32]
[BITS 32]

GO_TO_TMP_Protect:
	; jmp $
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
	jmp	SelectorCode64:OffsetOfKernelFile

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


[SECTION .s116]
[BITS 16]

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

DisplayPosition		dd	0

;=======	display messages


NoLoaderMessage:	db	"ERROR:No KERNEL Found"
KernelFileName:		db	"KERNEL  BIN",0
StartGetMemStructMessage:	db	"Start Get Memory Struct (address,size,type)."
GetMemStructErrMessage:	db	"Get Memory Struct ERROR"
GetMemStructOKMessage:	db	"Get Memory Struct SUCCESSFUL!"

StartGetSVGAVBEInfoMessage:	db	"Start Get SVGA VBE Info"
GetSVGAVBEInfoErrMessage:	db	"Get SVGA VBE Info ERROR"
GetSVGAVBEInfoOKMessage:	db	"Get SVGA VBE Info SUCCESSFUL!"

StartGetSVGAModeInfoMessage:	db	"Start Get SVGA Mode Info"
GetSVGAModeInfoOKMessage:	db	"Get SVGA Mode Info SUCCESSFUL!"

SetSVGAModeInfoVBAVESAMessage:	db	"Set SVGA Mode VBE VESA Fail"




