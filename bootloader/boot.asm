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
;|	9f000 ~ A0000	|
;|	 BIOS reserve	|
;|----------------------|
;|	90000 ~ 9f000	|
;|	 kernel tmpbuf	|
;|----------------------|
;|	10000 ~ 90000	|
;|	   LOADER	|
;|----------------------|
;|	8000 ~ 10000	|
;|	  VBE info	|
;|----------------------|
;|	7e00 ~ 8000	|
;|	  mem info	|
;|----------------------|
;|	7c00 ~ 7e00	|
;|	 MBR (BOOT)	|
;|----------------------|
;|	0000 ~ 7c00	|
;|	 BIOS Code	|
;|----------------------|








;_______________________________________________________
; START	END	    SIZE	        USED
; FFFF0	FFFFF	16B	        BIOS System Entry
; F0000	FFFEF	64KB-16B	BIOS System Code
; C8000	EFFFF	160KB	    ROM/Mapped IO
; C0000	C7FFF	32KB	    Graphic Adapter BIOS
; B8000	BFFFF	32KB	    Chroma Text Video Buffer
; B0000	B7FFF	32KB	    Mono Text Video Buffer
; A0000	AFFFF	64KB	    Graphic Video Buffer
; 9FC00	9FFFF	1KB	        Extended BIOS Data Area
; 7E00	9FBFF	622080B     Useable 608KB	
; 7C00	7DFF	512B	    MBR
; 500	7BFF	30464B      Useable 30KB	
; 400	4FF	    256B	    BIOS Data Area
; 000	3FF	    1KB	        IVT
; _____________________________________________________

format binary as 'img'  ; 输出为二进制格式
use16                   ; 使用16位模式（实模式）

org 0x7C00              ; 引导程序加载到 0x7C00

start:
    cli                 ; 禁用中断
    xor ax, ax          ; 清零 ax
    mov ds, ax          ; 设置数据段寄存器
    mov es, ax          ; 设置附加段寄存器
    mov ss, ax          ; 设置栈段寄存器
    mov sp, 0x7C00      ; 设置栈指针

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




    ; ; 绘制一个红色像素 (颜色值 0x04) 在 (x=100, y=100)
    ; mov ax, 0xA000  ; 显存段地址
    ; mov es, ax
    ; mov di, 100 * 320 + 100  ; 计算像素偏移量: y * 320 + x
    ; mov al, 0x04    ; 颜色值 (红色)
    ; mov [es:di], al ; 写入显存


    ; jmp $
;=======	display on screen : Start Booting......

	mov	ax,	1301h
	mov	bx,	000fh
	mov	dx,	0000h
	mov	cx,	10
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartBootMessage
	int	10h

    ; 设置目标地址为 0x10000
    mov ax, 0x1000
    mov es, ax     ; ES = 0x1000
    xor bx, bx     ; BX = 0x0000

    ; 设置 int 0x13 参数
    mov ah, 0x02   ; 功能号：读取扇区
    mov al, 7      ; 读取 7 个扇区
    mov ch, 0      ; 柱面号 0
    mov cl, 2      ; 扇区号 1（LBA 0）
    mov dh, 0      ; 磁头号 0
    mov dl, 0x80   ; 驱动器号：第一个硬盘
    int 0x13       ; 调用 BIOS 中断

    jc disk_error  ; 如果出错，跳转到错误处理

    ; 读取成功，继续执行
    jmp 0x1000:0x0000

disk_error:
    ; 打印错误消息
    mov si, disk_error_msg
    call print_string
    jmp $            ; 停止 CPU

print_string:
    mov ah, 0x0E   ; BIOS 打印字符功能
.next_char:
    lodsb          ; 加载下一个字符到 al
    cmp al, 0      ; 检查字符串结束
    je .done
    int 0x10       ; 调用 BIOS 中断打印字符
    jmp .next_char
.done:
    ret

disk_error_msg db "Disk read error!", 0
StartBootMessage:	db	"Start Boot"

times 510-($-$$) db 0 ; 填充剩余空间
dw 0xAA55             ; 引导扇区结束标志