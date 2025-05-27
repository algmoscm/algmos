%ifndef MEMORY_ASM
%define MEMORY_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]

memory_physical_table db "-------------------------Physical Memory Table: %x-----------------------------\n", 0
memory_physical_usable db "-------------------------Physical Memory Usable: %x----------------------------\n", 0
memory_total_physical_usable_memory db "Total Physical Usable Meomry:%d\n", 0

memory_bits_map_addr    db "Bits map  addr:%x          ", 0
memory_bits_map_size    db "Bits map  size:%x          ", 0
memory_bits_map_count   db "Bits map count:%x          \n", 0

memory_pages_addr       db "Pages     addr:%x          ", 0
memory_pages_size       db "Pages     size:%x          ", 0
memory_pages_count      db "Pages    count:%x          \n", 0

memory_zones_addr       db "Zones     addr:%x          ", 0
memory_zones_size       db "Zones     size:%x          ", 0
memory_zones_count      db "Zones    count:%x          \n", 0



zone_start_addr_msg db "zone_start_address:%x   ", 0
zone_end_addr_msg db "zone_end_address:%x   ", 0
zone_length_msg db "zone_length:%x   ", 0
pages_group_msg db "pages_group:%x   ", 0
pages_length_msg db "pages_length:%x\n", 0



memory_global_info_length db "Global info length:%x\n", 0

memory_physical_address db "Physical address: %x", 0
memory_physical_length db "     Physical length: %x", 0
memory_physical_type db "     Physical type: %d\n", 0




cr3_msg1 db "Global_CR3:%x", 0
cr3_msg2 db "*Global_CR3:%x", 0
cr3_msg3 db "**Global_CR3:%x\n", 0


alloc_pages_error_msg db "alloc_pages error zone_select index", 0
null_str db 0

Global_CR3: dq 0


memory_hex_messages: dq 0
meomry_decimal_messages: dq 0

; Define zone selection constants
%define ZONE_DMA      0
%define ZONE_NORMAL   1
%define ZONE_UNMAPED  2

ZONE_DMA_INDEX:dq 0
ZONE_NORMAL_INDEX:dq 0
ZONE_UNMAPED_INDEX:dq 0

; Page attribute flags
%define PG_PTable_Maped    (1 << 0)    ; Page table mapped flag
%define PG_Kernel_Init     (1 << 1)    ; Kernel initialization flag  
%define PG_Referenced      (1 << 2)    ; Page referenced flag
%define PG_Dirty          (1 << 3)    ; Page dirty flag
%define PG_Active         (1 << 4)    ; Page active flag
%define PG_Up_To_Date     (1 << 5)    ; Page up to date flag
%define PG_Device         (1 << 6)    ; Device page flag
%define PG_Kernel         (1 << 7)    ; Kernel page flag
%define PG_K_Share_To_U   (1 << 8)    ; Kernel shared to user flag
%define PG_Slab           (1 << 9)    ; Slab allocator page flag

; Add these constants at the top of the file
%define MEMORY_PAGE_OFFSET	0xffff800000000000

; Page size shifts
%define MEMORY_PAGE_GDT_SHIFT	39
%define MEMORY_PAGE_1G_SHIFT	30
%define MEMORY_PAGE_2M_SHIFT	21
%define MEMORY_PAGE_4K_SHIFT	12

; Page sizes
%define MEMORY_PAGE_2M_SIZE	(1 << MEMORY_PAGE_2M_SHIFT)
%define MEMORY_PAGE_4K_SIZE	(1 << MEMORY_PAGE_4K_SHIFT)

; Page masks for alignment
%define MEMORY_PAGE_2M_MASK	(~ (MEMORY_PAGE_2M_SIZE - 1))
%define MEMORY_PAGE_4K_MASK	(~ (MEMORY_PAGE_4K_SIZE - 1))

; Address translation macros
%macro Virt_To_Phy 1
    ; Input: Virtual address in %1
    ; Output: Physical address in %1
    push %1
    mov %1,MEMORY_PAGE_OFFSET
    sub qword[rsp],%1
    pop %1
