#!/bin/bash 
#封装以下Cygwin下操作mintty外壳的一些助手函数；

mintty() {
	#使用多标签模式打开mintty窗口执行命令(mintty不带参数默认每执行一个命令打开一个新窗口)
	#在需要一次性打开多个窗口多次执行某一命令时很有用
	# eg：
	#	2 mintty.exe --tabbar=3 ssh ztn1    #打开两个mintty新窗口并连接ssh到ztn1主机，（需配合~/.bashrc中的preexec函数沟子使用）
	#	2 mintty ssh ztn1
	#——————————————————————————————————————————————————————————————————————————————————
	#若要调用原始mintty文件请使用mintty.exe
	[ -z "$*" ] && set -- "cygwin"   #缺少参数时，默认调用Cygwin Bash会话进程
	mintty.exe --tabbar=3 "$@"
}
alias mintty-clink='mintty bash --login -i -c inclink'   #在mintty外壳中打开多个clink内部终端窗口（请配合数字前缀使用：eg：3 mintty-clink）
alias mclink='mintty-clink'
alias mintty-22cn='mintty ssh 22cn'  #打开新的mintty终端窗口并连接到服务器22cn的远程终端（可一次打开多个，eg：2 mintty-22cn）
alias mssh-22cn='mintty ssh 22cn'
alias mintty-hk2='mintty ssh hk2'   #打开新的mintty终端窗口并连接到服务器hk2的远程终端（可一次打开多个，eg：2 mintty-hk2）

nohismintty() {
	#打开新的mintty会话窗口（无痕窗口，不保存命令历史记录到 .bash_history 文件）
	#mintty "export HISTFILE=/dev/null;cygwin"
	#mintty.exe --tabbar=3 /bin/bash.exe -l -t <<<"export HISTFILE=/dev/null"
	#————————————————————————————————————————————————————————————————————————————————————————————————————————————
	#(mintty.exe -i /Cygwin-Terminal.ico --tabbar=3 /cygwin-dir-nohis.bat &)&>/dev/null  #<--20240309测试通过，请在终端窗口中执行`export|grep HIST`检查操作是否生效！
	#(mintty.exe -i /Cygwin-Terminal.ico --tabbar=3 -e bash --login -i -c "export HISTFILE=/dev/null;bash" &) &>/dev/null  #<--way2，20240309测试亦通过 （但.bash_profile引入的函数没有生效）
	(mintty.exe -i /Cygwin-Terminal.ico --tabbar=3 -e bash --login -i -c "HISTFILE=/dev/null ASMyBash=true bash -l -i" &) &>/dev/null #<--way3，20240309测试通过,工作良好
}
alias nomintty='nohismintty'

