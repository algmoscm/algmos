%ifndef INIT_ASM
%define INIT_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"


%include "../kernel/printk.asm"
%include "../kernel/expection.asm"
%include "../kernel/interrupt.asm"
%include "../kernel/memory.asm"

[BITS 64]

page_info_msg1 db "page attribute:%x     ", 0

page_info_msg2 db "page address:%x\n", 0

struc tss_table_info
    .reserved1:      resd 1
    .rsp0:           resq 1
    .rsp1:           resq 1
    .rsp2:           resq 1
    .reserved2:      resq 1
    .ist1:           resq 1
    .ist2:           resq 1
    .ist3:           resq 1
    .ist4:           resq 1
    .ist5:           resq 1
    .ist6:           resq 1
    .ist7:           resq 1
    .reserved3:      resd 1
    .reserved4:      resd 1
    .io_map_base:    resd 1
endstruc
struc tss_descriptor
    .limit_low:      resw 1    ; 段界限的低 16 位
    .base_low:       resw 1    ; 基地址的低 16 位

    .base_mid:       resb 1    ; 基地址的中间 8 位
    .type:           resb 1    ; 类型和属性（包括 P 位、DPL、TYPE）
    .limit_high:     resb 1    ; 段界限的高 4 位和标志（G、AVL 等）
    .base_high:      resb 1    ; 基地址的高 8 位

    .base_upper:     resd 1    ; 基地址的高 32 位（64 位地址支持）
    .reserved:       resd 1    ; 保留字段
endstruc
system_init:;input:kernel_end
    prolog 0
    get_param rsi, 1
    
    function video_init
    function printk_init
    function sys_vector_init


    ; function memory_init,1,rsi


    function test_printk
    function test_video

    ; function test_memory

    epilog
sys_vector_init:;init system interrupt vector
    prolog 0
    function setup_default_tss
    function init_expection
    function init_interrupt

    epilog
setup_default_tss:;setup tss
    prolog 0;

    mov rbx, GDTPointerUpperAddr
    mov rbx, [rbx + 2]
    add rbx, 0x40

    mov rax, TSSPointerUpperAddr
    mov  dx,word [rax]
    mov rax, [rax + 2]
    ; jmp $
    mov word [rbx + tss_descriptor.limit_low], dx
    mov word [rbx + tss_descriptor.base_low], ax
    shr rax, 16

    mov byte [rbx + tss_descriptor.base_mid], al
    mov byte [rbx + tss_descriptor.type], 0x89
    mov byte [rbx + tss_descriptor.limit_high], 0x00
    shr rax, 8

    mov byte [rbx + tss_descriptor.base_high], al
    shr rax, 8

    mov dword [rbx + tss_descriptor.base_upper], eax
    mov dword [rbx + tss_descriptor.reserved], 0x00


    mov rax, TSSPointerUpperAddr
    mov rbx, [rax + 2]

    mov rax, 0xffff800000007c00
    ; mov qword [rbx + tss_table_info.reserved1], 0x00
    mov qword [rbx + tss_table_info.rsp0], rax
    mov qword [rbx + tss_table_info.rsp1], rax
    mov qword [rbx + tss_table_info.rsp2], rax
    ; mov qword [rbx + tss_table_info.reserved2], 0x00
    mov qword [rbx + tss_table_info.ist1], rax
    mov qword [rbx + tss_table_info.ist2], rax
    mov qword [rbx + tss_table_info.ist3], rax
    mov qword [rbx + tss_table_info.ist4], rax
    mov qword [rbx + tss_table_info.ist5], rax
    mov qword [rbx + tss_table_info.ist6], rax
    mov qword [rbx + tss_table_info.ist7], rax

    ; mov qword [rbx + tss_table_info.reserved3], 0x00
    ; mov qword [rbx + tss_table_info.reserved4], 0x00

    mov dword [rbx + tss_table_info.io_map_base], 104
    
    mov cx, 0x0040
    ltr cx
    
    epilog


test_printk:;test printk
    prolog 2;

    ; function draw_char,1,0,0,'A'
    ; function print_char,1,'a'
    ; function print_char,1,'b'

    ; function print_char,1,'a'
    ; function print_char,1,'b'
    ;     function print_char,1,'a'
    ; function print_char,1,'b'

    ;     function print_char,1,'a'
    ; function print_char,1,'b'


    ;     lea rsi,[rel messages2]    
    ;    function print_string,1,rsi

    ;     lea rsi,[rel messages1]
    ;     function print_string,1,rsi

    ;     lea rsi,[rel messages2]    
    ;    function print_string,1,rsi

    ;     lea rsi,[rel messages1]
    ;     function print_string,1,rsi



    ; lea rsi,[rel decimal_messages]    
    ; function print_decimal,1,rsi

    ; lea rsi,[rel hex_messages]    
    ; function print_hex,1,rsi

    ; lea rsi,[rel hex_messages]    
    ; function print_hex,1,rsi

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx


    ;         lea rsi,[rel messages]    
    ;    function print_string,1,rsi

        lea rsi,[rel messages3]
        function print_string,1,rsi

    lea rsi, [rel format1]
    lea rdx, [rel string1]
    function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx


    ;         lea rsi,[rel messages]    
    ;    function print_string,1,rsi

    ;     lea rsi,[rel messages3]
    ;     function print_string,1,rsi

    ;         lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx


    ;         lea rsi,[rel messages]    
    ;    function print_string,1,rsi

    ;     lea rsi,[rel messages3]
    ;     function print_string,1,rsi

    ;         lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ;     lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format1]
    ; lea rdx, [rel string1]
    ; function printk,1,rsi,rdx


    ;         lea rsi,[rel messages]    
    ;    function print_string,1,rsi

    ;     lea rsi,[rel messages3]
    ;     function print_string,1,rsi

    
    ; lea rsi, [rel format2]
    ; lea rdx, [rel decimal_messages]
    ; function printk,1,rsi,rdx

    ; lea rsi, [rel format3]
    ; lea rdx, [rel hex_messages]
    ; function printk,1,rsi,rdx


    ;     lea rsi,[rel decimal_messages]    
    ; function print_decimal,1,rsi

    ;     lea rsi,[rel decimal_messages]    
    ; function print_decimal,1,rsi

    ; lea rsi,[rel messages1]
    ; function draw_string,1,0,20,rsi

    ; lea rsi,[rel messages2]
    ; function draw_string,1,0,40,rsi

    ; lea rsi,[rel messages3]
    ; function draw_string,1,0,60,rsi

    ; lea rsi,[rel messages4]
    ; function draw_string,1,0,80,rsi

    ; lea rsi,[rel hex_messages]
    ; function draw_hex,1,0,100,rsi

    ; lea rsi,[rel decimal_messages]
    ; function draw_decimal,1,0,120,rsi



    epilog

