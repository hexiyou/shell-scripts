#!/usr/bin/env bash
killsshps() {
	#终止某主机的SSH进程(根据主机的远程IP地址判断)；
	# $1 --> 可指定主机名称或IP地址；
	local host
	local hostIP
	local defaultJumpHost="host01" #默认经常使用的跳板机
	
	[ -z "$1" ] && echo "请指定SSH主机名或IP地址!" && return
	[[ "$1" =~ ^[0-9]{1,3}[0-9\.]+$ ]] && hostIP="$1" || host="$1"
	if [ -z "$hostIP" ];then
		hostInfo=$(eval sshfind $host)
		hostIP=$(echo "$hostInfo"|grep -m 1 -iE '^[^#]*Hostname [ ]*[0-9]{1,3}\..*$'|awk '{print $NF}')
	fi
	if [ -z "$hostIP" ];then
		print_color 40 "没有找到主机 \"$host\" !"
		return
	fi
	findremoteip "$hostIP" ssh
	local retCode=$?
	
	if [[ ! -z "$host" && ! -z "$defaultJumpHost" && "${host,,}" != "$defaultJumpHost" && $retCode != 0 ]];then #如果没有找到链接进程，可能使用了跳板机作为隧道进程，尝试终止kunming主机进程
		print_color 40 "没有找到 $host 主机相关 SSH 进程..."
		print_color 40 "查询是否有 $defaultJumpHost 主机进程，请确认 $host 主机是否使用了 $defaultJumpHost 作为跳板机？"
		killsshps $defaultJumpHost
	fi
}