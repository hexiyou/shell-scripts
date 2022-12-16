#!/usr/bin/env bash
#在终端获取建行官网的最细公告列表
#HTML解析依赖一个外部Python小工具pquery（https://github.com/hupili/pquery）

ccb-notice() {
	local listPage=$(curl -sSL http://www.ccb.com/cn/home/indexv3.html 2>/dev/null|pquery a -f '{text}||{href}'|grep '最新公告'|awk  -F '|' '{print "http://www.ccb.com"$NF}' 2>/dev/null)
	if [ ! -z "$listPage" ];then
		echo -e "列表页网址：\n\t$listPage"
		echo -e "————————————————————————————————————————————————————————————————————————"
		local listContent=$(curl -ssL http://www.ccb.com/cn/v3/include/notice/zxgg_1.html 2>/dev/null|pquery 'div.section>div>ul a' -f '{title}|http://www2.ccb.com/cn/v3/include/notice/{href}')
		[ -z "$listContent" ] && print_color 9 "获取列表内容失败..." && return
		local listDate=$(curl -ssL http://www.ccb.com/cn/v3/include/notice/zxgg_1.html 2>/dev/null|pquery 'div.section>div>ul span' -p text)
		local tmpDateFile=$(mktemp)
		echo "$listDate">$tmpDateFile
		local listContent=$(echo "$listContent"|paste -d '|' $tmpDateFile -)
		echo "$listContent"|awk -F '|' '{printf "["$1"] "$2"\n\t"$NF"\n\n"}'
		[ -f "$tmpDateFile" ] && rm -f "$tmpDateFile"
	fi
}
