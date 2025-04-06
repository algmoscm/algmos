%ifndef VIDEO_ASM
%define VIDEO_ASM
%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]
struc video_info
    ; .start:
    .xpixel:            resw 1      
    .ypixel:            resw 1       
    .byte_per_pixel:    resb 1     
    .video_framebuffer: resq 1
    ; .end:
endstruc
video_data:
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
    mov word [rel video_data + video_info.xpixel],bx

    mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.y_resolution
    mov rbx,0
    mov  bx, word [rsi]
    mov word [rel video_data + video_info.ypixel],bx

    mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.bits_per_pixel
    mov rbx,0
    mov bl, byte [rsi]
    shr bl,3
    mov byte [rel video_data + video_info.byte_per_pixel],bl

    ; mov rsi,KernelSpaceUpperAddress + VBEModeStructBufferAddr + vbe_mode_info_block.y_resolution
    ; mov rbx,0
    ; mov  bx, word [rsi]
    mov rsi,VideoFrameBufferAddress
    mov qword [rel video_data + video_info.video_framebuffer],rsi

    ret

draw_pixel:; Input: rdi = x, rsi = y, rdx = color

    prolog 2;
    get_param rdi, 1   ; a
    get_param rsi, 2   ; b
    get_param rdx, 3   ; c
    push rdx
    ; mov []
    lea rbx, [rel video_data] ; Load video info structure address



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

draw_line:
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