mintty-new-tab() {
	#在当前Mintty窗口中打开新的标签页（默认不新开窗口!!!），有别于 `mintty` 函数；
	#打开Mintty新选项卡演示：
	# eg:
	#	newtab 自定义标题的窗口 | newtab settitle 自定义标题的窗口   #打开TAB新选项卡，并设置窗口的标题；
	#	newtab ifconfig                                           #打开Mintty新选项卡执行任意命令；
	#	newtab 'ifconfig;df -hT'                                  #打开Mintty新选项卡执行多个任意命令,多个命令采用分号隔开（参数整体必须使用单引号或双引号包裹！）；
	#	newtab 'ifconfig123 && df -hT'                            #同上（但编排要执行的多个命令，前面的执行成功才会执行下一个）；
	#	newtab ssh myserver                                       #打开新tab直接连接远程服务器；
	#——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
	_print_usage() {
		cat <<'EOF'
mintty-new-tab|newtab
	在当前Mintty窗口中打开新的标签页，并可自动设置窗口标题或执行命令（注：此功能默认情况下不新开窗口!有别于 `mintty` 函数），；
Usage：
	newtab [TABbar Window Title]
	newtab command argments...
	newtab '[command1;command2;command3...]'
	newtab '[command1 && command2 && command3...]'
	newtab '[command1 || command2 || command3...]'
	newtab --alone command argments...
	newtab <taboptions~description~file or file~description~handle
	
Example:
	#打开Mintty新选项卡演示：
	newtab 自定义标题的窗口                             #打开TAB新选项卡，并设置窗口的标题；
	newtab settitle 自定义标题的窗口                    #同上；
	newtab ifconfig                                   #打开Mintty新选项卡执行任意命令；
	newtab 'ifconfig;df -hT'                          #打开Mintty新选项卡执行多个任意命令,多个命令采用分号隔开（参数整体必须使用单引号或双引号包裹！）；
	newtab 'ifconfig123 && df -hT'                    #同上（但编排要执行的多个命令，前面的执行成功才会执行下一个）；
	newtab ssh myserver                               #打开新TAB并直接连接远程服务器；	
	newtab --alone ssh myserver                       #打开新的独立窗口（非当前窗口新建TAB）并SSH连接远程服务器；
	cat tab-options.txt|newtab                        #从窗口描述文件中读取指令，一次性打开多个标签页（窗口指令文件格式详见下文Tips注释）；
	
Tips（小技巧）：
  >>>>
newtab 自定义窗口一
newtab 自定义窗口二
newtab 自定义窗口三
  <<<
	剪贴板复制以上文本，然后  eval `clip1|d2u -q` 即可一次性打开多个自定义标题的选项卡窗口；

【或者】
  手动输入从管道传递以下命令，即可一次性打开多个自定义标题的TAB窗口：
	newtab <<EOF
	> 窗口一
	> 窗口二
	> 窗口三
	> 窗口四
	> EOF

【或者】
  手动输入从管道传递以下命令，即可一次性打开多个自定义标题的TAB窗口，并执行多个各自不相同的命令：
	newtab <<EOF
	> 窗口一 ifconfig
	> 窗口二 pwd
	> 窗口三 df -hT
	> 窗口四 ls
	> EOF
EOF
	}
	[[ "${*,,}" == "-h" || "${*,,}" == "--help" ]] && _print_usage && return
	local tabbarFlag="--tabbar=4"   #新标签选项卡（同 Mintty 快捷键 Alt+F2）
	declare -a Options 
	while [ $# -gt 0 ];
	do 
		if [[ "${1,,}" == "--alone" ]];then   #传递--alone参数则代表mintty打开新的独立窗口，而不是新TAB标签选项卡(同 Mintty 快捷键 Ctrl+Alt+F2)；
			local tabbarFlag="--tabbar=3"
		else 
			Options=("${Options[@]}" "$1")
		fi
		shift
	done
	set -- "${Options[@]}"
	if [ -t 0 ];then  #没有管道输入时：
		[ $# -eq 1 ] && [[ "$1" =~ ^[^0-9a-z_-][^0-9a-z_-].*$ || "$1" =~ ^.*[^0-9a-z_-][^0-9a-z_-]$ ]] && set -- "settitle '$1'"  #<--如果仅传递了一个参数，且参数以两个及以上的汉字作为开头或结尾，则认定参数为要设置的窗口标题（注意此处正则表达式筛选列表中的下划线不能放在最后，否则匹配不上）；
		[ -z "$*" ] && set -- ":"     #没有任何参数时，默认执行空命令（否则新窗口进程会直接退出）
		(mintty.exe -i /Cygwin-Terminal.ico $tabbarFlag -- /bin/bash --login -i -c "${*};ASMyBash=1 exec bash --login -i" &)&>/dev/null
	else    #有管道数据输入时(通常用于一次性打开多个标签)：
		while read tabOptions;
		do 
		[ -z "$tabOptions" ] && break
		set -- $tabOptions  #<---此处变量不要用双引号包裹，否则会阻止set命令拆分参数
		local titleFlag="settitle '$1'" && shift   #<---可指定多个参数选项（空格分隔），第一个参数认定为窗口标题，后续参数认定为传递给新窗口的要执行的命令；
		[ -z "$*" ] && set -- ":"     #没有任何参数时，默认执行空命令（否则新窗口进程会直接退出）
		set -- "$titleFlag;$*"
		(mintty.exe -i /Cygwin-Terminal.ico $tabbarFlag -- /bin/bash --login -i -c "${*};ASMyBash=1 exec bash --login -i" &)&>/dev/null
		done <&0
	fi
}
alias newtab='mintty-new-tab'   #eg：自动打开自定义标题的mintty标签页： `newtab 自定义标题的窗口`

newtab-ssh() {
	#打开Mintty新TAB并直接SSH连接远程服务器；
	local targetHost="$1"
	[ $(eval sshfind "^$targetHost\$"|grep -ac '') -lt 5 ] && print_color 40 "\`ssh config\` 文件没有找到服务器 $targetHost ，程序退出，请检查！" && return
	print_color 70 "打开新标签窗口连接服务器 ${targetHost} ..."
	mintty-new-tab "settitle 服务器${targetHost}; ssh ${targetHost}"
}
alias newtabssh='newtab-ssh'

