[BITS 64]          ; 16位实模式
[ORG 0xFFFF800000106200]       ; BIOS 加载引导扇区到 0x7C00

; kernel_start:
;     mov rax, 0x120 ; 帧缓冲区起始地址
;     mov rdi, 0xffff800003000000 ; 帧缓冲区起始地址
;     mov rcx, 200

;     .draw_row:
;         push rcx
;         mov rcx, 800        ; 每行像素数
        
;     .draw_pixel:
;         mov dword [rdi], 0x00FFFF00  ; 红色像素 (ARGB: 0x00FF0000)
;         add rdi, 4           ; 移动到下一个像素
;         loop .draw_pixel
;         pop rcx
;         loop .draw_row

;     jmp	$



    mov rsi, 0xFFFF800000105200
; .putc:
;     mov cx,16
;     .line:
;     push rcx
;     mov al,[rsi+16-cx]
;     mov rcx, 8
;     .bit:
;         test al, 1
;         jz .zero
;         mov byte [rdi], 0x0F
;         jmp .next
;     .zero:
;         mov byte [rdi], 0x00
;     .next:
;         add rdi, 2
;         shr al, 1



; 绘制单个字符函数
; 输入: AL=ASCII字符, EDI=屏幕位置
; draw_char:
;     pusha
    
;     ; 计算字库中的字符地址
;     xor ebx, ebx
;     mov bl, al
;     shl ebx, 4                 ; 乘以16(每个字符16字节)
;     mov rbx, 'a'         ; EBX = 字符数据地址
;     mov rdi, 0xffff800003000000 ; 帧缓冲区起始地址
;     call putc
; ; jmp $

mov r8, 0
mov r9, 20
mov rsi, messages
call draw_string

jmp $


; draw string
; input: x,y,string
draw_string:

    mov rax, 0
    mov rax, r9
    imul rax,800
    add rax, r8
    ; jmp $
    mov rdi, 0xFFFF800003000000 ; 帧缓冲区起始地址
    add rdi, rax
    mov rax,0
    .next_char:
        lodsb                  
        test al, al
        jz .done
        mov rbx, 0
        mov bl, al

        call putc          
        add rdi, 8            
        jmp .next_char
    .done:
    ret

; put char
; input: rbx=char,rdi=vga_address
putc: ; draw a character
    xor rax, rax
    mov al, bl
    shl rax, 4                 ; 乘以16(每个字符16字节)

    push rsi
    mov rsi, 0xFFFF800000105200
    add rsi, rax         ; RSI = 字符数据地址
    mov rax,rsi
    mov rbx,rax
    pop rsi

    mov ecx, 16                ; 16行高度
    push rdi               ; 保存当前行起始位置
    .next_line:
        push rdi               ; 保存当前行起始位置
        
        ; 处理一行(8像素)
        mov dl, [rbx]          ; 获取字模数据
        mov dh, 8              ; 8位/行
        .next_pixel:
            test dl, 0x80       ; 测试最高位
            jz .skip_pixel
            mov byte [rdi], 0x33 ; 绘制像素(白色)
        .skip_pixel:
            shl dl, 1           ; 移到下一位
            inc rdi             ; 下一个像素位置
            dec dh
            jnz .next_pixel
        
        pop rdi                 ; 恢复行起始位置
        add rdi, 800            ; 移到下一行(320=屏幕宽度)
        inc rbx                 ; 下一个字模字节
        loop .next_line
    pop rdi                 ; 恢复行起始位置
    ret

    ; 绘制一个红色像素 (颜色值 0x04) 在 (x=100, y=100)

        ; mov rdi, 0xffff8000000B8000 ; 帧缓冲区起始地址
        ; mov dword   [rdi], 'abcd'  ; 红色像素 (ARGB: 0x00FF0000)
        
        ; mov es, ax
        ; mov di, 100 * 320 + 100  ; 计算像素偏移量: y * 320 + x
        ; mov al, 0x04    ; 颜色值 (红色)
        ; mov byte [es:di], al ; 写入显存

        ; mov rdi, 0xffff8000000B8000
        ; mov rax,2
        ; mov rbx,0
        ; mov rcx,3
        ; mov rsi,messages
        ; call print

        ; mov rdi, 0xffff8000000B8000
        ; mov rax,0
        ; mov rbx,0
        ; mov rcx,512
        ; mov rsi,0xffff800000008000
        ; call print_hex_str

        ; mov rdi, 0xffff8000000B8000
        ; mov rax,0
        ; mov rbx,0
        ; mov rcx,512
        ; mov rsi,0xffff800003009229
        ; call print_hex_str

        ; mov rdi, 0xffff8000000B8000
        ; mov rax,5
        ; mov rbx,0
        ; mov rcx,200
        ; mov rsi,0x8022
        ; call print_hex_str


        ; mov rdi, 0xffff8000000B8000
        ; mov rax,0
        ; mov rbx,0
        ; mov rcx,512
        ; mov rsi,0xc0009160
        ; call print_hex_str


; 		and	al,	0Fh
; 		cmp	al,	9
; 		ja	.1
; 		add	al,	'0'
; 		jmp	.2
; 	.1:

; 		sub	al,	0Ah
; 		add	al,	'A'
; 	.2:

; 		mov	[gs:edi],	ax
; 		add	edi,	2
		
; 		mov	al,	dl
; 		loop	.begin

; 		mov	[DisplayPosition],	edi

; 		pop	edi
; 		pop	edx
; 		pop	ecx
		
; 		ret




        jmp	$

print:
    cmp rcx, 0
    je .done
    push rbx
    mov rbx,    160
    mul rbx
    add rdi, rax
    pop rbx
    .str:
        mov al, [rsi]
        mov [rdi], al
        add rdi,2
        inc rsi
        dec rcx
        cmp rcx, 0
        jne .str
    .done:
        ret

print_hex_str:
    cmp rcx, 0
    je .done

    push rbx
    mov rbx,    160
    mul rbx
    add rdi, rax
    pop rbx
    .str:

        call print_hex_byte
        inc rsi
        call print_hex_byte
        inc rsi
        add rdi,2
        dec rcx
        cmp rcx, 0
        jne .str
    .done:
        ret
print_hex_byte:
        mov bl, [rsi]
        .h4:
            mov al, bl
            shr al, 4

            cmp al, 10
            jl .digit_h4
            add al, 'A'-'0'-10   ; 转换为A-F
            .digit_h4:
                add al, '0'          ; 转换为0-9
                mov [rdi], al
                add rdi,2

        .l4:
            mov al, bl
            and al, 0x0F

            cmp al, 10
            jl .digit_l4
            add al, 'A'-'0'-10   ; 转换为A-F
            .digit_l4:
                add al, '0'          ; 转换为0-9
                mov [rdi], al
                add rdi,2
        ret

print_string:
    add rdi, rax
    .str:
        mov al, [rsi]
        cmp al, 0
        je .done
        mov [rdi], al
        add rdi,2
        inc rsi
        jmp .str
    .done:
        ret

    ; call draw_rectangle
    jmp	$

messages: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0
messages2: times 10 db 0