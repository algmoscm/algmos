[BITS 64]          ; 16位实模式
[ORG 0xFFFF800000106200]       ; BIOS 加载引导扇区到 0x7C00

kernel_start:

call video_init

mov r8, 0
mov r9, 20
mov rsi, messages
call draw_string


mov rdi, 0xFFFF800003000000
mov rax,0
mov rbx,40
mov rcx,30
mov rsi,0xffff800000008800
call print_hex_str

jmp $

%include "../kernel/printk.asm"

messages: db 'codfjgcg', 0
messages1: db 'asdfghijklmnopqrstuvwxyz_ASDFGHJKLZXCVBNM1234567890', 0
messages2: times 10 db 0