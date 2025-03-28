fasm ../bootloader/boot.asm  boot.bin
fasm ../bootloader/loader.asm  loader.bin
# fasm ../kernel/head.asm  head.bin
nasm ../kernel/head.asm  -o head.bin
nasm ../kernel/kernel.asm  -o kernel.bin

dd if=boot.bin of=../hd60m.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=../hd60m.img bs=512 seek=1 conv=notrunc
dd if=/dev/zero of=../hd60m.img bs=512 seek=5 count=100 conv=notrunc
dd if=head.bin of=../hd60m.img bs=512 seek=16 conv=notrunc
dd if=kernel.bin of=../hd60m.img bs=512 seek=65 conv=notrunc
rm -rf ./*.bin
# qemu-system-x86_64 -S -hda ../hd60m.img -monitor stdio
qemu-system-x86_64 -m 1024M -hda ../hd60m.img -monitor stdio -vga std