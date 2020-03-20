#!/bin/bash

# Borrowed and modified from https://github.com/LukeSmithxyz/LARBS/blob/master/testing/arch.sh

#DO NOT RUN THIS YOURSELF because Step 1 is it reformatting /dev/sda WITHOUT confirmation,
#which means RIP in peace qq your data unless you've already backed up all of your drive.

pacman -Sy --noconfirm dialog || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

dialog --defaultno --title "WARNING!" --yesno "This is an Arch install script .\n\nOnly run this script if you don't mind deleting your entire /dev/sda drive."  15 60 || exit
dialog --defaultno --title "NO SERIOUSLY!" --yesno "This will delete ALL of /dev/sda and reinstall Arch.\n\nTo stop this script, press no."  10 60 || exit
dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp
dialog --defaultno --title "Time Zone select" --yesno "Do you want use the default time zone(America/Los_Angeles)?.\n\nPress no for select your own time zone"  10 60 && echo "America/Los_Angeles" > tz.tmp || tzselect > tz.tmp

dialog --no-cancel --inputbox "Enter swap in GB, then a space, then root partition size in GB." 10 60 2>psize
IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(12 25);
fi

echo Putting OSUOSL at top of the mirror list

echo 'Server = http://ftp.osuosl.org/pub/archlinux/$repo/os/$arch' > /mirrorlist
cat /etc/pacman.d/mirrorlist >> /mirrorlist
mv /mirrorlist /etc/pacman.d/mirrorlist

timedatectl set-ntp true

cat <<EOF | fdisk /dev/sda
o
n
p


+200M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

yes | mkfs.ext4 /dev/sda4
yes | mkfs.ext4 /dev/sda3
yes | mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home

pacman -Sy --noconfirm archlinux-keyring

pacstrap /mnt base base-devel linux linux-firmware neovim

genfstab -U /mnt >> /mnt/etc/fstab
cat tz.tmp > /mnt/tzfinal.tmp
rm tz.tmp
mv comp /mnt/etc/hostname
curl https://raw.githubusercontent.com/MarkZuber/arch/master/chroot.sh > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

dialog --defaultno --title "Final Qs" --yesno "Reboot computer?"  5 30 && reboot
dialog --defaultno --title "Final Qs" --yesno "Return to chroot environment?"  6 30 && arch-chroot /mnt
clear
