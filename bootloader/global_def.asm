%ifndef GLOBAL_DEF_ASM
%define GLOBAL_DEF_ASM
%define PLATFORM_QEMU_X64 1
%define PLATFORM_X64 2
%define DEBUG_PLATFORM PLATFORM_QEMU_X64
%define DEBUG_MODE 1


;|----------------------|
;|	100000 ~ END	|
;|	   KERNEL	|
;|----------------------|
;|	E0000 ~ 100000	|
;| Extended System BIOS |
;|----------------------|
;|	C0000 ~ Dffff	|
;|     Expansion Area   |
;|----------------------|
;|	A0000 ~ bffff	|
;|   Legacy Video Area  |
;|----------------------|
;|	9f000 ~ A0000	|
;|	 BIOS reserve	|
;|----------------------|
;|	90000 ~ 9f000	|
;|	 kernel tmpbuf	|
;|----------------------|
;|	10000 ~ 90000	|
;|	   LOADER	|
;|----------------------|
;|	8000 ~ 10000	|
;|	  VBE info	|
;|----------------------|
;|	7e00 ~ 8000	|
;|	  mem info	|
;|----------------------|
;|	7c00 ~ 7e00	|
;|	 MBR (BOOT)	|
;|----------------------|
;|	0000 ~ 7c00	|
;|	 BIOS Code	|
;|----------------------|


;_______________________________________________________
; START	END	    SIZE	        USED
; FFFF0	FFFFF	16B	        BIOS System Entry
; F0000	FFFEF	64KB-16B	BIOS System Code
; C8000	EFFFF	160KB	    ROM/Mapped IO
; C0000	C7FFF	32KB	    Graphic Adapter BIOS
; B8000	BFFFF	32KB	    Chroma Text Video Buffer
; B0000	B7FFF	32KB	    Mono Text Video Buffer
; A0000	AFFFF	64KB	    Graphic Video Buffer
; 9FC00	9FFFF	1KB	        Extended BIOS Data Area
; 7E00	9FBFF	622080B     Useable 608KB	
; 7C00	7DFF	512B	    MBR
; 500	7BFF	30464B      Useable 30KB	
; 400	4FF	    256B	    BIOS Data Area
; 000	3FF	    1KB	        IVT
; _____________________________________________________











;|----------------------|
;|	100000 ~ END	|
;|	   KERNEL	|
;|----------------------|
;|	E0000 ~ 100000	|
;| Extended System BIOS |
;|----------------------|
;|	C0000 ~ Dffff	|
;|     Expansion Area   |
;|----------------------|
;|	A0000 ~ bffff	|
;|   Legacy Video Area  |
;|----------------------|
;|	9F000 ~ A0000	|
;|	 BIOS reserve	|
;|----------------------|
;|	90000 ~ 9F000	|
;|	 kernel tmpbuf	|
;|----------------------|
;|	10000 ~ 90000	|
;|	   LOADER	|
;|----------------------|
;|	8000 ~ 10000	|
;|	  VBE info	|
;|----------------------|
;|	7E00 ~ 8000	|
;|	  mem info	|
;|----------------------|
;|	7C00 ~ 7E00	|
;|	 MBR (BOOT)	|
;|----------------------|
;|	0000 ~ 7C00	|
;|	 BIOS Code	|
;|----------------------|










;______________________________________________
; ----------------Vbe Info Block------------
; typedef struct {
;     unsigned char       vbe_signature;
;     unsigned short      vbe_version;
;     unsigned long       oem_string_ptr;
;     unsigned char       capabilities;
;     unsigned long       video_mode_ptr;
;     unsigned short      total_memory;
;     unsigned short      oem_software_rev;
;     unsigned long       oem_vendor_name_ptr;
;     unsigned long       oem_product_name_ptr;
;     unsigned long       oem_product_rev_ptr;
;     unsigned char       reserved[222];
;     unsigned char       oem_data[256];  
; } VbeInfoBlock;
;______________________________________________


BaseOfKernelFile	equ	0x00
OffsetOfKernelFile	equ	0x100000
BaseTmpOfKernelAddr	equ	0x9000
OffsetTmpOfKernelFile	equ	0x0000
VBEStructBufferAddr	equ	0x8000
VBEModeStructBufferAddr	equ	0x8200
MemoryStructBufferAddr	equ	0x8800



KernelSpaceUpperAddress equ 0xFFFF800000000000

GDTPointerUpperAddr equ 0xFFFF800000104000
IDTPointerUpperAddr equ 0xFFFF80000010400a
TSSPointerUpperAddr equ 0xFFFF800000104014

VideoFrameBufferAddress equ 0xFFFF800003000000
KernelStartSectorNum	equ	16




MasterSectorReadNumPort    equ	0x1F2
MasterSectorReadPort    equ	0x1F0

SlaveReadNumPort    equ	0x172
SlaveSectorReadPort    equ	0x170

