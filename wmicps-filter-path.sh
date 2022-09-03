wmicps-filter-path() {
	# 通过WMIC命令查询进程信息，可传递参数根据可执行文件路径过滤进程信息
	# eg:  wmicps-filter-path 'H:\Work\phpEnv\phpEnv'
	#	   wmicps-filter-path H:\\Work\\phpEnv\\phpEnv
	# 有关WMIC Like指令：
	# See Also：https://stackoverflow.com/questions/39731879/wmic-product-where-name-like-no-instances-available-if-run-in-batch-fil
	# See Also2：https://stackoverflow.com/questions/55140973/how-to-pass-variable-in-like-clause-of-wmic-process
	if [ $# -eq 0 ] || [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo -e "wmicps-filter-path：\n\t通过WMIC命令查询进程信息,并按可执行文件路径进行过滤；"
		echo -e "\t注意：参数传递路径包含反斜杠需要使用单引号包裹或者转义；"
		echo -e "\nUsage  ：wmicps-filter-path *executeable~path [--exit]"
		echo -e "\nExample：wmicps-filter-path 'H:\Work\Java'"
		echo -e "\t wmicps-filter-path H:\\\\\\Work\\\\\\Java"
		echo -e "\t wmicps-filter-path 'H:\Work\Java\java.exe'"
		echo -e "\n\t wmicps-filter-path 'H:\Work\Java\java.exe' --exit  #查询进程信息后直接退出，不进行Unix路径转换和关联Win32服务查询"
		return
	fi
	OLD_IFS=$IFS
	IFS=$(echo -e "\n") #适配进程名称带空格的情况；eg：TP-LINK Surveillance.exe；执行命令时使用单引号包裹；wmicps 'TP-LINK Surveillance.exe'
	local psPath="$1"
	shift 1
	#经测试有效的WMIC命令：
	#WMIC Process Where "ExecutablePath Like '%%H:\\Work\\phpEnv\\phpEnv%%'" get Name,ExecutionState,ExecutablePath,CommandLine,Status,ProcessId,UserModeTime,WindowsVersion /FORMAT:List
	psInfo=$(gsudo cmd /c wmic process Where "ExecutablePath Like '%%${psPath//\\/\\\\}%%'" get Name,ExecutionState,ExecutablePath,CommandLine,Status,ProcessId,UserModeTime,WindowsVersion /FORMAT:List|dos2unix -q|iconv -f GBK -t UTF-8|sed -r '/^[\s\t]*\r*\n*$/d')
	echo "$psInfo"
	if [[ "${1,,}" == "--exit" ]];then
		IFS=$OLD_IFS && return
	elif [ ! "${1,,}" = "--nopath" ];then
		#为每个可执行文件路径输出Cygwin窗口Ctrl+鼠标点击快速打开方式；
		#exePaths=$(echo "$psInfo"|awk -F '=' '/ExecutablePath=/{print $2}')
		mapfile -t exePaths<<<$(echo "$psInfo"|dos2unix -q|awk -F '=' '/ExecutablePath=/{print $2}') #这行使用mapfile为兼容路径包含空格的情况
		[ ! -z "${exePaths[*]}" ] && for exe in "${exePaths[@]}";
		do 	
			local exePath=`cygpath -au "${exe//\\/\\\\}"|sed -r 's/( |\(|\))/\\\\\1/g'` #20220226注：带空格带括号时，即便转义，鼠标点击仍然失效，疑似mintty版本更新后自身的Bug
			echo "$exePath"
			dirname "$exePath"
		done
	fi
	local pid=$(echo "$psInfo"|awk -F '=' '/ProcessId=/{print $2;exit}')
	if [ ! -z "$pid" ];then
		#查询此进程是否有关联的Win32服务
		#serviceInfo=$(gsudo cmd /c wmic service Where ProcessId=\"$pid\" Get Name,DisplayName,State,PathName,SystemName|dos2unix -q|sed -r '/^[\s\t]*\r*\n*$/d')
		serviceInfo=$(gsudo cmd /c wmic service Where ProcessId=\"$pid\" Get Name,DisplayName,State,PathName,SystemName /FORMAT:List 2>/dev/null|dos2unix -q|sed -r '/^[\s\t]*\r*\n*$/d')
		echo "$serviceInfo"|grep 'Running' &>/dev/null
		if [ $? -eq 0 ];then
			print_color 33 "\n$psName 有关联的Windows服务，具体信息如下：\n"
			echo "$serviceInfo"
			read -p "是否对服务进行操作？输入 \`stop\`停止服务，\`restart\`重启服务；直接回车退出:" opService
			if [ ! -z "$opService" ];then
				local serviceName=$(echo "$serviceInfo"|awk -F '=' '/Name=/{print $2;exit}')
				case "$opService" in
					"stop")
					gsudo cmd /c "net stop $serviceName"
					;;
					"restart")
					gsudo cmd /c 'net stop '"$serviceName"'&& net start '"$serviceName"
					;;
					*)
					echo "Nothing To Do..."
					;;
				esac
			fi
		fi
	fi
	IFS=$OLD_IFS
}