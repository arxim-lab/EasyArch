#!/bin/bash

trap '' 2

#检查Root权限
if [[ $(whoami) != 'root' ]]; then
    echo "Please log in as Root"
    exit 255
fi

#初始化参数传递
# 将所有的参数存储到 Para_ 数组中去，方便读参函数调用
i=0
for para_; do
    Para_[$i]=${para_}
    i=$(expr ${i} + 1)
done
unset para_
unset i

#初始化系统环境
source ./loader.sh                              # Completed

#加载函数
source ./modules/readvar.sh                     # Completed
source ./modules/installer.sh
source ./modules/selector.sh


#加载主程序
source ./controller.sh