%endmacro

%macro Phy_To_Virt 1
    ; Input: Physical address in %1
    ; Output: Virtual address in %1
    push %1
    mov %1,MEMORY_PAGE_OFFSET
    add qword[rsp],%1
    pop %1
%endmacro

%macro Virt_To_2M_Page 2
    ; Input: Virtual address in %1
    ; Output: Page structure pointer in %2
    push rax
    mov %2, %1
    Virt_To_Phy %2
    shr %2, MEMORY_PAGE_2M_SHIFT
    mov rax, 40                            ; size of page_info struct
    mul %2
    mov %2, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
    add %2, rax
    pop rax
%endmacro

%macro Phy_To_2M_Page 2
    ; Input: Physical address in %1
    ; Output: Page structure pointer in %2
    push rax
    mov %2, %1
    shr %2, MEMORY_PAGE_2M_SHIFT
    mov rax, 40                            ; size of page_info struct
    mul %2
    mov %2, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
    add %2, rax
    pop rax
%endmacro

%macro MEMORY_PAGE_4K_ALIGN 1
    ; Align the given address (argument 1) to the nearest 4K boundary
    ; Formula: ((addr + PAGE_4K_SIZE - 1) & PAGE_4K_MASK)

    ; mov qword[rsp],%1
    push %1
    add qword[rsp],MEMORY_PAGE_4K_SIZE - 1
    and qword[rsp],MEMORY_PAGE_4K_MASK
    pop %1
    ; mov %1,qword[rsp]
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


    push %1
    add qword[rsp],MEMORY_PAGE_2M_SIZE - 1
    and qword[rsp],MEMORY_PAGE_2M_MASK
    pop %1

    ; mov qword[rsp-8],%1
    ; add qword[rsp-8],MEMORY_PAGE_2M_SIZE - 1
    ; and qword[rsp-8],MEMORY_PAGE_2M_MASK
    ; mov %1,qword[rsp-8]

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

    .end_of_global_memory_info: resq 1  ; 96 end of global memory info
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
        at global_memory_info.end_of_global_memory_info, dq 0  ; 96 end of global memory info
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
        push rsi

        mov [rel meomry_decimal_messages], r13
        lea rsi, [rel memory_total_physical_usable_memory]
        lea rdx, [rel meomry_decimal_messages]
        function printk,1,rsi,rdx
        pop rsi

    ;Bits map init -->Get all zone physical memory to bitmap
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
        add rax,rdx;total memory contain unusable and empty block
        ; inc rax
        MEMORY_PAGE_4K_ALIGN rsi
        mov qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr],rsi
        shr rax,MEMORY_PAGE_2M_SHIFT
        mov qword [rel global_memory_info_ptr + global_memory_info.bitmap_size],rax
        mov rcx,rax
        add rax, 63                     ; Add 63 (bits_per_long - 1)
        shr rax, 6                      ; Divide by 64 (bits per long)
        shl rax, 3                      ; Multiply by 8 (bytes per long)
        and rax, ~7                     ; Align to 8 bytes

        mov qword [rel global_memory_info_ptr + global_memory_info.bitmap_count], rax ;bitmap bytes

        function kmemset,1,rsi,0xff,rax



    ;Pages init-->-->Get all zone physical memory to pages struct
        add rsi,rax
        MEMORY_PAGE_4K_ALIGN rsi
        mov qword [rel global_memory_info_ptr + global_memory_info.pages_addr],rsi
        mov rax, rcx
        mov qword [rel global_memory_info_ptr + global_memory_info.pages_size],rcx

            ; Calculate pages_count (total bytes needed for page structures)
        mov rax, rcx                    ; Number of pages
        mov rbx, 40        ; Size of page_info struct (40 bytes)
        mul rbx                         ; rax = number of pages * size of page_info
        add rax, 7                      ; Add (sizeof(long) - 1)
        and rax, ~7                     ; Align to 8 bytes
        mov qword [rel global_memory_info_ptr + global_memory_info.pages_count], rax

        function kmemset, 1, rsi, 0, rax  ; Zero out the entire pages array


    ;zones init -->
        add rsi, rax                    ; Add pages array size to current address
        MEMORY_PAGE_4K_ALIGN rsi        ; Align zones address to 4K boundary
        mov qword [rel global_memory_info_ptr + global_memory_info.zones_addr], rsi
        
        ; Set zones_size to 0
        xor rax, rax
        mov qword [rel global_memory_info_ptr + global_memory_info.zones_size], rax
        
        ; Calculate zones_count (5 zones * sizeof(zone_info) aligned to 8 bytes)
        mov rax, 0xf                      ; Number of zones
        mov rbx, 80                     ; Size of zone_info struct (10 * 8 = 80 bytes)
        mul rbx                         ; rax = 5 * sizeof(zone_info)
        add rax, 7                      ; Add (sizeof(long) - 1)
        and rax, ~7                     ; Align to 8 bytes
        mov qword [rel global_memory_info_ptr + global_memory_info.zones_count], rax
        
        ; Zero out the zones memory
        function kmemset, 1, rsi, 0, rax  ; Zero initialize zones array


    ;print global memory info
        mov r13,qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_addr]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.bitmap_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_size]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.bitmap_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_count]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx



        mov r13,qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_addr]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.pages_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_size]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.pages_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_count]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx



        mov r13,qword [rel global_memory_info_ptr + global_memory_info.zones_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_addr]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.zones_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_size]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx

        mov r13,qword [rel global_memory_info_ptr + global_memory_info.zones_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_count]
        lea rdx, [rel memory_hex_messages]
        function printk,1,rsi,rdx






    ;Loop through e820 entries to initialize zones
        mov rcx, qword [rel global_memory_info_ptr + global_memory_info.e820_size]
        xor r14, r14                    ; i = 0 (e820 entry index)
        mov r15, qword [rel global_memory_info_ptr + global_memory_info.zones_addr] ; zones base address

        .loop_e820_zones:
            push rcx
            mov rbx, qword [rel global_memory_info_ptr + global_memory_info.e820_addr]
            add rbx, r14                    ; current e820 entry

            ; Check if type == 1 (usable memory)
            mov eax, dword [rbx + e820_memory_info.type]
            cmp eax, 1
            jne .continue_e820_loop

            ; Calculate start address (PAGE_2M_ALIGN)
            mov rax, qword [rbx]           ; e820 entry base address
            push rax
            MEMORY_PAGE_2M_ALIGN rax
            mov r12, rax                   ; r12 = start address

            ; Calculate end address
            pop rax                        ; original base address

            add rax, qword [rbx + e820_memory_info.length_low]

            shr rax, MEMORY_PAGE_2M_SHIFT
            shl rax, MEMORY_PAGE_2M_SHIFT
            mov r13, rax                   ; r13 = end address

            ; Check if end <= start
            cmp r13, r12
            jle .continue_e820_loop

            ; Initialize zone structure
            mov rdi, r15                   ; Current zone structure
            mov rax, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
            inc rax
            mov qword [rel global_memory_info_ptr + global_memory_info.zones_size], rax


            ; Set zone fields
            mov qword [rdi + zone_info.zone_start_address], r12
            mov qword [rdi + zone_info.zone_end_address], r13
            mov rax, r13
            sub rax, r12
            mov qword [rdi + zone_info.zone_length], rax

            mov qword [rdi + zone_info.page_using_count], 0
            shr rax, MEMORY_PAGE_2M_SHIFT
            mov qword [rdi + zone_info.page_free_count], rax
            mov qword [rdi + zone_info.total_pages_link], 0
            mov qword [rdi + zone_info.zone_attribute], 0

            push rax
            lea rax,qword [rel global_memory_info_ptr]
            mov qword [rdi + zone_info.global_memory_info_address],rax
            pop rax

            ; Set pages group info
            mov qword [rdi + zone_info.pages_length], rax
            mov rax, r12
            shr rax, MEMORY_PAGE_2M_SHIFT
            mov rbx, 40                    ; size of page_info struct
            mul rbx
            add rax, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
            mov qword [rdi + zone_info.pages_group], rax


            ; Initialize pages in this zone
            mov rsi, rax                   ; rsi = first page
            mov rcx, qword [rdi + zone_info.pages_length]
            xor r9,r9
        .init_pages:
            push rcx
            push rdi

            ; Set page fields
            mov qword [rsi + page_info.zone_info_address], rdi
            mov rax, MEMORY_PAGE_2M_SIZE
            mul r9
            add rax, r12
            mov qword [rsi + page_info.physical_address], rax
            mov qword [rsi + page_info.page_attribute], 0
            mov qword [rsi + page_info.reference_count], 0
            mov qword [rsi + page_info.age], 0

            ; Update bitmap
            mov rax, qword [rsi + page_info.physical_address]
            shr rax, MEMORY_PAGE_2M_SHIFT
            mov rbx, rax
            shr rbx, 6                     ; divide by 64 to get long index

            and rax, 63                    ; get bit position
            mov rcx,rax
            mov rdx, 1
            shl rdx, cl                   ; create bit mask
            mov rdi, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
            xor qword [rdi + rbx * 8], rdx ; toggle bit in bitmap

            pop rdi
            pop rcx
            inc r9
            add rsi, 40                    ; move to next page
            dec rcx
            jnz .init_pages

            add r15, 80                    ; move to next zone struct

        .continue_e820_loop:
            pop rcx
            add r14, 20                    ; move to next e820 entry

            ; add r15, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
            dec rcx
            jnz .loop_e820_zones

            ; Initialize page 0
            mov rsi, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
            mov rdi, qword [rel global_memory_info_ptr + global_memory_info.zones_addr]
            mov qword [rsi + page_info.zone_info_address], rdi
            mov qword [rsi + page_info.physical_address], 0
            mov qword [rsi + page_info.page_attribute], 0
            mov qword [rsi + page_info.reference_count], 0
            mov qword [rsi + page_info.age], 0

            ; Update final zones length
            mov rax, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
            mov rbx, 80                    ; sizeof(zone_info)
            mul rbx
            add rax, 7                     ; align to 8 bytes
            and rax, ~7
            mov qword [rel global_memory_info_ptr + global_memory_info.zones_count], rax



    ;Print memory management information
        mov r13, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_addr]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.bitmap_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_size]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.bitmap_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_bits_map_count]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx



        mov r13, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_addr]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.pages_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_size]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.pages_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_pages_count]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx



        mov r13, qword [rel global_memory_info_ptr + global_memory_info.zones_addr]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_addr]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_size]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        mov r13, qword [rel global_memory_info_ptr + global_memory_info.zones_count]
        mov [rel memory_hex_messages], r13
        lea rsi, [rel memory_zones_count]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx



    mov qword [rel ZONE_DMA_INDEX], 0
    mov qword [rel ZONE_NORMAL_INDEX], 0


    ; Add this code after the zone initialization loop
    ; Print zone information
    mov rcx, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
    mov rsi, qword [rel global_memory_info_ptr + global_memory_info.zones_addr]

    .print_zones_loop:
        push rcx
        push rsi
        
        ; Print zone information
        mov rax, qword [rsi + zone_info.zone_start_address]
        mov [rel memory_hex_messages], rax
        lea rdi, [rel zone_start_addr_msg]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rdi, rdx
        
        mov rax, qword [rsi + zone_info.zone_end_address]
        mov [rel memory_hex_messages], rax
        lea rdi, [rel zone_end_addr_msg]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rdi, rdx
        
        mov rax, qword [rsi + zone_info.zone_length]
        mov [rel memory_hex_messages], rax
        lea rdi, [rel zone_length_msg]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rdi, rdx
        
        mov rax, qword [rsi + zone_info.pages_group]
        mov [rel memory_hex_messages], rax
        lea rdi, [rel pages_group_msg]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rdi, rdx
        
        mov rax, qword [rsi + zone_info.pages_length]
        mov [rel memory_hex_messages], rax
        lea rdi, [rel pages_length_msg]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rdi, rdx

        ; Check if zone_start_address is 0x100000000
        mov rax, qword [rsi + zone_info.zone_start_address]
        push rbx
        mov rbx, qword 0x100000000
        cmp rax, rbx
        pop rbx
        jne .continue_zone_print
        
        ; Store current zone index as ZONE_UNMAPED_INDEX
        mov rax, qword [rel global_memory_info_ptr + global_memory_info.zones_size]
        sub rax, rcx
        mov [rel ZONE_UNMAPED_INDEX], rax

    .continue_zone_print:
        pop rsi
        add rsi, 80                    ; Move to next zone structure
        pop rcx
        dec rcx
        jnz .print_zones_loop

        ; Calculate end_of_struct address
        mov rax, qword [rel global_memory_info_ptr + global_memory_info.zones_addr]    ; zones_struct address
        add rax, qword [rel global_memory_info_ptr + global_memory_info.zones_count]   ; add zones_length
        add rax, 256                                                                   ; add sizeof(long) * 32
        and rax, ~7                                                                    ; align to 8-byte boundary (~(sizeof(long) - 1))
        mov qword [rel global_memory_info_ptr + global_memory_info.end_of_global_memory_info], rax ; store result

        Virt_To_Phy rax

        shr rax, MEMORY_PAGE_2M_SHIFT


        ; Save number of pages to initialize (i value) in r12
        mov r12, rax
        
        ; Initialize each page from 0 to i
        xor r13, r13                    ; j = 0
    .init_kernel_pages:
        ; Calculate current page address
        mov rdi, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
        mov rax, r13                    ; j
        mov rbx, 40                     ; sizeof(page_info)
        mul rbx                         ; j * sizeof(page_info)
        add rdi, rax                    ; pages_struct + j
        
        ; Set up flags
        mov esi, PG_PTable_Maped | PG_Kernel_Init | PG_Active | PG_Kernel

        ; Call page_init
        push r12
        push r13
        function page_init, 1, rdi, rsi
        pop r13
        pop r12
        
        ; Increment j and compare with i
        inc r13
        cmp r13, r12
        jle .init_kernel_pages          ; Continue if j <= i




        ; Get CR3 value and store in Global_CR3
        function Get_gdt,1,0
        mov rax,[rsp-8]

        mov [rel Global_CR3], rax

        ; Print CR3 values
        mov [rel memory_hex_messages], rax
        lea rsi, [rel cr3_msg1]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        ; Print *Global_CR3
        mov rdi, rax
        Phy_To_Virt rdi
        mov rax, qword [rdi]
        and rax, ~0xff
        mov [rel memory_hex_messages], rax
        lea rsi, [rel cr3_msg2]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        ; Print **Global_CR3
        mov rdi, rax
        Phy_To_Virt rdi
        mov rax, qword [rdi]
        and rax, ~0xff
        mov [rel memory_hex_messages], rax
        lea rsi, [rel cr3_msg3]
        lea rdx, [rel memory_hex_messages]
        function printk, 1, rsi, rdx

        ; Clear first 10 CR3 entries
        mov rdi, [rel Global_CR3]
        Phy_To_Virt rdi
        xor rcx, rcx
    .clear_cr3_loop:
        mov qword [rdi + rcx * 8], 0
        inc rcx
        cmp rcx, 10
        jl .clear_cr3_loop

        ; Flush TLB
        function flush_tlb


        epilog


