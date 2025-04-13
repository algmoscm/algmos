%ifndef PRINTK_ASM
%define PRINTK_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/video.asm"
    
[BITS 64]
    ; struc cursor_info
    ;     .print_xpixel:            resw 1      
    ;     .print_ypixel:            resw 1       
    ;     .current_xpixel:          resw 1      
    ;     .current_ypixel:          resw 1
    ; endstruc
    ; cursor_info_ptr:
    ;     istruc cursor_info
    ;         at cursor_info.print_xpixel, dw 0
    ;         at cursor_info.print_ypixel, dw 0
    ;         at cursor_info.current_xpixel, dw 0
    ;         at cursor_info.current_ypixel, dw 0
    ;     iend

    ; struc font_info
    ;     .font_base_address:    resq 1
    ;     .font_size:            resq 1
    ;     .font_width:           resq 1
    ;     .font_height:          resq 1
    ; endstruc
    ; font_info_ptr:
    ;     istruc font_info
    ;         at font_info.font_base_address, dq 0
    ;         at font_info.font_size, dq 0
    ;         at font_info.font_width, dq 0
    ;         at font_info.font_height, dq 0
    ;     iend

struc print_info
    .cursor_current_xpixel:     resw 1
    .cursor_current_ypixel:     resw 1
    .cursor_current_line:       resw 1

    .cursor_print_xpixel:       resw 1
    .cursor_print_ypixel:       resw 1
    .cursor_print_line:         resw 1
    .cursor_print_address:      resq 1

    .font_base_address:         resq 1
    .font_size:                 resw 1
    .font_width:                resw 1
    .font_height:               resw 1

    .pixel_line_start:          resw 1
    .pixel_per_line:            resw 1 

    .default_color:             resw 1
    .current_color:             resw 1
 endstruc
print_info_ptr:
    istruc print_info
        at print_info.cursor_current_xpixel, dw 0
        at print_info.cursor_current_ypixel, dw 0
        at print_info.cursor_current_line, dw 0

        at print_info.cursor_print_xpixel, dw 0
        at print_info.cursor_print_ypixel, dw 0
        at print_info.cursor_print_line, dw 0
        at print_info.cursor_print_address, dq 0

        at print_info.font_base_address, dq 0
        at print_info.font_size, dw 0
        at print_info.font_width, dw 0
        at print_info.font_height, dw 0

        at print_info.pixel_line_start, dw 0
        at print_info.pixel_per_line, dw 0

        at print_info.default_color, dw 0
        at print_info.current_color, dw 0
    iend

printk_init:

    ; mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.x_resolution
    ; mov rbx,0
    ; mov  bx, word [rsi]
    prolog 0;

    mov word [rel print_info_ptr + print_info.cursor_print_xpixel],0
    mov word [rel print_info_ptr + print_info.cursor_print_ypixel],200
    mov word [rel print_info_ptr + print_info.cursor_print_line],10
    mov qword [rel print_info_ptr + print_info.cursor_print_address],0x5DC00

    mov word [rel print_info_ptr + print_info.cursor_current_xpixel],0
    mov word [rel print_info_ptr + print_info.cursor_current_ypixel],0    
    mov word [rel print_info_ptr + print_info.cursor_current_line],10

    mov rsi,0xFFFF800000105200
    mov qword [rel print_info_ptr + print_info.font_base_address],rsi
    mov word [rel print_info_ptr + print_info.font_size],16
    mov word [rel print_info_ptr + print_info.font_width],8
    mov word [rel print_info_ptr + print_info.font_height],16

    mov word [rel print_info_ptr + print_info.pixel_line_start],4
    mov word [rel print_info_ptr + print_info.pixel_per_line],20

    ; mov word [rel print_info_ptr + print_info.default_color],0x00FFFFFF
    ; mov word [rel print_info_ptr + print_info.current_color],0x00FFFFFF

    epilog

