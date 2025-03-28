cd ./bootloader
make
dd if=./boot.bin of=../a.img bs=512 count=1 conv=notrunc

sudo mount ../a.img /media/ -t vfat -o loop
sudo cp loader.bin	/media/
sudo sync
make clean

cd ../kernel
make

sudo cp kernel.bin	/media/
sudo sync
make clean
sudo umount /media/

cd ..

qemu-system-x86_64 -fda ./a.img -monitor stdio -vga std