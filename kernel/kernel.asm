%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"
[BITS 64]          ; 0xFFFF800000106200
ehdr:
    ABI_HEADER ABI_File_CORE, kernel_start, shdr,1
shdr:
    SECTION_HEADER Section_Type_LOAD, 0, kernel_start,section_end-section_start
section_start:
kernel_start:

    function init_sys_vector

    function video_init
    function printk_init


    function test_printk
    ; function test_video




    .endofkernel:
        jmp $
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


    lea rsi,[rel messages2]    
   function print_string,1,rsi

    lea rsi,[rel messages1]
    function print_string,1,rsi

    lea rsi,[rel messages2]    
   function print_string,1,rsi

    lea rsi,[rel messages1]
    function print_string,1,rsi

    lea rsi,[rel messages2]    
   function print_string,1,rsi

    lea rsi,[rel messages1]
    function print_string,1,rsi

    ; lea rsi,[rel decimal_messages]    
    ; function print_decimal,1,rsi

    ; lea rsi,[rel hex_messages]    
    ; function print_hex,1,rsi

    ; lea rsi,[rel hex_messages]    
    ; function print_hex,1,rsi

    lea rsi, [rel format1]
    lea rdx, [rel string1]
    function printk,1,rsi,rdx

        lea rsi, [rel format2]
    lea rdx, [rel decimal_messages]
    function printk,1,rsi,rdx

    lea rsi, [rel format3]
    lea rdx, [rel hex_messages]
    function printk,1,rsi,rdx
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

    ; function draw_screen,0,0x00000000
    function draw_pixel,1,100,200,0x00FFFFFF
    function draw_line,1,100,200,300,400,0x00FFFFFF
    function draw_rect,1,200,300,400,500,0x00FFFFFF
    function draw_circle,1,300,400,100,0x00FFFFFF
    function draw_triangle,1,100,100,200,100,100,200,0x00FFFFFF

    epilog    

parse_system_params:
    prolog 2;


    epilog
    
%include "../kernel/printk.asm"
; %include "../kernel/expection.asm"
; %include "../kernel/interrupt.asm"
%include "../kernel/init.asm"
messages: db 'hello world,here to show printk function\n', 0
; messages1: db 'a\nb\nc\nd\ne\nf\ng\n', 0

messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890\n', 0
messages2: db 'Image format was not specified for ./hd60m.img and probing guessed raw\n', 0
messages3: db 'Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.\n', 0

messages4: db '../kernel/printk.asm:100: warning: word data exceeds bounds [-w+number-overflow]\n', 0
messages5: db 'WARNING: Image format was not specified for ./hd60m.img and probing guessed raw.\n', 0
messages6: db '25088 bytes (25 kB, 24 KiB) copied, 0.000134717 s, 186 MB/s\n', 0

    format1 db "Hello, %s!\n", 0
    format2 db "Value: %d\n", 0
    format3 db "Hex: %x\n", 0
    string1 db "World", 0
hex_messages: dq 0x123456789abcdef0
decimal_messages: dq 123456789
params: times 10 dq 0x12345
messagess: times 10 db 0
kernel_end:
section_end: