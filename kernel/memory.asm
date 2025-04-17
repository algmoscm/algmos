%ifndef MEMORY_ASM
%define MEMORY_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]

memory_physical_table db "-------------------------Physical Memory Table: %x-----------------------------\n", 0
memory_physical_usable db "-------------------------Physical Memory Usable: %x----------------------------\n", 0
memory_total_physical_usable_memory db "Total Physical Usable Meomry:%d\n", 0

memory_physical_address db "Physical address: %x", 0
memory_physical_length db "     Physical length: %x", 0
memory_physical_type db "     Physical type: %d\n", 0

memory_hex_messages: dq 0
meomry_decimal_messages: dq 0

%define MEMORY_PAGE_OFFSET	0xffff800000000000

%define MEMORY_PAGE_GDT_SHIFT	39
%define MEMORY_PAGE_1G_SHIFT	30
%define MEMORY_PAGE_2M_SHIFT	21
%define MEMORY_PAGE_4K_SHIFT	12

%define MEMORY_PAGE_2M_SIZE	(1 << MEMORY_PAGE_2M_SHIFT)
%define MEMORY_PAGE_4K_SIZE	(1 << MEMORY_PAGE_4K_SHIFT)

%define MEMORY_PAGE_2M_MASK	(~ (MEMORY_PAGE_2M_SIZE - 1))
%define MEMORY_PAGE_4K_MASK	(~ (MEMORY_PAGE_4K_SIZE - 1))

%macro MEMORY_PAGE_4K_ALIGN 1
    ; Align the given address (argument 1) to the nearest 4K boundary
    ; Formula: ((addr + PAGE_4K_SIZE - 1) & PAGE_4K_MASK)

    mov qword[rsp],%1
    add qword[rsp],MEMORY_PAGE_4K_SIZE - 1
    and qword[rsp],MEMORY_PAGE_4K_MASK
    mov %1,qword[rsp]
    ; pop %1

    ; push %1
    ; push rax
    ; mov rax, %1                ; Load the address into rax
    ; add rax, MEMORY_PAGE_4K_SIZE - 1     ; Add 4K size - 1 (PAGE_4K_SIZE - 1)
    ; and rax, MEMORY_PAGE_4K_MASK  ; Apply the 4K mask (PAGE_4K_MASK)
    ; mov %1, rax                ; Store the aligned address back
    ; pop rax
    ; pop %1
    %endmacro

%macro MEMORY_PAGE_2M_ALIGN 1
    ; Align the given address (argument 1) to the nearest 2M boundary
    ; Formula: ((addr + PAGE_2M_SIZE - 1) & PAGE_2M_MASK)
    ; push %1


    mov qword[rsp],%1
    add qword[rsp],MEMORY_PAGE_2M_SIZE - 1
    and qword[rsp],MEMORY_PAGE_2M_SIZE
    mov %1,qword[rsp]

    ; push rax
    ; mov rax, %1                ; Load the address into rax
    ; add rax, MEMORY_PAGE_2M_SIZE - 1     ; Add 2M size - 1 (PAGE_2M_SIZE - 1)
    ; and rax, MEMORY_PAGE_2M_MASK  ; Apply the 2M mask (PAGE_2M_MASK)
    ; mov %1, rax                ; Store the aligned address back
    ; pop rax
    ; pop %1
    %endmacro

struc global_memory_info
    .e820_addr:    resq 1  ; 0  32 e820 address
    .e820_size:    resq 1  ; 8  e820 usable meomory zone size
    .e820_count:   resq 1  ; 16 e820 usable meomory zone count

    .bitmap_addr:  resq 1  ; 24 bitmap address
    .bitmap_size:  resq 1  ; 32 bitmap size
    .bitmap_count: resq 1  ; 40 bitmap count

    .pages_addr:   resq 1  ; 48 pages address
    .pages_size:   resq 1  ; 56 pages size
    .pages_count:  resq 1  ; 64 pages count

    .zones_addr:   resq 1  ; 72 zones address
    .zones_size:   resq 1  ; 80 zones size
    .zones_count:  resq 1  ; 88 zones count

    endstruc
global_memory_info_ptr:;
    istruc global_memory_info

        at global_memory_info.e820_addr,    dq 0  ; 0  32 e820 address
        at global_memory_info.e820_size,    dq 0  ; 8  e820 all meomory zone size
        at global_memory_info.e820_count,   dq 0  ; 16 e820 usable meomory zone count

        at global_memory_info.bitmap_addr,  dq 0  ; 24 bitmap address
        at global_memory_info.bitmap_size,  dq 0  ; 32 bitmap size
        at global_memory_info.bitmap_count, dq 0  ; 40 bitmap count

        at global_memory_info.pages_addr,   dq 0  ; 48 pages address
        at global_memory_info.pages_size,   dq 0  ; 56 pages size
        at global_memory_info.pages_count,  dq 0  ; 64 pages count

        at global_memory_info.zones_addr,   dq 0  ; 72 zones address
        at global_memory_info.zones_size,   dq 0  ; 80 zones size
        at global_memory_info.zones_count,  dq 0  ; 88 zones count

    iend

struc e820_memory_info
    .base_addr_low            resd 1    ; Lower 32 bits of the base address
    .base_addr_high           resd 1    ; Upper 32 bits of the base address
    .length_low               resd 1    ; Lower 32 bits of the length
    .length_high              resd 1    ; Upper 32 bits of the length
    .type                     resd 1    ; Memory type (1 = usable, others = reserved, etc.)
    ; .acpi_attributes          resd 1    ; ACPI 3.0+ attributes (optional, may be zero)
    endstruc

