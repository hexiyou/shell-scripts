#!/usr/bin/env bash
#last格式化时间输出
last-format() {
	#last命令格式化完整输出，转换并显示为国人适应的日期时间格式（yyyy-mm-dd HH:ii:ss）
	#注意此函数Cygwin下可能不可用（last没有-F选项），请在常规Linux系统下运行；
	# See Also：https://www.baeldung.com/linux/last-command
	# See Also2：https://www.howtogeek.com/416023/how-to-use-the-last-command-on-linux/
	# See Also3：https://serverfault.com/questions/375091/getting-login-year-data-with-the-last-command-on-linux
	last -F &>/dev/null
	local retCode=$?
	[ $retCode -ne 0 ]  && echo -e "当前系统 last 命令不支持 -F 选项，请在Linux系统终端运行以下命令："
	if [ $retCode -ne 0 ] || [[ "${1,,}" == "--show" || "${1,,}" == "--linux" ]];then #当前系统 last 命令不支持 -F 选项
		cat<<'EOF'
last -F|awk '{if(match($1,/reboot/) || match($0,/still logged/)){\
    /*print $0;*/
        next;
    }else{\
        begintime=sprintf("%s %s %s %s %s\n",$4,$5,$6,$7,$8);"date +\"%F %T\" -d\""begintime"\""|getline newbegintime;\
         endtime=sprintf("%s %s %s %s %s\n",$10,$11,$12,$13,$14);"date +\"%F %T\" -d\""endtime"\""|getline newendtime;\
         printf "%s %s %s %s %s %s %s\n",$1,$2,$3,newbegintime,$9,newendtime,$15
     }\
     }'|column -s ' ' -t
EOF
	else
		last -F|awk '{if(match($1,/reboot/) || match($0,/still logged/)){\
				/*print $0;*/
				next;
				 }else{\
					 begintime=sprintf("%s %s %s %s %s\n",$4,$5,$6,$7,$8);"date +\"%F %T\" -d\""begintime"\""|getline newbegintime;\
					 endtime=sprintf("%s %s %s %s %s\n",$10,$11,$12,$13,$14);"date +\"%F %T\" -d\""endtime"\""|getline newendtime;\
					 printf "%s %s %s %s %s %s %s\n",$1,$2,$3,newbegintime,$9,newendtime,$15
				 }\
				 }'|column -s ' ' -t
	fi
}