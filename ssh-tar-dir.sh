#!/bin/bash
ssh-tar-dir() {
	#通过SSH直接备份压缩某个文件到本地（通过管道直接传递压缩数据流）
	#实际调用形似ssh 'tar xxxx'|cat >file.bin 这样的命令；
	#getopt命令说明：http://yejinxin.github.io/parse-shell-options-with-getopt-command
	#关于getopt可选参数请查阅：https://unix.stackexchange.com/questions/628942/bash-script-with-optional-input-arguments-using-getopt
	#Google Search：https://www.google.com/search?q=linux+shell+getopt+get+optional+value&newwindow=1&sxsrf=ALiCzsaiJUyuDr1fx8MZ2fiOmcbFY_ZRYQ%3A1662912830646&source=hp&ei=PgkeY6mRJcuNr7wP_da24Ao&iflsig=AJiK0e8AAAAAYx4XTsTcr3kbthFoQ9OjLmQ4CQeiRjdY&oq=linux+shell+getopt+get+optinal&gs_lcp=Cgdnd3Mtd2l6EAMYATIHCCEQoAEQCjIHCCEQoAEQCjIHCCEQoAEQCjoGCLMBEIUEOg4ILhCABBCxAxDHARDRAzoICAAQgAQQsQM6CAgAELEDEIMBOhEILhCABBCxAxCDARDHARDRAzoICC4QsQMQgwE6CAguEIAEENQCOgsIABCABBCxAxCDAToECAAQAzoICC4QgAQQsQM6BQgAEIAEOgUILhCABDoHCAAQgAQQDDoECAAQHjoGCAAQHhAIOgUIIRCgAToECAAQDToGCAAQHhANOggIABAeEAgQDToMCAAQHhAPEAgQDRAKOgoIABAeEA8QCBANOgoIABAeEA8QCBAKOggIABAeEA8QCFDwBVj8gwFgppgBaAdwAHgAgAGJBIgBh2ySAQgzLTMxLjMuMpgBAKABAbABAQ&sclient=gws-wiz
	
	#如果不传递横线参数（-xxx）,则变换形式调用本函数；以简化命令行调用；
	#eg：ssh-tar-dir kunming /www/wwwroot/example.com
	if [ $# -gt 0 ] && [[ ! "$1" =~ ^\- ]];then
		local neededOpt="--host $1 --path $2" && shift 2
		ssh-tar-dir $neededOpt $@
		return
	fi
	
	local myOptions=()
	local targetHost
	local remotePath
	local compressFlag="" #SSH传输压缩标志
	local outputFile
	local status=0  #是否显示dd命令传输状态
	local verbose=0
	_print_usage() {
		echo -e "ssh-tar-dir|ssh-backup-dir：\n\t通过ssh调用远程tar命令，压缩备份服务器某个路径文件夹到本地（通过管道传输压缩数据流）；"
		echo -e "\t底层调用命令形似： ssh 'cd /path/to/dir;tar -zxvf - xxxx'|tee /tmp/tarfile.tar.gz；"
		echo -e "\t为避免参数解析出错，请尽可能按以下帮助文本指定的参数顺序来传递参数；"
		echo -e "\nUsage：\nssh-tar-dir [options]"
		echo -e "
参数说明：
	-h, --help:           打印本帮助信息
	-h, --host:           SSH主机名称，通常为在~/.ssh/config中定义HostName，也可指定临时形式：\`root@192.168.0.1\`
	                      （\$*仅指定 -h 时代表获取帮助，指定多个选项参数时，-h 代表指定主机参数）
	-p, --path:           指定远程主机要备份的路径（绝对路径）；eg：/www/wwwroot/example.com
	-C, --compress:       是否压缩SSH数据传输（同ssh的 -C 参数）;
	-o, --output:         指定本地保存归档文件的名称，可省略，默认自动生成归档文件名（ssh-tar_%Y%m%d_%H%M.tar.gz）;
	-s, --status:         是否显示dd命令传输状态，启用此选项将为dd命令添加\`status=progress\`
	-v, --verbose:        调试模式：输出底层执行的ssh原始命令
		"
		echo -e "Example:"
		echo -e "\tssh-tar-dir -h racknerd -p /www/wwwroot/www.hello.com"
		echo -e "\tssh-tar-dir -h racknerd -p /www/wwwroot/www.hello.com -o hello.com.tar.gz"
		echo -e "\tssh-tar-dir -h racknerd -p /www/wwwroot/www.hello.com -C -o hello.com.tar.gz"
		echo -e "\tssh-tar-dir -h racknerd -p /www/wwwroot/www.hello.com -o hello.com.tar.gz -s"
		echo -e "\tssh-tar-dir -h racknerd -p /www/wwwroot/www.hello.com --compress --status"
		echo -e "\tssh-tar-dir --host racknerd --path /www/wwwroot/www.hello.com --output hello.com.tar.gz"
		echo -e "\tssh-tar-dir --host racknerd --path /www/wwwroot/www.hello.com --output hello.com.tar.gz --status"
	}
	
	if [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then	
		_print_usage && return
	fi
	#echo "原始\$@参数：$@"
	Opts=$(getopt -n "ssh-tar-dir" -q -o h:p:C::o::s::v:: -l host:,path:,compress::,output::,status::,verbose:: -- $@) #注意传递真实参数前，参数中一定要传递--隔开，否则总是出错，碰到 -- 则代表命令行选项结束；传入多余不相关的参数会被舍弃！
	#[ $? -eq 0 ] && print_color 33 "按要求传递了命令行参数" || print_color 40 "警告：命令行参数不匹配"
	eval set -- "$Opts" #重置$@是为了舍弃不相关的参数,用eval前置调用set是为了正确处理getopt输出的参数带引号的情况！
	while [ $# -gt 0 ];  #获取多余的可选参数值
	do
		if [[ "$1" == "--" ]];then
			shift
			myOptions=($@)
			break
		else
			shift
		fi
	done
	#echo "多余的可选参数：${myOptions[@]}"
	eval set -- "$Opts" 
	#echo "重置后\$@参数：$@"
	while true;
	do
		#echo "\$1 ==> $1，\$2 ==> $2"
		case $1 in  #请尽可能合理安排枚举条件的顺序！
			-h|--host)
			   targetHost="$2"
			   shift 2 ;;
			-p|--path)
			   remotePath="$2"
			   shift 2 ;;
			-C|--compress)
			   compressFlag="-C"
			   shift ;;
			-o|--output)
			   outputFile="${myOptions[0]}" && unset myOptions[0]
			   shift ;;
			-s|--status)
			   #status="${myOptions[0]}" && unset myOptions[0]
			   status=1
			   shift ;;
			-v|--verbose)
			   verbose=1
			   shift ;;
			--)
			   shift
			   break ;;
			*)
			   #echo "收到了非选项参数！"
			   shift ;;
		esac
	done
	[ -z "$outputFile" ] && outputFile="${targetHost}_ssh-tar_$(date +'%Y%m%d_%H%M').tar.gz"
	[ $status = 1 ] && status=" status=progress" || status=""
	if [ -z "$targetHost" -o -z "$remotePath" ];then
		print_color 40 "缺少参数，主机名称和远程路径不能为空！"
		_print_usage
		return
	fi
	[[ ! "$remotePath" =~ "/" ]] && remotePath="/www/wwwroot/${remotePath}"  #如果路径参数不包含路径分隔符，则默认备份 wwwroot 下的文件夹;
	#测试主机连接及目标路径是否存在？
	ssh -o ConnectTimeout=4 $targetHost "cd ${remotePath};exit \$?";sshTest=$?
	if [ $sshTest -eq 255 ];then
		print_color 9 "主机连接失败，请检查主机名或用户登录信息是否正确！"
		return
	elif [ $sshTest -ne 0 ];then
		print_color 40 "指定的远程路径不存在，请检查！"
		return
	fi
	print_color 33 "开始备份文件，请稍后..."
	[ $verbose = 1 ] && set -x
	/usr/bin/ssh ${compressFlag} $targetHost 'cd '"${remotePath}"';tar -zcvf - .'|dd of="$outputFile" $status
	sshTest=$?
	[ $verbose = 1 ] && set +x
	if [ $sshTest -ne 0 ];then
		print_color 40 "警告：备份命令返回状态码异常！ExitCode：$sshTest"
	fi
	print_color "备份文件存储位置：`pwd`"
	print_color "备份到本地的归档文件为：$outputFile "
	print_color "All things Done..."
	return $sshTest  #返回状态码：供其他函数或脚本调用时检查结果成功与否！
}
alias ssh-backup-dir='ssh-tar-dir'
alias ssh-backup-www='ssh-tar-dir'