struc page_info
    .zone_info_address:     resq 1  ; 0  parent zone_info_address
    .physical_address:      resq 1  ; 8  page start physical address

    .page_attribute:        resq 1  ; 16 page attribute
    .reference_count:       resq 1  ; 24 reference count for multi map

    .age:                   resq 1  ; 32

 endstruc

struc zone_info
    .pages_group:                   resq 1  ; 0  zone pages start address
    .pages_length:                  resq 1  ; 8  zone pages length

    .zone_start_address:            resq 1  ; 16 zone_start_address
    .zone_end_address:              resq 1  ; 24 zone_end_address
    .zone_length:                   resq 1  ; 32 zone_length
    .zone_attribute:                resq 1  ; 40 zone_attribute

    .global_memory_info_address:    resq 1  ; 48 global_memory_info_address

    .page_using_count:              resq 1  ; 56 page_using_count
    .page_free_count:               resq 1  ; 64 page_free_count
    .total_pages_link:              resq 1  ; 72 total_pages_link

 endstruc
memory_init:;input:kernel_end
    prolog 2;

    get_param rsi, 1
    function parse_e820

    ;Get total usable memory
    mov rcx, qword [rel global_memory_info_ptr + global_memory_info.e820_size]
    mov r14,0
    mov r8,0
    mov r13,0
    .loop_e820_table:
        xor rax,rax
        mov rbx,qword [rel global_memory_info_ptr + global_memory_info.e820_addr]
        add rbx,r14

        mov eax,dword [rbx + e820_memory_info.type]

        cmp rax,1
        jne .loop_e820_table_continue
        mov rdx,qword [rbx]
        mov r8,rdx
        MEMORY_PAGE_2M_ALIGN rdx
        mov rax,qword [rbx + e820_memory_info.length_low]
        add rax,r8
        shr rax,MEMORY_PAGE_2M_SHIFT
        shl rax,MEMORY_PAGE_2M_SHIFT
        cmp rax,rdx
        jle .loop_e820_table_continue
        sub rax,rdx
        shr rax,MEMORY_PAGE_2M_SHIFT
        add r13,rax

        .loop_e820_table_continue:
            add r14,20
            loop .loop_e820_table

    mov [rel meomry_decimal_messages], r13
    lea rsi, [rel memory_total_physical_usable_memory]
    lea rdx, [rel meomry_decimal_messages]
    function printk,1,rsi,rdx

    ;Get all zone physical memory to bitmap
    mov rcx, qword [rel global_memory_info_ptr + global_memory_info.e820_size]
    sub rcx,1
    mov rax,20
    mul rcx
    mov rbx,qword [rel global_memory_info_ptr + global_memory_info.e820_addr]
    add rbx,rax

    xor rax,rax
    xor rcx,rcx
    xor rdx,rdx
    mov rax,qword [rbx]
    mov ecx,dword [rbx + e820_memory_info.type]
    mov rdx,qword [rbx + e820_memory_info.length_low]
    add rax,rdx
    inc rax
    MEMORY_PAGE_4K_ALIGN rax
    ; function kmemset,1,rax
    ; jmp $


    epilog
kmemset:;input:dest_addr,value,count
    prolog 2;
    get_param rdi,1
    get_param rsi,2
    get_param rdx,3

    ; Extend the value to 64 bit
    movzx rax, sil          
    mov rbx, rax            
    shl rax, 8              
    or rax, rbx             
    shl rax, 16             
    or rax, rbx             
    shl rax, 32             
    or rax, rbx             

    ;Fill the memory with the rax using the stosq instruction
    mov rcx, rdx            
    shr rcx, 3              
    rep stosq               

    ; deal with the remaining bytes
    mov rcx, rdx
    and rcx, 7              
    rep stosb              

    epilog
parse_e820:;get and print e820 info to global_memory_info
    prolog 2;

    xor rax,rax
    xor rbx,rbx
    mov rbx,KernelSpaceUpperAddress+MemoryStructBufferAddr+ e820_memory_entry.base_addr_low
    mov qword [rel global_memory_info_ptr + global_memory_info.e820_addr],rbx

    sub rbx,4
    mov rax,qword [rbx]

    mov qword [rel global_memory_info_ptr + global_memory_info.e820_size],rax

    mov [rel meomry_decimal_messages], rax
    lea rsi, [rel memory_physical_table]
    lea rdx, [rel meomry_decimal_messages]
    function printk,1,rsi,rdx
    mov rcx,rax
    mov r14,0
    mov r13,0
    .loop_tale:
        xor rax,rax
        mov rbx,KernelSpaceUpperAddress+MemoryStructBufferAddr+ e820_memory_entry.base_addr_low
        add rbx,r14
        mov rax,qword [rbx]
        mov [rel memory_hex_messages], rax
        lea rsi, [rel memory_physical_address]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        xor rax,rax
        mov rbx,KernelSpaceUpperAddress+MemoryStructBufferAddr+ e820_memory_entry.length_low
        add rbx,r14
        mov rax,qword [rbx]
        mov [rel memory_hex_messages], rax
        lea rsi, [rel memory_physical_length]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        xor rax,rax
        mov rbx,KernelSpaceUpperAddress+MemoryStructBufferAddr+ e820_memory_entry.type
        add rbx,r14
        mov eax,dword [rbx]
        cmp rax,1
        jne .count_skip
            inc r13
        .count_skip:
        mov [rel meomry_decimal_messages], rax
        lea rsi, [rel memory_physical_type]
        lea rdx, [rel meomry_decimal_messages]
        function printk,1,rsi,rdx

        add r14,20
        dec rcx
        jnz .loop_tale

        mov qword [rel global_memory_info_ptr + global_memory_info.e820_count],r13

        mov [rel meomry_decimal_messages], r13
        lea rsi, [rel memory_physical_usable]
        lea rdx, [rel meomry_decimal_messages]
        function printk,1,rsi,rdx
    epilog
%endif