nasm ../bootloader/boot.asm  -o boot.bin
nasm ../bootloader/loader.asm  -o loader.bin
nasm ../kernel/head.asm  -o head.bin
nasm ../kernel/kernel.asm  -o kernel.bin -l kernel.lst

dd if=/dev/zero of=./hd60m.img bs=512 count=8 conv=notrunc
dd if=boot.bin of=./hd60m.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=./hd60m.img bs=512 seek=1 conv=notrunc

dd if=/dev/zero of=./hd60m.img bs=512 seek=8 count=100 conv=notrunc
cat head.bin kernel.bin > ./kernel.img
dd if=kernel.img of=./hd60m.img bs=512 seek=16 conv=notrunc

rm -rf ./*.bin
# qemu-system-x86_64 -S -hda ../hd60m.img -monitor stdio

qemu-system-x86_64 -m 1024M -hda ./hd60m.img -monitor stdio -vga std
# qemu-system-x86_64 -m 1024M -hda ./hd60m.img -monitor stdio -vga std -S -s

