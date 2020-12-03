#!/bin/sh 
 
trap '' 1 2 3 24

#检查Root权限
if [[ $(whoami) != 'root' ]]; then
    echo "Please log in as Root"
    exit 255
fi

#脚本变量定义
BOOT_MODE=0
SYS_DRIVER=0
SYS_PART=0
LOCALE=0
EFI_PART=0
CPU_TYPE=0

#检查系统位数和EFI版本
FW_PLATFORM=$(cat /sys/firmware/efi/fw_platform_size)
echo 'Checking firmware platform...'
if [[ $? != 0 ]]; then
    BOOT_MODE='legacy'
elif [[ ${FW_PLATFORM} != '64' ]]; then
    BOOT_MODE='i386-efi'
else
    BOOT_MODE='x86_64-efi'
fi
unset FW_PLATFORM

#判断CPU品牌
# 0     未检测到CPU品牌
# amd   AMDCPU
# intel IntelCPU
# 为下面安装微码补丁做准备
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
# 你一台服务器用什么显卡，不装了！
# echo 'Checking GPU manufacturer...'
# lspci | grep -i vga | grep -i Intel > /dev/null
# if [[ $? == 0 ]]; then
#     GPU_TYPE='intel'
# fi
# lspci | grep -i vga | grep -i AMD > /dev/null
# if [[ $? == 0 ]]; then
#     GPU_TYPE='amd'
# fi
# lspci | grep -i vga | grep -i Nvidia > /dev/null
# if [[ $? == 0 ]]; then
#     GPU_TYPE='nvidia'
# fi

#检查网络连接
echo 'Checking network connection...'
pacman -Sy > /dev/null
# 使用pacman连通来判断网络连接
if [[ $? != 0 ]]; then
    # 默认只使用有线DHCP，此为定制规则
    echo -e "\033[33mWARN\033[0m: Network is unavailable."
    echo -e "\033[33mWARN\033[0m: Please go back to shell and check your network. When you are ready, run 'arch-install' again."
    exit 16
fi

#确认网络环境和服务器地理位置以确定是否使用国内源或教育网源
curl -s https://api.myip.la/en | grep -E "CN|China" > /dev/null
if [[ ${?} == 0 ]]; then
    curl -s http://myip.ipip.net | grep 教育网 > /dev/null
    if [[ ${?} == 0 ]]; then
        LOCALE='cnedu'
    else
        LOCALE='cnpub'
    fi
else
    LOCALE='oversea'
fi

#收集磁盘信息
# 获取所有可用的磁盘，筛去可移动磁盘和挂载盘
echo 'Checking hard disks...'
Disk_list_raw=$(lsblk -n -o KNAME,RM | grep -E ' 1|/' -v)
Disk_list_raw=${Disk_list_raw// 0/}
DISKS=(${Disk_list_raw// /})
unset Disk_list_raw
# 默认使用第一个识别到的硬盘，此为定制规则
SYS_DRIVER=${DISKS[0]}

# 默认为创建新服务器，所有的数据将被清除，如果使用EFI启动则新建EFI分区，此为定制规则

# 信息收集完毕，开始执行自动分区，默认使用Btrfs分区格式
# 如果为EFI启动，创建EFI分区
if [[ ${BOOT_MODE} != 'legacy' ]]; then
    EFI_KEY=$(echo 'g
n


+100M
t

1
w' | fdisk /dev/${SYS_DRIVER} | grep 'default' | awk -F'default ' '{print $2}' | awk -F'):' '{print $1}')
    EFI_PART=/dev/$(lsblk -n -o KNAME | grep ${SYS_DRIVER} | grep ${EFI_KEY})
    unset EFI_KEY
fi

# 新建分区，并获取分区编号
SYS_KEY=$(echo 'n



w' | fdisk /dev/${SYS_DRIVER} | grep 'default' | awk -F'default ' '{print $2}' | awk -F'):' '{print $1}')
# 通过块名和分区编号，获取完整分区块路径
SYS_PART=/dev/$(lsblk -n -o KNAME | grep ${SYS_DRIVER} | grep ${SYS_KEY})
unset SYS_KEY

mkfs.btrfs ${SYS_PART}
mount ${SYS_PART} /mnt
cd /mnt
btrfs subvolume create fs_arch
btrfs subvolume create fs_home
btrfs subvolume create fs_data
btrfs subvolume create fs_root
cd -
umount /mnt
mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=fs_arch ${SYS_PART} /mnt
mkdir -p /mnt/home
mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=fs_home ${SYS_PART} /mnt/home
mkdir -p /mnt/root
mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=fs_root ${SYS_PART} /mnt/root
mkdir -p /mnt/var/data
mount -o noatime,nodiratime,compress=zstd,ssd,discard,ssd_spread,space_cache,subvol=fs_data ${SYS_PART} /mnt/var/data
if [[ ${BOOT_MODE} != 'legacy' ]]; then
    mkdir -p /mnt/boot/efi
    mount ${EFI_PART} /mnt/boot/efi
fi

# 修改软件源
# 以下被注释代码将直接集成在ISO文件中，不需要脚本单独修改
# echo '[archlinuxcn]' >> /etc/pacman.conf
# echo 'Include = /etc/pacman.d/mirrorlist.cn' >> /etc/pacman.conf
# echo '[multilib]' >> /etc/pacman.conf
# echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
case ${LOCALE} in
    # 已经预先写好几份mirrorlist文件，只需要针对不同的情况修改文件名即可
    'oversea')
        # 海外网络不修改原有的mirrorlist
        cp /etc/pacman.d/oversea_archlinuxcn /etc/pacman.d/mirrorlist.cn
        ;;
    'cnpub')
        cp /etc/pacman.d/cnpub_archlinuxcn /etc/pacman.d/mirrorlist.cn
        cp /etc/pacman.d/cnpub_archlinux /etc/pacman.d/mirrorlist
        ;;
    'cnedu')
        cp /etc/pacman.d/cnedu_archlinuxcn /etc/pacman.d/mirrorlist.cn
        cp /etc/pacman.d/cnedu_archlinux /etc/pacman.d/mirrorlist
        ;;
