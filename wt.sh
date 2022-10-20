#!/usr/bin/env bash
#This file for Windows Terminal
#Cywgin/WSL专用：带参数一键运行Windows Terminal
windowsTerminal() {
	## Run Window Terminal UWP App From cygwin
	## Windows Terminal命令行参数参考：
	## https://docs.microsoft.com/zh-cn/windows/terminal/command-line-arguments?tabs=windows
	## 官方Github：https://github.com/microsoft/terminal
	## 配置文件说明：https://docs.microsoft.com/zh-cn/windows/terminal/install#settings-json-file
	## 自定义配色主题：https://docs.microsoft.com/zh-cn/windows/terminal/customize-settings/color-schemes
	#local apppath="C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\wt.exe"
	#local apppath="C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps\wt.exe"
	[ -z "$LOCALAPPDATA" ] && local LOCALAPPDATA="$SYSTEMDRIVE\\Users\\$USER\\AppData\\Local" #适配使用Xshell登录的情况
	local apppath="$LOCALAPPDATA\\Microsoft\\WindowsApps\\wt.exe"
	#local apppath="C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.3.2651.0_x64__8wekyb3d8bbwe\wt.exe"
	if [ -e "${apppath}" ];then
		local workDir
		#workDir="`pwd|cygpath -w -f-`" 
		workDir="`echo $_T|cygpath -w -f-`"  #支持通过环境变量指定打开的路径
		cmd /c start "" /D "$workDir" "$apppath" "$@"
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
		echo
		echo "你可以访问 Github Release 页面下载 .msixbundle 安装包："
		echo "https://github.com/microsoft/terminal/releases"
		echo "双击或在 PowerShell 中通过命令\`Add-AppxPackage ./xxxxx.msixbundle\`进行安装！"
		return 999
	fi
}
alias wt='windowsTerminal'

windowsTerminal2() {
	## Run Window Terminal UWP App From cygwin Way Two
	## windowsTerminal2：运行Window Terminal方式二：使用$*参数调用wt.exe，有别于windowsTerminal使用$@;
	## 目的，向wt.exe传递命令序列（即含;的参数）到wt.exe，执行一系列操作（参看onewt函数）！
	## 目前此函数主要供 `onewt` 调用；
	[ -z "$LOCALAPPDATA" ] && local LOCALAPPDATA="$SYSTEMDRIVE\\Users\\$USER\\AppData\\Local" #适配使用Xshell登录的情况
	local apppath="$LOCALAPPDATA\\Microsoft\\WindowsApps\\wt.exe"
	#local apppath="C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.3.2651.0_x64__8wekyb3d8bbwe\wt.exe"
	if [ -e "${apppath}" ];then
		cmd /c start "" /D "`pwd|cygpath -w -f-`" "$apppath" $*
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
		echo
		echo "你可以访问 Github Release 页面下载 .msixbundle 安装包："
		echo "https://github.com/microsoft/terminal/releases"
		echo "双击或在 PowerShell 中通过命令\`Add-AppxPackage ./xxxxx.msixbundle\`进行安装！"
		return 999
	fi
}

