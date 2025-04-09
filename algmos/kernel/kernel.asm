%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]          ; 0xFFFF800000106200
ehdr:
    ABI_HEADER ABI_File_CORE, kernel_start, shdr,1
shdr:
    SECTION_HEADER Section_Type_LOAD, 0, kernel_start,section_end-section_start
section_start:
kernel_start:

    prepare_call 1,1
    call video_init
    cleanup_call 1,1

    prepare_call 1,1
    call printk_init
    cleanup_call 1,1

    prepare_call 3,1
    mov qword [rsp+16], 0x00FFFFFF
    mov qword [rsp+8], 200
    mov qword [rsp], 100
    call draw_pixel
    cleanup_call 3,1
    mov rax, [rsp-8]

; draw_line:; Input: rdi = x1, rsi = y1, rdx = x2, rcx = y2, r8 = color
; mov rdi, 100
; mov rsi, 100
; mov rdx, 200
; mov rcx, 200
; mov r8, 0x00FF00FF
; call draw_line

;    jmp $
    mov r8, 0
    mov r9, 0
    lea rsi,[rel messages]
    call draw_string

    mov r8, 0
    mov r9, 20
    lea rsi,[rel messages1]
    call draw_string

    mov r8, 0
    mov r9, 40
    lea rsi,[rel messages2]
    call draw_string

    mov r8, 0
    mov r9, 60
    lea rsi,[rel messages3]
    call draw_string

        mov r8, 0
    mov r9, 80
    lea rsi,[rel messages4]
    call draw_string

        mov r8, 0
    mov r9, 100
    lea rsi,[rel messages5]
    call draw_string

        mov r8, 0
    mov r9, 120
    lea rsi,[rel messages6]
    call draw_string

    ; mov rdi, 0xFFFF800003000000
    ; mov rax,0
    ; mov rbx,40
    ; mov rcx,30

    ; ; lea rsi,[rel params]
    ; mov rsi,0xffff800000008800
    ; call print_hex_str

    jmp $

parse_system_params:


    prolog 2;
    ; get_param rax, 1   ; a

    ; add rax, 3       ; sum = a + b
    ; set_ret_param rax,1
    epilog
    
%include "../kernel/printk.asm"

messages: db 'hello world,here to show printk function', 0
messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0
messages2: db 'Image format was not specified for ./hd60m.img and probing guessed raw', 0
messages3: db 'Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.', 0

messages4: db '../kernel/printk.asm:100: warning: word data exceeds bounds [-w+number-overflow]', 0
messages5: db 'WARNING: Image format was not specified for ./hd60m.img and probing guessed raw.', 0
messages6: db '25088 bytes (25 kB, 24 KiB) copied, 0.000134717 s, 186 MB/s', 0


params: times 10 dq 0x12345
messagess: times 10 db 0
kernel_end:
section_end: