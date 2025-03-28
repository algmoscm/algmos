
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










;______________________________________________
; ----------------Vbe Info Block------------
; typedef struct {
;     unsigned char       vbe_signature;
;     unsigned short      vbe_version;
;     unsigned long       oem_string_ptr;
;     unsigned char       capabilities;
;     unsigned long       video_mode_ptr;
;     unsigned short      total_memory;
;     unsigned short      oem_software_rev;
;     unsigned long       oem_vendor_name_ptr;
;     unsigned long       oem_product_name_ptr;
;     unsigned long       oem_product_rev_ptr;
;     unsigned char       reserved[222];
;     unsigned char       oem_data[256];  
; } VbeInfoBlock;
;______________________________________________

format binary as 'img'  ; 输出为二进制格式

org	0000h
loader_Start:

	jmp loader_code_Start

BaseOfKernelFile	equ	0x00
OffsetOfKernelFile	equ	0x100000

BaseTmpOfKernelAddr	equ	0x9000
OffsetTmpOfKernelFile	equ	0x0000

MemoryStructBufferAddr	equ	0x7E00

LABEL_ttt:			dd	0xFFFFFFFF,0xFFFFFFFF

GDT32_START:
LABEL_GDT:			dd	0,0
LABEL_DESC_CODE32:	dd	0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:	dd	0x0000FFFF,0x00CF9200
GDT32_END:


GdtPtr:	dw	GDT32_END - GDT32_START - 1
		dd	GDT32_START + 0x10000

SelectorCode32	equ	(LABEL_DESC_CODE32 - LABEL_GDT)
SelectorData32	equ	(LABEL_DESC_DATA32 - LABEL_GDT)


GDT64_START:
LABEL_GDT64:		dq	0x0000000000000000
LABEL_DESC_CODE64:	dq	0x0020980000000000
LABEL_DESC_DATA64:	dq	0x0000920000000000
GDT64_END:

GdtPtr64:	dw	GDT64_END - GDT64_START - 1
			dd	GDT64_START + 0x10000


SelectorCode64	equ	(LABEL_DESC_CODE64 - LABEL_GDT64)
SelectorData64	equ	(LABEL_DESC_DATA64 - LABEL_GDT64)

StartLoaderMessage:	db	"Start Loader"


use16
loader_code_Start:

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
	mov	dx,	0100h		;row 2
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

	lgdt	[cs:GdtPtr]

	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax

	mov	ax,	SelectorData32
	mov	fs,	ax
	mov	eax,	cr0
	and	al,	11111110b
	mov	cr0,	eax

	sti
	
    ; 设置目标地址为 0x9000
    mov ax, BaseTmpOfKernelAddr
    mov es, ax     ; ES = 0x9000
    xor bx, bx     ; BX = 0x0000

    ; 设置 int 0x13 参数
    mov ah, 0x02   ; 功能号：读取扇区
    mov al, 50      ; 读取 1 个扇区
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

	mov	cx,	512*50

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

	pop	esi
	pop	ds
	pop	edi
	pop	eax
	pop	cx

;____________________Get VBE Info Block____________________
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
	; mov	esi,	0x8000
mov byte [es:0x8000],42
mov byte [es:0x8001],56
mov byte [es:0x8002],32
mov byte [es:0x8003],45

	mov	ax,	0x00
	mov	es,	ax
	mov	di,	0x8000
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
		; mov	dx,	0900h		;row 9
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



    ; mov si, vbe_signature_msg
    ; call print_string
    
    ; mov si, VBE_INFO_BLOCK_ADDR
    ; mov cx, 4            ; 签名长度为4字节
    ; call print_hex_bytes
    ; call print_newline

	; mov	ax,	0300h
	; mov	bx,	0000h
	; int	10h
	; add dh,1
	; mov dl,0

	; mov	ax,	1301h
	; mov	bx,	000Fh
	; mov	cx,	4
	; push	ax
	; mov	ax,	0
	; mov	es,	ax
	; pop	ax
	; mov	bp,	0x8000
	; int	10h

	; mov	ax,	0
	; mov	es,	ax


	; mov	ax,	0300h
	; mov	bx,	0000h
	; int	10h
	; add dh,1
	; mov dl,0

	; mov	ax,	1301h
	; mov	bx,	000Fh
	; mov	cx,	2
	; push	ax
	; mov	ax,	0
	; mov	es,	ax
	; pop	ax
	; mov	bp,	0x8004
	; int	10h

	; jmp	$
;____________________Get Mdoes Info Block__________________
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


; mov dword [es:0x8000],'V'
; mov dword [es:0x8001],'B'
; mov dword [es:0x8002],'E'
; mov dword [es:0x8003],'2'

