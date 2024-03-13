#!/bin/bash
#在Linux多IP服务器上一键切换出口IP（借助iptables规则）

ipchange() {
	#调用iptables一键切换出口IP（主要在Linux多IP站群服务器上使用）
	local changeToIP="$1"
	if [[ "$(uname -o)" != "GNU/Linux" ]];then 
		print_color 40 "【错误】：本函数仅能在Linux系统下使用，Cygwin、Msys2等模拟环境下不可用！"
		return
	else
		[[ ! "$(type -t iptables)" == "file" ]] && print_color 40 "系统没有发现iptables命令，可能是精简版系统或没有安装相关的包，退出后续操作..." && return
		local currentRule=$(iptables -nL POSTROUTING -t nat|grep NAT)
		if [ -z "$currentRule" ];then 
			print_color 40 "当前iptables没有生效的出口IP规则！"
		else 
			if [ $(echo "$currentRule"|wc -l) -gt 1 ];then 
				print_color 40 "【警告】：当前有多条出口IP规则，但仅第一条规则生效！"
			fi
			echo "$currentRule"|sed 's/^/\t/'  #打印iptables规则供确认？
			local outIP=$(echo "$currentRule"|awk -F ':' '{print $NF;exit}')      #当有多条IP规则时，仅获取第一条有效规则的IP
			print_color 40 "是否删除当前出口IP为 $outIP 的iptables规则？(yes/y，no/n，默认为no)"
			read -p "> " deleteIP
			if [[ "${deleteIP,,}" == "y" || "${deleteIP,,}" == "yes" ]];then 
				iptables -t nat -D POSTROUTING -o enp2s0f0 -d 0.0.0.0/0 -j SNAT --to-source $outIP
				local deleteRet=$?
				[ $deleteRet -ne 0 ] && print_color 40 "ErrCode：[$deleteRet]，iptables规则删除失败，请检查命令及其参数！"
			else 
				print_color 40 "跳过删除IP..."
			fi
		fi
		print_color 40 "是否添加规则，切换出口IP为 $changeToIP？(yes/y，no/n，默认为no)"
		read -p "> " insertIP
		[ -z "$changeToIP" ] && print_color 40 "没有指定要切换的出口IP，程序退出！" && return
		if [[ "${insertIP,,}" == "y" || "${insertIP,,}" == "yes" ]];then 
			iptables -t nat -I POSTROUTING -o enp2s0f0 -d 0.0.0.0/0 -j SNAT --to-source $changeToIP
			local insertRet=$?
			[ $insertRet -ne 0 ] && print_color 40 "ErrCode：[$insertRet]，iptables命令操作失败，可能是指定的出口IP无效！"
		else 
			print_color 40 "跳过切换IP操作..."
		fi
	fi
}