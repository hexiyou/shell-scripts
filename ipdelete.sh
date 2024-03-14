#!/usr/bin/env bash
#一键删除用于切换出口IP的iptables规则（主要在Linux多IP站群服务器上使用）

ipdelete() {
	#一键删除用于切换出口IP的iptables规则（主要在Linux多IP站群服务器上使用）
	if [[ "$(uname -o)" != "GNU/Linux" ]];then 
		print_color 40 "【错误】：本函数仅能在Linux系统下使用，Cygwin、Msys2等模拟环境下不可用！"
		return
	else
		[[ ! "$(type -t iptables)" == "file" ]] && print_color 40 "系统没有发现iptables命令，可能是精简版系统或没有安装相关的包，退出后续操作..." && return
		local currentRule=$(iptables -nL POSTROUTING -t nat|grep NAT)
		if [ -z "$currentRule" ];then 
			print_color 40 "当前iptables没有生效的出口IP规则！"
		else 
			local ruleCount=$(echo "$currentRule"|wc -l)
			if [ $ruleCount -gt 1 ];then 
				print_color 40 "【警告】：发现有多条出口IP规则（共 $ruleCount 条）！"
			fi
			echo "$currentRule"|sed 's/^/\t/'  #打印iptables规则供确认？
			print_color 40 "是否删除当前iptables规则（共 $ruleCount 条）？(yes/y，no/n，默认为no)"
			read -p "> " deleteIP
			if [[ "${deleteIP,,}" == "y" || "${deleteIP,,}" == "yes" ]];then
				local targetIPS=$(echo "$currentRule"|awk -F ':' '{print $NF}')
				while read outIP
				do
					iptables -t nat -D POSTROUTING -o enp2s0f0 -d 0.0.0.0/0 -j SNAT --to-source $outIP
					local deleteRet=$?
					[ $deleteRet -ne 0 ] && print_color 40 "ErrCode：[$deleteRet]，$outIP iptables规则删除失败，请检查命令及其参数！"
				done <<<"$targetIPS"
			else 
				print_color 40 "跳过删除iptables规则..."
			fi
		fi
	fi
}