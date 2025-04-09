[BITS 16]          ; 16位实模式
[ORG 0x7C00]       ; BIOS 加载引导扇区到 0x7C00    
    cli                 ; 禁用中断
    xor ax, ax          ; 清零 ax
    mov ds, ax          ; 设置数据段寄存器
    mov es, ax          ; 设置附加段寄存器
    mov ss, ax          ; 设置栈段寄存器
    mov sp, 0x7C00      ; 设置栈指针

;--------------------clear screen------------------;
;--------------------------------------------------;
	mov	ax,	0600h
	mov	bx,	0700h
	mov	cx,	0
	mov	dx,	0184fh
	int	10h

;---------------------set focus--------------------;
;--------------------------------------------------;
	mov	ax,	0200h
	mov	bx,	0000h
	mov	dx,	0000h
	int	10h

    ; 读取硬盘加载 Loader

            ; 设置目标地址为 0x10000
    mov ax, 0x1000
    mov es, ax     ; ES = 0x1000
    xor bx, bx     ; BX = 0x0000

    mov eax, 1
    mov ecx, 7

   .loop_read:
         call read_hard_disk_0
         inc eax
         loop .loop_read        

    ; call read_hard_disk_0

    ; 跳转执行内核加载器 Loader
    jmp 0x1000:0x0000
    ; 读取成功，继续执行

; ---------------------------------
; LBA 磁盘读取 (16 位)
; ---------------------------------
read_hard_disk_0:                                     ;从硬盘读取一个逻辑扇区
                                                      ;EAX=逻辑扇区号
                                                      ;EBX=目标缓冲区地址
                                                      ;返回：EBX=EBX+512
         push ax
         push cx
         push dx

         push ax

         mov dx, 0x1F2
         mov al, 1
         out dx, al                                   ;读取的扇区数

         inc dx                                       ;0x1f3
         pop ax
         out dx, al                                   ;LBA地址7~0

         inc dx                                       ;0x1f4
         mov cl, 8
         shr ax, cl
         out dx, al                                   ;LBA地址15~8

         inc dx                                       ;0x1f5
         shr ax, cl
         out dx, al                                   ;LBA地址23~16

         inc dx                                       ;0x1f6
         shr ax, cl
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

         mov cx, 256                                 ;总共要读取的字数
         mov dx, 0x1F0
  .readw:
         in ax, dx
         mov [es:bx], ax
         add bx, 2
         loop .readw

         pop dx
         pop cx
         pop ax

         ret

message db "Master Boot Record Started!", 0

;-----------------------------------
; MBR 结束标志
;-----------------------------------
times 510-($-$$) db 0
dw 0xAA55
