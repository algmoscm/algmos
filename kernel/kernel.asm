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
    mov qword [rsp+16], 0x00FF00FF
    mov qword [rsp+8], 200
    mov qword [rsp], 100
    call draw_pixel
    cleanup_call 3,1
    mov rax, [rsp-8]


    ; mov r8, 0
    ; mov r9, 20
    ; lea rsi,[rel messages]
    ; call draw_string

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

messages: db 'codfjgcg', 0
messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0

params: times 10 dq 0x12345
messages2: times 10 db 0
kernel_end:
section_end: