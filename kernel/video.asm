[BITS 64]
xpixel:   dw 0
ypixel:   dw 0
byte_per_pixel:   db 0
; byte_per_pixel:   db 0

video_init:
    mov rsi,0xFFFF800000008400
    mov rbx,0
    mov  bx, word [rsi]
    mov word [xpixel],bx

    mov rsi,0xFFFF800000008402
    mov rbx,0
    mov  bx, word [rsi]
    mov word [ypixel],bx

    mov rsi,0xFFFF800000008406
    mov rbx,0
    mov bl, byte [rsi]
    shr bl,3
    mov byte [byte_per_pixel],bl
    ret

draw_pixel:
    ; jmp $
    ret

draw_line:
    ret

draw_rect:
    ret

draw_screen:
    ret

fill_screen:
    ret