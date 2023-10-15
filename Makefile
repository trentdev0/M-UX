CC := x86_64-elf-gcc
AS := x86_64-elf-as
OBJCOPY := x86_64-elf-objcopy
CFLAGS := -g -pipe -Wall -Wextra -std=gnu11 -ffreestanding -fno-stack-protector -fno-stack-check -fno-lto -fno-pie -fno-pic -m64 -march=x86-64 -mabi=sysv -mno-80387 -mno-mmx -mno-sse -mno-sse2 -mno-red-zone -mcmodel=kernel -I. -MMD
LDFLAGS := -Tlinker.ld -ffreestanding -nostdlib

SRC_DIR := kernel
SRC_C_FILES := $(wildcard $(SRC_DIR)/*.c)
SRC_S_FILES := $(wildcard $(SRC_DIR)/*.S)
OBJ_C_FILES := $(patsubst $(SRC_DIR)/%.c, $(SRC_DIR)/%.o, $(SRC_C_FILES))
OBJ_S_FILES := $(patsubst $(SRC_DIR)/%.S, $(SRC_DIR)/%.o, $(SRC_S_FILES))
OBJ_FILES := $(OBJ_C_FILES) $(OBJ_S_FILES)

.PHONY: all clean limine cdrom run run-serial

all: kernel.elf cdrom

cdrom:
	mkdir -p bootdisk
	cp -v kernel.elf limine.cfg limine/limine.sys limine/limine-cd.bin limine/limine-cd-efi.bin bootdisk/
	xorriso -as mkisofs -b limine-cd.bin --no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-cd-efi.bin -efi-boot-part --efi-boot-image --protective-msdos-label bootdisk -o image.iso
	limine/limine-deploy image.iso

kernel.elf: $(OBJ_FILES)
	$(CC) $(LDFLAGS) $^ -o $@

$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(SRC_DIR)/%.o: $(SRC_DIR)/%.S
	$(AS) $< -o $@

limine:
	git clone https://github.com/limine-bootloader/limine.git --branch=v4.x-branch-binary --depth=1
	make -C limine

run:
	qemu-system-x86_64 -cdrom image.iso

run-serial:
	xterm -hold -e "qemu-system-x86_64 -nographic -serial mon:stdio -cdrom image.iso"

clean:
	rm -f kernel/*.o kernel/*.d kernel.elf image.iso