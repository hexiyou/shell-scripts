#!/usr/bin/env bash
phpweb() {
	#快速打开phpEnv集成开发环境下的某个网站目录
	local webRoot="$(_get_phpenv_path)\\www"
	[ ! -z "$PHPENV_WEBROOT" ] && webRoot="$PHPENV_WEBROOT" #读取环境变量，可用export PHPENV_WEBROOT=xxx 临时更改全部项目的根路径~
	if [ ! -d "$webRoot" ];then
		echo "Debug：webRoot => $webRoot"
		print_color 9 "\$webRoot 路径不存在，请使用环境变量 PHPENV_WEBROOT 指定正确的PHPENV网站项目根路径后重试！"
		print_color 40 "eg:\nexport PHPENV_WEBROOT=\"D:\\\\\\PHP_Work\\\\\\phpEnv\\\\\\www\""
		return
	fi
	local webDirs=$(pushd $webRoot &>/dev/null;ls -F|grep -E '/$')
	local opener="" #使用什么工具打开目标文件夹，默认使用cygstart调用，通常即是explorer；
	[ ! -z "$1" ] && opener="$1" #$1可打开文件夹使用的工具或命令
	
	[[ "${1,,}" == "root" ]] && cygstart $(cygpath -aw "$webRoot\\") && return # $1 为root则表示打开 PHPENV安装路径根目录
	[[ "${1,,}" == "rewrite" ]] && cygstart $(cygpath -aw "$webRoot\\..\\server\\nginx\\conf\\vhosts\\rewrite") && return # $1 为root则表示打开 PHPENV Nginx rewrite配置目录
	
	#子函数1：用VSCode打开网站目录；
	_vscode_open() {
		print_color "使用VSCode打开：$1"
		pushd "$1" &>/dev/null
		[ $? -eq 0 ] && eval vscode-cygwin . || return 1
		popd &>/dev/null
	}
	
	#子函数2：用Cygwin打开网站目录；
	_cygwin_open() {
		print_color "使用cygwin打开：$1"
		pushd "$1" &>/dev/null
		[ $? -eq 0 ] && cygwin || return 1
		popd &>/dev/null
	}
	#子函数3：用Windows Terminal打开网站目录；
	_wt_open() {
		print_color "使用Windows Terminal打开：$1"
		pushd "$1" &>/dev/null
		[ $? -eq 0 ] && _T="$1" eval wt || return 1
		popd &>/dev/null
	}
	#子函数4： etc......
	
	echo "可用网站目录："
	echo "$webDirs"|awk '{printf NR")：";print}'
	while :;
	do
		read -p "请输入序号选择要打开的网站目录，支持一次打开多个目录（多个序号用空格隔开）；"$'\n'"（输入 0 或 q 退出操作, p 输出选择清单）：" webChoose
		if [[ "$webChoose" == "0" || "${webChoose,,}" == "q" ]];then
			print_color 40 "退出操作..."
			return
		elif [[ "${webChoose,,}" == "p" ]];then #再次打印网站目录清单
			echo "$webDirs"|awk '{printf NR")：";print}'
			continue
		fi
		mapfile -t -d $' ' myWebArr<<<"$webChoose"			
		for web in ${myWebArr[@]};
		do 
			[[ "$web" == "0" ]] && { echo "exit...";return; }
			
			local webDir=$(echo "$webDirs"|awk 'NR=='"${web}"'{print $0;exit}')
			echo "打开网站目录：$webDir ..."
			if [ ! -z "$opener" ];then
				#echo "检测打开的函数或工具..."
				if [ $(type -t $opener) = "function" ];then
					$opener `cygpath -au "${webRoot}\\\\${webDir}"`   #调用子函数打开文件夹
					[ $? -ne 0 ] && print_color 9 "调用函数 $opener 返回状态异常！"
				else
					eval $opener `cygpath -au "${webRoot}\\\\${webDir}"` #调用某个alias或可执行文件打开文件夹
				fi
			else
				cygstart $(cygpath -aw "${webRoot}\\${webDir}")
			fi
		done
	done
}
alias phpweb2='phpweb _vscode_open' #用VSCode打开网站项目
alias vsphpweb='phpweb _vscode_open'
alias phpwebwt='phpweb _wt_open' #用Windows Terminal打开