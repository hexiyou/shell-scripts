#!/bin/bash
print_color() {
	## print_color 打印带颜色的文字
	# $1 -- 颜色编号,(可省略)；缺省为3 ——绿色字
	# $2 或 $* -- 打印的文字内容
	# -----------------------------
	:<<EOF
echo -e "\033[字背景颜色;文字颜色m字符串\033[0m"
例如: 
echo -e "\033[47;30m I love Android！ \033[0m"
	 其中47的位置代表背景色, 30的位置是代表字体颜色，需要使用参数-e，man  echo 可以知道-e     enable interpretation of backslash escapes。
----------
See Also：
https://www.cnblogs.com/fengliu-/p/10128088.html
EOF
	if [ $# -eq 0 ];
	then
		echo -e "\033[30m 黑色字 \033[0m"
		echo -e "\033[31m 红色字 \033[0m"
		echo -e "\033[32m 绿色字 \033[0m"
		echo -e "\033[33m 黄色字 \033[0m"
		echo -e "\033[34m 蓝色字 \033[0m"
		echo -e "\033[35m 紫色字 \033[0m"
		echo -e "\033[36m 天蓝字 \033[0m"
		echo -e "\033[37m 白色字 \033[0m"

		echo -e "\033[40;37m 黑底白字 \033[0m"
		echo -e "\033[41;37m 红底白字 \033[0m"
		echo -e "\033[42;37m 绿底白字 \033[0m"
		echo -e "\033[43;37m 黄底白字 \033[0m"
		echo -e "\033[44;37m 蓝底白字 \033[0m"
		echo -e "\033[45;37m 紫底白字 \033[0m"
		echo -e "\033[46;37m 天蓝底白字 \033[0m"
		echo -e "\033[47;30m 白底黑字 \033[0m"
		echo 
		echo -e "See Also：\n\thttps://www.cnblogs.com/fengliu-/p/10128088.html"
		return
	fi
	local color=3 #默认颜色
	#判断第一个参数是否为纯数字，如果是数字，则认定为设定颜色编号
	if [ $# -ge 2 ];
	then
		expr $1 "+" 10 &> /dev/null  
		if [ $? -eq 0 ];then
			local color=$1
			shift
		fi
	fi
	local str="$*"
	case $color in
		1)
		echo -e "\033[30m${str}\033[0m"
		;;              
		2)              
		echo -e "\033[31m${str}\033[0m"
		;;              
		3)              
		echo -e "\033[32m${str}\033[0m"
		;;              
		4)              
		echo -e "\033[33m${str}\033[0m"
		;;              
		5)              
		echo -e "\033[34m${str}\033[0m"
		;;              
		6)              
		echo -e "\033[35m${str}\033[0m"
		;;              
		7)              
		echo -e "\033[36m${str}\033[0m"
		;;              
		8)              
		echo -e "\033[37m${str}\033[0m"
		;;
		9)
		#红底白字
		echo -e "\033[41;37m${str}\033[0m"
		;;
		10)
		#白底黑字
		echo -e "\033[47;30m${str}\033[0m"
		;;
		33)
		#绿底黄字
		echo -e "\033[42;33m${str}\033[0m"
		;;
		37)
		#蓝底白字
		echo -e "\033[44;37m${str}\033[0m"
		;;
		40)
		#黑底黄字
		echo -e "\033[40;33m${str}\033[0m"
		;;
		41)
		#红底黄字
		echo -e "\033[41;33m${str}\033[0m"
		;;
		*)
		#蓝底白字
		echo -e "\033[44;37m${str}\033[0m"
		;;
	esac
}