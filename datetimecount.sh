datetimecount() {
	#计算某个日期偏移后的时差（目前主要供录制IPTV直播源时计算视频时长使用）
	# $1-->偏移量：符合date命令的描述参数即可,也支持传递标准时间格式：eg: +01:23:35 (标记符号（加减号）可省略，小时字段可省略)
	# $2-->要计算偏移时间基点：可省略（缺省时以当前时刻为偏移的基点）
	local moveTime="$1"
	[ ! -z "$moveTime" ] && shift
	[ -z "$*" ] && set -- "now"
	for targetTime in "$@"
	do
		local baseTime="$targetTime"
		if [[ "${moveTime}" =~ ^([-+] ?)?([0-9]{1,2}:)?[0-9]{1,2}:[0-9]{1,2}$ ]];then
			#echo "格式需要转换！"
			local moveTime=$(echo "$moveTime"|sed -r 's/^(\+|\-)/\1 /'|tr -s ' ')  #始终保证+号或-号后有一个空格；
			local convertCode=$(echo "$moveTime"|awk -F '[: ]' '{
				flag="";
				if($1=="-" || $1=="+"){
					flag=$1;
					sub($1,"");
				}
				seconds=$NF;
				if($(NF-1)) minutes=$(NF-1);
				if(NF-2>0) hours=$(NF-2);
				/** 判断&拼装 **/
				if(hours) hours=sprintf("%s%s hours ",flag,hours);
				if(minutes!="") minutes=sprintf("%s%s minutes ",flag,minutes);
				if(seconds!="") seconds=sprintf("%s%s seconds",flag,seconds);
				/* printf "%s %s %s %s\n",flag,hours,minutes,seconds; */
				printf "local moveTime=\"%s %s%s%s\"\n",flag,hours,minutes,seconds;
			}')
			eval "$convertCode"
			#echo "moveTime =>: $moveTime"
		fi
		column -t -R 1 -s "：" -o "："<<<$(
			printf "时间基点：%s\n" "$(date -d "$baseTime" +'%F %T')"
			date -d "${moveTime} ${baseTime}" +'偏移后的时间格式化：%F %T'$'\n''偏移后的时间戳：@%s'
		)
		[ $# -gt 1 ] && printf "\n"
	done
}