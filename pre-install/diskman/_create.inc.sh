#!/bin/bash

#==================================
# 此脚本征集简化意见
#==================================

EFI_BLOCK=0

#自动创建EFI分区函数、
# 自动执行 自动清除硬盘分区
# 参数必须
# $1 block
_createEFIDisk(){
    # 新建分区，并获取分区编号
    EFI_KEY=$(echo 'g
n


+100M
t

1
w' | fdisk /dev/${1} | grep 'default' | awk -F'default ' '{print $2}' | awk -F'):' '{print $1}')
    # 通过块名和分区编号，获取完整分区块路径
    EFI_BLOCK=/dev/$(lsblk -n -o KNAME | grep $1 | grep ${EFI_KEY})
    unset EFI_KEY
    mkfs.vfat ${EFI_BLOCK}
}

#自动创建根分区函数
# 自动执行
# 参数必须
# $1 ext4/btrfs
# $2 block
_createRootDisk(){
    # 新建分区，并获取分区编号
    ROOT_KEY=$(echo 'n



w' | fdisk /dev/${2} | grep 'default' | awk -F'default ' '{print $2}' | awk -F'):' '{print $1}')
    # 通过块名和分区编号，获取完整分区块路径
    ROOT_BLOCK=/dev/$(lsblk -n -o KNAME | grep $2 | grep ${ROOT_KEY})
    unset ROOT_KEY
    # 根据传入的参数创建文件系统，并自动挂载
    if [[ ${1} = 'ext4' ]]; then
        mkfs.ext4 ${ROOT_BLOCK}
        mount ${ROOT_BLOCK} /mnt
    elif [[ ${1} = 'btrfs' ]]; then
        mkfs.btrfs ${ROOT_BLOCK}
        mount ${ROOT_BLOCK} /mnt
        FOOT=$(pwd)
        cd /mnt
        btrfs subvolume create archfs
        btrfs subvolume create homefs
        cd ${FOOT}
        umount /mnt
        mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=archfs ${ROOT_BLOCK} /mnt
        mkdir -p /mnt/home
        mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=homefs ${ROOT_BLOCK} /mnt/home
    fi
}

#自动挂载EFI分区函数
# 自动执行
# 参数必须
_mountEFIDisk(){
    if [[ ${EFI_BLOCK} != 0 ]]; then
        mkdir -p /mnt/boot/efi
        mount ${EFI_BLOCK} /mnt/boot/efi
    else
        exit
    fi
}
