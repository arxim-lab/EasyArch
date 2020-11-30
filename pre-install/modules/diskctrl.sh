#!/bin/bash

createEFIDisk(){
    echo 'g
n


+100M
t

1
w' | fdisk /dev/${1} > /dev/null
    # mkfs.vfat /dev/${1}1
    # mkdir -p /mnt/boot/efi
    # mount /dev/${1}1 /mnt/boot/efi
}

# $1 ext4/btrfs
# $2 block
createRootDisk(){
    echo 'n



w' | fdisk /dev/${2} > /dev/null
    if [[ ${1} = 'ext4' ]]; then
        mkfs.ext4 /dev/${2}
        mount $ROOTdisk /mnt
    elif [[ ${1} = 'btrfs' ]]; then
        mkfs.btrfs /dev/${2}
        mount /dev/${2} /mnt
        cd /mnt
        btrfs subvolume create archfs
        btrfs subvolume create homefs
        cd ${FOOT}
        umount /mnt
        mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=archfs ${ROOTdisk} /mnt
        mkdir -p /mnt/home
        mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=homefs ${ROOTdisk} /mnt/home
    fi
}
