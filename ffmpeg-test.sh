#!/usr/bin/env bash
ffmpeg-test() {
    ## 利用ffmpeg测试流媒体链接可用性
	if [ $# -eq 1 ] && [[ "$1" =~ ^(http|https|rtmp|rtsp|rtp):// ]];then
		local playURL="$1"
	else
		print_color 40 "参数无效，\$1 请传递有效的媒体流链接（http/https/rtmp/rstp）！"
		return
	fi
	local tmpMP4="$(cygpath -aw /tmp/ffmpeg-test.mp4)"
	print_color "测试媒体流，请稍等..."
	#3秒超时
	#/v/mediadeps/ffmpeg/bin/ffmpeg.exe -rw_timeout 1000000 -i "$playURL" -t 1 -y "$tmpMP4"
	#ffmpeg -headers $'User-Agent: "AppleCoreMedia/1.0.0.7B367  (iPad; U; CPU OS 4_3_3 like Mac OS X)"\r\nAccept: */*\r\nConnection: close\r\n' -rw_timeout 3000000 -i "$playURL" -t 1 -y "$tmpMP4" &>/dev/null
	ffmpeg -rw_timeout 3000000 -i "$playURL" -t 1 -y "$tmpMP4" &>/dev/null
	local retCode=$?
	[ $retCode -eq 0 ] && print_color 33 "流媒体链接测试成功！"
	[ -f "$tmpMP4" ] && rm -f "$tmpMP4"
	return $retCode
}

ffmpeg-test2() {
    ## 利用ffmpeg测试流媒体链接可用性,特殊情况，流链接只有在接收Ctrl+C时才输出媒体信息
	if [ $# -eq 1 ] && [[ "$1" =~ ^(http|https|rtmp|rtsp|rtp):// ]];then
		local playURL="$1"
	else
		print_color 40 "参数无效，\$1 请传递有效的媒体流链接（http/https/rtmp/rstp）！"
		return
	fi
	_kill-ffmpeg() { #向ffmpeg发送Ctrl+C终止信号！
		local winPid=$(ps aux|grep "$1"|awk '{print $4}')
		mysudo SendSignalCtrlC64 "$winPid" &>/dev/null
		print_color 40 "强制终止ffmpeg进程..."
		mysudo killall ffmpeg-test &>/dev/null
	}
	_ffmpeg-test() { #用新进程名称启动探测进程,为了避免与其他常规工作的ffmpeg冲突，比如recordlive-xxx工作任务
		PATH="/v/mediadeps/ffmpeg/bin:/v/mediadeps/rtmpdump:$PATH" ffmpeg-test.exe "$@"
		return
	}
	local tmpMP4="$(cygpath -aw /tmp/ffmpeg-test.mp4)"
	print_color "测试媒体流，请稍等..."
	#3秒超时
	#/v/mediadeps/ffmpeg/bin/ffmpeg.exe -rw_timeout 1000000 -i "$playURL" -t 1 -y "$tmpMP4"
	(_ffmpeg-test -rw_timeout 3000000 -i "$playURL" -t 1 -y "$tmpMP4" &>/dev/null &)&>/dev/null
	local retCode=$?
	#local newPid=$$
	sleep 5  #延迟5秒终止进程后检查文件状态；
	#echo "newPid:$newPid"
	#local ffmpegPid=$(pstree -cpu|grep "$newPid"|grep ffmpeg|awk -F '[()]' '{print $(NF-1)}')
	local ffmpegPid=$(ps aux|grep 'ffmpeg-test'|awk '{print $1}')
	if [ ! -z "$ffmpegPid" ];then
		print_color 40 "发送 Ctrl+C 终止进程 $ffmpegPid..."
		_kill-ffmpeg "$ffmpegPid"
	fi
	ffprobe "$tmpMP4" &>/dev/null
	local retCode=$?  #以ffprobe探测结果为准
	[ $retCode -eq 0 ] && print_color 33 "流媒体链接测试成功！" || print_color 9 "流媒体链接测试失败！"
	[ -f "$tmpMP4" ] && rm -f "$tmpMP4"
	return $retCode
}