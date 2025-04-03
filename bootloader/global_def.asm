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
MemoryStructBufferAddr	equ	0x8800