; Function to flush single TLB entry
; Input: rdi = virtual address to invalidate
flush_tlb_one:
    prolog 1
    get_param rdi, 1
    invlpg [rdi]
    epilog

; Function to flush entire TLB
flush_tlb:
    prolog 0
    mov rax, cr3      ; Get current CR3
    mov cr3, rax      ; Write back to CR3 to flush TLB
    epilog

; Function to get CR3 value (GDT base)
Get_gdt:
    prolog 0
    mov rax, cr3      ; Get CR3 value
    ; jmp $
    set_ret_param rax, 2
    epilog            ; Return value in rax
; page_init function
page_init:
    prolog 2
    get_param rdi, 1      ; page struct pointer
    get_param rsi, 2      ; flags

    ; Check if page->attribute is 0
    cmp qword [rdi + page_info.page_attribute], 0
    jnz .page_has_attribute

    ; First initialization path
    mov rax, qword [rdi + page_info.physical_address]
    shr rax, MEMORY_PAGE_2M_SHIFT   ; Get page number
    mov rbx, rax
    shr rbx, 6                      ; Get bitmap long index

    and rax, 63                     ; Get bit position
    mov rcx, rax
    mov r8, 1
    shl r8, cl                      ; Create bit mask
    mov r9, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
    or qword [r9 + rbx * 8], r8     ; Set bit in bitmap


    ; Set page attributes
    mov qword [rdi + page_info.page_attribute], rsi
    inc qword [rdi + page_info.reference_count]
    
    ; Update zone counters
    mov r10, qword [rdi + page_info.zone_info_address]
    inc qword [r10 + zone_info.page_using_count]
    dec qword [r10 + zone_info.page_free_count]
    inc qword [r10 + zone_info.total_pages_link]
    jmp .done

    .page_has_attribute:
        ; Check for special flags
        mov rax, qword [rdi + page_info.page_attribute]
        mov rdx, rsi
        mov r8, PG_Referenced | PG_K_Share_To_U
        test rax, r8
        jnz .special_flags
        test rdx, r8
        jnz .special_flags

        ; Regular update path
        mov rax, qword [rdi + page_info.physical_address]
        shr rax, MEMORY_PAGE_2M_SHIFT
        mov rdx, rax
        shr rdx, 6
        and rax, 63
        mov rcx, rax
        mov r8, 1
        shl r8, cl
        mov r9, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
        or qword [r9 + rdx * 8], r8
        
        or qword [rdi + page_info.page_attribute], rsi
        jmp .done

    .special_flags:
        ; Update with reference counting
        or qword [rdi + page_info.page_attribute], rsi
        inc qword [rdi + page_info.reference_count]
        mov r10, qword [rdi + page_info.zone_info_address]
        inc qword [r10 + zone_info.total_pages_link]

    .done:
        xor rax, rax                    ; Return 0
    epilog

