#!/bin/bash

#安装软件包函数
installPackage(){
    i=0
    for pkg_; do
        PKGS_[${i}]=${pkg_}
        i=$(expr ${i} + 1)
    done
    pacstrap /mnt ${PKGS_[*]}
    if [[ $? != 0 ]]; then
        echo -e ${ERROR_MESSAGE[1]}
        exit 1
    fi
    unset pkg_
    unset i
    unset PKGS_
}

#安装系统内核函数
installKernel(){
    installPackage base base-devel
    installPackage ${KERNELset} ${KERNELset}-headers
    installPackage linux-firmware dkms
}

#安装驱动函数
installDrivers(){
    installPackage mesa lib32-mesa
    case ${CPU_TYPE} in
        'amd')
            installPackage amd-ucode
            ;;
        'intel')
            installPackage intel-ucode
            ;;
    esac
    case ${GPU_TYPE} in
        'intel')
            installPackage xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver lib32-libva-intel-driver libva-intel-driver
            ;;
        'amd')
            installPackage xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
            ;;
        'nvidia')
            if [[ ${isLINUXKernel} == 0 ]]; then
                installPackage nvidia-dkms
            else
                installPackage nvidia
            fi
            installPackage lib32-nvidia-utils nvidia-utils vdpau-video
            if [[ ${DEset} = 'kde' ]]; then
                echo "xrandr --setprovideroutputsource modesetting NVIDIA-0" >> /mnt/usr/share/sddm/scripts/Xsetup
                echo "xrandr --auto" >> /mnt/usr/share/sddm/scripts/Xsetup
            fi
            ;;
    esac
}

#安装引导器函数
installBootmgr(){
    exit
}

#安装桌面环境函数
installDE(){
    case ${DEset} in
        0)
            ;;
        'kde')
            installPackage plasma-meta konsole dolphin kate kcalc gwenview ark lrzip lzop p7zip unarchiver unrar kolourpaint okular
            ;;
        # 2)
        #     ;;
        # 3)
        #     ;;
    esac
}
