#!/usr/bin/env bash
clink() {
    ## Run clink From cygwin(在不注入的情况下打开clink环境，原生cmd窗口)
	## 注意此处使用目录软连接指向最新版本clink
	local apppath="/v/clink/clink/clink.bat"
	if [ -e "${apppath}" ];then
		if [[ "${*,,}" == "sudo" ]];then
			local winPWD=$(echo "$PWD"|cygpath -w -f-|sed -r 's/([&%!])/^\1/g')
			#cmd /c `cygpath -w /v/scripts/AdminRun.vbs` `cygpath -w "$apppath"` "" $winPWD #<---暂不支持直接切换到指定目录
			#下边这行现支持超管权限下直接切换clink到特定目录；
			cmd /c `cygpath -w /v/scripts/AdminRun.vbs` cmd.exe "/k cd /d $winPWD & `cygpath -w "$apppath"` inject" ""
		else
			#cmd /c start "" "$apppath" "$@"
			#下面两行区别在于是否传递Cygwin的$HOME环境变量，因该设置在一些程序中表现会有差别，比如cargo
			PATH="${ORIGINAL_PATH}" "$apppath" "$@"
			#PATH="${ORIGINAL_PATH}" HOME="" "$apppath" "$@"
		fi
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 

inclink() {
    ## Run clink From cygwin(在当前mintty窗口直接进入CMD clink环境)
	## 注意此处使用目录软连接指向最新版本clink
	local apppath="/v/clink/clink/clink.bat"
	if [ -e "${apppath}" ];then
		#下面两行区别在于是否传递Cygwin的$HOME等环境变量，因该设置在一些程序中表现会有差别，比如cargo
		#PATH="${ORIGINAL_PATH}" cmd /k `cygpath -aw "$apppath"` inject $@
		PATH="${ORIGINAL_PATH}" HOME="" TEMP="$LOCALAPPDATA\\Temp" TMP="$LOCALAPPDATA\\Temp" cmd /k `cygpath -aw "$apppath"` inject "$@"
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 

wtclink() {
    ## Run Clink in Windows Terminal
	## 注意此处使用目录软连接指向最新版本clink
	local apppath="/v/clink/clink/clink.bat"
	local workDIR=$(cygpath -aw "$PWD") #如果 Window Terminal配置文件设置了“使用父进程目录”，则此项参数可不进行传递
	if [ -e "${apppath}" ];then
		_T="${workDIR}" windowsTerminal new-tab --title Clink -d ${workDIR} "%SystemRoot%\System32\cmd.exe" /s /k \"$(cygpath -aw $apppath)\" inject "$@"
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 
alias wtcmd='wtclink ";;ft -t 0"' #同时打开Windows Powershell，共两个Tab，并聚焦到第一个Tab；
alias wtcmd2='wtclink ";;ft -t 1"' #同时打开Windows Powershell，共两个Tab，并聚焦到第二个Tab；

cmdi() {
	#交互式cmd窗口
	#运行Cmd with clink，自动判断 Windows Terminal 安装情况，有Windows Terminal则打开Windows Terminal，没有则打开原始CMD
	wtclink
	if [ $? -ne 0 ];then
		clink #没有Windows Terminal，自动运行CMD窗口
	fi
}