#!/usr/bin/env bash
#用途一：劫持rsync同名命令，自动转换Windows格式路径为Unix风格的路径；
#用途二：对执行失败的rsync命令自动发起重试，可使用环境变量指定重试间隔时间和最大重试次数

rsync() {
	#劫持rsync同名命令，转换参数中的Windows路径为Unix路径;
	#目的：适配在Windows Terminal拖动文件的情况
	#进程替换、tee单独重定向STDERR请参考以下资料；
	#See Also：https://stackoverflow.com/questions/692000/how-do-i-write-standard-error-to-a-file-while-using-tee-with-a-pipe
	#See Also2：https://stackoverflow.com/questions/363223/how-do-i-get-both-stdout-and-stderr-to-go-to-the-terminal-and-a-log-file
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
	local _rsyncStderr=$(mktemp --suffix=.stderr)
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
	if [ ! -z "$USESSHPASS" ];then   #指定USESSHPASS环境变量时，自动为密钥文件输入密码；
		Options=("${Options[@]}" "-e" "$USESSHPASS")
	fi
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
		#local _rsyncOutput=$(/usr/bin/rsync "$@" 2>&1|tee /dev/tty)
		/usr/bin/rsync "$@" >&1 2> >(tee $_rsyncStderr >&2)
		local retCode=$?
		let _runCount+=1
		[ -z "$RSYNCLOOP" ] && break
		#[ -z "$RSYNCLOOP" ] && __return $retCode
		echo "\$retCode：$retCode"
		[ $_rsyncCount -ne -1 ] && [ $_runCount -ge $_rsyncCount ] && break
		[ -z "$(cat $_rsyncStderr)" ] && break || {   #错误日志为空表示用户Ctrl+C中断退出;
			cat "$_rsyncStderr"|grep -i 'received SIGINT, SIGTERM, or SIGHUP' &>/dev/null && break  #<---STDERR日志中包含“received SIGINT, SIGTERM, or SIGHUP”关键字表示用户Ctrl+C中断退出；
		}
		[ $retCode -ne 0 ] && {
			[ -n "$RSYNCTIMESLEEP" ] && sleep $RSYNCTIMESLEEP || sleep $_timeSleep
		}
	done
	[ -f "$_rsyncStderr" ] && rm -vf "$_rsyncStderr" &>/dev/null
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

rsyncpass() {
	#封装rsync劫持函数，自动为rsync输入密钥密码短语；
	declare USESSHPASS hostTarget host SSHKeyPassphrase KeyPassphrase
	USESSHPASS=""
	hostTarget="${@:$#}"
	if [[ ! "$hostTarget" =~ ":" ]];then 
		hostTarget="${@:$#-1:1}" 
	fi
	host=$(echo "$hostTarget"|perl -plne 's|:.*$||g')
	SSHKeyPassphrase=`sshfind "${host}" 1|grep -iE '#KeyPassphrase ' 2>/dev/null`  #通过配置项KeyPassphrase检测密钥文件是否有密码
	if [ ! -z "$SSHKeyPassphrase" ];then
		>/dev/tty print_color "Notice：密钥文件包含密码短语，将为你自动输入..."
		KeyPassphrase="$(echo ""$SSHKeyPassphrase""|perl -plne 's/^[\s\t]//g;s/#KeyPassphrase //i;s/^\s*|\s*$//g')"
		local _pwdTmpFile=$(mktemp --suffix=.txt)
		cat >$_pwdTmpFile< <(echo "$KeyPassphrase")
		USESSHPASS="sshpass -f $_pwdTmpFile /usr/bin/ssh"
	fi
	USESSHPASS="$USESSHPASS" \
	RSYNCLOOP="$RSYNCLOOP" \
	RSYNCTIMESLEEP="$RSYNCTIMESLEEP" \
	RSYNCMAXRETRY="$RSYNCMAXRETRY" \
		rsync "$@"
	>/dev/tty print_color 40 "rsyncpass 执行完毕..."
	(
		(sleep 3s;[ -f "$_pwdTmpFile" ] && rm -vf $_pwdTmpFile) &
	)&>/dev/null   #延时删除临时文件
}

rsyncpassloop() {
	#指定临时环境变量，rsyncpass命令返回失败时自动重试（调用rsyncpass函数,rsyncpass再调用rsync命令同名劫持函数）
	RSYNCLOOP=1 RSYNCTIMESLEEP=6 rsyncpass "$@"
}
alias rsyncpassloop-1='rsyncpassloop'  #无限次重试
alias rsyncpassloop5='RSYNCMAXRETRY=5 rsyncpassloop'  #5次重试rsyncpass
alias rsyncpassloop10='RSYNCMAXRETRY=10 rsyncpassloop'  #10次重试rsyncpass
alias rsyncpassloop50='RSYNCMAXRETRY=50 rsyncpassloop'  #50次重试rsyncpass
alias rsyncpassloop100='RSYNCMAXRETRY=100 rsyncpassloop'  #100次重试rsyncpass