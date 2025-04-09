%ifndef VIDEO_ASM
%define VIDEO_ASM
%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]
struc video_info
    .start:
    .xpixel:            resw 1      
    .ypixel:            resw 1       
    .byte_per_pixel:    resb 1     
    .video_framebuffer: resq 1
    .end:
endstruc
video_info_ptr:
    istruc video_info
        at video_info.xpixel, dw 0
        at video_info.ypixel, dw 0
        at video_info.byte_per_pixel, db 0
        at video_info.video_framebuffer, dq 0
    iend
;argb
video_init:
    mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.x_resolution
    mov rbx,0
    mov  bx, word [rsi]
    mov word [rel video_info_ptr + video_info.xpixel],bx

    mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.y_resolution
    mov rbx,0
    mov  bx, word [rsi]
    mov word [rel video_info_ptr + video_info.ypixel],bx

    mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.bits_per_pixel
    mov rbx,0
    mov bl, byte [rsi]
    shr bl,3
    mov byte [rel video_info_ptr + video_info.byte_per_pixel],bl

    ; mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.y_resolution
    ; mov rbx,0
    ; mov  bx, word [rsi]
    mov rsi,VideoFrameBufferAddress
    mov qword [rel video_info_ptr + video_info.video_framebuffer],rsi

    ret

draw_pixel:; Input: rdi = x, rsi = y, rdx = color

    prolog 2;
    get_param rdi, 1   ; a
    get_param rsi, 2   ; b
    get_param rdx, 3   ; c
    push rdx
    ; mov []
    lea rbx, [rel video_info_ptr] ; Load video info structure address



    ; Calculate pixel offset
    mov rax,0
    movzx rax, word [rbx + video_info.xpixel] ; Screen width

    mul rsi                                 ; y * screen width
        ; jmp $
    add rax, rdi                             ; Add x
    movzx rcx, byte [rbx + video_info.byte_per_pixel] ; Bytes per pixel
    imul rax, rcx                          ; Offset = (y * width + x) * bytes_per_pixel

    ; Write color to framebuffer
    mov rbx, qword [rbx + video_info.video_framebuffer] ; Framebuffer address
    add rbx, rax                          ; rbx = framebuffer + offset

    pop rdx
    mov dword [rbx], edx                        ; Write color (assumes 32-bit color)

        ; jmp $
    set_ret_param rax,4
    epilog

draw_line:; Input: rdi = x1, rsi = y1, rdx = x2, rcx = y2, r8 = color
    push rbx
    push r9
    push r10
    push r11

    ; Calculate dx = abs(x2 - x1)
    mov r9, rdx          ; r9 = x2
    sub r9, rdi          ; r9 = x2 - x1
    mov r10, r9          ; r10 = dx
    test r9, r9
    jge .dx_positive
    neg r10              ; dx = abs(dx)
    .dx_positive:

        ; Calculate dy = abs(y2 - y1)
        mov r11, rcx         ; r11 = y2
        sub r11, rsi         ; r11 = y2 - y1
        mov r9, r11          ; r9 = dy
        test r11, r11
        jge .dy_positive
        neg r9               ; dy = abs(dy)
    .dy_positive:

        ; Determine the direction of the line
        mov r10, 1          ; x_step = 1
        test rdx, rdx
        jge .x_step_positive
        mov r10, -1         ; x_step = -1
    .x_step_positive:

        mov r11, 1          ; y_step = 1
        test rcx, rcx
        jge .y_step_positive
        mov r11, -1         ; y_step = -1
    .y_step_positive:

        ; Initialize error term
        cmp r9, r10          ; Compare dx and dy
        jle .steep_line
        ; Non-steep line (dx > dy)
        mov r8, r10         ; error = dx / 2
        shr r8, 1
        jmp .draw_line_loop
    .steep_line:
        ; Steep line (dy >= dx)
        mov r8, r9          ; error = dy / 2
        shr r8, 1

    .draw_line_loop:
        ; Draw the current pixel
        mov rdi, rdi         ; x
        mov rsi, rsi         ; y
        mov rdx, r8          ; color
        call draw_pixel

        ; Check if we've reached the end
        cmp rdi, rdx         ; x == x2?
        jne .update_x
        cmp rsi, rcx         ; y == y2?
        je .done

    .update_x:
        ; Update x and y based on the error term
        cmp r9, r10          ; Steep or non-steep line?
        jle .update_steep
        ; Non-steep line
        add r8, r9          ; error += dy
        cmp r8, r10         ; error >= dx?
        jl .update_x_only
        sub r8, r10         ; error -= dx
        add rsi, r11         ; y += y_step
    .update_x_only:
        add rdi, r10         ; x += x_step
        jmp .draw_line_loop

    .update_steep:
        ; Steep line
        add r8, r10         ; error += dx
        cmp r8, r9          ; error >= dy?
        jl .update_y_only
        sub r8, r9          ; error -= dy
        add rdi, r10         ; x += x_step
    .update_y_only:
        add rsi, r11         ; y += y_step
        jmp .draw_line_loop

    .done:
        pop r11
        pop r10
        pop r9
        pop rbx
        ret

draw_rect:
    ret

draw_screen:
    ret

fill_screen:
    ret
;-------------------------------------------------
draw_circle:
    ret
draw_triangle:
    ret



%endif