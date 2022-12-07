#!/usr/bin/env bash
#封装Git相关助手函数，一键查询某时间段内Git提交日志明细

git-plog-today() {
	#结构化打印今天的Git仓库代码提交记录
	git-plog --since="$(date -d '-1 days' +'%Y/%m/%d 23:59:59')" --until="$(date +'%Y/%m/%d')" "$@"
}
alias gtodayg='git-plog-today' #alias起名：g~today~graph

git-plog-yesterday() {
	#结构化打印昨天提交的代码提交记录；
	git-plog --since="$(date -d '-2 days' +'%Y/%m/%d 23:59:59')" --until="$(date -d '-1 days' +'%Y/%m/%d 23:59:59')" "$@"
}

git-plog-last-week() {
	#结构化打印上一周的代码提交记录（上周一至上周日）（以凌晨0点作为时间分界线）
	#`date`命令获取上周一或上周日的方法（自动计算偏移）：
	#      date -d "$(( $(date +%u)-1+7)) days ago" +'%F %T'      #上周一
	#      date -d "$(date +%u) days ago" +'%F %T'                #上周日
	git-plog --since="$(date -d "$(( $(date +%u)-1+7)) days ago" +'%Y/%m/%d 00:00:00')" --until="$(date -d "$(date +%u) days ago" +'%Y/%m/%d 23:59:59')" "$@"
}
#alias git-rplog-last-week='git-plog-last-week --reverse'  #选项 '--reverse' 和 '--graph' 不能同时使用

git-plog-this-week() {
	#结构化打印本周的代码提交记录（本周一道现在此刻）（以凌晨0点作为时间分界线）
	#    mon=$(date -d "$(( $(date +%u) - 1 )) days ago" +%Y%m%d)        #获取本周周一
	git-plog --since="$(date -d "$(( $(date +%u) - 1 )) days ago" +'%Y/%m/%d 00:00:00')" "$@"
}
#alias git-rplog-this-week='git-plog-this-week --reverse'  #选项 '--reverse' 和 '--graph' 不能同时使用

git-plog-the-day() {
	#指定具体日期，查询特定某一天的代码信息，结构化打印输出（即调用--graph选项）
	#eg：git-plog-the-day 2022-05-20
	#	 OR
	#    git-plog-the-day 20220520     #传递的日期格式只需符合`date`命令约定的格式即可，程序会自动转换
	[ ! -z "$1" ] && {
		local toDate=$(date -d "$1" +'@%s') 
		shift
		} || local toDate=$(date +'@%s')
	git-plog --since="\"$(date -d "${toDate}" +'%Y/%m/%dT00:00:00')\"" --until="\"$(date -d "${toDate}" +'%Y/%m/%dT23:59:59')\"" "$@"
}

git-log-today() {
	#打印今天提交的代码提交记录（以凌晨0点作为时间分界线，读取的时间区间：今天00:00~23:59）
	#按时间倒序排序
	\\git plog --since="$(date -d '-1 days' +'%Y/%m/%d 23:59:59')" --until="$(date +'%Y/%m/%d')" "$@"
}
alias gtoday='git-log-today'  #高频使用，取一个最短别名
alias git-rlog-today='git-log-today --reverse' #按时间先后顺序排序，最旧的提交排前边
alias gtodayr='git-log-today --reverse'

git-log-twoday() {
	#打印最近两天（昨天和今天）提交的代码提交记录（以凌晨0点作为时间分界线）
	#按时间倒序排序
	\\git plog --since="$(date -d '-2 days' +'%Y/%m/%d 23:59:59')" --until="$(date +'%Y/%m/%d')" "$@"
}
alias g2day='git-log-twoday'  #高频使用，取一个最短别名
alias git-log-2day='git-log-twoday'
alias git-rlog-2day='git-log-twoday --reverse'
alias g2dayr='git-log-twoday --reverse'

git-log-threeday() {
	#打印最近三天（前天、昨天和今天）提交的代码提交记录（以凌晨0点作为时间分界线）
	#按时间倒序排序
	\\git plog --since="$(date -d '-3 days' +'%Y/%m/%d 23:59:59')" --until="$(date +'%Y/%m/%d')" "$@"
}
alias g3day='git-log-threeday'
alias g3dayr='git-log-threeday --reverse'

git-log-yesterday() {
	#打印昨天提交的代码提交记录（以凌晨0点作为时间分界线）
	#按时间倒序排序
	\\git plog --since="$(date -d '-2 days' +'%Y/%m/%d 23:59:59')" --until="$(date -d '-1 days' +'%Y/%m/%d 23:59:59')" "$@"
}
alias gyesterday='git-log-yesterday'
alias git-rlog-yesterday='git-log-yesterday --reverse'
alias gyesterdayr='git-log-yesterday --reverse'

git-log-last-week() {
	#打印上一周的代码提交记录（上周一至上周日）（以凌晨0点作为时间分界线）
	#`date`命令获取上周一或上周日的方法（自动计算偏移）：
	#较为准确的获取方法：
	#See Also：https://stackoverflow.com/questions/6497525/print-date-for-the-monday-of-the-current-week-in-bash
	#      date -d "$(( $(date +%u)-1+7)) days ago" +'%F %T'      #上周一
	#      date -d "$(date +%u) days ago" +'%F %T'                #上周日
	#按时间倒序排序
	\\git plog --since="$(date -d "$(( $(date +%u)-1+7)) days ago" +'%Y/%m/%d 00:00:00')" --until="$(date -d "$(date +%u) days ago" +'%Y/%m/%d 23:59:59')" "$@"
}
alias glastweek='git-log-last-week'
alias glastweekr='git-log-last-week --reverse'

git-log-this-week() {
	#打印本周的代码提交记录（本周一道现在此刻）（以凌晨0点作为时间分界线）

	#See Also：https://stackoverflow.com/questions/6497525/print-date-for-the-monday-of-the-current-week-in-bash
	#    mon=$(date -d "$(( $(date +%u) - 1 )) days ago" +%Y%m%d)        #获取本周周一
	#按时间倒序排序
	\\git plog --since="$(date -d "$(( $(date +%u) - 1 )) days ago" +'%Y/%m/%d 00:00:00')" "$@"
}
alias gthisweek='git-log-this-week'
alias gthisweekr='git-log-this-week --reverse'