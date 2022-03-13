#/bin/bash
restore-schtasks() {
    ## 导入计划任务：从XML备份文件导入到Windows计划任务
	## restore-schtasks /path/to/xxxx.xml	;导入指定的xml任务备份文件
	OLD_IFS=$IFS
    IFS=$(echo -e "\n")
	local apppath="schtasks"
	local bakdir=~/.backup
	local profilename="Windows_${apppath}_"
	if [ ! -z "$1" ] && [[ ! "$1" =~ ^\\ ]];
	then	
		if [ -f "$1" ];
		then
			local backupFile=$(cygpath -au $1)
		else
			local backupFile=$(ls -t $bakdir/${1}*|head -n 1)
		fi
		echo "自定义导入文件：$backupFile"
		shift
	else
		local backupFile=$(ls -t $bakdir/${profilename}*|head -n 1)
	fi
	#是否定义了导入路径？
	local importPATH=""
	if [ ! -z "$1" ]
	then
		local importPATH=$1
	fi
	if [ ! -z "$backupFile" ];then
		local backup=$(cygpath -aw $backupFile)
		print_color "backup file store in $bakdir"
		print_color "restore $backupFile to Windows计划任务..."
		TasksFind=$(cat $backupFile|xmllint --noenc --xpath '//*[local-name()="Tasks"]' - 2>/dev/null|wc -l)
		if [ $TasksFind -eq 0 ];
		then
			#XML文件为单任务备份文件
			TaskName=$(cat $backupFile|iconv -s -f UTF-16 -t UTF-8|xmllint --noenc --xpath '//*[local-name()="Task"]/*[local-name()="RegistrationInfo"]/*[local-name()="URI"]/text()' -)
			[ ! -z "$importPATH" ] && TaskName=$importPATH$(basename $TaskName)
			# 获取当前电脑当前用户的User Sid替换xml，否则无法导入
			userSidInfo=$(PATH="$ORIGINAL_PATH" cmd /c whoami /user)
			userSid=$(echo "$userSidInfo"|tail -n 1|awk '{printf $2}')
			awk -i inplace '/<UserId>/{getline;print "<UserId>'"${userSid}"'</UserId>"}{print}' $(cygpath -au "$backupFile") 
			echo -e "导入单任务：$TaskName ..."
			gsudo SCHTASKS /Create /F /XML $backup /TN $TaskName
		else
			#XML文件为多个任务合一备份文件,拆分并导入~
			echo -e "XML为多任务文件，进行拆分并导入..."
			/v/bin/restore-tasks-from-xml $backupFile $importPATH
		fi
		print_color 33 "Done...."
	else
		print_color 9 "Backup file not found!\npath：${backupFile//\\/\\\\} "
	fi
	IFS=$OLD_IFS
} 