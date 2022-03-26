#!/bin/bash
##=======================Begin：Windows环境变量处理=============================

setenv() {
	## 设置Windows系统环境变量（通过调用自助编写的SetEnvironment.vbs实现）
	#SetEnvironment.vbs路径：/v/scripts/SetEnvironment.vbs
	local apppath="/v/scripts/SetEnvironment.vbs"
	if [ -e "${apppath}" ];then
	if [ $# -eq 0 ] || ([ $# -eq 1 ] && [[ "$1" == "-h" || "$1" == "--help" ]]) ;then
		echo -e "User Defined Function setenv：\n\t添加Windows环境变量，具体请参看 SetEnvironment.vbs 的用法.\n"
		echo -e "\t快捷用法一：参数一传递 pwd 可添加当前路径到 Windows PATH 变量，（eg. setenv pwd）"
		echo -e "\t快捷用法二：参数一传递 get 可查询当前 Windows PATH 变量的值，（eg. setenv get）\n"
		cmd /c cscript //nologo `echo $apppath|cygpath -w -f-` $@
		return
	elif [ $# -eq 1 ] && [[ "$1" == "pwd" ]];then
		echo -e "添加当前路径到 Windows PATH 环境变量..."
		curpwd=`pwd|cygpath -w -f-`
		echo -e "$curpwd"
		#cscript //nologo `echo $apppath|cygpath -w -f-` -add "$curpwd"
		#[[ "$(isadmin)" == "yes" ]] && cscript //nologo `echo $apppath|cygpath -w -f-` -add "$curpwd"
		#判断当前是否具有管理员权限,如果有，使用静默模式，提示信息显示在mintty窗口
		if [[ "$(isadmin)" == "yes" ]];then
			cscript //nologo `echo $apppath|cygpath -w -f-` -q -add "$curpwd"
		else
			wsudo -A -H cscript //nologo `echo $apppath|cygpath -w -f-` -add "$curpwd"
		fi
		return
	elif [ $# -eq 1 ] && ([[ "$1" == "get" ]] || [[ "$1" == "getpath" ]]);then
		##查询PATH环境变量
		cscript //nologo `echo $apppath|cygpath -w -f-` -q -read "PATH"
		return
	fi
	[[ "$(isadmin)" == "yes" ]] && {
		cmd /c cscript //nologo `echo $apppath|cygpath -w -f-` -q $@
		return
	}
	wsudo -A -H cscript //nologo `echo $apppath|cygpath -w -f-` $@
	else
	echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
}

alias setwinenv=setenv
##快速查询Windows PATH变量
alias winpath='setenv get'
alias listpath="winpath|tr -s ';'|tr ';' '\n'"
alias listwinpath=listpath
alias sortpath="winpath|sed -r '/^\s*$/d'|tr ';' '\n'|sort -dr"

allwinenv() {
	#借助powershell，获取原Windows所有环境变量，不含Cygwin生成的环境变量
	local _SYSTEM_prefix=$(cygpath -au "$SYSTEMROOT") #获取Windows系统盘路径，不写死，为适配系统盘非C盘的情况
	if [ $# -eq 0 ];
	then
		#列出所有项
		#(PATH="$ORIGINAL_PATH" /bin/bash -c ${_SYSTEM_prefix}'/System32/WindowsPowerShell/v1.0/powershell.exe -Command "Get-Item -Path Env:*"')	
		(PATH="$ORIGINAL_PATH" TEMP="$LOCALAPPDATA\\Temp" TMP="$LOCALAPPDATA\\Temp" ORIGINAL_PATH="" _T="" TERM_PROGRAM="" /bin/bash --noprofile --norc --noediting -c ${_SYSTEM_prefix}'/System32/WindowsPowerShell/v1.0/powershell.exe -Command "Get-Item -Path Env:*|Format-Table -Wrap"')
	else
		#查询某一项的值
		(PATH="$ORIGINAL_PATH" TEMP="$LOCALAPPDATA\\Temp" TMP="$LOCALAPPDATA\\Temp" ORIGINAL_PATH="" _T="" TERM_PROGRAM="" /bin/bash --noprofile --norc --noediting -c ${_SYSTEM_prefix}'/System32/WindowsPowerShell/v1.0/powershell.exe -Command "\$ENV:'${1}'"')
	fi
}

##列出Cygwin当前$PATH环境变量
listunixpath() {
	local PATHstr="$PATH"
	if [ ! -z "$1" ] && ([[ "$1" == "-l" ]] || [[ "$1" == "--list" ]]);then
		echo "$PATHstr"|tr ":" "\n"
	elif [ ! -z "$1" ] && ([[ "$1" == "-s" ]] || [[ "$1" == "--sort" ]]);then
		echo "$PATHstr"|tr ":" "\n"|sort -u
	else
		echo "$PATHstr"
	fi
	return
}
alias unixpath=listunixpath

##=======================End：Windows环境变量处理=============================