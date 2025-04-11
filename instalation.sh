#!/bin/bash

set -e

# Define disco e nome do host
DISK="/dev/sda"
HOST="archdev"
USERNAME="fireeletric"
PASSWORD="amora0182"

# Particiona o disco (GPT + EFI + root)
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB 512MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 512MiB 100%

# Formata as partições
mkfs.fat -F32 ${DISK}p1
mkfs.ext4 ${DISK}p2

# Monta as partições
mount ${DISK}p2 /mnt
mkdir -p /mnt/boot/efi
mount ${DISK}p1 /mnt/boot/efi

# Instalação do sistema base
pacstrap /mnt base linux linux-firmware vim sudo networkmanager grub efibootmgr base-devel git

# Gera fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Entra no sistema
arch-chroot /mnt /bin/bash <<EOF

# Timezone e locale
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Nome da máquina e hosts
echo "$HOST" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOST.localdomain $HOST" >> /etc/hosts

# Cria usuário e senha
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instala bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Ativa rede
systemctl enable NetworkManager

# Instala XFCE e ferramentas dev
pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
    neovim git cmake gdb valgrind clang lldb make ninja \
    avr-gcc avr-libc avrdude openocd dfu-util picocom \
    xfce4-terminal starship zsh htop

systemctl enable lightdm

EOF

# Fim
echo "Instalação concluída. Você pode reiniciar."