test_video:;test video
    prolog 2;

    xor rax,rax 
    xor rdx,rdx
    mov ax,word [rel video_info_ptr + video_info.xpixel]
    mov [rel decimal_messages], rax
    lea rsi, [rel init_video_xpixel]
    lea rdx, [rel decimal_messages]
    function printk,1,rsi,rdx

    xor rax,rax 
    xor rdx,rdx
    mov ax,word [rel video_info_ptr + video_info.ypixel]
    mov [rel decimal_messages], rax
    lea rsi, [rel init_video_ypixel]
    lea rdx, [rel decimal_messages]
    function printk,1,rsi,rdx

    xor rax,rax 
    xor rdx,rdx
    mov ax,word [rel video_info_ptr + video_info.byte_per_pixel]
    mov [rel decimal_messages], rax
    lea rsi, [rel init_video_byteperpixel]
    lea rdx, [rel decimal_messages]
    function printk,1,rsi,rdx



    ; function draw_screen,0,0x00000000
    function draw_pixel,1,1000,200,0x00FFFFFF
    function draw_line,1,1100,300,1300,500,0x00FFFFFF
    function draw_line,1,1300,300,1100,500,0x00FFFFFF
    function draw_rect,1,1100,300,1300,500,0x00FFFFFF
    function draw_circle,1,1200,400,100,0x00FFFFFF
    function draw_triangle,1,1150,200,1250,200,1200,300,0x00FFFFFF

    epilog    

test_memory:;test memory
    prolog 2;

    ; After memory initialization, add:

    ; Allocate 64 pages from ZONE_NORMAL
    mov rdi, ZONE_NORMAL
    mov rsi, 2
    mov rdx, PG_PTable_Maped | PG_Active | PG_Kernel


    function alloc_pages, 1, rdi, rsi, rdx

    function alloc_pages, 1, rdi, rsi, rdx


    mov rax,[rsp-8]
    mov r12, rax                    ; Save page pointer

    ; Print info for each pair of pages
    xor r13, r13                    ; i = 0
    mov r14,rsi
    .print_pages_loop:
        ; Print first page of pair
        ; mov [rel memory_hex_messages], r13
        ; mov rax, [r12 + r13 * 40 + page_info.page_attribute]

        ; mov [rel memory_hex_messages + 8], rax
        ; mov rax, [r12 + r13 * 40 + page_info.physical_address]
        ; mov [rel memory_hex_messages + 16], rax

        mov rax,r13
        mov rcx,40
        mul rcx
        add rax, r12

        mov rsi, [rax + page_info.page_attribute]
        mov [rel hex_messages], rsi
        lea rsi, [rel page_info_msg1]
        lea rdx, [rel hex_messages]
        function printk, 1, rsi, rdx

        mov rdx, [rax + page_info.physical_address]
        mov [rel hex_messages], rdx
        lea rsi, [rel page_info_msg2]
        lea rdx, [rel hex_messages]
        function printk, 1, rsi, rdx

        ; Move to next pair
        inc r13
        cmp r13, r14
        jl .print_pages_loop



    epilog
    





init_video_xpixel: db '[video info]     xpixel:%d',0
init_video_ypixel: db '    ypixel:%d',0
init_video_byteperpixel: db '    byte per pixel:%d\n',0

messages: db 'hello world,here to show printk function\n', 0

messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890\n', 0
messages2: db 'Image format was not specified for ./hd60m.img and probing guessed raw\n', 0
messages3: db 'Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.\n', 0

messages4: db '../kernel/printk.asm:100: warning: word data exceeds bounds [-w+number-overflow]\n', 0
messages5: db 'WARNING: Image format was not specified for ./hd60m.img and probing guessed raw.\n', 0
messages6: db '25088 bytes (25 kB, 24 KiB) copied, 0.000134717 s, 186 MB/s\n', 0

format1 db "Hello, %s!\n", 0
format2 db "Physical address: %d", 0


format3 db "Hex: %x\n", 0
string1 db "World", 0

hex_messages: dq 0
decimal_messages: dq 0
params: times 10 dq 0x12345
messagess: times 10 db 0

%endif