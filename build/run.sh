



if [ $# == 0 ]
then
        a="%define DEBUG_PLATFORM PLATFORM_QEMU_X64"
        sed -i "5c $a" ../bootloader/global_def.asm

else
    if [ $1 == "run" ]
        then

        a="%define DEBUG_PLATFORM PLATFORM_X64"
        sed -i "5c $a" ../bootloader/global_def.asm

    else
        a="%define DEBUG_PLATFORM PLATFORM_QEMU_X64"
        sed -i "5c $a" ../bootloader/global_def.asm

    fi
fi



dd if=/dev/zero of=./hd60m.img bs=512 seek=0 count=100 conv=notrunc
nasm ../bootloader/boot.asm  -o boot.bin
nasm ../bootloader/loader.asm  -o loader.bin
nasm ../kernel/head.asm  -o head.bin
nasm ../kernel/kernel.asm  -o kernel.bin -l kernel.lst


dd if=boot.bin of=./hd60m.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=./hd60m.img bs=512 seek=1 conv=notrunc
cat head.bin kernel.bin > ./kernel.img
dd if=kernel.img of=./hd60m.img bs=512 seek=16 conv=notrunc

rm -rf ./*.bin
# qemu-system-x86_64 -S -hda ../hd60m.img -monitor stdio -display sdl
# -display vnc=127.0.0.1:0,key-delay-ms=0,connections=15000,to=2,lossy=on,non-adaptive=off 

if [ $# == 0 ]
then
        a="%define DEBUG_PLATFORM PLATFORM_QEMU_X64"
        sed -i "5c $a" ../bootloader/global_def.asm
        qemu-system-x86_64 -m 2048M -hda ./hd60m.img -monitor stdio -vga std -rtc base=utc 
else
    if [ $1 == "run" ]
        then

        a="%define DEBUG_PLATFORM PLATFORM_X64"
        sed -i "5c $a" ../bootloader/global_def.asm

        sudo dd if=./hd60m.img of=/dev/sda
    else
        a="%define DEBUG_PLATFORM PLATFORM_QEMU_X64"
        sed -i "5c $a" ../bootloader/global_def.asm
        # sudo dd if=./hd60m.img of=/dev/sda
        qemu-system-x86_64 -m 2048M -hda ./hd60m.img -monitor stdio -vga std -rtc base=utc
    fi
fi

        # qemu-system-x86_64 -m 2048M -hda ./hd60m.img -monitor stdio -vga std -rtc base=utc -spice port=5900,addr=127.0.0.1,disable-ticketing=on &
        # remote-viewer spice://127.0.0.1:5900

        # qemu-system-x86_64 -m 2048M -hda ./hd60m.img -monitor stdio -vga std -rtc base=utc -full-screen 
# -display gtk,gl=on,full-screen=on -vga virtio -device virtio-vga-gl
# qemu-system-x86_64 -m 1024M -hda ./hd60m.img -vga std -g 1920x1080x32 -display sdl 
# qemu-system-x86_64 -m 1024M -hda ./hd60m.img -monitor stdio -vga std -S -s