esac
# 完成修改后更新数据库
pacman -Sy > /dev/null

# 安装软件包
pacstrap /mnt base base-devel linux-zen linux-zen-headers dkms linux-firmware vi vim sudo expect nano openssh btrfs-progs tigervnc man yay screen proxychains-ng grub archlinux-keyring archlinuxcn-keyring gnupg fish zsh git wget curl tor rsync
if [[ ${BOOT_MODE} != 'legacy' ]]; then
    pacstrap /mnt efibootmgr
fi
if [[ ${CPU_TYPE} != 0 ]]; then
    pacstrap /mnt ${CPU_TYPE}_ucode
fi

# 创建fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 创建记号
echo ${BOOT_MODE} > /mnt/root/boot_mode
echo ${SYS_DRIVER} > /mnt/root/sys_driver

# 修改新系统的软件源
case ${LOCALE} in
    # 已经预先写好几份mirrorlist文件，只需要针对不同的情况修改文件名即可
    'oversea')
        # 海外网络不修改原有的mirrorlist
        cp /etc/pacman.d/oversea_archlinuxcn /mnt/etc/pacman.d/mirrorlist.cn
        ;;
    'cnpub')
        cp /etc/pacman.d/cnpub_archlinuxcn /mnt/etc/pacman.d/mirrorlist.cn
        cp /etc/pacman.d/cnpub_archlinux /mnt/etc/pacman.d/mirrorlist
        ;;
    'cnedu')
        cp /etc/pacman.d/cnedu_archlinuxcn /mnt/etc/pacman.d/mirrorlist.cn
        cp /etc/pacman.d/cnedu_archlinux /mnt/etc/pacman.d/mirrorlist
        ;;
esac
# 修改新系统的pacman配置
sed -i 's/#Color/Color/g' /mnt/etc/pacman.conf
echo '[archlinuxcn]' >> /mnt/etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist.cn' >> /mnt/etc/pacman.conf
echo '[multilib]' >> /mnt/etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /mnt/etc/pacman.conf

# 设置新系统issue
cp /etc/welcome.issue /mnt/etc/issue

# 进入chroot环境执行安装后配置脚本
cp /usr/bin/after-install.sh /mnt/root/after-install.sh
arch-chroot /mnt /root/after-install.sh

# 检查错误
if [[ ${?} == 0 ]]; then
    rm /mnt/root/after-install.sh
    echo -e "\033[32mINFO\033[0m: Congratulations! Your system has been installed without errors."
    echo -e "\033[32mINFO\033[0m: System will reboot in 3 second."
    sleep 3
    sync
    reboot
else
    echo -e "\033[31mERR\033[0m: Something wrong happened when configuring your system."
    echo -e "\033[31mERR\033[0m: Please check and run again or configure your system manually."
    exit 1
fi