SectorReadNumPort    equ	MasterSectorReadNumPort
SectorReadPort    equ	MasterSectorReadPort

struc vbe_info_block
    .signature                 resb 4    ; 'VESA' signature (must be "VESA")
    .version                   resw 1    ; VBE version (e.g., 0x0300 for VBE 3.0)
    .oem_string_ptr            resd 1    ; Pointer to OEM string
    .capabilities              resd 1    ; Capabilities of the video card
    .video_mode_ptr            resd 1    ; Pointer to supported video modes
    .total_memory              resw 1    ; Total memory in 64KB blocks

    ; VBE 2.0+ fields
    .oem_software_rev          resw 1    ; OEM software revision
    .oem_vendor_name_ptr       resd 1    ; Pointer to OEM vendor name string
    .oem_product_name_ptr      resd 1    ; Pointer to OEM product name string
    .oem_product_rev_ptr       resd 1    ; Pointer to OEM product revision string
    .reserved                  resb 222  ; Reserved for VBE implementation
    .oem_data                  resb 256  ; Data area for OEM-specific information
endstruc

struc vbe_mode_info_block
    .attributes                resw 1    ; Mode attributes
    .winA_attributes           resb 1    ; Window A attributes
    .winB_attributes           resb 1    ; Window B attributes
    .win_granularity           resw 1    ; Window granularity in KB
    .win_size                  resw 1    ; Window size in KB
    .winA_segment              resw 1    ; Window A segment
    .winB_segment              resw 1    ; Window B segment
    .win_func_ptr              resd 1    ; Pointer to window function
    .bytes_per_scanline        resw 1    ; Bytes per scanline

    ; VBE 1.2+ fields
    .x_resolution              resw 1    ; Horizontal resolution in pixels
    .y_resolution              resw 1    ; Vertical resolution in pixels
    .x_char_size               resb 1    ; Character cell width in pixels
    .y_char_size               resb 1    ; Character cell height in pixels
    .number_of_planes          resb 1    ; Number of memory planes
    .bits_per_pixel            resb 1    ; Bits per pixel
    .number_of_banks           resb 1    ; Number of banks
    .memory_model              resb 1    ; Memory model type
    .bank_size                 resb 1    ; Bank size in KB
    .number_of_image_pages     resb 1    ; Number of images
    .reserved1                 resb 1    ; Reserved

    ; Direct Color fields (VBE 1.2+)
    .red_mask_size             resb 1    ; Size of direct color red mask
    .red_field_position        resb 1    ; Bit position of red mask
    .green_mask_size           resb 1    ; Size of direct color green mask
    .green_field_position      resb 1    ; Bit position of green mask
    .blue_mask_size            resb 1    ; Size of direct color blue mask
    .blue_field_position       resb 1    ; Bit position of blue mask
    .reserved_mask_size        resb 1    ; Size of direct color reserved mask
    .reserved_field_position   resb 1    ; Bit position of reserved mask
    .direct_color_mode_info    resb 1    ; Direct color mode attributes

    ; VBE 2.0+ fields
    .phys_base_ptr             resd 1    ; Physical address for flat memory frame buffer
    .reserved2                 resd 1    ; Reserved
    .reserved3                 resw 1    ; Reserved

    ; VBE 3.0+ fields
    .lin_bytes_per_scanline    resw 1    ; Bytes per scanline for linear modes
    .bnk_number_of_image_pages resb 1    ; Number of images for banked modes
    .lin_number_of_image_pages resb 1    ; Number of images for linear modes
    .lin_red_mask_size         resb 1    ; Size of direct color red mask (linear modes)
    .lin_red_field_position    resb 1    ; Bit position of red mask (linear modes)
    .lin_green_mask_size       resb 1    ; Size of direct color green mask (linear modes)
    .lin_green_field_position  resb 1    ; Bit position of green mask (linear modes)
    .lin_blue_mask_size        resb 1    ; Size of direct color blue mask (linear modes)
    .lin_blue_field_position   resb 1    ; Bit position of blue mask (linear modes)
    .lin_reserved_mask_size    resb 1    ; Size of direct color reserved mask (linear modes)
    .lin_reserved_field_position resb 1  ; Bit position of reserved mask (linear modes)
    .max_pixel_clock           resd 1    ; Maximum pixel clock (Hz)
    .reserved4                 resb 190  ; Reserved for future expansion
endstruc

struc e820_memory_entry
    .base_addr_low            resd 1    ; Lower 32 bits of the base address
    .base_addr_high           resd 1    ; Upper 32 bits of the base address
    .length_low               resd 1    ; Lower 32 bits of the length
    .length_high              resd 1    ; Upper 32 bits of the length
    .type                     resd 1    ; Memory type (1 = usable, others = reserved, etc.)
    ; .acpi_attributes          resd 1    ; ACPI 3.0+ attributes (optional, may be zero)
endstruc

%endif