#!/bin/bash 
set -e -v
pacstrap /mnt base linux linux-firmware linux-headers base-devel git vim amd-ucode
genfstab -U /mnt > /mnt/etc/fstab

cat <<EOF > /mnt/root/archbtw.sh
#!/bin/bash
set -e -v
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf
echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
update-initramfs -u
echo "HOST" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 HOST.localdomain    HOST" >> /etc/hosts
echo root:password | chpasswd

# /* setup systemd-boot */
bootctl install
mkdir -p /boot/loader/
echo "timeout       3" > /boot/loader/loader.conf
echo "console-mode  max" >> /boot/loader/loader.conf
echo "default       arch.conf" >> /boot/loader/loader.conf
mkdir -p /boot/loader/entries/
echo "title     Arch Linux" > /boot/loader/entries/arch.conf
echo "linux     /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd    /amd-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd    /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options   root=CHANGE_ME rw loglevel=3 quiet sysrq_always_enabled=1" >> /boot/loader/entries/arch.conf
sed -i "s/CHANGE_ME/root=$(echo "\\\"UUID=$(sudo blkid -s UUID -o value $(df -hT | grep /$ | awk '{print $1}'))\\\"")/" /boot/loader/entries/arch.conf

#  /* user */
useradd -m USER
echo USER:password | chpasswd
usermod -aG libvirt USER
echo "USER ALL=(ALL) ALL" >> /etc/sudoers.d/USER

rm -rf \$0
exit # farewell, my work here is done
EOF

arch-chroot /mnt /mnt/root/archbtw.sh
umount -R /mnt
rm -rf $0

shutdown -h now
