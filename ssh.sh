#!/bin/bash
#覆盖SSH基础配置，可以做一些判断操作，例如，连接国外服务器自动使用代理，连国内服务器不使用等等
#在命令行交互界面可以 unset ssh 反定义，卸载本函数
#单次执行时临时禁用本函数可以使用双反斜杠转义，如：\\ssh open，也可以直接使用大写的SSH避开调用本函数
#使用ssh作为管道的时候，注意屏蔽此函数，否则会导致终端输出的文本附加到文件中，比如以下命令会出问题。
#ssh open 'dd if=/usr/sbin/file_bin'|ssh suse 'dd of=/root/file_bin'
ssh() {
	#匹配到可能使用管道符的情况则直接调用ssh程序，不做任何处理
	if [ $# -eq 2 ] && ([[ "$2" =~ "tar " || "$2" =~ "dd " || "$2" =~ "cat " || "$2" =~ "7za " || "$2" =~ "gzip " || "$2" =~ "xz " || "$2" =~ "zip " || "$2" =~ "rar " || "$2" =~ "curl " ]]);then
		/usr/bin/ssh "$@"
		return
	fi
	local SCRIPTPATH="/v/bin/aliaswinapp"
	print_color 33 "$SCRIPTPATH"
	print_color 33 "SSH程序被自定义功能覆盖..."
	if [ $# -eq 1 ]||([ -n "$CheckProxy" ] && [[ ! "$1" =~ ^\- ]]);then ##只有一个参数时，进行后续判断，是否通过代理连接等...
		ProxyFind=`sshfind $1 1|grep -iE '[^#](ProxyCommand|ProxyJump)' 2>/dev/null`
		if [ $? -eq 0 ];then
			print_color "Notice：当前正通过代理中继连接到服务器..."
			echo -e "$(echo $ProxyFind|sed -r 's/^[\s\t]//g')"
			if [[ "$ProxyFind" =~ " ssh " || "$ProxyFind" =~ ^.*ProxyJump\ .*$ ]];then
				#如果是跳板机格式，则直接连接不进行网络通畅性检测
				print_color "Notice：通过跳板机连接..."
				/usr/bin/ssh "$@"
				return
			fi
			##检测代理的出口IP地址
			if [[ "$ProxyFind" =~ "nc -X 5" || "$ProxyFind" =~ "connect-proxy -S" ]];then
				local proxyType="socks5://"
			else
				local proxyType="http://"
			fi
			#awk里面正则表达式不要乱加ig标识符，会要命
			local proxyServer=$(echo $ProxyFind|awk -F '' '{gsub(/^[ \t\r\n]*/,"",$0);r=match($0,/(([0-9]{1,3}\.){3}[0-9]{1,3}[:][0-9]{2,5})/,arr);print arr[1]}')
			curl -sS -m 1 --connect-timeout 1 -x ${proxyType}${proxyServer} http://xxx.xxx.xxx/ipfull/
			if [ $? -ne 0 ];then
				print_color 9 "代理检测失败，中断后续连接..."
				return
			fi
			echo -e "\n\c"
		else  #安全起见，检测是否是禁止使用真实IP直接连接的主机
			local targetHost=$(echo "$@"|awk '{gsub(/-t .*$/,"");print $NF;}')
			local findHostMark=$(eval sshfind "$targetHost"|grep -iE '^host .*\b'"$targetHost"'\b.*$|^[^#]*proxy')
			if [ $(echo "$findHostMark"|wc -l) -eq 1 ] && [[ "$findHostMark" == *"aliyun"* ]];then
				print_color 40 "$targetHost 该主机禁止使用本机IP直连，请使用跳板机或网络代理...."
				echo "程序退出..."
				return
			fi
		fi
		#检查是否需要执行端口敲门指令（ssh port knock）
		#See Also：https://goteleport.com/blog/ssh-port-knocking/
		SSHKnockFind=`sshfind $1 1|grep -iE '#?SSHKnock ' 2>/dev/null`
		if [ $? -eq 0 ];then
			print_color "Notice：需要执行端口敲门命令（SSH Port Knock）..."
			local sshKnockCommand=$(echo "$SSHKnockFind"|sed -e 's/^[\s\t]//g' -e 's/#SSHKnock //')
			$sshKnockCommand
			/usr/bin/ssh "$@"
			return
		fi
	elif [[ "$*" =~ "-J" || "${*,,}" =~ "proxycommand=" ]];then
		local proxyMethod=$(echo "$*"|awk '/\-J /{r=gensub(/^.*-J +([^ ]+).*$/,"\\1","g"); \
			print "跳板机 "r;exit;} \
			/proxycommand=/i{r=gensub(/^.* ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{2,5}).*$/,"\\1","g");\
			print "网络代理 "r;}')  
			#注意：gensub函数有的awk版本没有此功能,See Also：https://stackoverflow.com/questions/1555173/gnu-awk-accessing-captured-groups-in-replacement-text
		print_color 40 "Notice：命令行指定了中继代理 \"${proxyMethod}\" 连接目标主机..."
	fi
	##以下使用可执行程序绝对路径调用，否则会陷入无限循环调用函数本身
	/usr/bin/ssh "$@"

nossh() {
	# 让 ssh 不读取任何配置文件(例如：~/.ssh/config)，直接执行命令
	# See also:https://www.gobeta.net/linux/using-the-ssh-config-file/
	/usr/bin/ssh -F /dev/null "$@"
}