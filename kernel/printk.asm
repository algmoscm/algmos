%ifndef PRINTK_ASM
%define PRINTK_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/video.asm"
    
[BITS 64]

%define COLOR_WHITE 	0x00ffffff		;WHITE
%define COLOR_BLACK 	0x00000000		;BLACK
%define COLOR_RED	    0x00ff0000		;RED
%define COLOR_ORANGE	0x00ff8000		;ORANGE
%define COLOR_YELLOW	0x00ffff00		;YELLOW
%define COLOR_GREEN	    0x0000ff00		;GREEN
%define COLOR_BLUE	    0x000000ff		;BLUE
%define COLOR_INDIGO	0x0000ffff		;INDIGO
%define COLOR_PURPLE	0x008000ff		;PURPLE

struc print_info
    .cursor_xposition:     resw 1
    .cursor_yposition:     resw 1
    .cursor_line:          resw 1

    .print_xposition:      resw 1
    .print_yposition:      resw 1
    .print_line:           resw 1
    .print_address:        resq 1

    .screen_xmax:          resw 1
    .screen_ymax:          resw 1

    .font_base_address:    resq 1
    .font_size:            resw 1
    .font_width:           resw 1
    .font_height:          resw 1

    .pixel_line_start:     resw 1
    .pixel_line_height:       resw 1 

    .default_color:        resd 1
    .current_color:        resd 1
 endstruc
print_info_ptr:;
    istruc print_info
        at print_info.cursor_xposition, dw 0
        at print_info.cursor_yposition, dw 0
        at print_info.cursor_line, dw 0

        at print_info.print_xposition, dw 0
        at print_info.print_yposition, dw 0
        at print_info.print_line, dw 0
        at print_info.print_address, dq 0

        at print_info.screen_xmax, dw 0
        at print_info.screen_ymax, dw 0

        at print_info.font_base_address, dq 0
        at print_info.font_size, dw 0
        at print_info.font_width, dw 0
        at print_info.font_height, dw 0

        at print_info.pixel_line_start, dw 0
        at print_info.pixel_line_height, dw 0

        at print_info.default_color, dd 0
        at print_info.current_color, dd 0
    iend

printk_init:;init printk
    prolog 0;

    mov word [rel print_info_ptr + print_info.cursor_xposition],0
    mov word [rel print_info_ptr + print_info.cursor_yposition],0
    mov word [rel print_info_ptr + print_info.cursor_line],0


    mov word [rel print_info_ptr + print_info.print_xposition],0
    mov word [rel print_info_ptr + print_info.print_yposition],0    
    mov word [rel print_info_ptr + print_info.print_line],0
    mov qword [rel print_info_ptr + print_info.print_address],0

    mov word [rel print_info_ptr + print_info.screen_xmax],240
    mov word [rel print_info_ptr + print_info.screen_ymax],54    

    mov rsi,0xFFFF800000105200
    mov qword [rel print_info_ptr + print_info.font_base_address],rsi
    mov word [rel print_info_ptr + print_info.font_size],16
    mov word [rel print_info_ptr + print_info.font_width],8
    mov word [rel print_info_ptr + print_info.font_height],16

    mov word [rel print_info_ptr + print_info.pixel_line_start],4
    mov word [rel print_info_ptr + print_info.pixel_line_height],20

    mov dword [rel print_info_ptr + print_info.default_color],COLOR_WHITE
    mov dword [rel print_info_ptr + print_info.current_color],COLOR_WHITE

    epilog

printk:; input: format string,pointer to arguments

    prolog 2
    get_param rsi, 1   ; rsi = format string
    get_param rdx, 2   ; rdx = pointer to arguments

    mov rax,0

    .next_char:
        lodsb                  ; Load next character from format string into AL
        test al, al            ; Check if end of string
        jz .done

        cmp al, '\'           ; Check for escape character
        je .escape_character

        cmp al, '%'            ; Check for format specifier
        jne .print_char
        lodsb                  ; Load format specifier
        cmp al, 'd'            ; Check for %d
        je .print_decimal
        cmp al, 'x'            ; Check for %x
        je .print_hex
        cmp al, 's'            ; Check for %s
        je .print_string
        jmp .next_char         ; Skip unknown specifier

    .print_char:
        function print_char,1,rax
        jmp .next_char

    .print_decimal:
        function print_decimal,1,rdx
        jmp .next_char

    .print_hex:
        function print_hex,1,rdx
        jmp .next_char

    .print_string:

        function print_string,1,rdx
        jmp .next_char

    .escape_character:
        lodsb                  ; Load next character from string into AL
        cmp al, 'n'            ; Check for %d
        je .new_line
        jmp .escape_done
        .new_line:
            add word [rel print_info_ptr + print_info.print_yposition],1
            mov word [rel print_info_ptr + print_info.print_xposition],0
        .escape_done:
            jmp .next_char           

    .done:
        epilog

