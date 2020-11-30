#!/bin/bash

_createEFIDisk(){
    echo -e "\033[33mWARN\033[0m: No EFI Partition!"
    read -p 'Do you want to create a new EFI partition? (y/n) ' _info
    if [[ ${_info} = 'y' || ${_info} = 'Y' ]]; then
        echo 'g
n


+100M
t

1
w' | fdisk /dev/${DISKS[0]} > /dev/null
        unset _info
        return 0
    else
        exit 1
    fi
    unset _info
}

_mulitEFIDisks(){
    echo -e "\033[33mWARN\033[0m: More than one disk exist. Please select which disk to use."
    for d_ in $(seq ${#DISKS[*]}); do
        D_=$(expr ${d_} - 1)
        Disk_list[${D_}]=${DISKS[${D_}]}"\t\t"$(smartctl /dev/${DISKS[${D_}]} -i | grep 'Model Number' | awk -F':' '{print $2}' | awk -F' ' '{print $1" "$2" "$3}')"\t\t"$(lsblk -n -o kname,size -d | grep "${DISKS[${D_}]}" | awk -F' ' '{print $2}')
    done
    unset d_
    unset D_
    while true; do
        for d_ in $(seq ${#DISKS[*]}); do
            D_=$(expr ${d_} - 1)
            echo -e " [ ${D_} ] ${Disk_list[${D_}]}"
        done
        read -p '#>' _num
        if [[ ${_num} -ge 0 && ${_num} -lt ${#DISKS[*]} ]]; then
            read -p 'Do you want to continue? (y/n) ' _info
            if [[ ${_info} = 'y' || ${_info} = 'Y' ]]; then
            echo 'g
n


+100M
t

1
w' | fdisk /dev/${DISKS[${_num}]} > /dev/null
            break
            fi
        else
            echo -e "\033[31mERROR\033[0m: Wrong number, please check your input.\n"
        fi
    done
    unset d_
    unset D_
    unset _num
    unset _info
    unset Disk_list
}

_multiEFIParts(){
    echo -e "\033[33mWARN\033[0m: More than one EFI Partition exist. Please select which disk to use."
    for d_ in $(seq ${#DISKS[*]}); do
        D_=$(expr ${d_} - 1)
        Disk_list[${D_}]=${DISKS[${D_}]}"\t\t"$(smartctl /dev/${DISKS[${D_}]} -i | grep 'Model Number' | awk -F':' '{print $2}' | awk -F' ' '{print $1" "$2" "$3}')"\t\t"$(lsblk -n -o kname,size -d | grep "${DISKS[${D_}]}" | awk -F' ' '{print $2}')
    done
    unset d_
    unset D_
    while true; do
        for d_ in $(seq ${#DISKS[*]}); do
            D_=$(expr ${d_} - 1)
            echo -e " [ ${D_} ] ${Disk_list[${D_}]}"
        done
        read -p '#>' _num
        if [[ ${_num} -ge 0 && ${_num} -lt ${#DISKS[*]} ]]; then
            read -p 'Do you want to continue? (y/n) ' _info
            if [[ ${_info} = 'y' || ${_info} = 'Y' ]]; then
            echo 'g
n


+100M
t

1
w' | fdisk /dev/${DISKS[${_num}]} > /dev/null
            break
            fi
        else
            echo -e "\033[31mERROR\033[0m: Wrong number, please check your input.\n"
        fi
    done
    unset d_
    unset D_
    unset _num
    unset _info
    unset Disk_list

}

_singleDisk(){
    ROOT_PART=0
    checkDisk ${DISKS[0]}
    case $? in
        0)
            createPart ${DISKS[0]}
            while true; do
                select fs_ in 'Ext4' 'btrfs'; do
                    case ${fs_} in
                        'ext4')
                            createExt4FS
                            break 2
                            ;;
                        'btrfs')
                            createBtrfsFS
                            break 2
                            ;;
                        *)
                            echo -e "\033[31mERROR\033[0m: Wrong number, please check your input.\n"
                            break
                            ;;
                    esac
                done 
            done
            unset fs_

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

_multiDisks(){
    exit
}