page_clean:
    prolog 2
    get_param rdi, 1                ; page struct pointer

    ; Check if page->attribute is 0
    cmp qword [rdi + page_info.page_attribute], 0
    jnz .has_attribute

    ; No attribute case
    mov qword [rdi + page_info.page_attribute], 0
    jmp .done

    .has_attribute:
        ; Check for special flags
        mov rax, qword [rdi + page_info.page_attribute]
        mov r8, PG_Referenced | PG_K_Share_To_U
        test rax, r8
        jz .regular_clean

        ; Special flags cleanup
        dec qword [rdi + page_info.reference_count]
        mov r10, qword [rdi + page_info.zone_info_address]
        dec qword [r10 + zone_info.total_pages_link]
        
        cmp qword [rdi + page_info.reference_count], 0
        jnz .done
        
        ; Reference count reached 0
        mov qword [rdi + page_info.page_attribute], 0
        dec qword [r10 + zone_info.page_using_count]
        inc qword [r10 + zone_info.page_free_count]
        jmp .done

    .regular_clean:
        ; Clear bit in bitmap
        mov rax, qword [rdi + page_info.physical_address]
        shr rax, MEMORY_PAGE_2M_SHIFT
        mov rdx, rax
        shr rdx, 6
        and rax, 63
        mov rcx, rax
        mov r8, 1
        shl r8, cl
        not r8
        mov r9, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
        and qword [r9 + rdx * 8], r8

        ; Reset page attributes and counters
        mov qword [rdi + page_info.page_attribute], 0
        mov qword [rdi + page_info.reference_count], 0
        mov r10, qword [rdi + page_info.zone_info_address]
        dec qword [r10 + zone_info.page_using_count]
        inc qword [r10 + zone_info.page_free_count]
        dec qword [r10 + zone_info.total_pages_link]

    .done:
        xor rax, rax                    ; Return 0
    epilog
