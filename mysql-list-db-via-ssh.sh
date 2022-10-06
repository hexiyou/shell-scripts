#!/usr/bin/env bash
__init-ssh-mysql() {
	#SSH for MySQL新环境的初始化操作！
	#如果专用于MySQL的ssh.exe副本不存在（实际为/v/bin/ssh-for-mysql），则拷贝之
	#使用单独的不同名的ssh进程操作服务器MySQL，避免和日常使用的ssh进程重名！
	[ -d /v/bin ] && [ ! -f /v/bin/ssh-for-mysql ] && cp /usr/bin/ssh /v/bin/ssh-for-mysql
}

mysql-list-db-via-ssh() {
	#通过SSH隧道列出远程服务器数据库：
	#查看指定的MySQL服务器端有哪些数据库：
	#------------------------
	#eg：mysql-list-db-via-ssh racknerd
	#	 mysql-list-db-via-ssh -pxxxxx racknerd  #指定mysql root密码
	#	 mysql-list-db-via-ssh -p xxxxx racknerd #空格可有可无
	#	 mysql-list-db-via-ssh  racknerd  -pxxxxx #指定mysql root密码,主机名可以不写在最后
	#------------------------
	__init-ssh-mysql
	#local targetHost="${@:$#}"
	local targetHost
	#local sshOptions="${@:1:$(($#-1))}"
	local sshOptions=()
	local mysqlOptions
	local mysqlPasswd
	local noExit=1 #操作结束是否退出ssh隧道进程，默认退出
	
	_print_usage() {
		echo -e "mysql-list-db-via-ssh：\n\t列出远程服务器MySQL数据库列表（通过SSH隧道映射远程MySQL端口到本机）；"
		echo -e "\nUsage：\n\tmysql-list-db-via-ssh [normail~ssh~options] [-p mysql~root~password] *targethost"
		echo -e "\tmysql-list-db-via-ssh *targethost [normail~ssh~options] [-p mysql~root~password]\n"
		echo -e "--------------------------------------------------------------"
		echo -e "\t-p           【可选】指定MySQL密码，通常为Root密码，其余用户未做适配，缺省密码时，会交互式询问密码；"
		echo -e "\t[ssh~options]【可选】-o、-J等ssh专用的命令行参数，会传递给ssh.exe；"
		echo -e "\t*targetHost  【必需】要连接的主机名称，在~/.ssh/config中配置，也可以使用临时主机形式 \`root@192.168.1.100\`"
		echo -e "\t--noexit     【可选】操作完成后是否终止ssh隧道进程，默认行为终止进程，指定此参数则不会终止进程；"
		echo -e "--------------------------------------------------------------"
		echo -e "\nExample：\n\tmysql-list-db-via-ssh racknerd"
		echo -e "\tmysql-list-db-via-ssh racknerd -p123456"
		echo -e "\tmysql-list-db-via-ssh -p123456 racknerd"
		echo -e "\tmysql-list-db-via-ssh -p 123456 racknerd"
		echo -e "\tmysql-list-db-via-ssh -p 123456 racknerd --noexit"
		echo -e "\tmysql-list-db-via-ssh -J ztn1 racknerd -p123456"
		echo -e "\tmysql-list-db-via-ssh -J ztn1 racknerd -p 123456"
		echo -e "\tmysql-list-db-via-ssh -J ztn1 -p 123456 racknerd"
		echo -e "\tmysql-list-db-via-ssh -J ztn1 -p 123456 racknerd --noexit"
		echo -e "\tmysql-list-db-via-ssh -o \"Proxycommand=nc -X 5 -x 127.0.0.1:8989 %h %p\" racknerd"
		echo -e "\tmysql-list-db-via-ssh -o \"Proxycommand=nc -X 5 -x 127.0.0.1:8989 %h %p\" racknerd -p123456"
	}
	
	if [[ $# == 0 || "${*,,}" == "-h" || "${*,,}" == "--help" ]];then	
		_print_usage && return
	fi
	
	#set -- "${@:1:$(($#-1))}" #去掉最后一个参数
	while [ $# -gt 0 ];
	do
		if [[ "$1" =~ ^\-p.+$ ]];then #参数-pxxx指定mysql密码
			mysqlPasswd="$1"
		elif [[ "$1" == "-p" ]];then #参数-p xxx指定mysql密码（注意-p后有个空格）
			mysqlPasswd="-p$2"
			shift
		elif [[ "$1" == "--noexit" ]];then #参数指定--noexit时不退出ssh隧道...
			noExit=0
		elif [[ "$1" =~ ^\-[a-z]$ ]];then
			sshOptions=(${sshOptions[@]} "$1" "\"$2\"")
			shift
		elif [[ ! "$1" =~ ^\-[a-z] && -z "$targetHost" ]];then  #处理主机名,目的：主机名不是非得写在参数最后！
			targetHost="$1"
		else
			sshOptions=(${sshOptions[@]} "$1")
		fi
		shift
	done
	[ ! -z "${sshOptions[*]}" ] && sshOptions="${sshOptions[@]}"
	local sshtunnelInfo=$(mysql-backup-db-via-ssh -so "$sshOptions" "$targetHost" --sshonly|tee /dev/tty)
	mysqlOptions=$(echo "$sshtunnelInfo"|grep -i 'mysql '|cut -d ' ' -f 2-)
	if [ -z "$mysqlOptions" ];then
		print_color 9 "SSH隧道创建失败，请检查主机名称及SSH授权是否有效，主机地址是否可达！"
		return
	fi
	print_color 40 "查询数据库列表："
	mysql-list-db $mysqlOptions $mysqlPasswd
	#killsshps $targetHost <<<"yes" &>/dev/null #老是不奏效，获取不到ssh进程
	if [ $noExit -eq 1 ];then #是否终止ssh隧道？
		[ $(type -t /v/bin/ssh-for-mysql) = "file" ] && killall ssh-for-mysql || killall ssh
	fi
}
alias ssh-mysql-list-db='mysql-list-db-via-ssh'
alias ssh-list-db='mysql-list-db-via-ssh'