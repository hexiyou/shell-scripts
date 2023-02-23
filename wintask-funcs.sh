#!/usr/bin/env bash
#命令行一键操作Windows计划任务相关助手函数

#wintask-query    #根据任务名称关键词查询Windows计划任务
#wintask-del      #根据任务名称关键词删除Windows计划任务，也可以传递计划任务完整路径
#wintask-run      #根据任务名称关键词立即运行Windows计划任务
#wintask-enable   #根据任务名称关键词启用Windows计划任务
#wintask-disable  #根据任务名称关键词禁用Windows计划任务

wintask-query(){
	# 根据任务名称关键词查询Windows计划任务
	# Usage：wintask-query xxx
	#————————————————————————————————————————————————————————————————————————————————————————————————————
	#gsudo schtasks.exe /Query /V /FO LIST|awk 'BEGIN{IGNORECASE = 1;}/TaskName:.*'$1'*/,/^\s+$/{print}'
	#修复正则匹配@20221226：
	#1、精确匹配多个相似任务名：eg：stop-potplayer OR stop-potplayer2
	#2、适配查询参数中带路径分隔符反斜杠的情况（\）
	gsudo schtasks.exe /Query /V /FO LIST|awk 'BEGIN{IGNORECASE = 1;}/TaskName:.*?'"${1//\\/\\\\}"'.*?$/,/^\s+$/{print}' 
}

