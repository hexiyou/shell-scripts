#!/usr/bin/env bash
#Git仓库按月统计特定周期内各个贡献者提交的代码数（统计具体代码行数，而非Commit个数）

git-lines-every-person() {
	## Git统计每个人一段时间内的工作量（提交了多少行代码）
	## See Also：https://blog.csdn.net/default7/article/details/118427616
	## See Also2：https://blog.csdn.net/weixin_39913105/article/details/110362774
	## See Also3：https://zhuanlan.zhihu.com/p/121746910
	#	指定时间 --since=2021/5/1 --until=2021/5/31
	#	指定时间 --since=30.day.ago
	#	指定时间 --since=4.weeks
	#   指定时间 --since=24.hours    #24小时内
	# 注意：当前结果 files changed 会重复统计统一文件，如果要统计不重复的文件数量，需要额外处理！
	#--------------------------------------------------------------------
	# Origin Commands test:
	#\\git log --shortstat --pretty="%cN(%cE)" --all --no-merges --since=4.weeks   | grep -v "^$"  | awk 'BEGIN { line=""; } !/^ / { if (line=="" || !match(line, $0)) {line = $0 "," line }} /^ / { print line " # " $0; line=""}'|sort|sed -E 's/# //;s/ files? changed,//;s/([0-9]+) ([0-9]+ deletion)/\1 0 insertions\(+\), \2/;s/\(\+\)$/\(\+\), 0 deletions\(-\)/;s/insertions?\(\+\), //;s/ deletions?\(-\)//'
	#--------------------------------------------------------------------
	[ -z "$*" ] && set -- "--since=4.weeks"   #默认查询最近4周（一个月的）提交数
	
	\\git log --shortstat --pretty="%cN(%cE)" --all --no-merges $@ \
	| grep -v "^$" \
	| awk 'BEGIN { line=""; } !/^ / { if (line=="" || !match(line, $0)) {line = $0 "," line }} /^ / { print line " # " $0; line=""}'  \
	| sort  \
	| sed -E 's/# //;s/ files? changed,//;s/([0-9]+) ([0-9]+ deletion)/\1 0 insertions\(+\), \2/;s/\(\+\)$/\(\+\), 0 deletions\(-\)/;s/insertions?\(\+\), //;s/ deletions?\(-\)//' \
	| awk 'BEGIN {name=""; files=0; insertions=0; deletions=0;} {if ($1 != name && name != "") { print name ": " files " files changed, " insertions " insertions(+), " deletions " deletions(-), "insertions-deletions " added lines, " insertions+deletions " net"; files=0; insertions=0; deletions=0; name=$1; } name=$1; files+=$2; insertions+=$3; deletions+=$4} END {print name ": " files " files changed, " insertions " insertions(+), " deletions " deletions(-), "insertions-deletions " added lines, " insertions+deletions " net";}' \
	| sort -k 7 -r
}
alias git-lines-2year='git-lines-every-person --since=2.years'
alias git-lines-1year='git-lines-every-person --since=1.years'
alias git-lines-72hours='git-lines-every-person --since=72.hours'
alias git-lines-48hours='git-lines-every-person --since=48.hours'
alias git-lines-24hours='git-lines-every-person --since=24.hours'
alias git-lines-12hours='git-lines-every-person --since=12.hours'
alias git-lines-2hours='git-lines-every-person --since=2.hours'
alias git-lines-1hours='git-lines-every-person --since=1.hours'
alias git-lines-30minutes='git-lines-every-person --since=30.minutes'
alias git-lines-5minutes='git-lines-every-person --since=5.minutes'
alias git-lines-2weeks='git-lines-every-person --since=2.weeks'
alias git-lines-week='git-lines-every-person --since=1.weeks'
alias git-lines-2month='git-lines-every-person --since=2.months'
alias git-lines-1month='git-lines-every-person --since=1.months'
alias git-lines-30days='git-lines-every-person --since=30.days'
alias git-lines-6days='git-lines-every-person --since=6.days'

