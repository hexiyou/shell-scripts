#!/bin/bash
#命令行终端文件夹书签功能，方便在Mintty窗口中使用Ctrl+鼠标左键单击打开指定目录；
paths() {
	## 存储一些常用的文件夹路径，d命令终端输出
	## 按住Ctrl键，鼠标单击条目即快速打开
	local apppath="/v/bin/dirs.conf"
	if [ -e "${apppath}" ];then
	if [ $# -eq 1 -a -d "$1" ];then
		echo "$1" >>${apppath}
		echo "add $1 To ${apppath} Done..."
		return
	elif [ $# -eq 1 ] && [[ "${1,,}" == "-c" || "${1,,}" == "--check" ]];then
		# $1==-c/--check 查询路径是否存在，以不同颜色显示进行区分
		local paths=$(cat ${apppath}|cygpath -u -f-|sed -r 's/\s/\?/g')
		for pathItem in ${paths[@]}
		do
			OLD_IFS=$IFS
			IFS=$(echo -e "\n")
			local showPath=$(echo $pathItem|sed -r 's/\?/\\\\ /g')
			if [ -e "$showPath" ];
			then
				echo -e "`echo $showPath|sed -r 's/\s/\\\ /g'`\t存在"
				#print_color 3 `echo $showPath|sed -r 's/\s/\\\ /g'`
			else
				#echo "$showPath  不存在"
				print_color 9 "${showPath}\t不存在"
			fi
			IFS=$OLD_IFS
		done	
	elif [ $# -eq 1 ];then
		cat ${apppath}|grep -i "$1"|cygpath -u -f-|sed -r 's/\s/\\\ /g'
	else
		#cat ${apppath}|cygpath -u -f-|sed "s/^/'/;s/$/'/"
		#以下处理为兼容路径中包含空格的情况
		cat ${apppath}|cygpath -u -f-|sed -r 's/\s/\\\ /g'
	fi
	else
		echo -e "dirs configure file not found!\npath：${apppath//\\/\\\\} "
	fi
}
alias d=paths
alias d2='paths --check'