#!/bin/bash

# 根据输入参数判断运行模式
if [[ $1 = 'auto' ]]; then
    source ./_auto.inc.sh
else
    source ./_manual.inc.sh
fi

# 空格分隔每一项，在外层添加括号使其变成数组
DISKS=($(lsblk -n -d -o KNAME,RM | grep -E ' 1|/' -v | awk -F' ' '{print $1}'))

# 设置EFI分区
while true; do
    # 获取所有的EFI分区
    EFI_PARTS_NUM=0
    EFI_PARTS=0
    EFI_DISKS=0
    for disk_ in ${DISKS}; do
        _efi=($(lsblk /dev/${disk_} -n -o KNAME,PARTTYPENAME | grep -i -E 'EFI System' | awk -F' ' '{print $1}'))
        if [[ $? == 0 ]]; then
            EFI_PARTS[${EFI_PARTS_NUM}]=${_efi[0]}
            EFI_DISKS[${EFI_PARTS_NUM}]=${disk_}
            EFI_PARTS_NUM=$(expr ${EFI_PARTS_NUM} + 1)
        fi
    done
    unset EFI_PARTS_NUM
    unset disk_

    # 确定使用的EFI分区
    case ${#EFI_PARTS[*]} in
        0)
            # 无EFI分区，创建并重新检测
            if [[ ${#DISKS[*]} == 1 ]]; then
                _createEFIDisk
            else
                _mulitEFIDisks
            fi
            ;;
        1)
            # 只有一个EFI分区，直接设置
            EFI_PART=/dev/${EFI_PARTS[0]}
            EFI_DISK=/dev/${EFI_DISKS[0]}
            break
            ;;
        *)
            # 多个EFI分区，提示用户选择
            _multiEFIParts
            break
            ;;
    esac
done

# 设置安装分区
while true; do
    if [[ ${#DISKS[*]} == 1 ]]; then
        # 单盘
        _singleDisk
        break
    else
        # 多盘
        _multiDisks
        break
    fi
done
