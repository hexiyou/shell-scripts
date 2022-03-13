#!/bin/bash
backup-schtasks() {
    ## 备份并导出Windows任务计划为XML文件
	# backup-schtasks all/-a  ；备份本机所有的计划任务
	# backup-schtasks 	；仅备份 子路径“\Cygwin自用\”下的计划任务
	# backup-schtasks '\自定义备份路径\'	；备份【自定义路径】下的计划任务
	# Lonelyer注：此备份貌似有问题：备份时可以一次性备份文件夹下多个任务，但导入时一次只能导入一个任务
	OLD_IFS=$IFS
    IFS=$(echo -e "\n")
	local apppath="schtasks"
	local bakdir=~/.backup
	local schbakpath='\Cygwin自用\'
	#备份命令：schtasks /Query /TN '\Cygwin自用\' /XML ONE
	if [ "$(type -t $apppath)" == "file" ];then
		[ ! -d "$bakdir" ] && mkdir $bakdir
		local backupName=$(cygpath -u `basename $apppath`)
		# local backupPath=$(cygpath -u `dirname $apppath`)		
		if [ ! -z "$1" ]; #$1可指定要备份的路径
		then
			if [[ "${1,,}" == "-a" || "${1,,}" == "all" ]];
			then
				local schbakpath='\'
				echo -e "备份本机所有任务计划..."
			else
				local schbakpath=$1
			fi
		fi	
		print_color "backup Windows计划任务 $apppath ... to $bakdir"
		# tar -zcvf $bakdir/${backupName}_$(date +"%Y%m%d-%H%M%S").tar.gz -C $backupPath $backupName
		gsudo schtasks /Query /TN $schbakpath /XML ONE >$(cygpath -aw "$bakdir/Windows_${backupName}_$(date +"%Y%m%d-%H%M%S").xml")
		print_color 33 "Done...."
	else
		print_color 9 "program not found!\npath：${apppath//\\/\\\\} "
	fi
	IFS=$OLD_IFS
} 