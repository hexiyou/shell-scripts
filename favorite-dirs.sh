#!/bin/bash
#Cygwin/WSL文件夹收藏书签功能，输入序号快速打开指定文件夹
favorite-dirs() {
	#使用资源管理器快速打开Windows系统常用文件夹
	local mydirs=$(cat<<EOF
	Shell:downloads
	Shell:documents
	Shell:Sendto
	Shell:Quick Launch
	Shell:AppsFolder
	Shell:AppData
	%LocalAppdata%
	Shell:startup
	Shell:common startup
	Shell:programfiles
	Shell:programfilesx86
	%UserProfile%
	%UserProfile%\.ssh
	Shell:ProgramFiles\git
	Shell:ProgramFiles\git\etc
	Shell:AppData\Google
	Shell:programfilesx86\NetSarang
	D:\MySelf\shell-scripts
	D:\Work\Documents
EOF
)
	#追加paths/d函数使用的书签文件到本函数目录列表；
	local mydirs="$mydirs"$'\n'"$(cat /v/bin/dirs.conf)"
	local openerTool="explorer.exe"
	while :;
	do
		#如果传入了$1参数，则对目录列表进行关键字搜索，而后仅列出匹配关键字的结果
		if [ $# -eq 1 -a ! -z "$1" ];then
			local mydirs=$(echo "$mydirs"|grep -i "$1")
			break
		elif [ $# -ge 1 ] && [[ "${1,,}" == "--open" ]];then #指定了额外程序替代资源管理器的情况
			shift
			if [ ! -z "$1" ] && [[ ! "$1" =~ ^\- ]];then
				local openerTool="$1"
				echo "使用 $openerTool 打开文件夹 ..."
				shift
			fi
		elif [ $# -ge 1 ];then
			local mydirs=$(echo "$mydirs"|grep $@)
			break
		else
			break
		fi
	done
	#echo "跳出参数解析..."
	#输出选择菜单：
	echo "$mydirs"|awk '{printf NR"): ";print}'
	while :;
	do
		read -p "请输入序号选择,可一次性输入多个选项[用空格隔开](输入 0 退出选择,输入 p 再次打印目录选项)：" dirChoose
		if [ ! -z "$dirChoose" ];then
			if [[ "${dirChoose,,}" == "p" ]];then
				echo "$mydirs"|awk '{printf NR"): ";print}'
				continue
			fi
			if [[ "$dirChoose" == "0" ]];then
				echo "exit..."
				break
			fi
			open-single-dir() {
				#local targetDir=$(echo "$mydirs"|awk "NR==$dirChoose"'{gsub(/^\s*/,"");print;exit}')
				local targetDir=$(echo "$mydirs"|awk "NR==$1"'{gsub(/^\s*/,"");print;exit}')
				if [ ! -z "$targetDir" ];then
					#echo "Open Dir $targetDir ..."
					#cmd /c explorer.exe "$targetDir"
					if [[ "$targetDir" =~ ^[a-z]:\\ || "$targetDir" =~ ^/cygdrive/ || "$targetDir" =~ ^/ ]];then #常规路径模式下判断文件夹是否存在
						if [ ! -e "$targetDir" ];then
							#echo -e "targetDir not exist!\n==>$targetDir"
							print_color 9 "targetDir not exist! ==> $targetDir"
						else
							echo "Open Dir $targetDir ..."
							#cmd /c explorer.exe `cygpath -aw "$targetDir"`
							cmd /c "$openerTool" `cygpath -aw "$targetDir"`
						fi
					else #适配Shell:模式或Windows原生环境变量模式；
						echo "Open Dir $targetDir ..."
						#cmd /c explorer.exe "$targetDir"
						cmd /c "$openerTool" "$targetDir"
					fi
				else
					echo "targetDir is empty!"
				fi
			}
			mapfile -t -d $' ' myDirArr<<<"$dirChoose"
			
			for dir in ${myDirArr[@]};
			do 
				#echo "open dir:$dir"
				[[ "$dir" == "0" ]] && { echo "exit...";return; }
				open-single-dir $dir
			done			
		else
			echo "Have No Choice...!"
		fi
	done
}
alias mydirs='favorite-dirs'
alias d3='favorite-dirs'