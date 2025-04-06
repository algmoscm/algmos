%ifndef PRINTK_ASM
%define PRINTK_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/video.asm"
    
[BITS 64]
struc cursor_info
    .print_xpixel:            resw 1      
    .print_ypixel:            resw 1       
    .current_xpixel:          resw 1      
    .current_ypixel:          resw 1
endstruc
cursor_data:
    istruc cursor_info
        at cursor_info.print_xpixel, dw 0
        at cursor_info.print_ypixel, dw 0
        at cursor_info.current_xpixel, dw 0
        at cursor_info.current_ypixel, dw 0
    iend
struc font_info
    .font_base_address:    resq 1
    .font_size:            resq 1
    .font_width:           resq 1
    .font_height:          resq 1
endstruc



printk_init:
    ret

printk:

    ret
putc: ; input: rbx=char,rdi=vga_address ;draw a character
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
            mov al,byte [video_info.byte_per_pixel]

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
        mov ax,word [video_info.xpixel]

        mov r8,rbx
        mov rbx,0
        mov bl,byte [video_info.byte_per_pixel]
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




draw_string:; input: x,y,string; draw string

    mov rax, 0
    mov rax, r9
    mov rbx,0
    mov bx,word [video_info.xpixel]
    imul rax,rbx
    add rax, r8
    mov rbx,0
    mov bl,byte [video_info.byte_per_pixel]
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
        mov bl,byte [video_info.byte_per_pixel]
        imul rbx,8        
        add rdi, rbx
                
        jmp .next_char
    .done:
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

%endif
