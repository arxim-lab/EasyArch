#!/bin/bash

#选择安装模式函数
selectMode(){
    if [[ ${MODEset} == 0 ]]; then
        echo ${QUESTION_SELECT_MODE}
        echo -e ${NOTICE_SELECT_MODE}
        while true; do
            select mode in ${OPTION_SELECT_MODE[*]}; do
                case ${mode} in
                    ${OPTION_SELECT_MODE[0]})
                        MODEset=1
                        break 2
                        ;;
                    ${OPTION_SELECT_MODE[1]})
                        MODEset=2
                        break 2
                        ;;
                    ${OPTION_SELECT_MODE[2]})
                        MODEset=3
                        break 2
                        ;;
                    ${OPTION_SELECT_MODE[3]})
                        exit
                        ;;
                    *)
                        echo -e ${ERROR_MESSAGE[0]}
                        break
                        ;;
                esac
            done
        done
        unset mode
    fi
    # case ${MODEset} in
    #     1)
    #         ;;
    #     2)
    #         ;;
    #     3)
    #         ;;
    #     *)
    #         echo -e ${ERROR_MESSAGE[3]}
    #         exit 3
    #         ;;
    # esac
}

#设置安装分区函数
# 导入辅助函数
source ./diskctrl.sh
# selectSysPart(){
#     if [[ ${SYSPARTset} == 0 ]]; then
#         echo ${QUESTION_SELECT_SYSPART}
#         while true; do
#             select choice in ${OPTION_SELECT_SYSPART[*]}; do
#                 case ${choice} in
#                     ${OPTION_SELECT_SYSPART[0]})
#                         createDisk
#                         break 2
#                         ;;
#                     ${OPTION_SELECT_SYSPART[1]})
#                         selectDisk
#                         break 2
#                         ;;
#                     *)
#                         echo -e ${ERROR_MESSAGE[0]}
#                         break
#                         ;;
#                 esac
#             done
#         done
#         unset choice
#     fi
# }

#选择系统内核函数
selectKernel(){
    if [[ ${KERNELset} == 0 ]]; then
        echo ${QUESTION_SELECT_KERNEL}
        while true; do
            select k in ${OPTION_SELECT_KERNEL[*]}; do
                case ${k} in
                    ${OPTION_SELECT_KERNEL[0]})
                        KERNELset='linux'
                        break 2
                        ;;
                    ${OPTION_SELECT_KERNEL[1]})
                        KERNELset='linux-zen'
                        break 2
                        ;;
                    ${OPTION_SELECT_KERNEL[2]})
                        KERNELset='linux-lts'
                        break 2
                        ;;
                    ${OPTION_SELECT_KERNEL[3]})
                        KERNELset='linux-hardened'
                        break 2
                        ;;
                    *)
                        echo -e ${ERROR_MESSAGE[0]}
                        break
                        ;;
                esac
            done
        done
        unset k
    fi
    # case ${KERNELset} in
    #     'linux')
    #     'linux-zen'
    # esac
}

#选择引导器函数
selectBootmgr(){
    if [[ ${BOOTMGRset} == 0 ]]; then
        echo ${QUESTION_SELECT_BOOTMGR}
        while true; do
            select mgr in ${OPTION_SELECT_BOOTMGR[*]}; do
                case ${mgr} in
                    ${OPTION_SELECT_BOOTMGR[1]})
                        BOOTMGRset=1
                        break 2
                        ;;
                    ${OPTION_SELECT_BOOTMGR[0]})
                        echo -e ${ERROR_MESSAGE[2]}
                        read -p 'Do you want to continue? (y/n) ' _info
                        if [[ ${_info} = 'y' || ${_info} = 'Y' ]]; then
                            BOOTMGRset=0
                            unset _info
                            break 2
                        fi
                        unset _info
                        break
                        ;;
                    *)
                        echo -e ${ERROR_MESSAGE[0]}
                        break
                        ;;
                esac
            done
        done
        unset mgr
    fi
}

#设置图像界面函数
selectDE(){
    if [[ $DEset == 0 ]]; then
        echo ${QUESTION_SELECT_DE}
        while true; do
            # select de in "KDE Plasma (recommended)" "GNOME 3" "Deepin DE" "Xfce 4" "not use desktop environment"; do
            select de in ${OPTION_SELECT_DE[*]}; do
                case ${de} in
                    ${OPTION_SELECT_DE[1]})
                        DEset='kde'
                        break 2
                        ;;
                    # "GNOME 3")
                    #     DEset='gnome'
                    #     break 2
                    #     ;;
                    # "Deepin DE")
                    #     DEset='dde'
                    #     break 2
                    #     ;;
                    ${OPTION_SELECT_DE[0]})
                        break 2
                        ;;
                    *)
                        echo -e ${ERROR_MESSAGE[0]}
                        break
                        ;;
                esac
            done
        done
        unset de
    fi
}

#无人值守安装函数
afkModeSet(){
    # Minimal Install
    if [[ ${MODEset} == 0  ]]; then
        lsblk -d -n 
    elif [[ ${MODEset} == 1 ]]; then
        exit
    fi
}
