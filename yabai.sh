#!/bin/bash
# Kaize's installer for Arch linux
# \ \/ / _ | / _ )/ _ | /  _/
#  \  / __ |/ _  / __ |_/ /  
#  /_/_/ |_/____/_/ |_/___/ 
# Author: Kaize <kaitsubaka@gmail.com>
# License: MIT
# version: 1.0
# created: 08.29.20

### VARIABLES ###
timeZone="America/Bogota"
hostName=""
rootPass=""
userName=""
fullName=""
userPass=""
grubName="kuro"
invalidOption="Invalid option, please try again"
### FUNCTIONS ###
function AskForReboot () {
    rm /mnt/yabaiChroot.sh
    while true; do
        read -p "Dou you want to reboot your system? [Yy/Nn]: " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo $invalidOption;;
        esac
    done
    clear
    umount -R /mnt
    swapoff /dev/sda2
    reboot
}

function WriteYabaiChroot () {
    cat << EOF >> /mnt/yabaiChroot.sh
#!/bin/bash
#Second part of yabai script

echo -e "Changing root password."
echo -e 'root:$rootPass' | chpasswd
echo -e "Root password changed\n"

echo -e "Changing hostname."
echo "$hostName" > /etc/hostname 
echo -e "hostname changed\n"

echo -e "Adding user $userName."
useradd -m -g wheel -s /bin/zsh -c "$fullName" "$userName" >/dev/null
echo "$userName:$userPass" | chpasswd
echo -e "User added\n"

echo -e "Changing zone settings...\n"
ln -sf /usr/share/zoneinfo/$timeZone /etc/localtime
hwclock --systohc

echo -e "Changing locale settings...\n"
echo "es_CO.UTF-8 UTF-8" >> /etc/locale.gen
echo "es_CO ISO-8859-1" >> /etc/locale.gen
locale-gen

echo -e "Enabling wi-fi\n"
systemctl enable NetworkManager

echo "Ranking mirrors at installation please wait..."
reflector --latest 200 --protocol https --sort rate --save /etc/pacman.d/mirrorlist > /dev/null

echo -e "Installing grub\n"
pacman --noconfirm --needed -S grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=$grubName && grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

function ExecuteYabaiChroot () {
    arch-chroot /mnt bash yabaiChroot.sh
}

function InitilalizeValues () {
    echo -e "Checking network..."
    (pacman -Sy > /dev/null && pacman --noconfirm --needed -S reflector > /dev/null && echo -e "Network check passed\nPlease complete the following information\n") ||
    (echo -e "Error at script start: Are you sure you're running this as the root user? \n Are you sure you have an internet connection?" && exit)
    
    echo -e "Please create a root password."
    while true; do
        read -sp "Type your root password: " rpass1
        echo
        read -sp "Type your root password again: " rpass2
        clear
        [ "$rpass1" == "$rpass2" ] && rootPass="$rpass1" && break
        echo -e "\npasswords doesn't match, please enter them again"
    done

    read -p "Type your user name(in lower case): " userName
    
    read -p "Type your full name: " fullName

    echo -e "Please create the password for $userName."
    while true; do
        read -sp "Type the password for $userName: " upass1
        echo
        read -sp "Type the password for $userName again: " upass2
        clear        
        [ "$upass1" == "$upass2" ] && userPass="$upass1" && break
        echo -e "\npasswords doesn't match, please enter them again"
    done
    
    read -p "Please enter a hostname (computer name): " hostName

    clear
    
    #enable ntp
    timedatectl set-ntp true
    
    while true; do
        read -p "Do you want to change the default time zone (default = $timeZone)?[Yy/Nn]: " yn
        case $yn in
            [Yy]* ) timeZone=$(tzselect); break;;
            [Nn]* ) break;;
            * ) echo $invalidOption;;
        esac
    done
    clear
}

function RankMirrorlist () {
    echo -e "Ranking mirrors, please wait..."
    reflector --latest 200 --protocol https --sort rate --save /etc/pacman.d/mirrorlist > /dev/null
    clear
}

function ShowWelcomeMsg () {
    clear
    echo -e "<<Welcome to yabai!>>" \
    "\n>>This script rise a base-devel installation of arch linux" \
    "\nwith some tweaks like nvim git and reflector" \
    "\n>>Only run this if you know what you are doing" \
    "\n-kai";
    read -p "Press enter to continue..."
    clear
}

function ConfirmDesition (){
    echo -e "Your installation will be called $hostName, with the user $userName.\nWith time zone = $timeZone.\n"
    while true; do
        read -p "Do you want continue?[Yy/Nn]: " yn
        case $yn in
            [Yy]* ) echo "Initializing the script. \n Possible errors will be displayed."; break;;
            [Nn]* ) exit;;
            * ) echo $invalidOption;;
        esac
    done
    clear
}

function MakePartitions () {
    echo -e "making partitions, please wait..."
    parted -s -a optimal /dev/sda mklabel gpt \
    mkpart primary fat32 1MiB 700MiB \
    mkpart primary linux-swap 700MiB 8Gib \
    mkpart primary ext4 8Gib 50GiB \
    -- mkpart primary ext4 50GiB -50s \
    set 1 esp on \
    set 1 boot on
    clear
}

function WriteFileSystems () {
    echo -e "Writing file systems, please wait..."
    mkfs.ext4 /dev/sda4
    mkfs.ext4 /dev/sda3
    mkswap /dev/sda2
    mkfs.fat -F32 /dev/sda1
    clear
}

function MountDisk () {
    echo -e "Mounting disk, please wait..."
    swapon /dev/sda2
    mount /dev/sda3 /mnt
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
    mkdir /mnt/home
    mount /dev/sda4 /mnt/home
    clear
}

function InstallBase () {
    pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware neovim dialog networkmanager reflector git zsh
    genfstab -U /mnt >> /mnt/etc/fstab
    clear
}

##SCRIPT##

#Welcome message
ShowWelcomeMsg

#initilalize the variables for the script
InitilalizeValues

#Rank the mirror list
RankMirrorlist

#ask for conformation to continue
ConfirmDesition

#create partitions in the HDD
MakePartitions

#create file systems for each partition
WriteFileSystems

#mount the disk in mnt
MountDisk

#pacstraping all needed stuff
InstallBase

#write  second part of the script
WriteYabaiChroot

#exectute second part of the script
ExecuteYabaiChroot

#reboot or continue in arch live iso
AskForReboot
