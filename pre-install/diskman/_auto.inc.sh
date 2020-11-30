#!/bin/bash

# 创建EFI分区并重新开始程序
_createEFIDisk(){
    echo 'g
n


+100M
t

1
w' | fdisk /dev/${DISKS[0]} > /dev/null
}

# 报错退出
_mulitEFIDisks(){
    echo -e "\033[31mWARN\033[0m: More than one disk exist. Automatic protocol cannot continue."
    exit 16
}

# 自动取第一个EFI分区
_multiEFIParts(){
    EFI_PART=/dev/${EFI_PARTS[0]}
    EFI_DISK=/dev/${EFI_DISKS[0]}
}

# 如果只有一块硬盘，执行以下逻辑
# 如果硬盘存在LFS分区，且大于10G,使用该分区作为根分区
# 如果不存在，且未分配大小大于10G,创建新分区并作为根分区
# 否则报错退出
_singleDisk(){
    ROOT_PART=0
    checkDisk ${DISKS[0]}
    case $? in
        0)
            createPart ${DISKS[0]}
            case ${FS_} in
                'ext4')
                    createExt4FS
                    ;;
                'btrfs')
                    createBtrfsFS
                    ;;
            esac
            ;;
        1)
            echo -e "\033[31mERR\033[0m: Not Enough Storage!"
            exit 16
            ;;
        2)
            case ${FS_} in
                'ext4')
                    createExt4FS
                    ;;
                'btrfs')
                    createBtrfsFS
                    ;;
            esac
            ;;
    esac
}

# 如果存在多个硬盘，取第一个含有EFI分区的硬盘，同单盘操作
_multiDisks(){
    _singleDisk
}