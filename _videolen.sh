#!/bin/bash
#通过ffmpeg/ffprobe查看视频文件时长，单位为秒

:<<EOF
ffprobe获取视频时长，单位：秒
ffprobe -i some_video -show_entries format=duration -v quiet -of csv="p=0"
ffprobe -i input.file -show_format | grep duration
ffprobe -i input.file -show_format -v quiet | sed -n 's/duration=//p'


ffmpeg -i file.mp4 2>&1 | grep Duration | sed 's/Duration: \(.*\), start/\1/g

ffmpeg -i file.mp4 2>&1 | grep Duration | awk '{print $2}' | tr -d ,
EOF

file="$1"

if [ ! -f "$file" ];
then
	echo "文件 \"$file\" 不存在！"
	exit 1
else
inputFile=$(cygpath -am "$file")
#echo $inputFile
fi

#下面这个方式输出浮点数，以秒为单位：eg：6678.744000
IFS=$(echo -e "\n") PATH="/v/mediadeps/ffmpeg/bin:/v/mediadeps/rtmpdump:$PATH" ffprobe -i "$inputFile" -show_entries format=duration -v quiet -of csv="p=0"
#IFS=$(echo -e "\n") PATH="/v/mediadeps/ffmpeg/bin:/v/mediadeps/rtmpdump:$PATH" ffprobe -i $inputFile -show_entries format=duration

#下面的方式，输出为人类可读的时间格式：eg：01:51:18.74
#IFS=$(echo -e "\n") PATH="/v/mediadeps/ffmpeg/bin:/v/mediadeps/rtmpdump:$PATH" ffmpeg -i "$inputFile" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,