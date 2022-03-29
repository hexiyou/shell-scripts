#!/bin/bash
#打包绿色版（便携版）软件
zipappdir() {
	if [ $# -eq 1 ] && [ ! -z "$1" ];then
		programName=$1
		programBody=$(declare -f $1)
		#local apppath=$(echo "$programBody"|grep -E '^[^#]*local apppath='|cut -d '=' -f2|tr -d ';"'\''')
		# Update@20210315：以下优化处理：当有两个以上结果时，只取最后一个
		local apppath=$(echo "$programBody"|tac|grep -m 1 -E '^[^#]*local apppath='|cut -d '=' -f2|tr -d ';"'\''')
		#local apppath=$(echo "$apppath"|cygpath -u -f-)
		if [ -z "$apppath" ];then
			# 如果传入的是alias名称，则递归查找相对应的可能存在$apppath定义的函数
			local aliasName=$(alias $programName 2>/dev/null|awk -F '=' '{print $NF}'|tr -d "'\"")
			if [ ! -z "$aliasName" ];
			then
				eval zipappdir $aliasName
				return
			else
				echo "Not found appPath in $programName"
				return
			fi
		else
			if [[ ! "$apppath" =~ "\\\\" && "$apppath" =~ "\\" ]];
			then
				#local apppath=$(echo -n "$apppath"|sed -r 's/(\ |\\)/\\\1/g')
				local apppath=$(echo -n "$apppath"|sed -r 's/(\\)/\\\1/g')
			fi
		fi
		#local apppath0=$(echo "$apppath"|sed -r 's/\$(APPDATA)/$\{\!\1\}/g')
		##以下这行目的在于展开$apppath中的环境变量，如 %APPDATA%，%LOCALAPPDATA%等
		[ $(echo "$apppath"|grep '\$') ] && local apppath=$(eval echo -e "$apppath")
		echo "$apppath"

		OLD_IFS=$IFS
		IFS=$(echo -e "\n")
		local exportDir="/tmp/zipappdir"
		[ ! -d "$exportDir" ] && mkdir -p $exportDir
		#判断传入的是文件名路径还是文件夹路径
		if [[ $apppath =~ \.[0-9a-z]{2,4}$ ]];then
			local appdir=$(dirname "$apppath"|cygpath -au -f-)	
		else
			local appdir=$(echo "$apppath"|cygpath -au -f-)
		fi
		#echo "appdir：$appdir"
		local parentDir=$(dirname "$appdir")
		local targetDir=$(basename "$appdir")
		#echo "parentDir：$parentDir"
		#echo "targetDir：$targetDir"
		[ ! -z "$parentDir" -a ! -z "$targetDir" ] && {
			echo "打包文件中 ${appdir} ..."
			tar -zcf $exportDir/${targetDir}_$(date +"%Y%m%d").tar.gz -C $parentDir $targetDir
			echo "打包 Done..."
		}
		IFS=$OLD_IFS
		read -p "是否打开输出文件夹？(y/n,默认n)" opendir
		if [ -z "${opendir}" ];then
			opendir="n"
		fi
		[[ "$opendir" == "y" ]] && eval o $exportDir
	else
		cat <<EOF
	打包/分发便携版软件
    Usage:
        zipappdir [fucntion origin name]
    Example:
        zipappdir iris
EOF
	fi
}