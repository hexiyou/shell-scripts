#!/bin/bash
#ping同名hook函数，可以ping一个网址，ping之前检查域名是否被hosts文件劫持，ping局域网ip检查是否开启了zerotier等异地组网服务；
ping() {
	if [ $# -eq 1 ] && [[ "$1" =~ "/" ]];then
	#if [ $# -eq 1 ] && [[ "$1" =~ ^http ]];then
		host=$(/usr/bin/env python3 /v/bin/python-parseurl.py "$1")
		[ ! -z "$host" ] && _ping $host
	else
		_ping "$@"
	fi
}

_ping(){
	# 检查域名是否被hosts文件劫持,同时检查局域网路由状态是否正常
	local winHosts="$SYSTEMROOT\\System32\\drivers\\etc\\hosts"
	local target="${@:$#}"
	if [[ ! "$target" =~ ^\- ]];
	then
		#grep -vE '^\s*\t*#' $winHosts|awk '{print $NF}'|grep -i $target >/dev/null 2>&1
		awk '!/^\s*\t*#|^$/{gsub("\r","");print $NF}' $winHosts|grep -ix "$target" >/dev/null 2>&1
		if [ $? -eq 0 ];
		then
			print_color 41 "Notice：$target 被hosts文件重定向...！"
		fi	
	fi
	if [[ "${@:$#}" =~ ^10\. || "${@:$#}" =~ ^192\.168 || "${@:$#}" =~ ^172\. || "${@:$#}" =~ ^100\. ]];then #IPv4 LAN CIDR check
		echo "检查局域网路由状态......"
		local targetHost="${@:$#}"
		local routeNextHop=$(cmd /c tracert -4 -d -w 2 -h 1 "$targetHost"|dos2unix -q|iconv -s -f GBK -t UTF-8|grep -vE '^[\s|\t]*$'|sed -n '2p'|awk '{print $NF}')
		#echo "$routeNextHop"
		if [ ! -z "$routeNextHop" ];then
			local routePrefix=$(echo "$routeNextHop"|cut -d "." -f1,2) #取IPv4地址前两段，只对前缀进行比较
			#echo "$routePrefix"
			echo "$targetHost"|grep "$routePrefix" &>/dev/null
			if [ $? -ne 0 ];then #路由第一跳IP地址前缀与ping的目标主机不匹配，则给出警告提示，是否开启了Zerotier等异地组网虚拟网卡服务
				print_color 40 "警告：目标地址为局域网IP，且网关路由第一跳与之不匹配！"
				print_color 40 "影响：可能导致\`ping\`不通目标地址或路由绕路。"
				print_color 40 "请注意人工确认是否开启了Zerotier、Tailscale等异地组网虚拟网卡服务，是否影响到获取正确的\`ping\`结果"
			fi
		fi
	fi
	/usr/bin/ping "$@"
}
