#!/usr/bin/env bash
#用途一：劫持rsync同名命令，自动转换Windows格式路径为Unix风格的路径；
#用途二：对执行失败的rsync命令自动发起重试，可使用环境变量指定重试间隔时间和最大重试次数

rsync() {
	#劫持rsync同名命令，转换参数中的Windows路径为Unix路径;
	#目的：适配在Windows Terminal拖动文件的情况
	:<<'EOF'
	#劫持rsync同名命令，转换参数中的Windows路径为Unix路径;
	#目的：适配在Windows Terminal拖动文件的情况;
——————————————————————————————————————————————————————————————————
	#增强用法：
	#	可指定环境变量 RSYNCLOOP=1 在rsync执行返回错误时反复重试；
	#	可使用环境变量 RSYNCTIMESLEEP 指定两次重试间的间隔时间（eg：RSYNCTIMESLEEP=10 单位：秒）;
	#	可使用环境变量 RSYNCMAXRETRY 指定最大重试次数（默认为-1，即无限次重试）;
EOF
	local Options=()
	local _timeSleep=5
	local _rsyncCount=-1
	while [ $# -gt 0 ];
	do
		if [[ "${1,,}" =~ ^\- ]];then
			Options=("${Options[@]}" "$1")
		elif [ -f "$1" ] && [[ "$1" =~ "\\" ]];then
			Options=("${Options[@]}" "$(cygpath -u $1)")
		else
			Options=("${Options[@]}" "$1")
		fi
		shift
	done
	set -- "${Options[@]}"
	local _runCount=0
	if [ -n "$RSYNCLOOP" ];then
		local retCode=1
		[ -n "$RSYNCMAXRETRY" ] && local _rsyncCount=$RSYNCMAXRETRY
	else
		local retCode=255
	fi
	while [ $retCode -eq 255 -o $retCode -ne 0 ];
	do
	    [ $retCode -eq 255 ] && unset -v retCode #手动销毁255状态码，避免跟下边的用户Ctrl+C中断退出码混淆
		/usr/bin/rsync "$@"
		local retCode=$?
		let _runCount+=1
		[ -z "$RSYNCLOOP" ] && break
		#[ -z "$RSYNCLOOP" ] && __return $retCode
		echo "\$retCode：$retCode"
		[ $_rsyncCount -ne -1 ] && [ $_runCount -ge $_rsyncCount ] && break
		[ $retCode -eq 255 -o $retCode -eq 20 ] && break  #<---返回码255或20表示用户键入Ctrl+C中断
		[ $retCode -ne 0 ] && {
			[ -n "$RSYNCTIMESLEEP" ] && sleep $RSYNCTIMESLEEP || sleep $_timeSleep
		}
	done
	return $retCode
}

rsyncloop() {
	#指定临时环境变量，rsync命令返回失败时自动重试（调用rsync同名劫持函数）
	RSYNCLOOP=1 RSYNCTIMESLEEP=6 rsync "$@"
}
alias rsyncloop-1='rsyncloop'  #无限次重试
alias rsyncloop10='RSYNCMAXRETRY=10 rsyncloop'  #10次重试rsync
alias rsyncloop50='RSYNCMAXRETRY=50 rsyncloop'  #50次重试rsync
alias rsyncloop100='RSYNCMAXRETRY=100 rsyncloop'  #100次重试rsync

_rsyncloop() {
	#指定会话环境变量（当前会话环境长期有效），rsync命令返回失败时自动重试（调用rsync同名劫持函数）
	export RSYNCLOOP=1 RSYNCTIMESLEEP=6
	rsync "$@"
}
