[BITS 64]          ; 16位实模式
[ORG 0xFFFF800000106200]       ; BIOS 加载引导扇区到 0x7C00

; kernel_start:


;        mov rdi, 0xffff8000000B8000
;         mov rax,0
;         mov rbx,0
;         mov rcx,512
;         mov rsi,0xffff800000008200
;         call print_hex_str
; jmp $

    mov rsi,0xFFFF800000008400
    mov rbx,0
    mov  bx, word [rsi]
    mov word [xpixel],bx
; jmp $
    mov rsi,0xFFFF800000008402
    mov rbx,0
    mov  bx, word [rsi]
    mov word [ypixel],bx

    mov rsi,0xFFFF800000008406
    mov rbx,0
    mov bl, byte [rsi]
    shr bl,3
    mov byte [byte_per_pixel],bl

; ypixel
; byte_per_pixel


mov r8, 0
mov r9, 20
mov rsi, messages
call draw_string


mov rdi, 0xFFFF800003000000
mov rax,0
mov rbx,40
mov rcx,30
mov rsi,0xffff800000008800
call print_hex_str

;  call print_hex_byte


jmp $


; draw string
; input: x,y,string
draw_string:

    mov rax, 0
    mov rax, r9
    mov rbx,0
    mov bx,word [xpixel]
    imul rax,rbx
    add rax, r8
    mov rbx,0
    mov bl,byte [byte_per_pixel]
    imul rax,rbx
    ; jmp $
    mov rdi, 0xFFFF800003000000 ; 帧缓冲区起始地址
    add rdi, rax
    mov rax,0
    ; jmp $
    .next_char:
        lodsb                  
        test al, al
        ; jmp $
        jz .done
        mov rbx, 0
        mov bl, al

        call putc  
        mov rbx,0
        mov bl,byte [byte_per_pixel]
        imul rbx,8        
        add rdi, rbx
                   
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
    mov rcx, 16                ; 16行高度
    push rdi               ; 保存当前行起始位置
    .next_line:
        push rdi               ; 保存当前行起始位置
        
        ; 处理一行(8像素)
        mov dl, [rbx]          ; 获取字模数据
        mov dh, 8              ; 8位/行
        .next_pixel:
            xor rax,rax
            mov al,byte [byte_per_pixel]

            test dl, 0x80       ; 测试最高位
            jz .skip_pixel


            cmp al,4
            jb .pixel_2byte
            mov byte [rdi+2], 0x00 ; 绘制像素(白色)
            mov byte [rdi+3], 0xff ; 绘制像素(白色)
            .pixel_2byte:
                mov byte [rdi], 0xff ; 绘制像素(白色)
                mov byte [rdi+1], 0x00 ; 绘制像素(白色)
            ; jmp $
        .skip_pixel:
            shl dl, 1           ; 移到下一位
            add rdi,rax
            dec dh
            jnz .next_pixel
        
        pop rdi                 ; 恢复行起始位置
        xor rax,rax
        mov ax,word [xpixel]

        mov r8,rbx
        mov rbx,0
        mov bl,byte [byte_per_pixel]
        imul rax,rbx
        mov rbx,r8
        add rdi,rax; 移到下一行(320=屏幕宽度)
        ; jmp $
        inc rbx                 ; 下一个字模字节

        loop .next_line
                ; jmp $
    pop rdi                 ; 恢复行起始位置
    ret

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

    push rax
    mov rax,    1920
    mul rbx
    mov rbx,rax
    pop rax
    add rax ,rbx
    mov rbx,rax

    mov rax,4
    mul rbx
    add rdi, rax

    .str:
        push rcx
        call print_hex_byte

        inc rsi
        call print_hex_byte
                ; jmp $
        inc rsi
        add rdi,32
        pop rcx
        dec rcx
        cmp rcx, 0
        jne .str
    .done:
        ret
print_hex_byte:
        xor rax,rax
        xor rbx,rbx
        mov bl, [rsi]
        .h4:
            mov al, bl
            shr al, 4

            cmp al, 10
            jl .digit_h4
            add al, 'A'-'0'-10   ; 转换为A-F
            .digit_h4:
                add al, '0'          ; 转换为0-9
                mov bl, al
                call putc
                ; mov [rdi], al
                ; add rdi,2
                add rdi,32

        .l4:
                xor rax,rax
        xor rbx,rbx
        mov bl, [rsi]
            mov al, bl
            and al, 0x0F
; jmp $
            cmp al, 10
            jl .digit_l4
            add al, 'A'-'0'-10   ; 转换为A-F
            .digit_l4:
                add al, '0'          ; 转换为0-9
                mov bl, al
                call putc
                add rdi,32
                ; mov [rdi], al
                ; add rdi,2
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

xpixel:   dw 0
ypixel:   dw 0
byte_per_pixel:   db 0

messages: db 'codfjgcg', 0
messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0
messages2: times 10 db 0