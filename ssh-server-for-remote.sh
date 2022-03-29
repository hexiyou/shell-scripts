#!/bin/bash
ssh-server-for-remote() {
	# 登录本地localhost SSH服务，并映射22端口到本地7001端口，以方便在远程服务器上ssh登录本机
	# 本功能适用于家中具有公网IP的情况，Direct connect Home Wan-ip address
	# Usage：ssh-server-for-remote 7001 12345678
	#	ssh-server-for-remote 7001 -vvv administrator@127.0.0.1 -p 22
	#	ssh-server-for-remote 7002 -p 456 administrator@127.0.0.1
	#  可用 sshproxy list/kill 查看或终结相关进程
	local SSHPORT=22
	local SSHBIN="/v/bin/ssh-for-proxy"
	local FORWARDPOST=7001
	
	local DDNSDOMAIN="ip.xxxx.net"
	local DDNSDOMAIN2="frp.xxxx.net"
	
	local SSHPASSENV=""
	local SSHOPTIONS="administrator@127.0.0.1"
	expr $1 "+" 10 &> /dev/null  
	# $1 可指定本地对外映射的端口
	if [ $? -eq 0 ];then
		FORWARDPOST=$1
		shift
	fi
	if [ $# -eq 1 -a ! -z "$1" ];
	then
		SSHPASSENV="sshpass -p $1"
	elif [ $# -gt 1 ];
	then
		# 处理 $2 为密码的情况
		if [[ ! "$1" =~ ^\-.*$ ]] && [[ ! "$1" =~ ^(.+@.+|.*([0-9]{1,3}\.){3}[0-9]{1,3}.*)$ ]];
		then
			SSHPASSENV="sshpass -p $1"
			shift
		fi
		SSHOPTIONS="$*"
		## 处理本地SSH Server非22端口的情况
		local paramsPort=$(echo "$*"|awk '/\-[a-z0-9]*p [0-9]{2,5}/{for(i=1;i<=NF;i++){if(match($i,/\-[a-z0-9]*p/)){printf $(i+1);exit}}}')
		if [ ! -z "$paramsPort" ];
		then
			SSHPORT=$paramsPort
		fi
	fi
	nc -v -w 2 127.0.0.1 ${SSHPORT}
	if [ $? -eq 0 ];
	then
		$SSHPASSENV $SSHBIN -C -N -f -g -L :${FORWARDPOST}:127.0.0.1:${SSHPORT} $SSHOPTIONS
		print_color 33 "Excute Done..."
		echo -e "Testing port..."
		nc -v -w 2 127.0.0.1 ${FORWARDPOST}
		local SSHOPTIONS2=$(echo "$SSHOPTIONS"|sed -r 's/@[^ $]+/@'${DDNSDOMAIN}'/g')
		local SSHOPTIONS3=$(echo "$SSHOPTIONS"|sed -r 's/@[^ $]+/@'${DDNSDOMAIN2}'/g')
		print_color 33 "\nUsage："
		echo -e "ssh -p ${FORWARDPOST} ${SSHOPTIONS2}"
		echo -e "rsync -rlvvztPD -e 'ssh -p ${FORWARDPOST}' ${SSHOPTIONS2}"
		echo
		echo -e "ssh -p ${FORWARDPOST} ${SSHOPTIONS3}"
		echo -e "rsync -rlvvztPD -e 'ssh -p ${FORWARDPOST}' ${SSHOPTIONS3}"
	else
		print_color 9 "本地SSH服务连接失败，请检查本机Cygwin SSHD服务进程是否成功启动"
	fi
}