#!/bin/sh

trap '' 1 2 3 24

# 设置时区为中国时间
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc # UTC

# 设置编码
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i 's/#zh_CN/zn_CN/g' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# 设置hosts
echo '127.0.0.1 localhost' >> /etc/hosts
echo '::1 localhost' >> /etc/hosts

# 设置hostname
echo 'easyarch' > /etc/hostname

# 添加sudoer
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# 设置NTP服务器
sed -i 's/#NTP=/NTP=cn.pool.ntp.org/g' /etc/systemd/timesyncd.conf
sed -i 's/#//g' /etc/systemd/timesyncd.conf

# 创建新用户
useradd -G wheel -m admin
echo 'admin@test
admin@test
' | passwd admin
NEW_PASS=$(mkpasswd)
echo "${NEW_PASS}
${NEW_PASS}
" | passwd root

# 创建GRUB引导
BOOT_MODE=$(cat /root/boot_mode)
SYS_DRIVER=$(cat /root/sys_driver)
if [[ ${BOOT_MODE} = 'legacy' ]]; then
    grub-install /dev/${SYS_DRIVER}
else
    grub-install --target=${BOOT_MODE} --efi-directory=/boot/efi --bootloader-id='GRUB Boot Loader'
fi
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -Sy > /dev/null

# 配置OpenSSH (临时)
echo 'Port 22' >> /etc/ssh/sshd_config
echo 'AddressFamily any' >> /etc/ssh/sshd_config
echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config
echo 'ListenAddress ::' >> /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
echo 'Banner /etc/issue' >> /etc/ssh/sshd_config

# 启动BBR加速
echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/tcp-bbr.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/tcp-bbr.conf
echo "tcp_bbr" > /etc/modules-load.d/80-bbr.conf

# 启动系统服务
systemctl enable systemd-network        # DHCP服务
systemctl enable systemd-timesyncd      # 时间服务
systemctl enable systemd-resolved       # DNS服务
systemctl enable sshd                   # SSH服务

# 删除残留的系统文件
rm /root/boot_mode
rm /root/sys_driver
