#!/bin/bash
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
	ffmpeg -rw_timeout 3000000 -i "$playURL" -t 1 -y "$tmpMP4" &>/dev/null
	local retCode=$?
	[ $retCode -eq 0 ] && print_color 33 "流媒体链接测试成功！"
	[ -f "$tmpMP4" ] && rm -f "$tmpMP4"
	return $retCode
}