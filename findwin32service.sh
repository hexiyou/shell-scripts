#!/usr/bin/env bash

findservice() {
	# 根据进程名称或进程ID查找关联的Windows服务；
	if [ -z "$1" ]||([[ "$*" == "-h" || "$*" == "--help" ]]);then
		[ -z "$1" ] && echo -e "缺少进程名/进程ID！"
		echo -e "\`findservice\` 查看某进程关联的Windows服务;"
		echo -e "注：(如果存在多个同名进程，请指定pid而不是进程名称，以便于区分！)\n"
		echo -e "Usage： findservice CCB_HDZB_2G_DeviceService.exe"
		echo -e "\tfindservice 5360"
		return 0
	fi
	local parameter="$1" && shift
	expr "$parameter" + 0 &>/dev/null
	if [ $? -eq 0 ];then
		local serviceInfo=$(cmd /c tasklist /svc /NH /FI "PID EQ ${parameter}"|iconv -s -f GBK -t UTF-8)
	else
		local serviceInfo=$(cmd /c tasklist /svc /NH /FI "IMAGENAME EQ ${parameter}"|iconv -s -f GBK -t UTF-8)
	fi
	echo -e "关联服务信息查询：$serviceInfo"
	local serviceName=$(echo "$serviceInfo"|tr -s '[\t ]'|grep "${parameter}"|tac|dos2unix -q|awk -F '[\t ]' \
	'{srvname="";for(i=3;i<NF;i++){srvname=sprintf("%s %s",srvname,$i)};sub(" ","",srvname);print srvname;exit}') #目前仅适配关联一个服务的情况，关联多个服务暂不考虑
	if [ ! -z "$serviceName" -a ! "$serviceName" = "N/A" -a ! "$serviceName" = "暂缺" ];then	
		read -p ">> 进程发现关联服务，是否需要停止服务 “$serviceName”? yes/no(y/n),默认No： " stopService
		if [[ "${stopService,,}" == "y" || "${stopService,,}" == "yes" ]];then
			echo ">>> Stop Service ..."
			gsudo net stop "$serviceName"
			echo "To find process associated service again ..."
			findservice "$parameter"
		fi
	elif [ ! -z "$serviceName" ];then
		local pid
		expr "$parameter" + 0 &>/dev/null && pid="$parameter" || \
				pid=$(echo "$serviceInfo"|tr -s '[\t ]'|grep "${parameter}"|tac|dos2unix -q|awk -F '[\t ]' '{print $2;exit}')  #目前未处理多个同名进程的情况
		echo "pid为 $pid 的进程未关联服务或服务不是Win32本地系统服务！"
		echo "如：（“Cygwin sshd”是常驻服务，但不是本地服务，是用户登录服务）"
		
		read -p ">> 是否需要终止进程 “PID：$pid”? yes/no(y/n),默认No： " killProcess
		if [[ "${killProcess,,}" == "y" || "${killProcess,,}" == "yes" ]];then
			echo ">>> Kill Process ..."
			gsudo taskkill /F /PID "$pid"
		fi
	else
		echo "找到没有相关进程！"
	fi
}