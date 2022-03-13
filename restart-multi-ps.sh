restart-multi-ps() {
	# 重启某进程，本函数匹配多个同名进程实例存在的情况
	if [ $# -eq 0 ] || [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo "restart-multi-ps：带命令行参数重启某进程，例如重启frpc等进程极为有用！"
		echo "restart-multi-ps：本函数适配存在多个同名进程的情况，提供手动输入序号选择的选项！"
		echo -e "\n参数说明："
		echo -e "  \$1 —— 必选，进程名称，eg：msedge|msedge.exe"
		echo -e "  \$2 —— 可选，指定运行窗口显示方式，显示或隐藏；有效的参数有两个：show/hide，可省略，默认为show"
		echo -e "  \$3 —— 可选，start命令运行窗口的Caption标题栏，可省略，默认为空"
		echo -e "\nUsage  ：restart-multi-ps process-name [windows state(show/hide)] [cmd Caption]"
		echo -e "\nExample：restart-multi-ps frpc.exe"
		echo -e "\t restart-multi-ps frpc"
		echo -e "\t restart-multi-ps frpc.exe Caption:Frpc内网穿透"
		echo -e "\t restart-multi-ps frpc.exe hide 第一个Frpc进程..."
		echo -e "\t restart-multi-ps frpc.exe show 第二个Frpc进程..."
		return
	fi
	local psName="$1"
	local windowState="$2"
	psInfo=$(wmicps "$psName" --nopath|dos2unix -q|iconv -f GBK -t UTF-8|grep -iE '(ProcessId=|ExecutablePath=|CommandLine=)') #注意iconv兼容命令行参数带中文的情况
	if [ -z "$psInfo" ];then
		echo "没有找到相关进程..."
		return
	fi
	
	psCount=0
	parsePsInfo() {
		if [[ "$2" =~ CommandLine\= ]];then 
			let psCount+=1
			echo -e "\n==============="
			echo -e "\033[32m${psCount}：\033[0m"
		fi
		echo "$2"
		if [[ "$2" =~ ProcessId\= ]];then 
			echo "---------------------"
		fi
	}

	mapfile -t -C "parsePsInfo" -c 1 <<<"$psInfo"
	echo "提示：按Pid终止单个进程请直接输入序号数字即可,如 12，如果需终止所有同名进程，并按所选的命令行参数重新运行进程，请输入任意字母+数字序号，比如 \`a12\`"
	read -p "共有 $psCount 个同名实例，你要操作哪一个进程，请选择：" psChoose
	psItem=$(echo "$psChoose"|sed -r 's/[^0-9]//g')
	if [ -z "$psItem" ];then
		echo "退出选择..."
		return
	fi
	#echo "$psInfo"|awk -v selectedLine="$psChoose" '/(selectedLine-1)*3,(selectedLine-1)*3+3/{print}'
	psItemInfo=$(echo "$psInfo"|awk -v startLine=$((($psItem-1)*3)) '(NR>startLine&&NR<=(startLine+3)){print}')
	expr $psChoose + 0 &>/dev/null
	if [ $? -eq 0 ];then	
		echo "终止单个进程，序号： $psChoose"
		local pid=$(echo "$psItemInfo"|awk -F '=' '/ProcessId=/{sub("ProcessId=","");print;exit}')
		echo "终止进程 pid：$pid"
		winkill $pid
	else
		echo "终止所有进程 $psName"
		winkill "$psName"
	fi
	
	OLD_IFS=$IFS
	IFS=$(echo -e "\n")
	exePath=$(echo "$psItemInfo"|awk -F '=' '/ExecutablePath=/{print $2;exit}')
	commandLine=$(echo "$psItemInfo"|awk -F '=' '/CommandLine=/{sub($1"=","");print $0;exit}')
	batPrefix=""
	##判断窗口隐藏状态，部分Console类窗口视具体情况可能需要隐藏运行，如（mysqld、httpd等），也可以在$2中使用`show`或`hide`显式指定
	if [[ "${windowState,,}" == "show" ]];then
		local runState=" "
		shift
	elif [[ "${windowState,,}" == "hide" ]];then
		local runState=" /B "
		shift
	##针对一些常用的后台进程常驻服务（MySQL、MongoDB等）。不指定窗口显示方式时，默认方式即设为隐藏窗口
	elif [ -z "${windowState}" ] && [[ "${psName,,}" =~ ^mysqld || "${psName,,}" =~ ^httpd || "${psName,,}" =~ ^frpc ]];then
		local runState=" /B "
	else
		local runState=" "
	fi
	
	echo "$commandLine"|grep -iE '\\.*\.exe"? ' &>/dev/null
	if [ $? -eq 0 ];then
		runCommandLine="$commandLine"
		batPrefix="@pushd \""$(cygpath -aw `dirname "$exePath"`)"\"" #保险起见：无论如何都pushd到可执行文件所在路径
	else
		echo "命令行参数需要特殊处理..."
		batPrefix="@pushd \""$(cygpath -aw `dirname "$exePath"`)"\""
		_commandLine=$(echo "$commandLine"|awk -F ' ' '{gsub($1" ","");print $0}')
		runCommandLine="\"$exePath\" ${_commandLine}"
	fi
	echo "Origin run Command is：$runCommandLine"
	echo "重启进程ing..."	
	local runbat=$(mktemp --suffix=.bat)
	local caption=""
	[ ! -z "$2" ] && caption="$2"
	cat>$runbat<<<"${batPrefix}"$'\r\n'"@start \"${caption}\"${runState}$runCommandLine"
	cat $runbat
	chmod a+x "$runbat"
	cmd /Q /c `cygpath -aw $runbat`
	[ -f "$runbat" ] && rm -vf $runbat
	IFS=$OLD_IFS
}