kmemset:;input:dest_addr,value,count
    prolog 2;
    get_param rdi,1 ;dest_addr
    get_param rsi,2 ;fill value
    get_param rdx,3 ;count byte

    ; Extend the value to 64 bit
    movzx rax, sil 

    mov rbx, rax

    shl rax, 8              
    or rax, rbx

    shl rax, 8             
    or rax, rbx

    shl rax, 8             
    or rax, rbx

    shl rax, 8             
    or rax, rbx    

    shl rax, 8             
    or rax, rbx

    shl rax, 8             
    or rax, rbx

    shl rax, 8             
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



alloc_pages:; Input: rdi = zone_select, rsi = number, rdx = page_flags
    prolog 8              ; Need local variables
    get_param rdi, 1      ; zone_select
    get_param rsi, 2      ; number
    get_param rdx, 3      ; page_flags
    mov qword [rbp - 8], rdx
    ; Initialize local variables
    ; push 0                ; page = 0
    mov r8, 0            ; zone_start = 0
    mov r9, 0            ; zone_end = 0

    ; Switch on zone_select
    cmp rdi, ZONE_DMA
    je .zone_dma
    cmp rdi, ZONE_NORMAL
    je .zone_normal
    cmp rdi, ZONE_UNMAPED
    je .zone_unmaped
    jmp .error_exit

    .zone_dma:
        mov r8, 0                    ; zone_start = 0
        mov r9, [rel ZONE_DMA_INDEX] ; zone_end = ZONE_DMA_INDEX
        jmp .search_zones

    .zone_normal:
        mov r8, [rel ZONE_DMA_INDEX]     ; zone_start = ZONE_DMA_INDEX
        mov r9, [rel ZONE_NORMAL_INDEX]  ; zone_end = ZONE_NORMAL_INDEX
        jmp .search_zones

    .zone_unmaped:
        mov r8, [rel ZONE_UNMAPED_INDEX] ; zone_start = ZONE_UNMAPED_INDEX
        mov rax, [rel global_memory_info_ptr + global_memory_info.zones_size]
        dec rax
        mov r9, rax                      ; zone_end = zones_size - 1
        jmp .search_zones

    .error_exit:
        ; Print error message
        lea rsi, [rel alloc_pages_error_msg]
        lea rdx, [rel null_str]
        function printk, 1, rsi, rdx
        xor rax, rax                     ; Return NULL
        set_ret_param rax, 4
        epilog

    .search_zones:
        mov r12, r8                      ; i = zone_start
    ; Input: 
    ; r12 = i (zone index)
    ; r9 = zone_end
    ; rsi = number (number of pages requested)
    ; rdx = page_flags

    .zone_loop:
        ; Get current zone pointer
        mov r13, qword [rel global_memory_info_ptr + global_memory_info.zones_addr]
        mov rax, r12                    ; i
        mov rbx, 80                     ; sizeof(zone_info)
        mul rbx
        add r13, rax                    ; z = zones_struct + i

        ; Check if zone has enough free pages
        mov rax, qword [r13 + zone_info.page_free_count]
        cmp rax, rsi                    ; compare with number
        jl .next_zone

        ; Calculate page range
        mov r14, qword [r13 + zone_info.zone_start_address]
        shr r14, MEMORY_PAGE_2M_SHIFT   ; start
        mov r15, qword [r13 + zone_info.zone_end_address]
        shr r15, MEMORY_PAGE_2M_SHIFT   ; end

        ; Calculate tmp = 64 - start % 64
        ; mov rax, r14
        ; mov rbx, 64
        ; xor rdx, rdx
        ; div rbx                         ; rdx = start % 64
        ; mov rax, 64
        ; sub rax, rdx
        ; mov rbx, rax                    ; rbx = tmp

        mov  rax, r14        ; start
        and  rax, 63         ; rax = start % 64
        mov  rbx, 64         ; rbx = 64
        sub  rbx, rax        ; rbx = 64 - (start % 64)


        ; For loop: j = start
        mov rcx, r14                    ; j = start
    .page_search_loop:
        ; Calculate bitmap position
        mov rax, rcx                    ; j
        mov r8, 64
        xor rdx, rdx
        div r8                          ; rax = j/64, rdx = j%64

        ; Get bitmap pointer
        mov r10, qword [rel global_memory_info_ptr + global_memory_info.bitmap_addr]
        lea r10, [r10 + rax * 8]       ; p = bits_map + (j >> 6)

        ; Inner loop
        mov r8, rdx                     ; k = shift
    .inner_loop:
        ; Calculate ((*p >> k) | (*(p + 1) << (64 - k)))
        mov rax, qword [r10]           ; *p
        mov r9, r8

        push rcx
        mov rcx,r9
        shr rax, cl                    ; *p >> k
        pop rcx

        mov rbx, qword [r10 + 8]       ; *(p + 1)
        mov r9, 64
        sub r9, r8                      ; 64 - k

        push rcx
        mov rcx,r9
        shl rbx, cl                    ; *(p + 1) << (64 - k)
        pop rcx
               

        or rax, rbx                    ; combine with OR

        ; Create mask based on number
        cmp rsi, 64
        je .full_mask

        mov rbx, 1
        push rcx
        mov rcx, rsi
        shl rbx, cl                    ; 1UL << number
        pop rcx
        dec rbx                        ; (1UL << number) - 1
        jmp .check_mask

    .full_mask:
        mov rbx, -1                    ; 0xffffffffffffffff

    .check_mask:

        and rax, rbx                   ; Check against mask

        jnz .continue_inner

        ; Found free pages - initialize them
        mov rax,rcx
        add rax,r8
        ; lea rax, [rcx + r8]
        dec rax                        ; page = j + k - 1
        mov r11, rax                   ; Save page number

        ; Initialize pages
        mov rcx, rsi                   ; number of pages to init
    .init_pages:
        push rcx
        
        ; Calculate page address
        mov rdi, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
        mov rax, r11
        mov rbx, 40                    ; sizeof(page_info)
        mul rbx
        add rdi, rax                   ; pages_struct + page

        push r11
        mov r11,qword [rbp - 8]

        function page_init, 1, rdi, r11
        pop r11

        inc r11
        pop rcx
        dec rcx
        jnz .init_pages

        ; Return pointer to first page
        mov rbx, qword [rel global_memory_info_ptr + global_memory_info.pages_addr]
        mov rax, r11
        sub rax, rsi                   ; subtract number to get first page
        mov rcx, 40                    ; sizeof(page_info)
        mul rcx
        add rax, rbx

        set_ret_param rax, 4
        epilog

    .continue_inner:

        inc r8                        ; k++
        mov rax, 64
        sub rax, rdx                  ; 64 - shift
        cmp r8, rax
        jl .inner_loop

        ; Update j for next iteration
        mov rax, rcx
        mov rbx, 64
        xor rdx, rdx
        div rbx                       ; Get j % 64 in rdx
        test rdx, rdx
        cmovnz rax, rbx              ; Use tmp if j % 64 != 0
        add rcx, rax                 ; j += (j % 64 ? tmp : 64)
        cmp rcx, r15
        jle .page_search_loop

    .next_zone:
        inc r12                      ; i++
        cmp r12, r9
        jle .zone_loop

        ; No free pages found
        xor rax, rax                 ; Return NULL
        set_ret_param rax, 4
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