#!/usr/bin/env bash
#在Cygwin、MSYS2中以多种方式运行原始的CMD.exe
minttycmd() {
    ## 使用mintty打开独立的CMD窗口，不继承Cygwin的环境变量，在Bash窗口直接运行 mintty cmd命令则是共享Cygwin环境变量, 区别于下面的innercmd函数
	local apppath='/bin/mintty.exe'
	if [ -e "${apppath}" ];then
		#cmd /c start "" `echo ${apppath}|cygpath -w -f-` cmd
		#一定要用VBS作为启动中介，否则会继承Cygwin的环境变量(比如上面这行)，可在新窗口用 echo %PATH% 测试 
		cmd /c AdminRun.vbs `echo ${apppath}|cygpath -w -f-` cmd `pwd|cygpath -w -f-`
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 
alias alonecmd=minttycmd

innercmd() {
    ## 使用mintty打开独立的CMD窗口，此方法会（继承/共享）Cygwin的环境变量，（例如%Path%包含Cygwin下bin目录、/v/bin等），可以直接使用Cygwin下各Bash命令，如 pwd ，sed ，grep等
	local apppath='/bin/mintty.exe'
	if [ -e "${apppath}" ];then
		cmd /c start "" `echo ${apppath}|cygpath -w -f-` cmd
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 
alias newcmd=innercmd

incmd() {
    ## 在当前会话窗口进入cmd命令提示符，供Xshell工作使用
	local apppath='/bin/mintty.exe'
	PATH="${ORIGINAL_PATH}" TEMP="$LOCALAPPDATA\\Temp" TMP="$LOCALAPPDATA\\Temp" ORIGINAL_PATH="" _T="" TERM_PROGRAM="" cmd.exe
} 

mycmd() {
	## 打开独立的cmd窗口，会继承cygwin环境变量。本方法使用原始cmd窗口，不使用mintty作为终端
	if [[ "${*,,}" == "sudo" ]];then
		#mysudo cmd /c start cmd
		gsudo cmd /c start cmd
	else
		cmd /c start cmd
	fi
}
alias cmd1=mycmd
alias cmd2=mycmd
alias ocmd=mycmd #顾名思义：old cmd
alias sucmd='mycmd sudo' #管理员cmd
alias admincmd='mycmd sudo'

oldcmd() {
	# 打开原始cmd新窗口，不继承Cygwin的环境变量
	if [[ "${*,,}" == "sudo" ]];then # <-- 以管理员权限运行
		#bash -c 'exec -c gsudo cmd /c start cmd'
		#cmd /c `cygpath -w /v/scripts/AdminRun.vbs` cmd "" `echo "$PWD"|cygpath -w -f-` # <--- 使用这行管理员模式下无法顺利切换到特定目录
		#下边这行Update@20221019,管理员模式下依然切换cmd到特定目录,支持带空格带特殊符号（%、&、!等）的路径
		#eg：C:\Users\Administrator\Desktop\带空格 带特殊符号&的 目录! 测试%
		cmd /c `cygpath -w /v/scripts/AdminRun.vbs` cmd "/k cd /d `echo "$PWD"|cygpath -w -f-|sed -r 's/([&%!])/^\1/g'`" "" 
	else #<-- 普通用户权限（非管理员）运行：
		#bash -c 'exec -c cmd /c start cmd'
		#bash -c 'exec -c wscript //nologo `cygpath -w /v/scripts/NormalRun.vbs` cmd "" `echo "$PWD"|cygpath -w -f-`'
		#bash --noprofile --norc -c 'cmd /c start /I cmd'
		# 以下为经过反复尝试非管理员运行且不继承Cygwin环境变量的方法，上面的都不行。
		cmd /c `cygpath -w /v/scripts/AdminRun.vbs` `cygpath -w /v/bin/wsudo.exe` "-U cmd /c start cmd" `echo "$PWD"|cygpath -w -f-`
	fi
}
alias suoldcmd='oldcmd sudo'

origincmd() {
	# 同上，打开原始cmd新窗口，不继承Cygwin的环境变量,way2
	if [[ "${*,,}" == "sudo" ]];then
		#bash -c 'exec -c gsudo cmd /c start cmd'
		cmd /c `cygpath -w /v/scripts/AdminRun.vbs` cmd "" `echo "$PWD"|cygpath -w -f-`
	else
		#bash -c 'exec -c cmd /c start cmd'
		#bash -c 'exec -c wscript //nologo `cygpath -w /v/scripts/NormalRun.vbs` cmd "" `echo "$PWD"|cygpath -w -f-`'
		#bash --noprofile --norc -c 'cmd /c start /I cmd'
		PATH="$ORIGINAL_PATH" cmd /c start cmd
	fi
}