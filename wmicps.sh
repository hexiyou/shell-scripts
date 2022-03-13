#!/bin/bash
wmicps() {
	# 通过WMIC命令查询进程信息，以便方便地获取路径、命令行等参数，比tasklist提供的信息更加丰富
	if [ $# -eq 0 ] || [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo "wmicps：通过WMIC命令查询进程信息（进程ID、可执行文件路径、命令行参数等）"
		echo -e "\nUsage  ：wmicps process-name"
		echo -e "\nExample：wmicps 360chrome.exe"
		echo -e "\t wmicps 360chrome"
		return
	fi
	OLD_IFS=$IFS
	IFS=$(echo -e "\n") #适配进程名称带空格的情况；eg：TP-LINK Surveillance.exe；执行命令时使用单引号包裹；wmicps 'TP-LINK Surveillance.exe'
	local psName="$1"
	if [[ ! "$psName" =~ \.exe$ ]];then
		local psName="$1.exe"
	fi
	#wmic process Where Name=\"${psName}\" get Name,ExecutionState,ExecutablePath,CommandLine,Status,ProcessId,UserModeTime,WindowsVersion /FORMAT:List|dos2unix -q|sed -r '/^[\s\t]*\r*\n*$/d'
	#gsudo cmd /c wmic process Where Name=\"${psName}\" get Name,ExecutionState,ExecutablePath,CommandLine,Status,ProcessId,UserModeTime,WindowsVersion /FORMAT:List|dos2unix -q|sed -r '/^[\s\t]*\r*\n*$/d' #不使用超管权限的话有的进程信息拿不到
	psInfo=$(gsudo cmd /c wmic process Where Name=\"${psName}\" get Name,ExecutionState,ExecutablePath,CommandLine,Status,ProcessId,UserModeTime,WindowsVersion /FORMAT:List|dos2unix -q|sed -r '/^[\s\t]*\r*\n*$/d')
	echo "$psInfo"
	if [ ! "${2,,}" = "--nopath" ];then
		#为每个可执行文件路径输出Cygwin窗口Ctrl+鼠标点击快速打开方式；
		#exePaths=$(echo "$psInfo"|awk -F '=' '/ExecutablePath=/{print $2}')
		mapfile -t exePaths<<<$(echo "$psInfo"|dos2unix -q|awk -F '=' '/ExecutablePath=/{print $2}') #这行使用mapfile为兼容路径包含空格的情况
		[ ! -z "${exePaths[*]}" ] && for exe in "${exePaths[@]}";
		do 	
			local exePath=`cygpath -au "${exe//\\/\\\\}"|sed -r 's/( |\(|\))/\\\1/g'` #20220226注：带空格带括号时，即便转义，鼠标点击仍然失效，疑似mintty版本更新后自身的Bug
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
alias ps2=wmicps