wtpowershell() {
    ## Run Powershell in Windows Terminal
	## 此函数存在的目的主要在于 Windows Terminal 默认配置文件不是 PowerShell 时直接一键打开 PowerShell
	local apppath="%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
	#local workDIR=$(cygpath -aw "$PWD") #如果 Window Terminal配置文件设置了“使用父进程目录”，则此项参数可不进行传递
	#指定了环境变量时使用环境变量作为工作目录，而不是使用当前目录；eg：_T='C:\' wtpowershell
	# 注：环境变量的值支持包含其他环境变量，会自动解析； _T="~" wtpowershell 等价于 _T=~ wtpowershell
	# 包含Linux或Windows环境变量示例：_T="$APPDATA" wtpowershell 或 _T="%APPDATA%" wtpowershell (注意当前逻辑下路径包含%号时无法正确处理！)
	# eg：_T="%USERPROFILE%" wtpowershell ；_T="$HOME" wtpowershell
	[ ! -z "$_T" ] && {
		[[ "$_T" =~ "%" ]] && local workDIR="$(cmd.exe /c echo "${_T//\\/\\\\}"|cygpath -aw -f-)" || \
							local workDIR="$(eval echo "${_T//\\/\\\\}"|cygpath -aw -f-)"
	} || local workDIR=$(cygpath -aw "$PWD")
	if [ -e "$(cmd /c echo ${apppath}|dos2unix -q|sed 's/\\/\\\\/g')" ];then
		_T="${workDIR}" windowsTerminal new-tab -d ${workDIR} --title Windows~PowerShell "${apppath}" "$@"
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 
alias wtpwsh=wtpowershell

wtcygwin() {
    ## Run Cygwin in Windows Terminal
	## 此函数存在的目的主要在于 Windows Terminal 默认配置文件不是 Cygwin 时直接一键打开 Cygwin
	local apppath="$(cygpath -aw /bin/bash)"
	#local workDIR=$(cygpath -aw "$PWD") #如果 Window Terminal配置文件设置了“使用父进程目录”，则此项参数可不进行传递
	#指定了环境变量时使用环境变量作为工作目录，而不是使用当前目录；eg：_T='C:\' wtcygwin
	# 注：环境变量的值支持包含其他环境变量，会自动解析； _T="~" wtcygwin 等价于 _T=~ wtcygwin
	# 包含Linux或Windows环境变量示例：_T="$APPDATA" wtcygwin 或 _T="%APPDATA%" wtcygwin (注意当前逻辑下路径包含%号时无法正确处理！)
	# eg：_T="%USERPROFILE%" wtcygwin ；_T="$HOME" wtcygwin
	[ ! -z "$_T" ] && {
		[[ "$_T" =~ "%" ]] && local workDIR="$(cmd.exe /c echo "${_T//\\/\\\\}"|cygpath -aw -f-)" || \
							local workDIR="$(eval echo "${_T//\\/\\\\}"|cygpath -aw -f-)"
	} || local workDIR=$(cygpath -aw "$PWD")
	if [ -e "$(cmd /c echo ${apppath}|dos2unix -q|sed 's/\\/\\\\/g')" ];then
		_T="${workDIR}" windowsTerminal new-tab -d "${workDIR}" --title Cygwin "${apppath}" "$@"
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 
alias wtbash='wtcygwin'

onewt() {
	## 一键启动Window Terminal多个 tab
	## See Also：https://docs.microsoft.com/zh-cn/windows/terminal/command-line-arguments?tabs=windows
	local apppath=$(cygpath -aw /bin/bash)
	local workDIR=$(cygpath -aw "$PWD") #如果 Window Terminal配置文件设置了“使用父进程目录”，则此项参数可不进行传递
	local method=""
	# 如果 $1 传递的是文件夹路径；则设置工作目录为 $1
	if [ ! -z "$1" -a -d "$1" ];then
		local workDIR=$(cygpath -aw "$1")
		shift
	elif [ $# -ge 2 ];then
		local method="${1,,}"
		local workDIR=$(cygpath -aw "$2")
	elif [ ! -z "$1" ];then
		local method="${1,,}"
	fi
	if [[ "$method" == "--pwsh" ]];then #注意：传递给Cygwin Bash的当前工作路径必须以 Shell方式 Name=XXXX 的环境变量方式前置传递，Window Terminal的-d选项不起作用
		_T="${workDIR}" windowsTerminal2 "new-tab --title 守护进程面板 --suppressApplicationTitle -d ${workDIR}  ${apppath} --login -i ; new-tab --title 交互面板1：${workDIR} --suppressApplicationTitle -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} -p Windows PowerShell; ft -t 0"
	elif [[ "$method" == "--two" ]];then #目前没啥用，暂时备用，可根据需要定义多个不同窗口面板运行配置方案，eg：三个tab，数个cmd。数个pwsh，tab1分屏等等
		_T="${workDIR}" windowsTerminal2 "new-tab --title 守护进程面板 --suppressApplicationTitle -d ${workDIR} ${apppath} --login -i ; new-tab --title 交互面板1：${workDIR} --suppressApplicationTitle -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} -p 命令提示符; ft -t 0"
	else
		_T="${workDIR}" windowsTerminal2 "new-tab --title 守护进程面板 --suppressApplicationTitle -d ${workDIR} ${apppath} --login -i ; new-tab --title 交互面板1：${workDIR} --suppressApplicationTitle -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} ${apppath} --login -i ; new-tab -d ${workDIR} -p 命令提示符; ft -t 0"
	fi
}
alias wt1='onewt --pwsh'
alias wt2='onewt --cmd'
alias wt3='onewt --way3' #示例：配置多个窗口布局运行方案