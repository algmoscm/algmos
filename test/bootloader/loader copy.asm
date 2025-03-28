org	10000h
	jmp	Label_Start

BaseOfKernelFile	equ	0x00
OffsetOfKernelFile	equ	0x100000				;内核起始物理地址0x100000(1MB),因为1MB以下的物理地址并不全是可用的地址空间,这段物理地址被分为若干段子空间,它们可以是内存空间,非内存空间以及地址空洞
												;随着内核体积的不断增长,未来的内核程序很可能超过1MB,所以让内核程序跳过这些复杂的内存空间,从平坦的1MB开始
BaseTmpOfKernelAddr		equ	0x00
OffsetTmpOfKernelFile	equ	0x7E00				;内核程序的临时转存空间,由于内核程序的读取操作是通过BIOS中断INT 13h实现的,BIOS在实模式下只支持上限为1MB的物理地址空间寻址,所以必须先将内核程序读入临时转存空间
												;然后再通过特殊方式搬运到1MB以上的内存空间,当内核程序被转存到最终内存空间后,这个临时转存空间就可另作他用,此处将其改为内存结构数据的存储空间
MemoryStructBufferAddr	equ	0x7E00				;供内核程序初始化时使用

[SECTION gdt]	;本节创建了一个临时GDT表,为了避免保护模式段结构的复杂性,此处将代码段和数据段的段基地址都设置在0x0000 0000处,段限长为0xffff ffff,可以索引0~4GB内存
												;0000 0000 1100 1111 1001 1010 0000 0000	执行只读代码段
LABEL_GDT:			dd	0,0						;0000 0000 0000 0000 1111 1111 1111 1111
LABEL_DESC_CODE32:	dd	0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:	dd	0x0000FFFF,0x00CF9200	;0000 0000 1100 1111 1001 0010 0000 0000	读写数据段
												;0000 0000 0000 0000 1111 1111 1111 1111
GdtLen	equ	$ - LABEL_GDT
GdtPtr	dw	GdtLen - 1		;GDTR的前16位保存GDT长度,后32位保存GDT基地址,GdtPtr是要加载的GDT数据结构的起始地址
		dd	LABEL_GDT
;段选择子,15~3位描述符索引,2位TI位,1~0位RPL位
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT	;刚开始怀疑是不是少除8,其实是对的,(LABEL_DESC_CODE32 - LABEL_GDT)=8=1000b,前3位TI和RPL,第3位刚好是索引号1b
SelectorData32	equ	LABEL_DESC_DATA32 - LABEL_GDT	;同上,(LABEL_DESC_DATA32 - LABEL_GDT)=16=1 0000b,前3位TI和RPL,第3位刚好是索引号10b=2
												;0000 0000 0010 0000 1001 1000 0000 0000	字节粒度指令偏移16位,存在的0特权级只执行64位代码段
[SECTION gdt64]									;0000 0000 0000 0000 0000 0000 0000 0000

LABEL_GDT64:		dq	0x0000000000000000
LABEL_DESC_CODE64:	dq	0x0020980000000000
LABEL_DESC_DATA64:	dq	0x0000920000000000		;0000 0000 0000 0000 1001 0010 0000 0000	字节粒度,使用SP,存在的0特权级读写数据段
												;0000 0000 0000 0000 0000 0000 0000 0000
GdtLen64	equ	$ - LABEL_GDT64
GdtPtr64	dw	GdtLen64 - 1					;GDT表边界
			dd	LABEL_GDT64						;GDT线性基地址

SelectorCode64	equ	LABEL_DESC_CODE64 - LABEL_GDT64	;每个描述符占8字节,描述符在表内的偏移地址是索引号乘以8
SelectorData64	equ	LABEL_DESC_DATA64 - LABEL_GDT64	;同上

[SECTION .s16]	;定义段.s16
[BITS 16]		;当NASM编译器处于16位宽(BITS 16)状态下,使用32位宽数据指令时需要在指令前加入前缀0x66,使用32位宽地址指令时需要在指令前加入前缀0x67
				;而在32位宽(BITS 32)状态下,使用16位宽指令也需要加入指令前缀
Label_Start:

	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ax,	0x00
	mov	ss,	ax
	mov	sp,	0x7c00

;=======	display on screen : Start Loader......

	mov	ax,	1301h
	mov	bx,	000fh
	mov	dx,	0100h		;row 2
	mov	cx,	12
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartLoaderMessage	;StartLoaderMessage:			db	"Start Loader"
	int	10h

