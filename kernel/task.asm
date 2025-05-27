%ifndef TASK_ASM
%define TASK_ASM

%include "../bootloader/global_def.asm"
%include "../kernel/stddef.asm"

[BITS 64]

    ; struc context
    ;     .street:     resb 50
    ;     .city:       resb 30
    ;     .zipcode:    resd 1
    ; endstruc

    ; struc Person
    ;     .name:       resb 32
    ;     .age:        resd 1
    ;     .address:    resb Address_size    ; Nested Address structure
    ; endstruc

    ; ; Initialize structure data
    ; person_data:
    ;     istruc Person
    ;         at Person.name,    db 'John Doe', 0
    ;         at Person.age,     dd 30
    ;         istruc Address
    ;             at Address.street,     db '123 Main St', 0
    ;             at Address.city,       db 'New York', 0
    ;             at Address.zipcode,    dd 10001
    ;         iend
    ;     iend

; Task structure definition PCB and TCB
struc PCB
    .prv            resq    1
    .next           resq    1

    .state:         resq    1       ; volatile long (8 bytes)
    .flags:         resq    1       ; unsigned long (8 bytes)

    .mm:            resq    1       ; pointer to mm_struct (8 bytes)
    .thread:        resq    1       ; pointer to thread_struct (8 bytes)
    
    .addr_limit:    resq    1       ; unsigned long (8 bytes)
    .pid:           resq    1       ; long (8 bytes)
    .counter:       resq    1       ; long (8 bytes)
    .signal:        resq    1       ; long (8 bytes)
    .priority:      resq    1       ; long (8 bytes)
    endstruc

pcb_list_head_ptr : dq 0
pcb_current_ptr : dq 0

; Address limit constants
%define USER_ADDR_LIMIT    0x00007FFFFFFFFFFF    ; User space limit
%define KERNEL_ADDR_LIMIT  0xFFFFFFFFFFFFFFFF    ; Kernel space limit

task_init;creat and fill pcb
    prolog 0

    epilog

task_schedule
    prolog 0

    epilog
creat_process;creat and fill pcb
    prolog 0
                                                  ;输入：R8=程序的起始逻辑扇区号

         ;首先在地址空间的高端（内核）创建任务控制块PCB
         mov rcx, 512                             ;任务控制块PCB的尺寸
         call core_memory_allocate                ;在虚拟地址空间的高端（内核）分配内存

         mov r11, r13                             ;以下，R11专用于保存PCB线性地址

         mov qword [r11 + 24], USER_ALLOC_START   ;填写PCB的下一次可分配线性地址域

         ;从当前活动的4级头表复制并创建新任务的4级头表。
         call copy_current_pml4
         mov [r11 + 56], rax                      ;填写PCB的CR3域，默认PCD=PWT=0

         ;以下，切换到新任务的地址空间，并清空其4级头表的前半部分。不过没有关系， 我们正
         ;在地址空间的高端执行，可正常执行内核代码并访问内核数据，毕竟所有任务的高端（全
         ;局）部分都相同。同时，当前使用的栈位于地址空间高端的栈。
         mov r15, cr3                             ;保存控制寄存器CR3的值
         mov cr3, rax                             ;切换到新4级头表映射的新地址空间

         ;清空当前4级头表的前半部分（对应于任务的局部地址空间）
         mov rax, 0xffff_ffff_ffff_f000           ;当前活动4级头表自身的线性地址
         mov rcx, 256
  .clsp:
         mov qword [rax], 0
         add rax, 8
         loop .clsp

         mov rax, cr3                             ;刷新TLB
         mov cr3, rax

         mov rcx, 4096 * 16                       ;为TSS的RSP0开辟栈空间
         call core_memory_allocate                ;必须是在内核的空间中开辟
         mov [r11 + 32], r14                      ;填写PCB中的RSP0域的值

         mov rcx, 4096 * 16                       ;为用户程序开辟栈空间
         call user_memory_allocate
         mov [r11 + 120], r14                     ;用户程序执行时的RSP。

         mov qword [r11 + 16], 0                  ;任务状态=就绪

         ;以下开始加载用户程序
         mov rcx, 512                             ;在私有空间开辟一个缓冲区
         call user_memory_allocate
         mov rbx, r13
         mov rax, r8                              ;用户程序起始扇区号
         call read_hard_disk_0

         mov [r13 + 16], r13                      ;在程序中填写它自己的起始线性地址
         mov r14, r13
         add r14, [r13 + 8]
         mov [r11 + 192], r14                     ;在PCB中登记程序的入口点线性地址

         ;以下判断整个程序有多大
         mov rcx, [r13]                           ;程序尺寸
         test rcx, 0x1ff                          ;能够被512整除吗？
         jz .y512
         shr rcx, 9                               ;不能？凑整。
         shl rcx, 9
         add rcx, 512
  .y512:
         sub rcx, 512                             ;减去已经读的一个扇区长度
         jz .rdok
         call user_memory_allocate
         ;mov rbx, r13
         shr rcx, 9                               ;除以512，还需要读的扇区数
         inc rax                                  ;起始扇区号
  .b1:
         call read_hard_disk_0
         inc rax
         loop .b1                                 ;循环读，直到读完整个用户程序

  .rdok:
         mov qword [r11 + 200], USER_CODE64_SEL   ;新任务的代码段选择子
         mov qword [r11 + 208], USER_STACK64_SEL  ;新任务的栈段选择子

         pushfq
         pop qword [r11 + 232]

         call generate_process_id
         mov [r11 + 8], rax                       ;记录当前任务的标识

         call append_to_pcb_link                  ;将PCB添加到进程控制块链表尾部

         mov cr3, r15                             ;切换到原任务的地址空间

    epilog

append_to_pcb_link;creat and fill pcb
    prolog 0

    epilog
%endif

