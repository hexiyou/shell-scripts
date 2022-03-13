#!/bin/bash
findport() {
	# 查看Windows监听端口占用相关进程：
	if [ -z "$1" ]
	then
		echo "缺少端口号！"
		echo "\`findport\` 查看占用端口的进程："
		echo "Usage：findport 3450"
		return 0
	fi
	local port="$1"
	shift
	#local netstatInfo=$(cmd /c netstat -ano -p TCP|grep ":$port ")
	local netstatInfo=$(cmd /c netstat -ano -p TCP|awk '{if(match($2,/'":$port"'$/)){print}}')
	echo "$netstatInfo"
	local pid=$(echo "$netstatInfo"|grep 'LISTENING'|awk '{print $NF;exit}'|tr -d '\n\r')
	if [ -z "$pid" ]
	then
		echo "$port 端口没有找到相关进程..."
		return 0
	fi
	if [ ! -z "$1" ] && [[ "${1,,}" == "/v" || "${1,,}" == "-v" ]]
	then
		cmd /c tasklist /v|iconv -s -f GBK -t UTF-8|grep $pid
	else
		cmd /c tasklist|grep $pid
	fi
	##查看此进程是否关联Windows服务，如果有，提示是否需要net stop停止服务
	## Also you can use this powershell command：(Get-WmiObject Win32_Service -Filter "ProcessId='$PID'")
	local serviceInfo=$(cmd /c tasklist /svc /NH /FI "PID EQ $pid"|iconv -s -f GBK -t UTF-8)
	echo -e "关联服务信息查询：$serviceInfo"
	local serviceName=$(echo "$serviceInfo"|dos2unix -q|sed -r '/^$/!{s/^.*'$pid' //;s/[\t| ]*$//g}'|tr -d '\n')
	if [ ! "$serviceName" = "N/A" -a ! "$serviceName" = "暂缺" ];then	
		read -p ">> 进程发现关联服务，是否需要停止服务 “$serviceName”? yes/no(y/n),默认No： " stopService
		if [[ "${stopService,,}" == "y" || "${stopService,,}" == "yes" ]];then
			echo ">>> Stop Service ..."
			gsudo net stop "$serviceName"
			echo "To check port $port again ..."
			findport $port
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
}