;=======	open address A20,置位0x92端口的位1(快速A20)
	push	ax
	in	al,	92h
	or	al,	00000010b
	out	92h,	al
	pop	ax

	cli		;关闭外部中断

	db	0x66
	lgdt	[GdtPtr]	;加载GDT表到GDTR
;置位CR0寄存器的的第0位来开启保护模式,进入保护模式,为FS段寄存器加载新的数据段值,一旦完成数据加载就从保护模式中退出,并开启外部中断,看似多此一举的代码,目的是为了让FS可以在实模式下寻址能力超过1MB,也就是Big Real Mode模式
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax
;开启保护模式
	mov	ax,	SelectorData32	;32位数据段选择子
	mov	fs,	ax				;FS指向0~4GB地址空间
	mov	eax,	cr0			;关闭保护模式
	and	al,	11111110b
	mov	cr0,	eax

	sti		;开启外部中断
;此时FS的状态信息与其他段寄存器不同,特别是段基地址base=0x0000 0000和段限长limit=0x0xffff ffff,它的寻址能力已经从20位(1MB)扩展到32位(4GB)
;=======	reset floppy	;这里需要注意的是在物理平台下,当段寄存器拥有这种特殊能力后,如果重新赋值会失去特殊能力,但Bochs放宽了检测条件,即使重新赋值依然拥有特殊能力
;INT 13h,AH=00h功能:重置磁盘驱动器,为下一次读写软盘做准备,DL=驱动器号,00H~7FH:软盘,80H~0FFH:硬盘
	; xor	ah,	ah							;AH=00h功能:重置磁盘驱动器
	; xor	dl,	dl							;DL=00H代表第一个软盘驱动器drive A:,01H代表第二个软盘驱动器drive B:
	; int	13h								;DL=80H代表第一个硬盘驱动器,81H代表第二个硬盘驱动器
;上面的代码相当于重新初始化软盘驱动器,从而将软盘驱动器的磁头移动至默认位置

    ; 设置目标地址为 0x7E00
    mov ax, OffsetTmpOfKernelFile
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

    jc disk_error  ; 如果出错，跳转到错误处理