printk:; input: format string,pointer to arguments
    prolog 2
    get_param rsi, 1   ; rsi = format string
    get_param rdx, 2   ; rdx = pointer to arguments

    ; mov word [rel print_info_ptr + print_info.cursor_current_xpixel],0
    ; mov word [rel print_info_ptr + print_info.cursor_current_ypixel],200
    ; mov word [rel print_info_ptr + print_info.cursor_current_line],10
    ; mov word [rel print_info_ptr + print_info.cursor_print_line],10
    ; mov word [rel print_info_ptr + print_info.cursor_print_xpixel],0
    ; mov word [rel print_info_ptr + print_info.cursor_print_ypixel],200

    mov rax, 0
    mov ax, word [rel print_info_ptr + print_info.cursor_print_ypixel]
    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    imul rax,rbx
    mov rcx,0
    mov cx,word [rel print_info_ptr + print_info.cursor_print_xpixel]
    add rax, rcx
    mov rbx,0
    mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    imul rax,rbx
    ; jmp $
    mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    add rdi, rax
    mov rax,0

    .next_char:
        lodsb                  ; Load next character from format string into AL
        test al, al            ; Check if end of string
        jz .done

        cmp al, '%'            ; Check for format specifier
        jne .print_char
    ; jmp $
        lodsb                  ; Load format specifier
        cmp al, 'd'            ; Check for %d
        je .print_decimal
        cmp al, 'x'            ; Check for %x
        je .print_hex
        cmp al, 's'            ; Check for %s
        je .print_string
        jmp .next_char         ; Skip unknown specifier

    .print_char:
        mov rbx, 0
        mov bl, al             ; Character to print

        prepare_call 2,1
        mov qword [rsp+8], rdi
        mov qword [rsp], rbx
        call putc
        cleanup_call 2,1
        mov rax, [rsp-8]

        mov rbx,0
        mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
        imul rbx,8        
        add rdi, rbx

        jmp .next_char

    .print_decimal:
        push rdx               ; Save argument pointer
        mov rax, [rdx]         ; Load integer argument
        add rdx, 8             ; Move to next argument
        call print_decimal     ; Convert and print integer
        pop rdx                ; Restore argument pointer
        jmp .next_char

    .print_hex:
        push rdx               ; Save argument pointer
        mov rax, [rdx]         ; Load integer argument
        add rdx, 8             ; Move to next argument
        call print_hex         ; Convert and print hexadecimal
        pop rdx                ; Restore argument pointer
        jmp .next_char

    .print_string:



            prepare_call 3,1

    mov rsi, [rdx]         ; Load string pointer
    mov qword [rsp+16], rsi

    mov qword [rsp+8], 60
    mov qword [rsp], 0
    call draw_string
    cleanup_call 3,1
    mov rax, [rsp-8]

        push rdx               ; Save argument pointer
        
        add rdx, 8             ; Move to next argument
        call draw_string       ; Print string
        pop rdx                ; Restore argument pointer
        jmp .next_char

    .done:
        epilog

putc: ; input: rbx=char,rdi=vga_address ;draw a character

    prolog 2;
    get_param rbx, 1   ; x
    get_param rdi, 2   ; y

    xor rax, rax
    mov al, bl
    shl rax, 4                 ; 乘以16(每个字符16字节)

    push rsi
    mov rsi, [rel print_info_ptr + print_info.font_base_address]
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
            mov al,byte [rel video_info_ptr + video_info.byte_per_pixel]

            test dl, 0x80       ; 测试最高位
            jz .skip_pixel


            cmp al,4
            jb .pixel_2byte
            mov byte [rdi+2], 0xFF ; 绘制像素(白色)
            mov byte [rdi+3], 0x00 ; 绘制像素(白色)
            .pixel_2byte:
                mov byte [rdi], 0xFF ; 绘制像素(白色)
                mov byte [rdi+1], 0xFF ; 绘制像素(白色)
            ; jmp $
        .skip_pixel:
            shl dl, 1           ; 移到下一位
            add rdi,rax
            dec dh
            jnz .next_pixel
        
        pop rdi                 ; 恢复行起始位置
        xor rax,rax
        mov ax,word [rel video_info_ptr + video_info.xpixel]

        mov r8,rbx
        mov rbx,0
        mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
        imul rax,rbx
        mov rbx,r8
        add rdi,rax; 移到下一行(320=屏幕宽度)
        ; jmp $
        inc rbx                 ; 下一个字模字节

        loop .next_line
                ; jmp $
    pop rdi                 ; 恢复行起始位置
    epilog

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
print_decimal:
    push rbx
    push rcx
    push rdx
    xor rbx, rbx
    mov rbx, 10              ; Base 10
    xor rcx, rcx             ; Digit counter

    .convert_loop:
        xor rdx, rdx
        div rbx              ; Divide rax by 10, remainder in rdx
        push rdx             ; Save remainder (digit)
        inc rcx              ; Increment digit counter
        test rax, rax
        jnz .convert_loop    ; Repeat until rax == 0

    .print_digits:
        pop rdx              ; Get digit from stack
        add dl, '0'          ; Convert to ASCII
        mov rbx, rdx
        prepare_call 2, 1
        mov qword [rsp+8], rdi ; VGA address
        mov qword [rsp], rbx   ; Character
        call putc
        cleanup_call 2, 1
        loop .print_digits

    pop rdx
    pop rcx
    pop rbx
    ret

print_hex:
    push rbx
    push rcx
    push rdx
    mov rcx, 16              ; Process 16 digits (64-bit number)
    .convert_loop:
        rol rax, 4           ; Rotate left by 4 bits
        mov dl, al           ; Extract lower nibble
        and dl, 0x0F         ; Mask to get a single hex digit
        cmp dl, 10
        jl .digit
        add dl, 'A' - 10     ; Convert to 'A'-'F'
        jmp .output
    .digit:
        add dl, '0'          ; Convert to '0'-'9'
    .output:
        mov rbx, rdx
        prepare_call 2, 1
        mov qword [rsp+8], rdi ; VGA address
        mov qword [rsp], rbx   ; Character
        call putc
        cleanup_call 2, 1
        loop .convert_loop

    pop rdx
    pop rcx
    pop rbx
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


