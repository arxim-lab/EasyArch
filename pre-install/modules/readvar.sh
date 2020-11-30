#!/bin/bash

#读参函数
# 用法：
# 1) 布尔值（1或0）传参
#    readSingleVar 接收参数的变量名 参数文字
# 2) 带值的传参
#    readSingleVar 接收参数的变量名 参数文字 接收传值的变量名
readSingleVar(){
    # 检查此次函数调用的用法
    case $# in
        2)
            ;;
        3)
            # 此次读参需要传值，设置传值开关为 y (yes)
            isSetValue='y'
            inValue=$3
            ;;
        *)
            return 1
            ;;
    esac
    # 接收函数的传值
    inVariate=$1
    inParameter=$2
    # 开始遍历参数数组
    for p_ in ${Para_[*]}; do
        # 捕捉到参数后，读入参数的值
        if [[ ${isSetValue} = 'r' ]]; then
            export ${inValue}=${p_}
            break
        fi
        if [[ ${p_} = ${inParameter} ]]; then
            export ${inVariate}=1
            # 如果需要传值，改变传值开关值，否则跳出循环
            if [[ ${isSetValue} = 'y' ]]; then
                # 参数已经捕捉到，即将读入参数的值，设置传值开关为 r (ready)
                isSetValue='r'
            else
                break
            fi
        else
            export ${inVariate}=0
        fi
    done
    # 结束遍历并释放所有临时变量，避免未释放的值干扰下次调用
    unset p_
    unset inVariate
    unset inValue
    unset inParameter
    unset isSetValue
}
