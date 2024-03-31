#!/bin/bash
#调用ffmpeg，转换MP4视频文件为WMV文件（当前用途：为方便使用 FastStone Capture 对WMV视频二次编辑，如添加箭头、线条、文字说明等...）
#
#转换mp4为wmv时，如何保证较高的视频质量，请参看以下文档：
#	https://stackoverflow.com/questions/11079577/how-to-get-better-quality-converting-mp4-to-wmv-with-ffmpeg
#	https://superuser.com/questions/532626/how-to-get-a-reasonable-file-size-when-converting-from-mp4-to-wmv
#

SCRIPTPATH=$(realpath $0)

display_usage() {
	echo -e "$SCRIPTPATH\n"
    echo -e "\t转换mp4视频文件为wmv文件（目的：为方便 FastStone Capture 软件对wmv视频进行二次编辑）。"
	echo -e "\tNotice1：支持截取某个时间区间片段，即指定ffmpeg的 \`-ss\` 和 \`-to\` 参数；"
	echo -e "\tNotice2：支持自定义ffmpeg使用的滤镜、编码器等命令参数，如果不指定则使用脚本内置的参数选项；"
	echo -e "\t\t（ffmpeg默认使用参数：-q:v 1 -q:a 1）"
	echo -e "Usage:"
    echo -e "\tmp42wmv [-ss start-time -to stop-time] [custom ffmpeg options] Input-MP4-File Output-WMV-File"
	echo -e "Example:"
	echo -e "\tmp42wmv input.mp4 out.wmv   <最简洁用法：注意输入文件名在先，输出文件名在后！>"
	echo -e "\tmp42wmv -ss 00:22 -to 00:50 input.mp4 out.wmv"
    echo -e "\tmp42wmv -ss 00:01:22 -to 00:02:26 input.mp4 out.wmv"
	echo -e "\tmp42wmv -b 1000k -vcodec wmv2 -acodec \
wmav2 -crf 19 -filter:v fps=fps=24 input.mp4 out.wmv"
	echo -e "\tmp42wmv -ss 00:01:22 -to 00:02:26 -b 1000k -vcodec wmv2 -acodec \
wmav2 -crf 19 -filter:v fps=fps=24 input.mp4 out.wmv"
}

# if less than two arguments supplied, display usage
if [  $# -lt 1 ]
then
    display_usage
    exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $* == "--help") ||  $* == "-h" ]]
then
    display_usage
    exit 0
fi

#检查时间参数格式是否正确
checkTimeFormatter() {
	if [[ "$1" =~ ^([0-9]{1,2}:)?[0-9]{1,2}:[0-5][0-9](\.[0-9]{3})?$ ]]
	then
		return 0
	fi
	return 1	
}

printMessage() {
	echo -e "\033[42;33m${1}\033[0m"
	[ "$2" = 1 ] && {
		display_usage
		exit 1
	}
}

mapfile -t options <<<""
mapfile -t timePrefix <<<""

#Ffmpeg缺省情况下默认使用的命令行参数，资料来源：https://stackoverflow.com/questions/11079577/how-to-get-better-quality-converting-mp4-to-wmv-with-ffmpeg
optionsPrepare="-q:v 1 -q:a 1"
#See Also：https://superuser.com/questions/532626/how-to-get-a-reasonable-file-size-when-converting-from-mp4-to-wmv
#optionsPrepare="-b 1000k -vcodec wmv2 -acodec wmav2 -crf 19 -filter:v fps=fps=24" 

inputFile=""
outputFile=""

while (($#))
do
	case "$1" in
		"-ss"|"-to")
			checkTimeFormatter "$2"
			if [ $? -eq 0 ]
			then
				timePrefix+=("$1")
				timePrefix+=("$2")
				shift 2
			else
				if [ "$1" = "-ss" ]
				then
					timeDesc="起始时间"
				else
					timeDesc="终止时间"
				fi				
				printMessage "${1}：${timeDesc}格式错误！" 1
			fi
		;;
		*)
			if [ $# -eq 2 ]
			then
				[ ! -f "$1" ] && printMessage "要转换的源文件 “${1}” 不存在！" 1
				inputFile="$1"
			elif [ $# -eq 1 ]
			then
				outputFile="$1"
			else
				options+=("$1")
			fi
			shift
		;;
	esac
done

[ ${#options[@]} -lt 2 ] && options=("$optionsPrepare")

#执行格式转换操作
PATH="/v/mediadeps/ffmpeg/bin:/v/mediadeps/rtmpdump:$PATH"
echo ffmpeg ${timePrefix[@]} -i "$inputFile" ${options[@]} "$outputFile"
ffmpeg ${timePrefix[@]} -i "$inputFile" ${options[@]} "$outputFile"