flush_framebuffer:
    prolog 0;
    mov rax, 0
    mov ax, word [rel print_info_ptr + print_info.cursor_print_ypixel]
    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    imul rax,rbx
    mov rcx,0
    mov cx,word [rel print_info_ptr + print_info.cursor_print_xpixel]
    add rax, rcx
    mov rbx,0
    mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    imul rax,rbx
    ; jmp $
    mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    add rdi, rax
    mov rax,0
    epilog





draw_char:; input: x,y,char; draw a character
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; char

    mov rax, 0
    mov rax, r9

    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    imul rax,rbx

    mov rcx,0
    mov rcx,r8
    add rax, rcx

    mov rbx,0
    mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    imul rax,rbx
    ; jmp $
    mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    add rdi, rax        ;rdi=屏幕地址


    xor rax, rax
    mov rax,rsi

    shl rax, 4                 ; 乘以16(每个字符16字节)
    mov rbx, [rel print_info_ptr + print_info.font_base_address]
    add rbx, rax         ; RSI = 字符数据地址
    mov rsi,rbx


    mov rcx, 16                ; 16行高度
    push rdi               ; 保存当前行起始位置
    .next_line:
        push rdi               ; 保存当前行起始位置
        
        ; 处理一行(8像素)
        mov dl, [rsi]          ; 获取字模数据
        mov dh, 8              ; 8位/行
        .next_pixel:
            xor rax,rax
            mov al,byte [rel video_info_ptr + video_info.byte_per_pixel]

            test dl, 0x80       ; 测试最高位
            jz .skip_pixel


            cmp al,4
            jb .pixel_2byte
            mov byte [rdi+2], 0xFF ; 绘制像素(白色)
            mov byte [rdi+3], 0x00 ; 绘制像素(白色)
            .pixel_2byte:
                mov byte [rdi], 0xFF ; 绘制像素(白色)
                mov byte [rdi+1], 0xFF ; 绘制像素(白色)
            ; jmp $
        .skip_pixel:
            shl dl, 1           ; 移到下一位
            add rdi,rax
            dec dh
            jnz .next_pixel
        
        pop rdi                 ; 恢复行起始位置

        xor rax,rax
        mov ax,word [rel video_info_ptr + video_info.xpixel]

        mov rbx,0
        mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
        imul rax,rbx
        add rdi,rax
        inc rsi                 ; next char font
        loop .next_line
                ; jmp $
    pop rdi                 ; 恢复行起始位置
    epilog



draw_string:; input: x,y,string; draw string
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; string

    ; mov rax, 0
    ; mov rax, r9
    ; mov rbx,0
    ; mov bx,word [rel video_info_ptr + video_info.xpixel]
    ; imul rax,rbx
    ; add rax, r8

    ; mov rax, 8
    ; mov rbx,0
    ; mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    ; imul rax,rbx

    ; jmp $
    ; mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    ; add rdi, rax
    ; mov rax,0
    ; jmp $
    .next_char:
        lodsb                  
        test al, al
        ; jmp $
        jz .done
        mov rbx, 0
        mov bl, al

        ; prepare_call 2,1
        ; mov qword [rsp+8], rdi
        ; mov qword [rsp], rbx
        ; call putc
        ; cleanup_call 2,1
        ; mov rax, [rsp-8]

        function draw_char,1,r8,r9,rbx
        add r8, 8
        ; mov rbx,0
        ; mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
        ; imul rbx,8        
        ; add rdi, rbx
                
        jmp .next_char
    .done:
    epilog

draw_hex:; input: x,y,hex; draw hex
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; hex

    mov rbx,'0'
    function draw_char,1,r8,r9,rbx
    add r8, 8

    mov rbx, 'x'
    function draw_char,1,r8,r9,rbx    
    add r8, 8


    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov rax, [rsi]
    ; jmp $
    mov rcx, 16              ; Process 16 digits (64-bit number)
    .convert_loopqq:
        rol rax, 4           ; Rotate left by 4 bits
        ; jmp $
        mov dl, al           ; Extract lower nibble

        and dl, 0x0F         ; Mask to get a single hex digit

        cmp dl, 10
        jl .digitqq
        add dl, 'A' - 10     ; Convert to 'A'-'F'
        jmp .outputqq
    .digitqq:
        add dl, '0'          ; Convert to '0'-'9'
    .outputqq:
        mov rbx, rdx

        function draw_char,1,r8,r9,rbx
        
        add r8, 8
        loop .convert_loopqq
        ; .stop:
        ; add rcx,0x1000
        ;     jmp $
    epilog
draw_decimal:; input: x,y,dec; draw dec
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; dec

    mov rax, 0
    mov ax, word [rel print_info_ptr + print_info.cursor_print_ypixel]
    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    imul rax,rbx
    mov rcx,0
    mov cx,word [rel print_info_ptr + print_info.cursor_print_xpixel]
    add rax, rcx
    mov rbx,0
    mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    imul rax,rbx
    ; jmp $
    mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    add rdi, rax
    mov rax,0
    epilog
%endif