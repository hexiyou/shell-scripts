#!/usr/bin/env bash
#对MySQL命令行交互美化工具mycli的封装
#See Also：
#    https://www.mycli.net/
#    https://github.com/dbcli/mycli

_mycli() {
	#调用Windows下Python包：MySQL CLI客户端自动补全和高亮工具~
	#See Also：https://pypi.org/project/mycli/
	#Github：https://github.com/dbcli/mycli
	#-----------------------------------------
	if [ ! $(type -t mycli.exe) = "file" ];then
		print_color 9 "错误！程序退出后续操作...."
		print_color 40 "没有发现 mycli.exe，请先在Windows Python环境下安装 mycli 工具！(eg：\`pip install mycli\`)"
		print_color 40 "并将“X:\Pythonxxx\Scripts”路径加入环境变量，确保 %PATH% 环境变量下有 mycli.exe!"
		return
	fi
	#PATH="$ORIGINAL_PATH" mycli.exe "$@"   #注意：此处需使用Cygwin PATH环境，不能使用Windows纯净PATH环境，Windows 没有`less`命令
	mycli.exe "$@"
}

mycli() {
	# mycli同名Hook命令，在Laravel项目根目录时，自动读取.env配置文件中MySQL账密配置信息连接数据库；
	# 在非Laravel环境下则尝试使用默认用户名和密码连接本地MySQL主机；
	#-----------------
	#判断mysql命令行中是否传递了dbName
	local options=( )
	local dbName
	while [ $# -gt 0 ];
	do
		if [[ ! "$1" =~ ^\- ]] && [ -z "$dbName" ];then
			dbName="$1"
		else
			options=(${options[@]} "$1")
		fi
		shift
	done
	set -- "${options[@]}"
	if [ $# -ne 0 ];then
		OLD_IFS=$IFS
		IFS=$(echo -e "\n") #兼容参数值带空格的情况：eg：mysql -h127.0.0.1 -uroot -proot -e 'show databases;'
		_mycli $@ "$dbName"
		local ret=$?
		IFS=$OLD_IFS
		return $ret
	elif [ -f ./composer.json -a -f ./.env ];then #判断是否在Laravel项目的根目录路径下
		local dbHost=$(cat .env|awk -F '=' '/DB_HOST/{gsub(" ","");print $2;exit}')
		local dbPort=$(cat .env|awk -F '=' '/DB_PORT/{gsub(" ","");print $2;exit}')
		local dbName=$(cat .env|awk -F '=' '/DB_DATABASE/{gsub(" ","");print $2;exit}')
		local dbUser=$(cat .env|awk -F '=' '/DB_USERNAME/{gsub(" ","");print $2;exit}')
		local dbPasswd=$(cat .env|awk -F '=' '/DB_PASSWORD/{gsub(" ","");print $2;exit}')
		print_color 40 "mycli -h${dbHost} -P${dbPort} -u${dbUser} -p${dbPasswd} -D ${dbName}"
		_mycli -h${dbHost} -P${dbPort} -u${dbUser} -p${dbPasswd} -D "${dbName}"
		return
	else
		_mycli -h127.0.0.1 -uroot -proot "$dbName"
	fi
}
alias mycli-dsm918='mycli -h10.10.10.100 -P3307 -uxxxuser -pxxxxxxx'

mycli-by-ssh() {
	#通过mycli自带的SSH隧道功能连接到远程服务器MySQL数据库；
	#请注意：在Cygwin和CMD下运行此函数，mycli.exe默认读取%UserProfile%\.ssh下的密钥，请注意密钥文件是否存在（取决于$HOME环境变量的不同）
	#经测试，此功能直连服务器，并不会调用.ssh/config的ProxyJump等网络代理功能，需要代理功能请使用`ssh-mysql`函数
	[ $# -gt 0 ] && [[ ! "${@:$#}" =~ ^- ]] && local targetHost="${@:$#}"
	local options=( "$@" )
	[ ! -z "${options[*]}" -a ! -z "$targetHost" ] && unset "options[${#options[@]}-1]" && set -- "${options[@]}"  #去掉$@最后一个参数
	[ -z "$targetHost" -a -z "$*" ] && print_color 40 "请指定远程主机名..." && return
	#_mycli "$@" --ssh-config-path "$(cygpath -aw ~/.ssh/config.gbk)" --ssh-config-host $targetHost   # <---- 默认使用当前终端的$USER（通常是Administrator）链接MySQL
	[ ! -z "$targetHost" ] && local HostOption="--ssh-config-host $targetHost" || local HostOption=""
	USER=root _mycli "$@" --ssh-config-path "$(cygpath -aw ~/.ssh/config.gbk)" $HostOption  #使用root作为连接默认用户名
}