wintask-del(){
	# 根据任务名称关键词删除Windows计划任务，也可以传递计划任务完整路径
	#  Usage：wintask-del xxx
	#     eg：wintask-del stop-potplayer2      #关键字搜索
	#         wintask-del '\Cygwin自用\定时执行命令：stop-potplayer2'  #任务完整路径
	if [ $# -ge 1 ] && [[ "$1" != "" ]];
	then
		if [[ $1 =~ ^\\ ]];
		then
			local taskName=$1
		else
			#local taskName=$(wintask-query "$1"|dos2unix|awk '/TaskName/{printf $2;exit}')
			local taskNames="$(wintask-query $1|dos2unix|awk '/TaskName/{sub($1" ","");sub(/^[ \t]*/,"");print $0}')"  #适配关键词匹配到多个任务的情况
		fi
		[ -z "${taskNames}" ] && local taskNames=("${taskName//\\/\\\\}")
		#local taskCount=(${taskNames})
		declare -a taskCount
		while read -u 0 taskName
		do
			local taskCount=("${taskCount[@]}" "$taskName")
		done<<<"$taskNames"
		if [ ${#taskCount[*]} -gt 1 ];
		then
			echo -e "警惕操作：\"$1\" 匹配到多个任务！(${#taskCount[*]})"
			#echo "${taskCount[*]}"|sed -r 's/ /\n/g'
			echo "$taskNames"
			read -p "是否继续操作？(y/n,yes/no),默认为no: " delcontinue
			if [[ ! "${delcontinue,,}" == "y" && ! "${delcontinue,,}" == "yes" ]];
			then
				echo "退出操作..." && return
			fi
		elif [ ${#taskCount[*]} -eq 1 ];
		then
			read -p "是否确认要删除任务 ${taskCount[0]}？(y/n,yes/no),默认为no: " delcontinue
			if [[ ! "${delcontinue,,}" == "y" && ! "${delcontinue,,}" == "yes" ]];
			then
				echo "退出操作..." && return
			fi
		fi
		#for taskName in `read -u 0`
		while read -u 0 taskName
		do
			#echo "Do => $taskName"
			gsudo schtasks.exe /Delete /TN "$taskName" /F
		done<<<"${taskNames//\\/\\\\}"
	else
		echo -e "Need Paramter: Task Name KeyWord or Full Path!"
	fi
}

wintask-run(){
	# 根据任务名称关键词立即运行Windows计划任务；
	# Usage：wintask-run xxx
	# 可传递具体任务路径或任务关键字进行搜索；
	# Example：
	# wintask-run '\Cygwin自用\语音整点报时' || wintask-run '\Cygwin自用\定时执行命令：alarm'
	#     OR
	# wintask-run 语音整点报时
	if [ $# -ge 1 ] && [[ "$1" != "" ]];
	then
		if [[ $1 =~ ^\\ ]];
		then
			local taskName=$1
		else
			#local taskName=$(wintask-query $1|dos2unix|awk '/TaskName/{printf $2;exit}')
			local taskNames="$(wintask-query $1|dos2unix|awk '/TaskName/{sub($1" ","");sub(/^[ \t]*/,"");print $0}')" #适配关键词匹配到多个任务的情况
		fi
		[ -z "${taskNames[*]}" ] && local taskNames=("$taskName")
		declare -a taskCount
		while read -u 0 taskName
		do
			local taskCount=("${taskCount[@]}" "$taskName")
		done<<<"$taskNames"
		#local taskCount=(${taskNames[@]})
		if [ ${#taskCount[*]} -gt 1 ];
		then
			echo -e "提示：\"$1\" 匹配到多个任务！(${#taskCount[*]})"
			#echo "${taskCount[*]}"|sed -r 's/ /\n/g'
			echo "$taskNames"|awk '{print NR" )："$0;}'
			while :;
			do
				read -p "请输入序号选择你要执行的任务（输入 all/a 运行全部任务，q 或 0 退出操作）: " taskChoose
				if [ -z "$taskChoose" ] || [[ "${taskChoose,,}" == "q" || "${taskChoose,,}" == "0" ]];then
					echo "退出操作..." && return
				elif expr "$taskChoose" + 0 &>/dev/null;
				then
					local taskName=$(echo "$taskNames"|awk 'NR=='$taskChoose'{print;exit}' 2>/dev/null)
					[ ! -z "$taskName" ] && {
						echo "运行任务：$taskName"
						gsudo schtasks.exe /Run /TN "$taskName"
						return
						} || echo "序号选择无效，请重新选择！"
				elif [[ "${taskChoose,,}" == "all" || "${taskChoose,,}" == "a" ]];
				then
					echo "运行全部任务：" && break
				else
					echo "无效选择，退出操作..." && return
				fi
			done
		fi
		#for taskName in $taskNames
		while read taskName
		do
			#echo "Do => $taskName"
			gsudo schtasks.exe /Run /TN "$taskName"
		done<<<"${taskNames//\\/\\\\}"
	else
		echo -e "Need Paramter: Task Name KeyWord or Full Path!"
	fi
}

wintask-enable(){
	# 根据任务名称关键词启用Windows计划任务
	# Usage：wintask-enable xxx
	if [ $# -ge 1 ] && [[ "$1" != "" ]];
	then
		if [[ $1 =~ ^\\ ]];
		then
			local taskName=$1
		else
			#local taskName=$(wintask-query $1|dos2unix|awk '/TaskName/{printf $2;exit}')
			#local taskNames=$(wintask-query $1|dos2unix|awk '/TaskName/{gsub(/TaskName:[\t| ]+/,"");print}') #兼容计划任务名包含空格的情况
			local taskNames=$(wintask-query $1|dos2unix|awk '/TaskName/{gsub(/TaskName:[\t| ]+/,"");taskname=$0}\
														/Scheduled Task State/{if($NF=="Disabled"){printtaskname="true"}}\
														/Repeat: Stop If Still Running/{if(printtaskname=="true"){\
															print taskname;\
															printtaskname="";\
														}}')  #仅搜索包含关键词且处于禁用状态的任务
		fi
		[ -z "$taskNames" ] && taskNames="$taskName"
		[ -z "$taskNames" ] && echo "“$1” 没有找到任何匹配的任务！" && return
		[ $(echo "$taskNames"|wc -l) -gt 1 ] && {
			echo "$taskNames"
			read -p "“$1” 匹配到多于一个的计划任务，是否批量启用以上任务？"$'\n'"> " goContinue
			[[ ! "${goContinue,,}" == "yes" && ! "${goContinue,,}" == "y" ]] && echo "取消操作..." && return
			}
		OLD_IFS=$IFS
		IFS=$(echo -e "\n")
		#for taskName in $taskNames
		while read taskName
		do
			#echo "操作任务：=> $taskName"
			gsudo schtasks.exe /CHANGE /ENABLE /TN "$taskName"
		done<<<"${taskNames//\\/\\\\}"
		IFS=$OLD_IFS
	else
		echo -e "Need Paramter: Task Name KeyWord or Full Path!"
	fi
}

_wintask-disable-for-select(){
	# 根据任务名称关键词禁用Windows计划任务
	# 此函数专供SSH远程链接会话序号选择使用（因手机上不好输入或者复制计划任务的网址途径）
	if [ $# -ge 1 ] && [[ "$1" != "" ]];
	then
		if [[ $1 =~ ^\\ ]];
		then
			local taskName=$1
		else
			local taskNames=$(wintask-query $1|dos2unix|awk '/TaskName/{gsub(/TaskName:[\t| ]+/,"");print}') #兼容计划任务名包含空格的情况
		fi
		[ -z "$taskNames" ] && taskNames="$taskName"
		echo "$taskNames"|awk '{printf "%2d)：%s\n",NR,$0}'
		declare chooseTask
		while [ -z "$chooseTask" ];
		do
			read -p "请输入序号选择你要禁用的计划任务(0/q：退出，p/l:再次打印列表)："$'\n'"> " chooseTask
			[ -z "$chooseTask" ] && echo "退出操作..." && return
			[[ "$chooseTask" == "0" || "${chooseTask,,}" == "q" ]] && echo "退出操作..." && return
			[[ "${chooseTask,,}" == "p" || "${chooseTask,,}" == "l" ]] && {
				echo "$taskNames"|awk '{printf "%2d)：%s\n",NR,$0}'
				chooseTask="" && continue
				}
			local taskName=$(echo "$taskNames"|sed -n "${chooseTask}p" 2>/dev/null)
			[ ! -z "$taskName" ] && break || {
				echo "选择无效，请重新选择！"
				chooseTask=""
			}
		done
		#echo "操作任务=>： $taskName"
		SSH_CONNECTION="" wintask-disable "$taskName"
	else
		echo -e "Need Paramter: Task Name KeyWord or Full Path!"
	fi	
}

wintask-disable(){
	# 根据任务名称关键词禁用Windows计划任务
	# Usage：wintask-disable xxx
	declare taskName
	declare taskNames
	if [ $# -ge 1 ] && [[ "$1" != "" ]];
	then
		if [ ! -z "$SSH_CONNECTION" ];then
			print_color 3 "当前通过ssh远程连接，提供序号选择列表："
			_wintask-disable-for-select "$@"
			return
		fi
		if [[ $1 =~ ^\\ ]];
		then
			local taskName=$1
		else
			#local taskName=$(wintask-query $1|dos2unix|awk '/TaskName/{printf $2;exit}')
			#local taskNames=$(wintask-query $1|dos2unix|awk '/TaskName/{print $2}') #适配关键词匹配到多个任务的情况
			local taskNames=$(wintask-query $1|dos2unix|awk '/TaskName/{gsub(/TaskName:[\t| ]+/,"");print}') #兼容计划任务名包含空格的情况
		fi
		[ -z "$taskNames" ] && taskNames="$taskName"
		[ -z "$taskNames" ] && echo "“$1” 没有找到任何匹配的任务！" && return
		[ $(echo "$taskNames"|wc -l) -gt 1 ] && {
			echo "$taskNames"
			read -p "“$1” 匹配到多于一个的计划任务，是否批量禁用以上任务？"$'\n'"> " goContinue
			[[ ! "${goContinue,,}" == "yes" && ! "${goContinue,,}" == "y" ]] && echo "取消操作..." && return
			}
		OLD_IFS=$IFS
		IFS=$(echo -e "\n")
		#for taskName in $taskNames
		while read taskName
		do
			#echo "操作任务=>： $taskName"
			gsudo schtasks.exe /CHANGE /DISABLE /TN "$taskName"
		done<<<"${taskNames//\\/\\\\}"
		IFS=$OLD_IFS
	else
		echo -e "Need Paramter: Task Name KeyWord or Full Path!"
	fi	
}