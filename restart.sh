#!/usr/bin/env bash
#提供交互式选择列表，快速重启浏览器或其他程序进程。

#不建议在本函数中直接kill然后start进程，建议在全局函数配置文件中分别定义独立的重启某个进程的函数；
#优点：可以针对不同软件的重启过程做额外操作（比如：预处理，清理临时文件等等...）
#如：下文代码中的 restart-sunlogin 、restart-explorer、restart-winmedia、restart-winshare 等等选项均是为了此目的而独立封装的函数；

restart() {
	#智能判断当前系统各进程运行状态，交互式提示用户选择要重启的软件或进程！
	#注：传递参数或管道数据可以转化为非交互式操作！
	#1、可通过$*传递序号来直接选择操作；
	#	eg：restart 1 6 7   或   restart restart-chrome  1 6 7  ($1为非数字参数时绕过浏览器进程检测)
	#2、可通过标准输出管道传递序号来选择操作；
	#	eg：restart <<<"1"  或   restart <<<"1 6 7"    （可传递多个序号批量执行）
	#3、【案例】：不管当前运行哪一个浏览器，自动检测并重启浏览器：
	#   eg：restart 1 或  restart <<<1
	#exec 6>&1 1>&-
	local browserAction=""
	declare -a selectAction  #定义数组存储多个要执行的动作
	
	#指定了$1参数，且$1为非数字选项时，认定$1为要执行的浏览器重启动作(此时不再动态检测浏览器运行清空，较为节省时间)
	if [ ! -z "$1" ] && ! expr "$1" + 0 &>/dev/null;then
		browserAction="$1"
		shift
	else
		local browser=$(ps2 360ChromeX.exe --nopath &>/dev/null && echo "360ChromeX.exe 360极速浏览器X版 restart-360chromex" && exit \
			||ps2 chrome.exe --nopath &>/dev/null && echo "chrome.exe 谷歌或Cent浏览器 restart-chrome" && exit \
			||ps2 360chrome.exe --nopath &>/dev/null && echo "360chrome.exe 360极速浏览器（旧版） restart-360chrome" && exit \
			||ps2 SogouExplorer.exe --nopath &>/dev/null && echo "SogouExplorer.exe 搜狗浏览器 restart-sogouexplorer" && exit \
			||echo "None 没有浏览器在运行" >/dev/null)   #<--判断当前系统哪一款浏览器在运行？
		#exec 1>&6 6>&-
		#echo "运行的浏览器：$browser"  ##<---Test Get Dynamic WebBrowser
		[ ! -z "$browser" ] && browserAction=$(echo "$browser"|awk '{print $NF;exit}')
	fi
	local actionList=$(cat <<EOF
${browserAction}
restart-sunlogin
restart-interactive-sshd
restart-cygwin-sshd
restart-explorer
restart-winmedia
restart-winshare
restart-graphics
restart-mysqld
restart-httpd
restart-phpfpm
restart-msedge
restart-excel
restart-zerotier
restart-tailscale
restart-tplink
restart-wcc
restart-winaudio
restart-proxifier
restart-shadowsocks
restart-all-frpc
restart-allone
EOF
)
	print_color 40 "交互式重启程序向导："
	echo "$actionList"|awk '{printf "%2d)：%s\n",NR,$0}'
	if [ $# -gt 0 -a -t 0 ];then #有数字序号,同时没有管道数据传入时；
		restart "$browserAction" <<<"$@"
		return
	fi
	while :;
	do
		print_color 40 "请输入序号选择要执行操作，支持多选，多个序号用空格隔开（0 或 q 退出操作）:"
		read -p "> " doSelect
		if [[ "${doSelect,,}" == "0" || "${doSelect,,}" == "q" ]];then
			print_color 40 "用户取消，退出操作..."
			break
		elif [ -z "$doSelect" ];then
			print_color 40 "选择为空，退出操作..."
			break
		else
			mapfile -t -d $' ' selectArr <<<$(echo "$doSelect")
			for selectItem in ${selectArr[@]}
			do
				local _action=$(echo "$actionList"|awk 'NR=='"${selectItem}"'{print;exit}' 2>/dev/null)
				if [ -z "$_action" ];then
					print_color 40 "选项 “${selectItem}” 无效，请重新选择！" 
					selectAction=()  #如果有选错的选项，清空已存储的动作列表，让用户重新选择
					break  
				else
					selectAction[${#selectAction[@]}]="$_action"
				fi
			done
			[ ${#selectAction[@]} -gt 0 ] && break
		fi
	done
	[ -z "${selectAction[*]}" ] && return
	for doAction in "${selectAction[@]}"
	do
		echo "执行的操作：=> $doAction ..."
		eval "$doAction"
	done
}
alias restart2='restart restart-chrome'  #认定运行的浏览器为谷歌或Cent浏览器，不再动态检测