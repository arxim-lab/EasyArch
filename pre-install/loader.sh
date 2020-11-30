#!/bin/bash

#脚本变量定义
MODEset=0
BOOTMGRset=0
SYSPARTset=0
DRIVERSset=0
LOCALEset=0
DEset=0
KERNELset=0
isLINUXKernel=1
EFIroot=0
ROOTroot=0

#检查系统位数和EFI版本
FW_PLATFORM=$(cat /sys/firmware/efi/fw_platform_size)
echo 'Checking firmware platform...'
if [[ $? != 0 ]]; then
    echo -e "\033[32mYOUR COMPUTER IS PIECE OF SHIT!\033[0m"
    echo -e "\033[31mYOUR FIRMWARE DOES NOT SUPPORT UEFI!\033[0m"
    exit 255
elif [[ ${FW_PLATFORM} != '64' ]]; then
    echo -e "\033[32mYOUR COMPUTER IS PIECE OF SHIT!\033[0m"
    echo -e "\033[32mYOUR UEFI FIRMWARE IS NOT 64 BIT!\033[0m"
    exit 255
fi
unset FW_PLATFORM

#检查网络连接
while true; do
    echo 'Checking network connection...'
    sudo pacman -Sy > /dev/null
    if [[ $? != 0 ]]; then
        echo -e "\033[33mWARN\033[0m: Network is unavailable."
        echo -e "\033[32mTIP\033[0m: Wired connection and android network share are recommended."
        echo -e "\033[32mTIP\033[0m: WLAN connection is not recommended."
        read -n1 -s -p 'Please check your network. When you are ready, press any key to continue.'
        echo -e "\n"
    else
        break
    fi
done

#判断CPU品牌
# 0     未检测到CPU品牌
# amd   AMDCPU
# intel IntelCPU
# 为下面安装微码补丁做准备
CPU_TYPE=0
echo 'Checking CPU manufacturer...'
cat /proc/cpuinfo |grep -i Intel > /dev/null
if [[ $? == 0 ]]; then
    CPU_TYPE='intel'
fi
cat /proc/cpuinfo |grep -i AMD > /dev/null
if [[ $? == 0 ]]; then
    CPU_TYPE='amd'
fi

#判断显卡品牌
# 0      未检测到显卡品牌
# intel  Intel核显
# amd    AMD核显&独显
# nvidia Nvidia独显
# 为下面安装显卡驱动做准备
GPU_TYPE=0
echo 'Checking GPU manufacturer...'
lspci | grep -i vga | grep -i Intel > /dev/null
if [[ $? == 0 ]]; then
    GPU_TYPE='intel'
fi
lspci | grep -i vga | grep -i AMD > /dev/null
if [[ $? == 0 ]]; then
    GPU_TYPE='amd'
fi
lspci | grep -i vga | grep -i Nvidia > /dev/null
if [[ $? == 0 ]]; then
    GPU_TYPE='nvidia'
fi

#收集磁盘信息
# 获取所有可用的磁盘，筛去可移动磁盘和挂载盘
echo 'Checking hard disks...'
Disk_list_raw=$(lsblk -n -o KNAME,RM | grep -E ' 1|/' -v)
Disk_list_raw=${Disk_list_raw// 0/}
DISKS=(${Disk_list_raw// /})
# 搜索可用的EFI分区,如果有就是UEFI启动，没有就是Legacy引导启动
#! 决定抛弃针对legacy类型引导的支持
#! 都0202年了，不会真还有人的电脑不支持64位和UEFI吧，不会吧不会吧
echo 'Searching for EFI partition...'
EFI_DISKS_NUM=0
for disk_ in ${DISKS[*]}; do
    lsblk /dev/${disk_} -n -o NAME,PARTTYPENAME | grep -i -E 'EFI System' > /dev/null
    if [[ $? == 0 ]]; then
        # Boot_Type='UEFI'
        EFI_list_raw=$(lsblk /dev/${disk_} -n -o NAME,PARTTYPENAME | grep -i -E 'EFI System')
        EFI_list_raw=${EFI_list_raw//EFI System/}
        EFI_DISKS[${EFI_DISKS_NUM}]=${EFI_list_raw[0]}
        unset EFI_list_raw
        EFI_DISKS_NUM=$(expr ${EFI_DISKS_NUM} + 1)
    fi
done
# 对收集到的EFI分区名进行处理
if [[ $Boot_Type = 'UEFI' ]]; then
    EFI_DISKS=${EFI_DISKS// /}
    EFI_DISKS=${EFI_DISKS//├─/}
fi
unset Disk_list_raw
unset EFI_DISKS_NUM
unset disk_

#模块变量定义
# 问候语设置
QUESTION_SELECT_MODE='In which way do you want to install Archlinux on your pc?'
QUESTION_SELECT_SYSPART='Please choose the operation you want.'
QUESTION_SELECT_KERNEL='Which linux kernel would you like to install?'
QUESTION_SELECT_BOOTMGR='Which boot manager do you want to choose?'
QUESTION_SELECT_DE='Which desktop environment do you want to use?'

NOTICE_WELCOME=""
NOTICE_SELECT_MODE="\033[32mTIP\033[0m: Automatic installation is only available for single-disk computer system.\n\033[32mTIP\033[0m: If you have more than one disk and the disk you select is not the first block (sda or nvme0n1),\n\033[32mTIP\033[0m: your data will be damaged and maybe not able to recover."

# 选项设置
OPTION_SELECT_MODE=(
    "Minimal Install (Automatic Install, no X tools)"
    "Typical Install (Automatic Install, typical Archlinux system, with KDE desktop)"
    "Customized Install (Manually select applications you want to install)"
    "Exit this script"
)
OPTION_SELECT_SYSPART=(
    "Select an existed disk."
    "Create a new disk."
)
OPTION_SELECT_KERNEL=(
    "Linux (stable)"
    "Linux Zen (possible for everyday systems)"
    "Linux LTS (long-term support)"
    "Linux Hardened (much safer)"
)
OPTION_SELECT_BOOTMGR=(
    "not use any boot manager (not recommended)"
    "GRUB (default)"
)
OPTION_SELECT_DE=(
    "not use desktop environment"
    "KDE Plasma (recommended)"
    "GNOME 3"
    "Deepin DE"
)

# 错误信息抛出
ERROR_MESSAGE[0]="\033[31mERROR\033[0m: Wrong number, please check your input.\n"
ERROR_MESSAGE[1]="\E[31m\033[6mERR\033[0m: There is something wrong happend when installing packages.\n     Please reexec this script."
ERROR_MESSAGE[2]="\033[33mWARN\033[0m: Unrecommended choice! If continue, your system would be not able to start."
ERROR_MESSAGE[3]="\033[31mERROR\033[0m: Wrong modeset code, please try again."
