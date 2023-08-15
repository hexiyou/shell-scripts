#!/bin/bash
#供Total Commander新增自定义命令或功能按钮计算选中单个或多个视频文件的时长；
#此文件功能依赖videolen.sh文件中定义的函数；

videolen-from-tmd() {
	#递归调用videolen，适配多文件的情况,eg：videolen *.mp4
	#本函数适配从Total Commander调用；
	#使用方式：在Total Commander面板选中多个视频文件后，在命令输入框执行 em_videolen 命令即可看到效果；
	#具体 Total Commander 配置的调用的入口脚本请参看：D:\Extra_bin\bash-videolen.bat
	#——————————————————————————————————————————————————————————————
	# bash-videolen.bat Bat脚本代码备份：
	#	@echo off
	#	REM chcp 65001
	#	REM echo %*
	#	REM H:\cygwin64\bin\bash.exe --login -i -c "videolen-from-tmd %*"
	#	
	#	set "tmpFileList=%~dp0tmd-video-filelist.txt"
	#	
	#	REM 清空原有的临时列表文件内容
	#	>%tmpFileList% cd.
	#	
	#	for %%a in (%*) do (
	#	  echo %%a
	#	) >>%tmpFileList%
	#	
	#	H:\cygwin64\bin\bash.exe --login -i -c "videolen-from-tmd %*"
	#	pause
	#——————————————————————————————————————————————————————————————
	#print_color 70 "videolen-from-tmd 被调用！"
	local apppath='D:\Extra_bin\tmd-video-filelist.txt'
	[ ! -s "$apppath" ] && print_color 40 "视频列表文件 “$apppath” 不存在或内容为空，程序退出..." && return
	local fileList=$(cat "$apppath"|tr -d '"'|dos2unix -q|iconv -s -f GBK -t UTF-8|cygpath -au -f-)
	echo "$fileList"|videolen-by-filelist
	#echo "$fileList"|videolenfull-by-filelist
}

videolenfull-from-tmd() {
	#递归调用videolenfull，适配多文件的情况,eg：videolenfull *.mp4
	#本函数适配从Total Commander调用；
	#同样的实现参考本文件 videolen-from-tmd 函数；
	#使用方式：在Total Commander面板选中多个视频文件后，在命令输入框执行 em_videolenfull 命令即可看到效果；
	#具体 Total Commander 配置的调用的入口脚本请参看：D:\Extra_bin\bash-videolenfull.bat	
	#——————————————————————————————————————————————————————————————
	# bash-videolen.bat Bat脚本代码备份：
	#	@echo off
	#	REM chcp 65001
	#	REM echo %*
	#	REM H:\cygwin64\bin\bash.exe --login -i -c "videolenfull-from-tmd %*"
	#	
	#	set "tmpFileList=%~dp0tmd-video-filelist.txt"
	#	
	#	REM 清空原有的临时列表文件内容
	#	>%tmpFileList% cd.
	#	
	#	for %%a in (%*) do (
	#	  echo %%a
	#	) >>%tmpFileList%
	#	
	#	H:\cygwin64\bin\bash.exe --login -i -c "videolenfull-from-tmd %*"
	#	pause
	#——————————————————————————————————————————————————————————————
	#print_color 70 "videolenfull-from-tmd 被调用！"
	local apppath='D:\Extra_bin\tmd-video-filelist.txt'
	[ ! -s "$apppath" ] && print_color 40 "视频列表文件 “$apppath” 不存在或内容为空，程序退出..." && return
	local fileList=$(cat "$apppath"|tr -d '"'|dos2unix -q|iconv -s -f GBK -t UTF-8|cygpath -au -f-)
	echo "$fileList"|videolenfull-by-filelist
}