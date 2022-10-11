#!/usr/bin/env bash
ffmpeg-audio-channel() {
	##调用ffmpeg处理视频文件声道问题，屏蔽左声道或右声道
	## See Also：http://m.blog.chinaunix.net/uid-23145525-id-5847953.html
	## See Also2：https://blog.csdn.net/hondodo/article/details/123791761
	## See Also3：https://tieba.baidu.com/p/2599797422
	local inputFile
	local outputFile
	local muteAudioChannel #指定要屏蔽的声道，1/left 左声道；2/right 右声道
	while [ $# -gt 0 ];
	do
		if [[ "$1" == "-i" ]];then
			inputFile="$2" && shift
		elif [[ "$1" == "-o" ]];then
			outputFile="$2" && shift
		elif [[ "$1" == "--channel" || "$1" == "-c" ]];then
			muteAudioChannel="$2" && shift
		else
			if [ -z "$inputFile" ];then
				inputFile="$1"
			elif [ -z "$outputFile" ];then
				outputFile="$1"
			fi
		fi
		shift
	done
	[ ! -f "$inputFile" ] && print_color 9 "$inputFile 输入文件不存在！" && return
	[ -z "$outputFile" ] && outputFile="$(basename $inputFile)_channel_new.mp4"
	
	if [[ "${muteAudioChannel,,}" == "1" || "${muteAudioChannel,,}" == "left" ]];then #屏蔽左声道
		ffmpeg -i "$(cygpath -aw $inputFile)" -af "pan=stereo|c1=FR" "$outputFile"
	elif [[ "${muteAudioChannel,,}" == "2" || "${muteAudioChannel,,}" == "right" ]];then #屏蔽右声道
		ffmpeg -i "$(cygpath -aw $inputFile)"  -af "pan=stereo|c0=FL" "$outputFile"
	else #立体声
		print_color "Nothing to do..."
		#ffmpeg将分别只有左声道、及只有右声道的音频 写入到目标文件的左右声道:
		#ffmpeg.exe -i sofia_left.wav -i dura_right.wav -filter_complex "[0:a][1:a]amerge=inputs=2,pan=stereo|c0 -map "[a]" sofia_dura_merge.mp3
	fi
}