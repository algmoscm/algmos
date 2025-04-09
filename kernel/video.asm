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
    prolog 0;
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

    epilog

draw_pixel:; Input: x,y,color
    prolog 2;
    get_param rdi, 1   ; x
    get_param rsi, 2   ; y
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

draw_line:; Bresenham's line algorithm Input: x1,y1,x2,y2,color
    prolog 2;
    get_param rdi, 1    ; x1
    get_param rsi, 2    ; y1
    get_param rdx, 3    ; x2
    get_param rcx, 4    ; y2
    get_param r8,  5    ; color

    ; Calculate dx and dy
    mov r9, rdx         ; r9 = x2
    sub r9, rdi         ; dx = x2 - x1
    mov r10, rcx        ; r10 = y2
    sub r10, rsi        ; dy = y2 - y1

    ; Determine the absolute values of dx and dy
    mov r11, r9         ; r11 = dx
    test r11, r11
    jns .dx_positive
    neg r11             ; r11 = abs(dx)
    .dx_positive:
        mov r12, r10        ; r12 = dy
        test r12, r12
        jns .dy_positive
        neg r12             ; r12 = abs(dy)
    .dy_positive:

        ; Determine the direction of the line
        mov r13, 1          ; x_step = 1
        test r9, r9
        jns .x_step_positive
        mov r13, -1         ; x_step = -1
    .x_step_positive:
        mov r14, 1          ; y_step = 1
        test r10, r10
        jns .y_step_positive
        mov r14, -1         ; y_step = -1
    .y_step_positive:

    cmp r11, r12        ; Compare abs(dx) and abs(dy)
    jge .steep_x        ; If abs(dx) >= abs(dy), use x-major line
    mov r15, r11        ; error = abs(dx)
    shl r15, 1          ; error = 2 * abs(dx)
    sub r15, r12         ; error = 2 * abs(dx) - abs(dy)

    mov r9, r11         ; r9 = abs(dx)
    shl r9, 1           ; delta_error = 2 * abs(dx)

    mov r10,r9
    push r15
    mov r15, r12
    shl r15, 1           ; delta_error = 2 * abs(dy)
    sub r10,r15
    pop r15
    jmp .draw_loop_dy
    .steep_x:
        mov r15, r12        ; error = abs(dy)
        shl r15, 1          ; error = 2 * abs(dy)
        sub r15, r11         ; error = 2 * abs(dy) - abs(dx)

        mov r9, r12         ; r9 = abs(dy)
        shl r9, 1           ; delta_error = 2 * abs(dy)

        mov r10,r9
        push r15
        mov r15, r11
        shl r15, 1           ; delta_error = 2 * abs(dx)
        sub r10,r15
        pop r15
        jmp .draw_loop_dx
    .draw_loop_dy:
        cmp rsi, rcx        ; Compare y1 with y2
        je .done            ; If both match, we're done

        cmp r15,0
        jge .yup1
        add rsi, r14        ; y += y_step
        add r15,r9
        jmp .ydrawloop
        .yup1:
            add rdi, r13        ; x += x_step
            add rsi, r14        ; y += y_step
            add r15,r10
        .ydrawloop:
            ; Draw the current pixel
            prepare_call 3,1
            mov qword [rsp+16], r8
            mov qword [rsp+8], rsi
            mov qword [rsp], rdi
            call draw_pixel
            cleanup_call 3,1
            ; mov rax, [rsp-8]
            jmp .draw_loop_dy            ; If both match, we're done

    .draw_loop_dx:
        cmp rdi, rdx        ; Compare y1 with y2
        je .done            ; If both match, we're done

        cmp r15,0
        jge .xup1
        add rdi, r13        ; y += y_step
        add r15,r9
        jmp .xdrawloop
        .xup1:
            add rdi, r13        ; x += x_step
            add rsi, r14        ; y += y_step
            add r15,r10
        .xdrawloop:
            ; Draw the current pixel
            prepare_call 3,1
            mov qword [rsp+16], r8
            mov qword [rsp+8], rsi
            mov qword [rsp], rdi
            call draw_pixel
            cleanup_call 3,1
            ; mov rax, [rsp-8]
            jmp .draw_loop_dx            ; If both match, we're done
        
    .done:
        set_ret_param rcx,6
        epilog

draw_rect:; Input: x1,y1,x2,y2,color
    prolog 2;
    get_param rdi, 1    ; x1
    get_param rsi, 2    ; y1
    get_param rdx, 3    ; x2
    get_param rcx, 4    ; y2
    get_param r8,  5    ; color
    ; jmp $
    .line1:
        prepare_call 5,1
        mov qword [rsp+32], 0x00FFFFFF
        mov qword [rsp+24], rsi
        mov qword [rsp+16], rdx

        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        call draw_line
        cleanup_call 5,1
        mov rax, [rsp-8]
    .line2:
        prepare_call 5,1
        mov qword [rsp+32], 0x00FFFFFF
        mov qword [rsp+24], rcx
        mov qword [rsp+16], rdx

        mov qword [rsp+8], rsi
        mov qword [rsp], rdx
        call draw_line
        cleanup_call 5,1
        mov rax, [rsp-8]
    .line3:
        prepare_call 5,1
        mov qword [rsp+32], 0x00FFFFFF
        mov qword [rsp+24], rcx
        mov qword [rsp+16], rdi

        mov qword [rsp+8], rcx
        mov qword [rsp], rdx
        call draw_line
        cleanup_call 5,1
        mov rax, [rsp-8]
    .line4:
        prepare_call 5,1
        mov qword [rsp+32], 0x00FFFFFF
        mov qword [rsp+24], rsi
        mov qword [rsp+16], rdi

        mov qword [rsp+8], rcx
        mov qword [rsp], rdi
        call draw_line
        cleanup_call 5,1
        mov rax, [rsp-8]
    .done:
        set_ret_param rcx,6
        epilog

