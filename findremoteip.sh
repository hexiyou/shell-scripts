#!/usr/bin/env bash
findremoteip() {
	# 根据网络连接的远程主机IP查找Windows相关进程：
	# 目前仅针对IPv4做适配，IPv6暂不考虑
	if [ -z "$1" ]
	then
		echo -e "缺少远程IP！"
		echo -e "\`findremoteip\` 查看连接到指定IP的相关进程：\n"
		echo -e "Example: "
		echo -e "\tfindremoteip *remote~ip [filter~by~process~name] [-v]\n"
		echo -e "Usage： findremoteip 114.114.114.114"
		echo -e "\tfindremoteip 114.114.114.114 ssh  #仅查找该IP的ssh进程，其他进程忽略"
		return 0
	fi
	local remoteIP="$1" && shift
	local psName=""  #用此参数查找进程，当远程IP有多个匹配进程时，用于过滤；
	[ ! -z "$1" ] && [[ ! "${1,,}" == "/v" && ! "${1,,}" == "-v" ]] && psName="$1" && shift
	#local netstatInfo=$(cmd /c netstat -ano -p TCP|grep ":$port ")
	local netstatInfo=$(cmd /c netstat -ano -p TCP|awk '{if(match($3,/^'"$remoteIP"':/)){print}}')
	[ ! -z "$netstatInfo" ] && echo "$netstatInfo"
	#local pid=$(echo "$netstatInfo"|grep 'LISTENING'|awk '{print $NF;exit}'|tr -d '\n\r')
	local pids=$(echo "$netstatInfo"|grep 'ESTABLISHED'|awk '{print $NF}'|dos2unix -q)
	if [ -z "$pids" ]
	then
		echo "$remoteIP 地址没有找到相关进程..."
		return 1
	fi
	for pid in $pids; #对多个远程IP关联进程依次处理！
	do
		if [ ! -z "$1" ] && [[ "${1,,}" == "/v" || "${1,,}" == "-v" ]]
		then
			cmd /c tasklist /v|iconv -s -f GBK -t UTF-8|grep $pid
		else
			cmd /c tasklist|grep $pid
		fi
		##查看此进程是否关联Windows服务，如果有，提示是否需要net stop停止服务
		## Also you can use this powershell command：(Get-WmiObject Win32_Service -Filter "ProcessId='$PID'")
		local serviceInfo=$(cmd /c tasklist /svc /NH /FI "PID EQ $pid"|iconv -s -f GBK -t UTF-8|grep -i "$psName")
		[ -z "$serviceInfo" ] && continue
		echo -e "关联服务信息查询：$serviceInfo"
		local serviceName=$(echo "$serviceInfo"|dos2unix -q|sed -r '/^$/!{s/^.*'$pid' //;s/[\t| ]*$//g}'|tr -d '\n')
		if [ ! "$serviceName" = "N/A" -a ! "$serviceName" = "暂缺" ];then	
			read -p ">> 进程发现关联服务，是否需要停止服务 “$serviceName”? yes/no(y/n),默认No： " stopService
			if [[ "${stopService,,}" == "y" || "${stopService,,}" == "yes" ]];then
				echo ">>> Stop Service ..."
				gsudo net stop "$serviceName"
				echo "To check remoteip $remoteIP again ..."
				findremoteip $remoteIP
			fi
		else
			echo "pid为 $pid 的进程未关联服务或服务不是Win32本地系统服务！"
			echo "如：（“Cygwin sshd”是常驻服务，但不是本地服务，是用户登录服务）"
			
			read -p ">> 是否需要终止进程 “PID：$pid”? yes/no(y/n),默认No： " killProcess
			if [[ "${killProcess,,}" == "y" || "${killProcess,,}" == "yes" ]];then
				echo ">>> Kill Process ..."
				gsudo taskkill /F /PID "$pid"
			fi
		fi
	done
}