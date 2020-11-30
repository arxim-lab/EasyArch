#!/bin/bash
DISKS=($(lsblk -n -d -o KNAME,RM | grep -E ' 1|/' -v | awk -F' ' '{print $1}'))
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
    read -p '#>' _info
    if [[ ${_info} -ge 0 && ${_info} -lt ${#DISKS[*]} ]]; then
        break
    else
        echo -e "\033[31mERROR\033[0m: Wrong number, please check your input.\n"
    fi
done
unset d_
unset D_
unset Disk_list