#!/usr/bin/env bash
#调用ffprobe统计多个视频的总时长...

#借助awk进行浮点数比较
#See Also：https://stackoverflow.com/questions/8654051/how-can-i-compare-two-floating-point-numbers-in-bash
_numCompare() {
    if awk "BEGIN {exit !($1 == $2)}"; then
        return 0 #二者相等
    elif awk "BEGIN {exit !($1 > $2)}";then
        return 1 #前者比后者大
    else
        return 2 #前者比后者小
    fi
}

videolen() {
	#递归调用videolen，适配多文件的情况,eg：videolen *.mp4	
	_print_help() {
		echo -e "videolen：\n\t调用 ffprobe 查看和计算单个或多个视频的时长（支持通配符*指定某个文件类型）；\n"
		echo -e "Usage:"
		echo -e "\tvideolen file1 [file2 file3 ...]\n"
		echo -e "Example:"
		echo -e "\tvideolen hello.mp4"
		echo -e "\tvideolen 1.mp4 2.mp4 3.mp4 4.mp4"
		echo -e "\tvideolen *.mp4"
	}
	if [ $# -eq 0 ]||[[ "$*" == "-h" || "$*" == "--help" ]];
	then
		_print_help && return
	elif [ $# -eq 1 ];
	then
		printf "时长（秒）："
		IFS=$(echo -e "\n") /v/bin/videolen "$1"|dos2unix -q
		return
	fi
	OLD_IFS=$IFS
	IFS=$(echo -e "\n") 
	local totalTime=0
	local Hours
	local Mintues
	local Seconds
	for file in $@
	do
		#echo -e "$file\t\c"
		#/v/bin/videolen "$file"
		local vTime=$(/v/bin/videolen "$file"|dos2unix -q)
		totalTime=$(echo "${totalTime}+${vTime}"|dos2unix|bc)
		echo -e "$vTime <= $file"
	done
	
	_numCompare "$totalTime" 3600
	local HoursFlag=$?
	_numCompare "$totalTime" 60
	local MintuesFlag=$?
	
	if [ $HoursFlag -le 1 ];then  #时长大于1小时的情况
		Hours=$(echo "$totalTime/3600"|bc)
		#echo -e "小时数：$Hours"
		Mintues=$(echo "($totalTime-3600*$Hours)/60"|bc)
		#echo -e "分钟数：$Mintues"
		Seconds=$(echo "$totalTime%60"|bc)
		#echo -e "秒数：$Seconds"
	elif [ $MintuesFlag -le 1 ];then  #时长大于1分钟的情况
		Mintues=$(echo "$totalTime/60"|bc)
		#echo -e "分钟数：$Mintues"
		Seconds=$(echo "$totalTime%60"|bc)
		#echo -e "秒数：$Seconds"
	fi
	echo "====================================================="
	echo "总时间：$totalTime 秒"
	if [ ! -z "$Mintues" ];then
		printf "合计："
		[ ! -z "$Hours" ] && printf "%s 小时 " $Hours
		[ ! -z "$Mintues" ] && printf "%s 分钟 " $Mintues
		[ ! -z "$Seconds" ] && printf "%s 秒 " $Seconds
		printf "\n"
	fi
	IFS=$OLD_IFS
}
