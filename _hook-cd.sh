#!/usr/bin/env bash

_hook-cd() {
	#劫持cd命令，方便在手机终端不方便打汉字的情况下切换目录
	[ $# -gt 0 ] && \cd "$@" && return
	[[ "$-" != *i* ]] && \cd "$@" && return  #非交互式会话操作直接返回
	[ -z "$SSH_TTY" ] && \cd "$@" && return  #如果是本地终端窗口，不是SSH远程会话连接，则不做任何修改
	#echo "创建交互式选择列表..."
	print_color 40 "请选择要切换到的子目录..."
	local subDirs=$(\ls -F|grep '/$'|tr '\t' '\n')
	local toDir
	echo "$subDirs"|awk '{print NR" )："$0}'
	while :;
	do
		read -p "请输入序号选择要切换到的目录（输入 0 或 q 退出操作）：" toDir
		if [[ "${toDir,,}" == "0" || "${toDir,,}" == "q" ]];then
			print_color 40 "退出操作..."
			return
		elif [ -z "$toDir" ];then
			print_color 40 "选择为空，退出操作..."
			return
		else
			#echo "你选择了 $toDir..."
			toDir=$(echo "$subDirs"|awk 'NR=='"$toDir"'{print $0;exit}' 2>/dev/null)
			[ ! -z "$toDir" ] && break
			print_color 40 "选择无效，请重新选择...."
		fi
	done
	echo "切换到目录 $toDir ..."
	#---------------------------------------
	#_T="`realpath $toDir`" ASMyBash=true exec bash --login -i   # <--- 此行会fork一个子进程以取代当前进程~作用与cd xxx相同，但会产生额外内存开销，可用于应对其他复杂情况
	#---------------------------------------
	\cd "$toDir"
}
[ ! -z "$SSH_TTY" ] && alias cd='_hook-cd' #只有在远程终端连接的情况下才劫持cd命令