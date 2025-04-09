%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]          ; 0xFFFF800000106200
ehdr:
    ABI_HEADER ABI_File_CORE, kernel_start, shdr,1
shdr:
    SECTION_HEADER Section_Type_LOAD, 0, kernel_start,section_end-section_start
section_start:
kernel_start:

    function video_init
    ; prepare_call 1,1
    ; call video_init
    ; cleanup_call 1,1

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

    ; draw_line; Input: x1,y1,x2,y2,color
    prepare_call 5,1
    mov qword [rsp+32], 0x00FFFFFF
    mov qword [rsp+24], 400
    mov qword [rsp+16], 400

    mov qword [rsp+8], 200
    mov qword [rsp], 200
    call draw_line
    cleanup_call 5,1
    mov rax, [rsp-8]

    ; draw_rect; Input: x1,y1,x2,y2,color
    ; prepare_call 5,1
    ; mov qword [rsp+32], 0x00FFFFFF
    ; mov qword [rsp+24], 400
    ; mov qword [rsp+16], 400

    ; mov qword [rsp+8], 200
    ; mov qword [rsp], 200
    ; call draw_rect
    ; cleanup_call 5,1
    ; mov rax, [rsp-8]

    function draw_rect,1,200,300,400,500,0x00FFFFFF
    ; ; draw_screen; Input: color
    ; prepare_call 1,1
    ; mov qword [rsp], 0x00000000
    ; call draw_screen
    ; cleanup_call 1,1
    ; mov rax, [rsp-8]

; draw_circle: ; Input: x_center, y_center, radius, color
    prepare_call 4,1
    mov qword [rsp+24], 0x00FFFFFF
    mov qword [rsp+16], 200

    mov qword [rsp+8], 300
    mov qword [rsp], 300
    call draw_circle
    cleanup_call 4,1
    mov rax, [rsp-8]

    ;draw_triangle: ; Input: x1, y1, x2, y2, x3, y3, color
    prepare_call 7,1
    mov qword [rsp+48], 0x00FFFFFF

    mov qword [rsp+40], 350
    mov qword [rsp+32], 350

    mov qword [rsp+24], 300
    mov qword [rsp+16], 400

    mov qword [rsp+8], 300
    mov qword [rsp], 300
    call draw_triangle
    cleanup_call 7,1
    mov rax, [rsp-8]




    prepare_call 3,1
    lea rsi,[rel messages]
    mov qword [rsp+16], rsi
    mov qword [rsp+8], 0
    mov qword [rsp], 0
    call draw_string
    cleanup_call 3,1
    mov rax, [rsp-8]



    prepare_call 3,1
    lea rsi,[rel messages1]
    mov qword [rsp+16], rsi
    mov qword [rsp+8], 20
    mov qword [rsp], 0
    call draw_string
    cleanup_call 3,1
    mov rax, [rsp-8]

        prepare_call 3,1
    lea rsi,[rel messages2]
    mov qword [rsp+16], rsi
    mov qword [rsp+8], 40
    mov qword [rsp], 0
    call draw_string
    cleanup_call 3,1
    mov rax, [rsp-8]

        prepare_call 3,1
    lea rsi,[rel messages3]
    mov qword [rsp+16], rsi
    mov qword [rsp+8], 60
    mov qword [rsp], 0
    call draw_string
    cleanup_call 3,1
    mov rax, [rsp-8]
jmp $

    prepare_call 2,1
    lea rsi, [rel format1]
    lea rdx, [rel string1]

    mov qword [rsp+8], rdx
    mov qword [rsp], rsi
    call printk
    cleanup_call 2,1
    mov rax, [rsp-8]

    ; lea rsi, [format1]
    ; lea rdx, [string1]
    ; call printk

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


    epilog
    
%include "../kernel/printk.asm"

messages: db 'hello world,here to show printk function', 0
messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0
messages2: db 'Image format was not specified for ./hd60m.img and probing guessed raw', 0
messages3: db 'Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.', 0

messages4: db '../kernel/printk.asm:100: warning: word data exceeds bounds [-w+number-overflow]', 0
messages5: db 'WARNING: Image format was not specified for ./hd60m.img and probing guessed raw.', 0
messages6: db '25088 bytes (25 kB, 24 KiB) copied, 0.000134717 s, 186 MB/s', 0

    format1 db "Hello, %s!", 0
    format2 db "Value: %d", 0
    format3 db "Hex: %x", 0
    string1 db "World", 0

params: times 10 dq 0x12345
messagess: times 10 db 0
kernel_end:
section_end: