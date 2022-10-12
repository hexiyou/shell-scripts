#!/usr/bin/env bash
#创建ctime时刻为为任意日期时间的新文件
fakedatefile() {
	##创建一个假“创建时间（create time/birth time）”的文件；
	##因touch命令只能修改文件的“修改时间（Modify Time）”和“访问时间（Access Time）”，故用此函数曲线救国；
	# See Also：https://unix.stackexchange.com/questions/36021/how-can-i-change-change-date-of-file
	local settingDate="${1}"
	local file="$2"
	_print_usage() {
		echo -e "fakedatefile：\n\t伪造新建文件的时间：创建一个以指定日期时间作为Create Time的新文件；"
		echo -e "\t原理：设置当前系统时间为假时间，创建新文件，再修改系统时间回正确时间；"
		echo -e "\t因touch命令默认只能修改文件的“修改时间（Modify Time）”和“访问时间（Access Time）”，故使用此函数；"
		echo -e "\nUsage：\n\tfakedatefile *the~date~time *file~name\n"
		echo -e "--------------------------------------------------------------"
		echo -e "\nExample：\n\tfakedatefile \"2018-08-15 08:08:08\" newfile.txt"
	}
	
	if [[ $# == 0 || "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		_print_usage && return
	elif [ $# -lt 2 ];then
		echo "缺少参数，请指定日期时间和要创建的文件名！"
		_print_usage && return
	fi
	
	if [[ "$(uname)" =~ "CYGWIN" ]];then
		#Cygwin下需要使用超级管理员执行此命令（因只有管理员权限能修改系统时间）；
		#echo "Running on Cygwin..."
		ASMyBash=true mysudo "NOW=\$(date +@%s) && date -s \"${settingDate}\" && touch \"$file\" && date -s \"\$NOW\""
	else
		NOW=$(date +@%s) && date -s "${settingDate}" && touch "$file" && date -s "$NOW"
	fi
	echo -e "\n【File】：$file 已创建！\n"
	stat "$file"
	echo "All thing Done..."
}