git-lines-per-month() {
	## Git仓库按月统计每个人的代码提交行数，依赖本文件中的函数`git-lines-every-person`；
	## 默认以当前日期时间作为向后推进的基准时间，可以-d参数自定义截止时间：eg：git-lines-per-month -d "20220601"
	## 自定义某个日期获取格式化后日期格式：
	## eg：
	## date -d '-1 months' +'%F %T'  OR  date -d '-1 days' +'%F %T'   #以当前时间为基准计算偏移后的时间
	## date -d '20221201 00:00' +'%F %T'    #以当前时区为基准指定某个时间获取格式化输出
	## date -d '20221201 00:00 UTC+8' +'%F %T'   #指定时间的同时指定时区
	## date -d '20221201 23:00 UTC+8 -5 months' +'%F %T'     #指定时区+时间的同时，计算某个单位量的时间偏移
	#------------------------------------------------
	#此函数以自然月（每月1号）作为月份分界，不依赖当前日期号数（例：12月5号以12月1日作为分界）
	local options=( )
	
	__print_help() {
		echo -e "git-lines-per-month:"
		echo -e "\tGit仓库按月统计每个人的代码提交行数(按月为单位，时间向后推进)，\$1可指定统计的月份个数;"
		echo -e "\t默认以当前日期为基准，统计最近一年（即指定\$1=12）各月每个人的代码提交行数;"
		echo -e "\t注：本函数以自然月（每月1号）作为月份分界，不依赖当前日期号数（例：12月5号以12月1日作为分界）;"
		echo -e "Usage:"
		echo -e "\tgit-lines-per-month [month~count]"
		echo -e "\tgit-lines-per-month [-d custom~end~datetime] [month~count]"
		echo -e "Example:"
		echo -e "\tgit-lines-per-month                      #默认统计12个月"
		echo -e "\tgit-lines-per-month 5                    #仅统计倒数5个月"
		echo -e "\tgit-lines-per-month -d \"2022-06-01\"      #以2022-06-01作为截止时间，统计一年内每月代码数"
		echo -e "\tgit-lines-per-month -d \"2022-06-01\" 10   #以2022-06-01作为截止时间，统计倒数10个月"
		echo -e "Alias:"
		echo -e "\tgit-lines-last-year                     #统计最近一年每个月的代码行数"
		echo -e "\tgit-lines-half-year                     #统计最近半年每个月的代码行数"
	}
	
	while [ $# -gt 0 ];
	do
		if [[ "$1" == "-d" && ! "$2" == "" ]];  #使用 -d 参数可以指定终止日期，不以当前日期作为基准：eg：git-lines-per-month -d "2022-06-11"
		then
			local setEndTime="$2"
			shift
		elif [[ "$1" == "-h" || "$1" == "--help" ]]; #如果参数包含 -h 或 --help，则停止解析其他参数，直接获取帮助信息
		then   #目的：为了便于本函数的其他alias也能使用--help获取帮助；比如：git-lines-last-year --help
			local options=("--help")
			break
		else
			local options=(${options[@]} "$1")
		fi
		shift
	done
	set -- "${options[@]}"
	
	if [[ "$*" == "--help" || "$*" == "-h" ]]; # --help / -h 获取帮助信息
	then
		__print_help && return
	fi
	
	local calcCount=12  #计算的单位计数，从截止时间往后递减，（12月，11月，10月...）默认计算12次（即最近一年）
	[ ! -z "$1" ] && expr "$1" + 0 &>/dev/null && local calcCount=$1   #$1可传递参数自定义要计算的次数
	[ ! -z "$setEndTime" ] && local nextMonthFirstDay=$(date -d "${setEndTime} UTC+8 +1 months" +'%Y%m') || local nextMonthFirstDay=$(date -d '+1 months' +'%Y%m')
	local timeEndPoint=$(date -d "${nextMonthFirstDay}01" +'%FT%T')   #计算的截止时间，默认为截止下月一号（eg：今天12月5号，即统计1月1号之前代码）
	#--since=2021/5/1 --until=2021/5/31
	
	for runCount in `seq 1 $calcCount`;
	do
		#echo "运行 $runCount 次..."
		[ -z "$endTime" ] && local endTime="$timeEndPoint" || local endTime=$(date -d "$endTime UTC+8 -1 months" +'%FT%T')
		local beginTime=$(date -d "$endTime UTC+8 -1 months" +'%FT%T')
		#echo "run：git-lines-every-person --since='$beginTime' --until='$endTime'"
		echo -e "$beginTime —— $endTime"
		git-lines-every-person --since="$beginTime" --until="$endTime"
		echo -e "----------------------------------------------------------------------------------------"
	done
	return
}
alias git-lines-last-year='git-lines-per-month 12'  #按月统计最近一年每个人提交的代码行数
alias git-lines-half-year='git-lines-per-month 6'