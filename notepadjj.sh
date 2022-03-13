#!/bin/bash
notepadjj() {
    ## Run Notepad++ From cygwin
	##传入的文件参数支持windows风格的环境变量，如%Appdata% %windir%等等;
	##传入绝对路径时包含反斜杠情况下必须使用双引号或单引号包含路径;
    ##支持直接传入文件名（指向当前目录下的文件）;
	##支持相对路径，如 ../test.txt 或者 ../../swoole-src/build.sh;
	##支持传入多个文件 如：../../swoole-src/build.sh ../../swoole-src/CMakeLists.txt；
	##支持传入通配符，如 * 代表打开当前目录的所有文件， *.md或者 *.html 打开所有指定类型的文件;
	local apppath='C:\Program Files\Notepad++\notepad++.exe'
	if [ -e "${apppath}" ];then
		if [ 1 -eq $# ] && [[ ! "$1" =~ ^.*\*.*$ ]]; then
	    #echo "单个参数且不含通配符"
		## 仅有单个参数时，路径参数支持直接输入 cygwin unix 风格的路径，此处自动转换！
		local parms=$(cygpath -w -a "$1")
		else
			local parms=$*
		fi
		#echo $parms
		#此处若加 winpty 前缀会导致重定向失败（stdout is not a tty），非Console程序不建议使用 winpty 执行
		cmd /c start "" "$apppath" ${parms}
		### 以下64位notepad++不存在则尝试查找32位的
	elif [ -e 'C:\Program Files (x86)\Notepad++\notepad++.exe' ];
	then
		local apppath='C:\Program Files (x86)\Notepad++\notepad++.exe'
		if [ 1 -eq $# ] && [[ ! "$1" =~ ^.*\*.*$ ]]; then
			local parms=$(cygpath -w -a "$1")
		else
			local parms=$*
		fi
		cmd /c start "" "$apppath" ${parms}
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
		eval download-notepadjj run
	fi
} 

alias notepad++=notepadjj