; 	push	cx
; 	push	eax
; ;	push	fs		;must don`t change !!!!
; 	push	edi
; 	push	ds
; 	push	esi

; 	mov	cx,	512

; 	mov	edi,OffsetOfKernelFile

; 	mov	ax,	BaseTmpOfKernelAddr
; 	mov	ds,	ax
; 	mov	esi,OffsetTmpOfKernelFile
; 	; cld

; Label_Mov_Kernel:

; 	mov	al,	byte	[ds:esi]
; 	mov	byte	[fs:edi],	al

; 	inc	esi
; 	inc	edi

; 	loop	Label_Mov_Kernel

; 	pop	esi
; 	pop	ds
; 	pop	edi
; 	pop	eax
; 	pop	cx
; ;=======	get memory address size type
; ;当内核程序不再借助临时转存空间后,这块临时转存空间将用于保存物理地址空间信息,物理地址空间信息由一个结构体数组构成,计算机平台的地址空间划分情况都可以从这个结构体数组中反映出来
; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0200h		;row 4
; 	mov	cx,	24
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	StartGetMemStructMessage
; 	int	10h
; ;物理地址空间信息记录的地址空间类型包括可用物理内存空间/设备寄存器地址空间/内存空洞等,详细内容见第7章
; 	mov	ebx,	0
; 	mov	ax,	0x00
; 	mov	es,	ax
; 	mov	di,	MemoryStructBufferAddr	;MemoryStructBufferAddr	equ	0x7E00				;供内核程序初始化时使用
; ;这段程序将借助BIOS中断INT 15h来获取物理地址空间信息,并将其保存在0x7E00处的临时转存空间中,操作系统会在初始化内存管理单元时解析该结构体数组
; Label_Get_Mem_Struct:

; 	mov	eax,	0x0E820
; 	mov	ecx,	20
; 	mov	edx,	0x534D4150
; 	int	15h
; 	jc	Label_Get_Mem_Fail
; 	add	di,	20

; 	cmp	ebx,	0
; 	jne	Label_Get_Mem_Struct
; 	jmp	Label_Get_Mem_OK


; Label_Get_Mem_Fail:

; 	mov	ax,	1301h
; 	mov	bx,	008Ch
; 	mov	dx,	0300h		;row 5
; 	mov	cx,	23
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetMemStructErrMessage
; 	int	10h
; 	jmp	$

; Label_Get_Mem_OK:
	
; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0300h		;row 6
; 	mov	cx,	29
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetMemStructOKMessage
; 	int	10h	

; ;=======	get SVGA information
; ;这段程序将借助BIOS中断INT 15h来获取物理地址空间信息,并将其保存在0x7E00处的临时转存空间中,操作系统会在初始化内存管理单元时解析该结构体数组
; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0400h		;row 8
; 	mov	cx,	23
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	StartGetSVGAVBEInfoMessage
; 	int	10h

; 	mov	ax,	0x00
; 	mov	es,	ax
; 	mov	di,	0x8000
; 	mov	ax,	4F00h

; 	int	10h

; 	cmp	ax,	004Fh

; 	jz	.KO
	
; ;=======	Fail

; 	mov	ax,	1301h
; 	mov	bx,	008Ch
; 	mov	dx,	0500h		;row 9
; 	mov	cx,	23
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetSVGAVBEInfoErrMessage
; 	int	10h

; 	jmp	$

; .KO:

; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0500h		;row 10
; 	mov	cx,	29
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetSVGAVBEInfoOKMessage
; 	int	10h

; ;=======	Get SVGA Mode Info

; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0600h		;row 12
; 	mov	cx,	24
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	StartGetSVGAModeInfoMessage
; 	int	10h

; 	mov	ax, 0B800h
; 	mov	gs, ax

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

; 	add	esi,	2
; 	add	edi,	0x100

; 	jmp	Label_SVGA_Mode_Info_Get
		
; Label_SVGA_Mode_Info_FAIL:

; 	mov	ax,	1301h
; 	mov	bx,	008Ch
; 	mov	dx,	0700h		;row 13
; 	mov	cx,	24
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetSVGAModeInfoErrMessage
; 	int	10h

; Label_SET_SVGA_Mode_VESA_VBE_FAIL:

; 	jmp	$

; Label_SVGA_Mode_Info_Finish:

; 	mov	ax,	1301h
; 	mov	bx,	000Fh
; 	mov	dx,	0800h		;row 14
; 	mov	cx,	30
; 	push	ax
; 	mov	ax,	ds
; 	mov	es,	ax
; 	pop	ax
; 	mov	bp,	GetSVGAModeInfoOKMessage
; 	int	10h

;=======	set the SVGA mode(VESA VBE)
;设置SVGA芯片的显示模式,代码中的0x180和0x143是显示模式号,0x180(1440列X900行,物理地址e000 0000h,像素点位宽32bit),0x143(800列X600行,物理地址e000 0000h,像素点位宽32bit)

	; mov	ax,	4F02h
	; mov	bx,	4180h	;========================mode : 0x180 or 0x143
	; int 	10h

	; cmp	ax,	004Fh
	; jnz	Label_SET_SVGA_Mode_VESA_VBE_FAIL

;=======	init IDT GDT goto protect mode 
;这段代码在执行加载描述符表之前均插入一个字节0x66,这个字节是LGDT和LIDT汇编指令的前缀,用于修饰当前指令的操作数是32位宽
	cli			;======close interrupt

	db	0x66
	lgdt	[GdtPtr]

;	db	0x66
;	lidt	[IDT_POINTER]

	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax	

	jmp	dword SelectorCode32:GO_TO_TMP_Protect

disk_error:
    ; 打印错误消息
    ; mov si, disk_error_msg
    ; call print_string
    jmp $            ; 停止 CPU


[SECTION .s32]
[BITS 32]
;从此处开始执行IA-32e模式的切换程序
GO_TO_TMP_Protect:
;一旦进入保护模式,首要任务是初始化各个段寄存器以及栈指针,然后检测处理器是否支持IA-32e模式(长模式),如果哦不支持就进入待机状态,如果支持就向IA-32e模式切换
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

;=======	init temporary page table 0x90000
;该段程序将IA-32e模式的页目录首地址设置在0x90000地址处,并相继配置各级页表项的值(该值由页表起始地址和页属性组成)
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
;使用LGDT指令加载IA-32e模式的临时GDT表到GDTR,并将临时GDT表的数据段初始化到各个数据段寄存器,CS除外(需借助跨段跳转指令或跨段调用指令改变)
	db	0x66
	lgdt	[GdtPtr64]
	mov	ax,	0x10
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax
	mov	gs,	ax
	mov	ss,	ax
;当DS/ES/FS/GS/SS加载了IA-32e模式的段描述符后,它们的段基地址和段界限长皆以失效(全部清零),而CS依然运行在保护模式之下,段基地址和段限长均有效
	mov	esp,	7E00h

;=======	open PAE(物理地址扩展功能)
;CR4控制寄存器的第5位是PAE功能的标志位,置位该标志位可开启PAE功能,当开启PAE功能后,下一步将临时页目录的首地址设置到CR3
	mov	eax,	cr4
	bts	eax,	5				;置位第5位
	mov	cr4,	eax

;=======	load	cr3
;将临时页目录的首地址设置到CR3
	mov	eax,	0x90000
	mov	cr3,	eax
;向保护模式切换的过程中未开启分页机制,便是考虑到稍后的IA-32e模式切换过程中必须关闭分页并重新构造页表结构
;=======	enable long-mode
;按照官方提供的模式切换步骤,当页目录基址已加载到CR3,接下来就可以通过置位IA-32EFER寄存器的LME标志位激活IA-32e模式,IA-32EFER寄存器位于MSR寄存器组内,它的第8位是LME位
	mov	ecx,	0C0000080h		;IA32_EFER	为了操作IA-32EFER寄存器,必须借助特殊的汇编指令rdmsr/wrmsr(必须在0特权级下执行,使用之前应检测处理器是否支持MSR寄存器组)
	rdmsr
;在访问MSR寄存器之前,必须向ECX传入寄存器地址,在64位模式下,RCX的高32位无效,而目标MSR寄存器则是由EDX:EAX组成的64位寄存器代表,其中EDX保存MSR的高32位,在64位模式下,RAX/RDX的高32位为0
	bts	eax,	8				;置位第8位是LME位
	wrmsr
;在
;=======	open PE and paging
;保险起见这里再次使能保护模式和分页机制,至此处理器进入IA-32e模式,但是处理器目前正在执行保护模式程序,这种状态叫做兼容模式,即运行在IA-32e(64位)模式下的32位模式程序
	mov	eax,	cr0
	bts	eax,	0
	bts	eax,	31
	mov	cr0,	eax
;跨段跳转/调用指令及那个CS更新为IA-32e模式的代码段描述符,伴随着Loader的最后一条远跳转指令的执行,处理器的控制权就移交到了内核程序手上,此刻Loader程序已经完成了使命,其占用的内存空间可以释放另作他用
	; jmp $
	jmp	SelectorCode64:OffsetTmpOfKernelFile
	; jmp	SelectorCode64:OffsetOfKernelFile	;特别注意:这是Loader程序的最后一条指令(远跳转),Loader程序随即将处理器的控制权交给Kernel内核程序,Loader程序的任务已全部完成,此后不会再使用它,占用的内存空间可以释放掉
;目前系统虽已进入IA-32e模式,但这只是临时中转模式,接下来的内核程序将会为系统重新创建IA-32e模式的段结构和页结构
;=======	test support long mode or not
;cpuid指令的扩展功能项0x8000 0001的第29位,指示处理器是否支持IA-32e模式,本段程序首先检测当前处理器对cpuid指令的支持情况,判断该指令的最大扩展功能号是否超过0x8000 0000
support_long_mode:	;只有当cpuid的扩展功能号大于等于0x8000 0001时才有可能支持64位长模式,因此要先检测cpuid指令支持的扩展功能号,再读取相应的标志位,最后将读取结果存入EAX供模块调用者判断
;EFLAGS的ID标志位表明处理器是否支持cpuid指令,如果程序可以操作此标志位,说明处理器支持,cpuid指令会根据EAX传入的基础功能号(有时还需ECX传入扩展功能号),查询处理器的鉴定信息和机能信息
	mov	eax,	0x80000000	;返回结果保存在EAX/EBX/ECX/EDX中
	cpuid
	cmp	eax,	0x80000001
	setnb	al	
	jb	support_long_mode_done	;jb意思是低于则跳转
	mov	eax,	0x80000001
	cpuid
	bt	edx,	29				;将指定位置比特传送到CF
	setc	al
support_long_mode_done:
	
	movzx	eax,	al			;movzx意思是带零扩展的传送
	ret

;=======	no support

no_support:
	jmp	$

;=======	read one sector from floppy

[SECTION .s16lib]
[BITS 16]


;=======	display num in al
;这段代码与配置系统功能无关,只是为了显示查询出的信息,与Lable_File_Loaded模块使用了相同的方法,这个程序模块可以将十六进制数值显示在屏幕上,AL=要显示的十六进制数
Label_DispAL:
;Label_DispAL模块首先保存即将变更的寄存器值到栈,然后把变量DisplayPosition保存的屏幕偏移值(字符游标索引值)载入EDI,并向AH存入字体的颜色属性,为了先显示AL的高4位数据,暂且先把AL的低4位保存到DL
	push	ecx		;接着将AL的高4位数值与9比较,如果大于9,则减去0Ah并与字符A相加,否则直接将其与字符0相加,然后将AX的值保存到以GS为基址,DisplayPosition为偏移的显示字符内存空间中,然后再按上述过程将AL的低4位值显示出来
	push	edx
	push	edi
	
	mov	edi,	[DisplayPosition]	;DisplayPosition			dd	0
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

	mov	[DisplayPosition],	edi		;DisplayPosition			dd	0

	pop	edi
	pop	edx
	pop	ecx
	
	ret


;=======	tmp IDT

IDT:
	times	0x50	dq	0
IDT_END:

IDT_POINTER:
		dw	IDT_END - IDT - 1
		dd	IDT

;=======	tmp variable


SectorNo				dw	0
Odd						db	0
OffsetOfKernelFileCount	dd	OffsetOfKernelFile

DisplayPosition			dd	0

;=======	display messages

StartLoaderMessage:			db	"Start Loader"
NoLoaderMessage:			db	"ERROR:No KERNEL Found"
KernelFileName:				db	"KERNEL  BIN",0
StartGetMemStructMessage:	db	"Start Get Memory Struct."
GetMemStructErrMessage:		db	"Get Memory Struct ERROR"
GetMemStructOKMessage:		db	"Get Memory Struct SUCCESSFUL!"

StartGetSVGAVBEInfoMessage:	db	"Start Get SVGA VBE Info"
GetSVGAVBEInfoErrMessage:	db	"Get SVGA VBE Info ERROR"
GetSVGAVBEInfoOKMessage:	db	"Get SVGA VBE Info SUCCESSFUL!"

StartGetSVGAModeInfoMessage:	db	"Start Get SVGA Mode Info"
GetSVGAModeInfoErrMessage:	db	"Get SVGA Mode Info ERROR"
GetSVGAModeInfoOKMessage:	db	"Get SVGA Mode Info SUCCESSFUL!"


;以下是注释说明:
;最初的处理器只有20根地址线,这使得处理器只能寻址1MB以内的物理地址空间,如果超过1MB范围的寻址操作,也只有低20位有效,随着处理器寻址能力的不断增强,20根地址线无法满足后续的开发要求
;为了保证硬件平台的向后兼容性,便出现了一个控制开启或禁止1MB以上地址空间的开关,当时的8042键盘控制器上恰好有空闲的端口引脚(输出端口P2,引脚P21),从而使用此引脚作为功能控制开关,即A20功能
;如果A20引脚为低电平0,那么只有低20位地址有效,其他位均为0,在机器上电时,默认A20是禁用的,所以操作系统必须采用适当的方法启用它,由于硬件平台的兼容设备种类繁杂,所以出现了多种开启A20的方法
;1.开启A20的常用方法是操作键盘控制器,由于键盘控制器是低速设备,以至于功能开启速度相对较慢
;2.A20快速门使用端口0x92来处理A20信号线,对于不含键盘控制器的操作系统,就只能使用0x92端口来控制,但是该端口有可能被其他设备使用
;3.使用BIOS中断INT 15h的主功能号AX=2401可开启A20地址线,功能号AX=2400可禁用A20地址线,功能号AX=2403可查询A20地址线的当前状态
;4.通过读0xee端口来开启A20信号线,而写该端口会禁止A20信号线
;当A20功能开启后,紧接着使用指令CLI关闭外部中断,再通过指令LGDT加载保护模式结构数据信息,并置位CR0寄存器的第0位来开启保护模式
;当进入保护模式后,为FS加载新的数据段值,一旦完成数据加载就从保护模式中退出,并开启外部中断,看似多此一举的代码,目的是为了让FS可以在实模式下寻址能力超过1MB,也就是Big Real Mode模式
;此时FS的状态信息与其他段寄存器不同,特别是段基地址base=0x0000 0000和段限长limit=0x0xffff ffff,它的寻址能力已经从20位(1MB)扩展到32位(4GB)
;这里需要注意的是在物理平台下,当段寄存器拥有这种特殊能力后,如果重新赋值会失去特殊能力,但Bochs放宽了检测条件,即使重新赋值依然拥有特殊能力
;
;软盘驱动器控制功能表
;	位			名称			说明
;	7			MOT_EN3			控制软驱D马达,1启动0关闭
;	6			MOT_EN2			控制软驱C马达,1启动0关闭
;	5			MOT_EN1			控制软驱B马达,1启动0关闭
;	4			MOT_EN0			控制软驱A马达,1启动0关闭
;	3			DMA_INT			1允许DMA和中断请求,0禁止DMA和中断请求
;	2			RRSET			1允许软盘控制器发送控制信息,0复位软盘驱动器
;	1			DRV_SEL1		00~11用于选择软盘驱动器
;	0			DRV_SEL0
;
;		从实模式进入保护模式
;为了进入保护模式,处理器必须在模式切换前在内存中创建一段可在保护模式下执行的代码以及必要的系统数据结构保证模式切换的顺利完成
;相关的数据结构包括GDT/IDT/LDT各一个,其中LDT可选,任务状态段TSS,至少一个页目录和页表(如果开启分页机制)和至少一个异常/中断处理模块
;还必须初始化GDTR/IDTR(亦可推迟到进入保护模式后,使能中断前),CR1~4/MTTRs内存范围类型寄存器
;	1.系统数据结构
;		系统在进入保护模式之前,必须创建一个拥有代码段描述符和数据段描述符的GDT,并且一定要使用LGDT加载到GDTR,保护模式的栈寄存器SS使用可读写的数据段即可,无需创建专用的描述符
;		对于多段式操作系统,可采用LDT局部描述符表(必须保存在GDT描述符表中)来管理程序,多个应用程序可共享或独享一个局部描述符表LDT,如果希望开启分页机制,则必须准备至少一个页目录项和页表项
;		如果使用4MB页表,那么准备一个页目录即可
;	2.中断和异常
;		在保护模式下,中断/异常处理程序皆由IDT来管理,IDT由若干个门描述符组成,如果采用中断门或陷阱门,它们可以直接指向异常处理程序,如果采用任务们,则必须为处理程序准备TSS段描述符,额外的代码和数据以及任务段描述符等结构
;		如果处理器允许接收外部中断请求,那么IDT还必须为每个中断处理程序建立门描述符,在使用IDT之前,必须使用LITD将其加载到IDT寄存器,典型的加载时机是处理器切换到保护模式之前
;	3.分页机制
;		CR0的PG标志位用于控制分页机制的开启和关闭,在开启分页机制前,必须在内存中创建一个页目录和页表(此时的页目录和页表不可使用同一物理页),并将页目录的物理地址加载到CR3(PDBR)
;		当上述工作准备就绪后,可同时置位CR0的PE和PG标志位
;	4.多任务机制
;		如果希望使用多任务机制或允许改变特权级,则必须在首次执行任务切换之前创建至少一个任务状态段TSS结构和附加的TSS段描述符,当特权级切换至0,1,2时,栈段寄存器与栈指针寄存器皆从TSS段结构中获得
;		在使用TSS结构之前,必须使用LTR加载至TR寄存器,这个过程只能在进入保护模式之后执行,此表也必须保存在全局描述符表GDT中,而且任务切换不会影响其他段描述符/LDT表/TSS段结构以及TSS段描述符的自由创建
;		只有处理器才能在任务切换时置位TSS段描述符的忙状态位,否则忙状态位始终保持复位状态
;		如果既不想开启多任务机制,也不允许改变特权级,则无需加载TR任务寄存器,也无需创建TSS段结构
;
;
;在处理器切换至保护模式之前,引导加载程序已使用cli禁用外部中断,所以在切换到保护模式的过程中不会产生中断和异常,进而不必完整地初始化IDT,只要有相应的结构即可
;如果能够保证处理器在模式切换的过程中不会产生中断,即使没有IDT也可以
;当保护模式的数据结构准备就绪后,便可着手编写模式切换程序,处理器从实模式进入保护模式的契机是,执行mov汇编指令置位CR0的PE位(同时可置位CR0的PG位以开启分页)
;进入保护模式后,处理器将从0特权级,CPL=0开始执行,为了保证代码在不同种Intel处理器中的前后兼容性,建议遵循下面的步骤执行模式切换操作
;	1.执行cli禁止可屏蔽硬件中断,对于不可屏蔽中断NMI只能借助外部电路才能禁止(模式切换程序必须保证在切换过程中不能产生异常和中断)
;	2.执行LGDT将GDT的基地址和长度加载到GDTR
;	3.执行mov cr0指令置位CR0的PE标志位(可同时置位PG标志位)
;	4.一旦mov cr0指令结束,紧随其后必须执行一条远跳转指令或远调用指令以切换到保护模式的代码段执行(典型的保护模式切换方法)
;	5.通过执行JMP或CALL指令,可改变处理器的流水线,进而使处理器加载执行保护模式的代码段
;	6.如果开启分页机制,那么mov cr0指令和JMP/CALL指令必须位于同一性地址映射的页面内,因为保护模式和分页机制使能后的物理地址,与执行JMP/CALL指令前的线性地址相同
;	  至于JMP/CALL指令的目标地址,则无需进行同一性地址映射
;	7.如需使用LDT,则必须借助LLDT指令将GDT内的LDT段选择子加载到LDTR寄存器
;	8.执行LTR指令将一个TSS段描述符的段选择子加载到TR任务寄存器,处理器对TSS段结构无特殊要求,可写内存空间即可
;	9.进入保护模式之后,数据段寄存器还保留着实模式的段数据,必须重新加载数据段选择子或使用JMP/CALL指令执行新的任务,便可将其更新为保护模式(执行步骤四已经将代码段寄存器更新为保护模式)
;	  对于不使用的数据段寄存器(DS和SS除外),可将NULL段选择子加载到其中
;	10.执行LIDT指令将保护模式下的IDT表的基地址和长度加载到IDTR寄存器
;	11.执行STI指令使能可屏蔽硬件中断,并执行必要的硬件操作使能NMI不可屏蔽中断
;
;		从保护模式进入IA-32e模式
;在进入IA-32e模式之前,处理器依然要为IA-32e模式准备执行代码/必要的数据结构以及配置相关控制寄存器,与此同时还要求处理器只能在开启分页机制的保护模式下切换到IA-32e模式
;	1.系统数据结构
;		当IA-32e模式激活后,系统各描述符表寄存器(GDTR/LDTR/IDTR/TR)依然沿用保护模式的描述符表,由于保护模式的描述符基地址是32位,这使得它们均位于低4GB线性地址空间内
;		既然已经开启IA-32e模式,那么系统各描述符表寄存器必须重新加载为IA-32e模式的64位描述符表
;	2.中断和异常
;		当软件激活IA-32e模式后,IDTR仍然使用保护模式的中断描述符表,那么在将IDTR更新为64位中断描述符表IDT前不要触发中断和异常,否则处理器会把32位兼容模式的中断门解释为64位中断门,从而导致不可预料的后果
;		使用cli禁止可屏蔽硬件中断,不可屏蔽中断NMI只能借助外部电路才能禁止
;IA32_EFER寄存器(位于MSR寄存器组内)的LME标志位用于控制IA-32e模式的开启和关闭,该寄存器会伴随处理器的重启而清零
;IA-32e模式的页管理机制将物理地址扩展为4层页表结构,在IA-32e模式激活之前(CR0.PG=0,处理器运行在32位兼容模式下),CR3仅有低32位可写入数据从而限制页表只能寻址4GB物理内存空间
;也就是在初始化IA-32e模式时,分页机制只能使用前4GB物理地址空间,一旦激活IA-32e模式,软件便可重定位页表到物理内存空间的任何地方
;
;		IA-32e模式的标准初始化步骤
;1.在保护模式下.,使用mov cr0复位CR0的PG位,关闭分页机制(此后的指令必须位于同一性地址映射的页面内)
;2.置位CR4的PAE标志位,开启物理地址扩展功能,在IA-32e模式的初始化过程中,如果PAE开启失败,会产生通用保护性异常#GP
;3.将页目录(顶层页表PML4)的物理基地址加载到CR3
;4.置位IA32_EFER寄存器的LME标志位,开启IA-32e模式
;5.置位CR0的PG位开启分页机制,此时处理器会自动置位IA32_EFER寄存器的LMA标志位,当执行mov cr0开启分页机制时,其后续的指令必须位于同一性地址映射的页面内(直至处理器进入IA-32e模式后才可以使用非同一性地址映射的页面)
;
;如果试图改变IA32_EFER.LME/CR0.PG/CR4.PAE等影响IA-32e模式开启的标志位,处理器会进行64位模式的一致性检测,以确保处理器不会进入未定义模式或不可预测的运行状态
;如果一致性检测失败,会产生通用保护性异常#GP,以下环境会导致一致性检测失败:
;	1.当开启分页机制后,再试图使能或禁止IA-32e模式
;	2.当开启IA-32e模式后,试图在开启物理地址扩展PAE功能前使能分页机制
;	3.在激活IA-32e模式后,试图禁止物理地址扩展PAE功能
;	4.当CS的L位被置位时,再试图激活IA-32e模式,L位是64位代码段标志
;	5.如果TR寄存器加载的是16位TSS段结构
;
;IA-32e模式的段结构和保护模式的段结构极其相似,不过数据显得更为简单,因为IA-32e模式简化了保护模式的段结构,删减掉冗余的段基地址和段限长,使段直接覆盖整个线性地址空间,进而变成平坦地址空间









times 2048-($-$$) db 0



; ; loader.asm
; [BITS 16]          ; 16位实模式
; [ORG 0x10000]       ; Loader 被加载到 0x7E00

; start:
;     ; 打印 Loader 消息
;     mov si, loader_msg
;     call print_string

;     ; 进入保护模式
;     cli
;     lgdt [gdt32_descriptor]

;     ; 启用保护模式
;     mov eax, cr0
;     or eax, 0x1
;     mov cr0, eax

;     ; 远跳转到保护模式代码段
;     jmp 0x08:protected_mode

; print_string:
;     mov ah, 0x0E   ; BIOS 打印字符功能
; .next_char:
;     lodsb          ; 加载下一个字符到 al
;     cmp al, 0      ; 检查字符串结束
;     je .done
;     int 0x10       ; 调用 BIOS 中断打印字符
;     jmp .next_char
; .done:
;     ret

; [BITS 32]
; protected_mode:
;     ; 更新段寄存器
;     mov ax, 0x10
;     mov ds, ax
;     mov ss, ax
;     mov es, ax
;     mov fs, ax
;     mov gs, ax

;     ; 设置栈指针
;     mov esp, 0x9000

;     ; 检查 CPU 是否支持长模式
;     call check_long_mode
;     jc no_long_mode

;     ; 设置分页
;     call setup_paging

;     ; 启用长模式
;     mov ecx, 0xC0000080 ; EFER MSR
;     rdmsr
;     or eax, 0x00000100  ; 设置长模式位
;     wrmsr

;     ; 启用分页
;     mov eax, cr0
;     or eax, 0x80000000  ; 设置 PG 位
;     mov cr0, eax

;     ; 加载 64 位 GDT
;     lgdt [gdt64_descriptor]

;     ; 远跳转到 64 位代码段
;     jmp 0x08:long_mode


; check_long_mode:
;     ; 检查 CPUID 是否支持
;     pushfd
;     pop eax
;     mov ecx, eax
;     xor eax, 0x200000
;     push eax
;     popfd
;     pushfd
;     pop eax
;     xor eax, ecx
;     shr eax, 21
;     and eax, 1
;     push ecx
;     popfd
;     test eax, eax
;     jz .no_cpuid

;     ; 检查长模式是否支持
;     mov eax, 0x80000000
;     cpuid
;     cmp eax, 0x80000001
;     jb .no_long_mode

;     mov eax, 0x80000001
;     cpuid
;     test edx, 1 << 29
;     jz .no_long_mode
;     ret

; .no_cpuid:
;     stc
;     ret

; .no_long_mode:
;     stc
;     ret

; setup_paging:
;     ; 设置 4 级分页表
;     mov eax, p4_table
;     or eax, 0b11 ; 设置 Present 和 Writable 位
;     mov [p4_table + 511 * 8], eax ; 映射最后一个条目到自身

;     mov eax, p3_table
;     or eax, 0b11
;     mov [p4_table], eax

;     mov eax, p2_table
;     or eax, 0b11
;     mov [p3_table], eax

;     ; 映射 2MB 大页
;     mov ecx, 0
; .map_p2_table:
;     mov eax, 0x200000
;     mul ecx
;     or eax, 0b10000011 ; 大页标志
;     mov [p2_table + ecx * 8], eax
;     inc ecx
;     cmp ecx, 512
;     jne .map_p2_table

;     ; 启用分页
;     mov eax, p4_table
;     mov cr3, eax
;     ret



; ; 32 位 GDT
; gdt32_start:
;     dq 0x0000000000000000  ; 空描述符
;     dq 0x00CF9A000000FFFF  ; 代码段描述符
;     dq 0x00CF92000000FFFF  ; 数据段描述符
; gdt32_end:

; gdt32_descriptor:
;     dw gdt32_end - gdt32_start - 1
;     dd gdt32_start

; ; 64 位 GDT
; gdt64_start:
;     dq 0x0000000000000000  ; 空描述符
;     dq 0x00209A0000000000  ; 代码段描述符
;     dq 0x0000920000000000  ; 数据段描述符
; gdt64_end:

; gdt64_descriptor:
;     dw gdt64_end - gdt64_start - 1
;     dq gdt64_start

; ; 分页表
; align 4096
; p4_table:
;     times 4096 db 0
; p3_table:
;     times 4096 db 0
; p2_table:
;     times 4096 db 0