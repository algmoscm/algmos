%include "../bootloader/global_def.asm"

[BITS 16]          ; 16位实模式
[ORG 0x10000]       ; BIOS 加载引导扇区到 0x10000

loader_Start:

	jmp loader_code_Start



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

	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax	;10000:0000
	mov	sp,	0x8000


	mov	ax, 0B800h
	mov	gs, ax

;--------display on screen : Start Loader-----------;
;---------------------------------------------------;
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
	
    ; 设置目标地址为 0x9000
    mov ax, BaseTmpOfKernelAddr
    mov es, ax     ; ES = 0x9000
    xor bx, bx     ; BX = 0x0000

    ; 设置 int 0x13 参数
    mov ah, 0x02   ; 功能号：读取扇区
    mov al, 52      ; 读取 1 个扇区
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

	mov	cx,	512*52

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

    mov word [es:0x8400], 0;x
    mov word [es:0x8402], 0;y
    mov word [es:0x8404], 0;mode
    mov word [es:0x8406], 0;byte per pixel

	call detect_max_resolution

	; jmp	$
	mov	ax,	0x00
	mov	es,	ax
	mov	di,	0x8200
	mov	ax,	4F01h
	mov cx,	word [es:0x8404]	;========================mode : 0x115 800*600 4byte
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
	mov	di,	0x8200

	mov	ax,	4F01h
	mov cx,	bx	;========================mode : 0x115 800*600 4byte
	int	10h

	cmp	ax,	004Fh
    jne .mode_failed

    
    ; 3. 检查分辨率是否比当前最佳模式更高
    mov ax, word [es:0x8200 + 0x12]  ; X分辨率
    mov bx, word [es:0x8200 + 0x14]  ; Y分辨率
	xor dx,dx
	mov dl, byte [es:0x8200 + 0x19]  ; pixel byte
    
    ; cmp ax, word [es:0x8400]
    ; jb .mode_failed
	cmp ax, 0x780
    jnz .mode_failed

    cmp bx, word [es:0x8402]
    jb .mode_failed
	cmp dl, byte [es:0x8406]
    jb .mode_failed
    
    ; 更新最佳模式
    mov word [es:0x8400], ax
    mov word [es:0x8402], bx
	mov word [es:0x8404], cx
	mov byte [es:0x8406], dl
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
	mov	bx,	[es:0x8404]	;========================mode : 4115 800*600 4byte 103
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