; mov dword [es:0x8000],'VBE2'
; VBE2

; move 


; 	mov	eax,	80*2*10
; 	mov	[DisplayPosition],	eax


; 	mov	ax,	0x00
; 	mov	es,	ax
; 	mov	esi,	0x8000

; 	; mov	esi,	dword	[es:si]
; 	mov	edi,	0x8200

; Label_SVGA_Mode_Info_Get:

; 	mov	cx,	word	[es:esi]

; ;=======	display SVGA mode information

; 	push	ax
	
; 	mov	ax,	00h
; 	mov	al,	ch
; 	call	Label_DispAL

; 	mov	ax,	00h
; 	mov	al,	cl	
; 	call	Label_DispAL
	
; 	pop	ax

; ;=======
	
; 	cmp	cx,	0FFFFh
; 	jz	Label_SVGA_Mode_Info_Finish

	mov	ax,	0x00
	mov	es,	ax
	; mov	esi,	0x8000
	; mov	esi,	dword	[es:si]
	mov	di,	0x8200

	mov	ax,	4F01h
	mov cx,	103h	;========================mode : 0x115 800*600 4byte
	int	10h

	cmp	ax,	004Fh
	jnz	Label_SVGA_Mode_Info_FAIL
	jz	Label_SVGA_Mode_Info_Finish
	; jnz	Label_SVGA_Mode_Info_FAIL	

; 	inc	dword		[SVGAModeCounter]
; 	add	esi,	2
; 	add	edi,	0x100

; 	add	dword [DisplayPosition],	2
; 	jmp	Label_SVGA_Mode_Info_Get
		


; jmp	$




; 	mov	eax,	80*2*10
; 	mov	[DisplayPosition],	eax


; 	mov	ax,	0x00
; 	mov	es,	ax
; 	mov	si,	0x800e

; 	mov	esi,	dword	[es:si]
; 	mov	edi,	0x8200

; Label_SVGA_Mode_Info_Get:

; 	mov	cx,	word	[es:esi]

; ;=======	display SVGA mode information

; 	push	ax
	
; 	mov	ax,	00h
; 	mov	al,	ch
; 	call	Label_DispAL

; 	mov	ax,	00h
; 	mov	al,	cl	
; 	call	Label_DispAL
	
; 	pop	ax

; ;=======
	
; 	cmp	cx,	0FFFFh
; 	jz	Label_SVGA_Mode_Info_Finish

; 	mov	ax,	4F01h
; 	int	10h

; 	cmp	ax,	004Fh

; 	jnz	Label_SVGA_Mode_Info_FAIL	

; 	inc	dword		[SVGAModeCounter]
; 	add	esi,	2
; 	add	edi,	0x100

; 	add	dword [DisplayPosition],	2
; 	jmp	Label_SVGA_Mode_Info_Get
		
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

; jmp $



;-----------------------set VESA VBE mode------------------------;


; jmp	$
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
	


	mov	ax,	4F02h
	mov	bx,	4103h	;========================mode : 4115 800*600 4byte
	int 	10h

	cmp	ax,	004Fh
	jnz	Label_SET_SVGA_Mode_VESA_VBE_FAIL


    ; 设置 VGA 图形模式 0x13 (320x200 256色)

    ; mov ax, 0x13
    ; int 0x10

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
; jmp $
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax	


	jmp	pword SelectorCode32:GO_TO_TMP_Protect+0x10000

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
; print_16:
Protect_mode_Start:
; org ( 0x10000 + ( Protect_mode_Start - loader_Start ) ) 
use32
GO_TO_TMP_Protect:
;=======	go to tmp long mode

	mov	ax,	0x10
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax

	mov	ss,	ax


	mov	esp,	7E00h
; jmp $
	call	support_long_mode
	test	eax,	eax

	jz	no_support
; jmp $
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
	; jmp $
;=======	load GDTR

	db	66h
	lgdt	[GdtPtr64+0x10000]

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





;=======	tmp IDT

IDT:
	times	0x50	dq	0
IDT_END:

IDT_POINTER:
		dw	IDT_END - IDT - 1
		dd	IDT+0x10000

;=======	tmp variable


SectorNo		dw	0
Odd			db	0
OffsetOfKernelFileCount	dd	OffsetOfKernelFile

MemStructNumber		dd	0

SVGAModeCounter		dd	0

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
GetSVGAModeInfoErrMessage:	db	"Get SVGA Mode Info ERROR"
SetSVGAModeInfoVBAVESAMessage:	db	"Set SVGA Mode VBE VESA Fail"