draw_screen:;Input:color
    prolog 2;

    get_param rdi, 1   ; x

    lea rbx, [rel video_info_ptr] ; Load video info structure address
    ; Calculate pixel offset
    mov rax,0
    movzx rax, word [rbx + video_info.xpixel] ; Screen width

    mov rcx,0
    movzx rcx, word [rbx + video_info.ypixel] ; Screen height

    mul rcx

    mov rcx,rax
    movzx rdx, byte [rbx + video_info.byte_per_pixel] ; Bytes per pixel
    mul rdx                          ; Offset = (y * width + x) * bytes_per_pixel

    mov rbx, qword [rbx + video_info.video_framebuffer] ; Framebuffer address
    add rbx,rax
    .write_color:
        ; Write color to framebuffer
        
        mov dword [rbx], edi                        ; Write color (assumes 32-bit color)
        sub rbx,4                          ; rbx = framebuffer + offset
        loop .write_color

        ; jmp $
    set_ret_param rax,2

    epilog


draw_triangle: ; Input: x1, y1, x2, y2, x3, y3, color
    prolog 2;
    get_param rdi, 1    ; x1
    get_param rsi, 2    ; y1
    get_param rdx, 3    ; x2
    get_param rcx, 4    ; y2
    get_param r8,  5    ; x3
    get_param r9,  6    ; y3
    get_param r10, 7    ; color

    ; Draw line from (x1, y1) to (x2, y2)
    prepare_call 5, 1
    mov qword [rsp+32], r10 ; color
    mov qword [rsp+24], rcx ; y2
    mov qword [rsp+16], rdx ; x2
    mov qword [rsp+8], rsi  ; y1
    mov qword [rsp], rdi    ; x1
    call draw_line
    cleanup_call 5, 1

    ; Draw line from (x2, y2) to (x3, y3)
    prepare_call 5, 1
    mov qword [rsp+32], r10 ; color
    mov qword [rsp+24], r9  ; y3
    mov qword [rsp+16], r8  ; x3
    mov qword [rsp+8], rcx  ; y2
    mov qword [rsp], rdx    ; x2
    call draw_line
    cleanup_call 5, 1

    ; Draw line from (x3, y3) to (x1, y1)
    prepare_call 5, 1
    mov qword [rsp+32], r10 ; color
    mov qword [rsp+24], rsi ; y1
    mov qword [rsp+16], rdi ; x1
    mov qword [rsp+8], r9   ; y3
    mov qword [rsp], r8     ; x3
    call draw_line
    cleanup_call 5, 1

    set_ret_param rax, 8
    epilog

draw_circle: ; Input: x_center, y_center, radius, color
    prolog 2;
    get_param rdi, 1    ; x_center
    get_param rsi, 2    ; y_center
    get_param rdx, 3    ; radius
    get_param rcx, 4    ; color

    ; Initialize variables
    mov r8, 0           ; x = 0
    mov r9, rdx         ; y = radius
    mov r10, 3          ; decision = 1 - radius
    mov rax, rdx         ; r = radius
    mov rbx,2
    mul rbx
    sub r10,rax
    ; d = 3 - 2 * r;

    .circle_loop:
        ; Draw the 8 symmetric points of the circle
        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        add qword [rsp], r8
        add qword [rsp+8], r9
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        sub qword [rsp], r8
        add qword [rsp+8], r9
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        add qword [rsp], r8
        sub qword [rsp+8], r9
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        sub qword [rsp], r8
        sub qword [rsp+8], r9
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        add qword [rsp], r9
        add qword [rsp+8], r8
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        sub qword [rsp], r9
        add qword [rsp+8], r8
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        add qword [rsp], r9
        sub qword [rsp+8], r8
        call draw_pixel
        cleanup_call 3, 1

        prepare_call 3, 1
        mov qword [rsp+16], rcx
        mov qword [rsp+8], rsi
        mov qword [rsp], rdi
        sub qword [rsp], r9
        sub qword [rsp+8], r8
        call draw_pixel
        cleanup_call 3, 1

        ; Update decision parameter and coordinates


        ;     if (d < 0) {
        ;         d = d + 4 * x + 6;
        ;     } else {
        ;         d = d + 4 * (x - y) + 10;
        ;         y --;
        ;     }
        ;     x ++;
        ; }
        ; r10
        cmp r10, 0
        jl .update_y
        mov rax, r8
        sub rax, r9
        
        mov rbx,4
        mul rbx
        add rax,10
        add r10, rax         ; d = d + 4 * (x - y) + 10;

        sub r9, 1           ; y--
        jmp .update_x
        .update_y:
            mov rax, r8

            mov rbx,4
            mul rbx

            add rax,6
            add r10, rax         ;d = d + 4 * x + 6;
        .update_x:
            add r8, 1           ; x++
            cmp r8, r9
            jle .circle_loop

        set_ret_param rax, 5
        epilog

%endif