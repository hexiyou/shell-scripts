#!/bin/bash
#Cygwin/WSL文件夹收藏书签功能，输入序号快速打开指定文件夹
favorite-dirs() {
	#使用资源管理器快速打开Windows系统常用文件夹
	local mydirs=$(cat<<EOF
	Shell:downloads
	Shell:documents
	Shell:Sendto
	Shell:Quick Launch
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
					echo "Open Dir $targetDir ..."
					cmd /c explorer.exe "$targetDir "
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