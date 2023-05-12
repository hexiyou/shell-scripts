#!/usr/bin/env bash
#调用ffprobe统计多个视频的总时长...

#注意：以下代码中的 /v/bin/videolen 为外部子shell脚本，具体代码请查看本仓库同目录下的 _videolen.sh 文件；

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

ideolen-by-filelist() {
	#通过指定的文件列表计算所有视频文件的时长，有别于`videolen`函数：参数直接传递视频文件名
	#适用情况：适用于要统计的视频文件不在同一个目录下，在多个不同子目录或分散在多个不同路径文件夹下的情况（使用`find`命令生成文件列表后调用此函数计算）
	#列表文件（通常为txt文件，后缀不敏感）内容为存放视频文件名或文件路径，一行一个
	#（注：列表内视频的路径用相对路径或绝对路径均可，使用相对路径时需要注意命令行的工作目录，只需调用函数时能读取到相应的视频文件即可）
	_print_help() {
		echo -e "videolen-by-filelist：\n\t通过指定的文件列表计算列表中所有视频文件的时长（格式：通常为txt文件，文件名或文件路径一行一个）；"
		echo -e "\t支持从管道（标准输入）读取文件名列表;\n"
		echo -e "Usage:"
		echo -e "\tvideolen-by-filelist video~list~file"
		echo -e "\tcommandline~to~pipeline|videolen-by-filelist\n"
		echo -e "Example:"
		echo -e "\tvideolen-by-filelist filelist.txt"
		echo -e "\tfind -type f -iname '*.mp4'|videolen-by-filelist"
	}
	if [ $# -eq 0 -a -t 0 ]||[[ "$*" == "-h" || "$*" == "--help" ]];
	then
		_print_help && return
	elif [ $# -eq 1 ];
	then
		[ ! -f "$1" ] && print_color 40 "指定的文件列表( $1 )不存在，请确认！" && return
	fi
	local fileList="$1"
	OLD_IFS=$IFS
	IFS=$(echo -e "\n") 
	local totalTime=0
	local Hours
	local Mintues
	local Seconds
	
	[ ! -t 0 ] && fileHandle=/dev/stdin || fileHandle="$fileList"
	
	while read file;
	do 
		local vTime=$(/v/bin/videolen "$file"|dos2unix -q)
		[ -z "$vTime" ] && printf "0 <= %s \033[40;33m【文件无效或不是视频文件！】\033[0m\n" "$file" && continue  #跳过非视频文件和无效的视频文件
		totalTime=$(echo "${totalTime}+${vTime}"|dos2unix|bc)
		echo -e "$vTime <= $file"
	done <$fileHandle
	
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
alias videolen-from-list='videolen-by-filelist'
alias videolen2='videolen-by-filelist'

findmp4-to-playlist() {
	#通过 find 命令查找mp4文件生成M3U播放列表，供 PotPlayer 使用;
	#默认仅查找后缀名为.mp4的文件，列表顺序按文件名顺序进行排列；
	#$1可指定要查找文件的根目录，默认为当前工作路径下查找；
	#eg:
	#	findmp4-to-playlist|tee playlist.m3u
	#   findmp4-to-playlist >playlist.m3u
	#   findmp4-to-playlist /cygdrive/d/Temp/php/录制|tee playlist.m3u
	local workPath="$PWD"
	local noPwd=0
	while [ $# -gt 0 ];
	do
		if [[ "${1,,}" == "--nopwd" ]];then
			local noPwd=1
		elif [ ! -z "$1" -a -d "$1" ];then
			workPath="$1"
		fi
		shift
	done
	[ $noPwd -eq 1 ] && local WPWD="" || local WPWD="$(echo $workPath|cygpath -aw -f-)"
	pushd "$workPath" &>/dev/null
	find -type f -iname '*.mp4'|awk '{print "'${WPWD//\\/\\\\}'"$0}'
	popd &>/dev/null
}
alias video-to-playlist='findmp4-to-playlist'
alias video-to-playlist-nopwd='findmp4-to-playlist --nopwd'
alias video-to-playlist2='findmp4-to-playlist --nopwd'

videolenfull-by-filelist() {
	#通过指定的文件列表计算所有视频文件的时长，有别于`videolen-by-filelist`函数：本函数同时会格式化单个视频的时长（几小时几分钟）
	_print_help() {
		echo -e "videolenfull-by-filelist：\n\t通过指定的文件列表计算列表中所有视频文件的时长（格式：通常为txt文件，文件名或文件路径一行一个）；"
		echo -e "\t支持从管道（标准输入）读取文件名列表;\n"
		echo -e "Usage:"
		echo -e "\tvideolenfull-by-filelist video~list~file"
		echo -e "\tcommandline~to~pipeline|videolenfull-by-filelist\n"
		echo -e "Example:"
		echo -e "\tvideolenfull-by-filelist filelist.txt"
		echo -e "\tfind -type f -iname '*.mp4'|videolenfull-by-filelist"
	}
	if [ $# -eq 0 -a -t 0 ]||[[ "$*" == "-h" || "$*" == "--help" ]];
	then
		_print_help && return
	elif [ $# -eq 1 ];
	then
		[ ! -f "$1" ] && print_color 40 "指定的文件列表( $1 )不存在，请确认！" && return
	fi
	local fileList="$1"
	OLD_IFS=$IFS
	IFS=$(echo -e "\n") 
	local totalTime=0
	local Hours
	local Mintues
	local Seconds
	
	[ ! -t 0 ] && fileHandle=/dev/stdin || fileHandle="$fileList"
	
	while read file;
	do 
		local vTime=$(/v/bin/videolen "$file"|dos2unix -q)
		[ -z "$vTime" ] && printf "0 <= %s \033[40;33m【文件无效或不是视频文件！】\033[0m\n" "$file" && continue  #跳过非视频文件和无效的视频文件
		totalTime=$(echo "${totalTime}+${vTime}"|dos2unix|bc)
		#echo -e "$vTime <= $file"
		_numCompare "$vTime" 3600
		local HoursFlag=$?
		_numCompare "$vTime" 60
		local MintuesFlag=$?
		
		if [ $HoursFlag -le 1 ];then  #时长大于1小时的情况
			Hours=$(echo "$vTime/3600"|bc)
			#echo -e "小时数：$Hours"
			Mintues=$(echo "($vTime-3600*$Hours)/60"|bc)
			#echo -e "分钟数：$Mintues"
			Seconds=$(echo "$vTime%60"|bc)
			#echo -e "秒数：$Seconds"
		elif [ $MintuesFlag -le 1 ];then  #时长大于1分钟的情况
			Mintues=$(echo "$vTime/60"|bc)
			#echo -e "分钟数：$Mintues"
			Seconds=$(echo "$vTime%60"|bc)
			#echo -e "秒数：$Seconds"
		fi
		if [ ! -z "$Mintues" ];then
			[ ! -z "$Hours" ] && printf "%s 小时 " $Hours
			[ ! -z "$Mintues" ] && printf "%s 分钟 " $Mintues
			[ ! -z "$Seconds" ] && printf "%s 秒 " $Seconds
			printf " <= %s" "$file"
			printf "\n"
		fi
	done <$fileHandle
	
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

videolenfull() {
	#调用 videolenfull-by-filelist 计算单个视频的时长（完整模式：格式化为小时数、分钟数）和统计多个视频的时长
	if [ ! -t 0 ];then
		videolenfull-by-filelist </dev/stdin
	else
		if [ $# -gt 1 ];then
			#echo "多个参数处理流程..."
			#videolenfull-by-filelist <<<"$@"
			#See Also：https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string
			local _list=$(IFS=$'\n'; echo "$*")
			videolenfull-by-filelist <<<"$_list"
		else
			if [ ! -f "$1" ] && [[ "${1,,}" =~ ^- ]];then
				videolenfull-by-filelist "$@"
			elif [[ "${1,,}" =~ \.txt$ || "${1,,}" =~ \.log$ ]];then
				videolenfull-by-filelist "$@"
			else
				videolenfull-by-filelist <<<"$@"
			fi
		fi
	fi
}
