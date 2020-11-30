#!/bin/bash

checkDisk(){
    _d=$1
    # 判断是否存在Linux文件系统
    _parts=($(lsblk /dev/${_d} -n -o KNAME,PARTTYPENAME | grep -i 'Linux filesystem' | awk -F' ' '{print $1}'))
    if [[ ${#_parts[*]} != 0 ]]; then
        for _P in ${_parts[*]}; do
            _S=$(lsblk /dev/${_P} -n -o SIZE -r | awk '/^([1-9][0-9]*)+(\.[0-9]{1,2})?/ {print int($1)}')
            # 如果空间单位是K,M,B 显然大小不足，跳出循环执行下一步
            lsblk /dev/${_P} -n -o SIZE -r | grep -E '[KMB]$' > /dev/null
            if [[ $? == 0 ]]; then
            continue
            fi
            lsblk /dev/${_P} -n -o SIZE -r | grep 'G' > /dev/null
            if [[ $? == 0 ]]; then
                # 如果空间单位为G且大小值小于等于10 可能空间不足，跳出循环执行下一步
                if [[ ${_S} -le 10 ]]; then
                    continue
                fi
            fi
            # 返回2 表示已分区且空间充足
            ROOT_PART=/dev/${_P}
            return 2
        done
    fi
    Space=($(echo 'F
' | fdisk /dev/${_d} | grep 'Un' | awk -F': ' '{print $3}' | awk -F', ' '{print $1}' | awk -F' ' '{print $1" "$2}'))
    # 如果未分配空间单位为B或KiB,显然空间不足
    # 如果为GiB以及上述两种单位以外的单位，显然空间充足
    case ${Space[1]} in
        'B')
            return 1
            ;;
        'KiB')
            return 1
            ;;
        'GiB')
            if [[ ${Space[0]} -le 10 ]]; then
                return 1
            else
                return 0
            fi
            ;;
        *)
            return 0
            ;;
    esac
    unset _d
    unset _parts
    unset Space
    unset _P
    unset _S
}

createExt4FS(){
    mkfs.ext4 ${ROOT_PART}
    mount ${ROOT_PART} /mnt
    mkdir -p /mnt/boot/efi
    mount ${EFI_PART} /mnt/boot/efi
}

createBtrfsFS(){
    mkfs.btrfs ${ROOT_PART}
    mount ${ROOT_PART} /mnt
    cd /mnt
    btrfs subvolume create archfs
    btrfs subvolume create homefs
    cd ${FOOT}
    umount /mnt
    mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=archfs ${ROOT_PART} /mnt
    mkdir -p /mnt/home
    mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=homefs ${ROOT_PART} /mnt/home
    mkdir -p /mnt/boot/efi
    mount ${EFI_PART} /mnt/boot/efi
}

createPart(){
    # 新建分区，并获取分区编号
    ROOT_KEY=$(echo 'n



w' | fdisk /dev/$1 | grep 'default' | awk -F'default ' '{print $2}' | awk -F'):' '{print $1}')
    # 通过块名和分区编号，获取完整分区块路径
    ROOT_PART=/dev/$(lsblk -n -o KNAME | grep $1 | grep ${ROOT_KEY})
    unset ROOT_KEY
}