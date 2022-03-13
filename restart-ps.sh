#!/bin/bash
restart-ps() {
	# 借助WMIC命令（封装后的参数为wmicps），带命令行参数重启指定进程
	if [ $# -eq 0 ] || [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo "restart-ps：带命令行参数重启某进程，例如重启frpc等进程极为有用！"
		echo -e "\nUsage  ：restart-ps process-name"
		echo -e "\nExample：restart-ps frpc.exe"
		echo -e "\t restart-ps frpc"
		return
	fi
	psInfo=$(wmicps "$1") #依赖于本文件另一函数wmicps
	cmdInfo=$(echo "$psInfo"|awk '/CommandLine=/{print $0};/ExecutablePath=/{print $0}'|dos2unix -q|iconv -f GBK -t UTF-8) #注意适配命令行参数带中文的情况：iconv	
	[ -z "$cmdInfo" ] && {
		echo "没有找到相关进程..."
		return
	}
	
	if [ $(echo "$cmdInfo"|wc -l) -gt 2 ];then
		#echo "当前进程存在多个同名实例，程序无法自动判断，请手动进行重启！"
		#echo "程序退出..."
		echo "进程名存在多个同名实例，将进入多实例判断程序，请根据情况选择你需要操作哪一个进程！"
		restart-multi-ps "$1"
		return
	else
		echo "$cmdInfo"
		OLD_IFS=$IFS
		IFS=$(echo -e "\n")
		exePath=$(echo "$cmdInfo"|awk -F '=' '/ExecutablePath=/{print $2;exit}')
		commandLine=$(echo "$cmdInfo"|awk -F '=' '/CommandLine=/{sub($1"=","");print $0;exit}')
		batPrefix=""
		
		echo "$commandLine"|grep -iE '\.exe"? ' &>/dev/null
		if [ $? -eq 0 ];then
			runCommandLine="$commandLine"
		else
			echo "命令行参数需要特殊处理..."
			batPrefix="@pushd \""$(cygpath -aw `dirname "$exePath"`)"\""
			_commandLine=$(echo "$commandLine"|awk -F ' ' '{gsub($1" ","");print $0}')
			runCommandLine="\"$exePath\" ${_commandLine}"
		fi
		echo "Origin run Command is：$runCommandLine"
		winkill "$1"
		echo "重启进程ing..."	
		local runbat=$(mktemp --suffix=.bat)
		cat>$runbat<<<"${batPrefix}"$'\r\n'"@start \"\" $runCommandLine"
		cat $runbat
		chmod a+x "$runbat"
		cmd /Q /c `cygpath -aw $runbat`
		[ -f "$runbat" ] && rm -vf $runbat
		IFS=$OLD_IFS
	fi
}