print_char:; input:char
    prolog 2;

    get_param rsi, 1   ; char



    mov rax, 0
    mov ax, word [rel print_info_ptr + print_info.print_yposition]

    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    mul rbx


    mov rbx,0
    mov bx,word [rel print_info_ptr + print_info.pixel_line_height]
    mul rbx

    push rax
    xor rax,rax
    mov ax,word [rel print_info_ptr + print_info.print_xposition]
    mov rbx,0
    mov bx,word [rel print_info_ptr + print_info.font_width]
    mul rbx


    mov rcx,0
    pop rcx
    add rax, rcx

    mov rbx,0
    mov bl,byte [rel video_info_ptr + video_info.byte_per_pixel]
    mul rbx

    mov rdi, qword [rel video_info_ptr + video_info.video_framebuffer]
    add rdi, rax        ;rdi=屏幕地址


    shl rsi, 4

    mov rbx,0
    mov rbx, [rel print_info_ptr + print_info.font_base_address]
    add rsi, rbx        ; RSI = 字符数据地址

    xor rcx,rcx
    mov cx, word [rel print_info_ptr + print_info.font_height]

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
        mul rbx

        add rdi,rax; 移到下一行(320=屏幕宽度)

        inc rsi                 ; 下一个字模字节

        loop .next_line
    
    add word [rel print_info_ptr + print_info.print_xposition],1
    epilog

print_decimal:;input:rsi=decimal number

    prolog 2;

    get_param rsi, 1   ; dec

    ; mov rbx, 'D'
    ; function print_char,1,rbx    

    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov rax, [rsi]

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
        function print_char,1,rbx    

        loop .print_digits

    epilog


print_hex:;input:rsi=hex number

    prolog 2;

    get_param rsi, 1   ; dec

    ; mov rbx, 'X'
    ; function print_char,1,rbx    

    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov rax, [rsi]

    mov rcx, 16              ; Process 16 digits (64-bit number)
    .convert_loop:
        rol rax, 4           ; Rotate left by 4 bits
        mov dl, al           ; Extract lower nibble
        and dl, 0x0F         ; Mask to get a single hex digit
        cmp dl, 10
        jl .digit
        add dl, 'a' - 10     ; Convert to 'A'-'F'
        jmp .output
    .digit:
        add dl, '0'          ; Convert to '0'-'9'
    .output:
        mov rbx, rdx
        function print_char,1,rbx    
        loop .convert_loop
    epilog



print_string:;input: string
    prolog 2;
    get_param rsi, 1   ; string

    xor rax,rax
    .next_char_t:
        lodsb                  ; Load next character from string into AL
        test al, al            ; Check if end of string
        jz .done_t

        cmp al, '\'           ; Check for escape character
        je .escape_character

        function print_char,1,rax

        jmp .next_char_t
        .escape_character:
            lodsb                  ; Load next character from string into AL
            cmp al, 'n'            ; Check for %d
            je .new_line
            jmp .escape_done
            .new_line:
                add word [rel print_info_ptr + print_info.print_yposition],1
                mov word [rel print_info_ptr + print_info.print_xposition],0
            .escape_done:
                jmp .next_char_t            
    .done_t:
    epilog
flush_framebuffer:;flush framebuffer
    prolog 0;
    mov rax, 0
    mov ax, word [rel print_info_ptr + print_info.print_yposition]
    mov rbx,0
    mov bx,word [rel video_info_ptr + video_info.xpixel]
    imul rax,rbx
    mov rcx,0
    mov cx,word [rel print_info_ptr + print_info.print_xposition]
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
            jmp .pixel_write_done
        .skip_pixel:
            mov byte [rdi+2], 0x00 ; 绘制像素(白色)
            mov byte [rdi+3], 0x00 ; 绘制像素(白色)
            mov byte [rdi], 0x00 ; 绘制像素(白色)
            mov byte [rdi+1], 0x00 ; 绘制像素(白色)
            .pixel_write_done:
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

    .next_char:
        lodsb                  
        test al, al
        jz .done
        mov rbx, 0
        mov bl, " "
        function draw_char,1,r8,r9,rbx ;clear char
        mov rbx, 0
        mov bl, al
        function draw_char,1,r8,r9,rbx
        add r8, 8

        jmp .next_char
    .done:
    epilog

draw_hex:; input: x,y,hex; draw hex
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; hex

    mov rbx, 'X'
    function draw_char,1,r8,r9,rbx    
    add r8, 8


    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov rax, [rsi]

    mov rcx, 16              ; Process 16 digits (64-bit number)
    .convert_loopqq:
        rol rax, 4           ; Rotate left by 4 bits
        mov dl, al           ; Extract lower nibble

        and dl, 0x0F         ; Mask to get a single hex digit

        cmp dl, 10
        jl .digitqq
        add dl, 'a' - 10     ; Convert to 'A'-'F'
        jmp .outputqq
    .digitqq:
        add dl, '0'          ; Convert to '0'-'9'
    .outputqq:
        mov rbx, rdx

        function draw_char,1,r8,r9,rbx
        
        add r8, 8
        loop .convert_loopqq

    epilog
draw_decimal:; input: x,y,decimal address; draw dec
    prolog 2;
    get_param r8, 1   ; x
    get_param r9, 2   ; y
    get_param rsi, 3   ; dec

    mov rbx, 'D'
    function draw_char,1,r8,r9,rbx    
    add r8, 8

    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov rax, [rsi]

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
        function draw_char,1,r8,r9,rbx    
        add r8, 8

        loop .print_digits

    epilog
; debug_stop:
;     mov r15,0x99999
;     jmp $
%endif