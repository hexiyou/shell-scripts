#!/usr/bin/env bash
ssh-mysql() {
	#MySQL Cli通过SSH隧道连接远程服务器
	# 即mysql-list-db-via-ssh 与 mysql 函数合二为一
	#--------------------------------------
	# eg:
	#	ssh-mysql racknerd
	#   ssh-mysql -p123456 racknerd
	#--------------------------------------
	_print_usage() {
		echo -e "ssh-mysql：\n\t创建SSH隧道映射远程MySQL服务到本地，并自动进入MySQL CLI交互环境；"
		echo -e "\nUsage：\n\tssh-mysql [normail~ssh~options] [-p mysql~root~password] *targethost"
		echo -e "\tssh-mysql [normail~ssh~options] [-pmysql~root~password] *targethost\n"
		echo -e "--------------------------------------------------------------"
		echo -e "\t-p           【可选】指定MySQL密码，通常为Root密码，其余用户未做适配，缺省密码时，会交互式询问密码；"
		echo -e "\t[ssh~options]【可选】-o、-J等ssh专用的命令行参数，会传递给ssh.exe；"
		echo -e "\t*targetHost  【必需】要连接的主机名称，在~/.ssh/config中配置，也可以使用临时主机形式 \`root@192.168.1.100\`"
		echo -e "--------------------------------------------------------------"
		echo -e "\nExample：\n\tssh-mysql racknerd"
		echo -e "\tssh-mysql -p123456 racknerd"
		echo -e "\tssh-mysql -p 123456 racknerd"
		echo -e "\tssh-mysql -J ztn1 racknerd -p123456"
		echo -e "\tssh-mysql -J ztn1 -p123456 racknerd"
		echo -e "\tssh-mysql -o \"Proxycommand=nc -X 5 -x 127.0.0.1:8989 %h %p\" racknerd"
		echo -e "\tssh-mysql -o \"Proxycommand=nc -X 5 -x 127.0.0.1:8989 %h %p\" -p123456 racknerd"
	}
	
	if [[ $# == 0 || "${*,,}" == "-h" || "${*,,}" == "--help" ]];then	
		_print_usage && return
	fi
	
	local targetHost="${@:$#}"
	local sshOptions="${@:1:$(($#-1))}"
	local mysqlOptions
	local dbListInfo=$(mysql-list-db-via-ssh $sshOptions "$targetHost" --noexit|tee /dev/tty)
	echo "$dbListInfo"|grep 'information_schema' &>/dev/null
	if [ $? -eq 0 ];then
		print_color 3 "【成功】：=> 进入 MySQL CLI 环境..."
		mysqlOptions=$(echo "$dbListInfo"|tac|grep -m 1 '/usr/bin/mysql '|sed -e 's#/usr/bin/mysql ##' -e 's#-e '\''show databases;'\''##')
		echo "mysql $mysqlOptions"
		mysql $mysqlOptions
		read -p $'\n'"已退出MySQL CLI，是否终止ssh隧道进程？[y/yes | n/no]（默认为yes）：" exitTunnelPS
		if [[ "${exitTunnelPS,,}" == "n" || "${exitTunnelPS,,}" == "no" ]];then
			echo "MySQL代理隧道后台运行中..."
			print_color 40 "Notice：你可以通过以下命令再次进入MySQL命令行环境："
			echo "mysql $mysqlOptions"
		else
			[ $(type -t /v/bin/ssh-for-mysql) = "file" ] && killall ssh-for-mysql || killall ssh
		fi
	else
		print_color 9 "列出数据库列表失败，请检查主机名和连接参数！"
		return 1
	fi
}