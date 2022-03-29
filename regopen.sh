#!/bin/bash
regopen() {
	#从剪贴板打开注册表路径
	local apppath="/v/scripts/从剪贴板获取路径打开注册表项目.vbs"
	if [ $# -eq 1 ] && [[ ! -z "$1" ]];
	then
		#echo "${1//\\/\\\\}">/dev/clipboard
		#echo -n "$1"|clip
		case "${1,,}" in
			"background"|"backgroundm"|"background1") # 桌面空白区域右键菜单:位置一
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\Background\shell'|clip
			;;
			"backgroundclass"|"backgroundc"|"background2") # 桌面空白区域右键菜单：位置二
			echo -n 'HKEY_CLASSES_ROOT\Directory\Background\shell'|clip
			;;
			"folder"|"folderm"|"folder1") # 文件夹右键菜单：位置一
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\shell'|clip
			;;
			"folderclass"|"folderc"|"folder2") # 文件夹右键菜单：位置二
			echo -n 'HKEY_CLASSES_ROOT\Directory\shell'|clip
			;;			
			"run"|"machinerun"|"mrun") # 机器自启动项
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'|clip
			;;
			"run2"|"mrun2"|"wowrun") #机器自动启动项2 ：WOW6432Node
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'|clip
			;;	
			"run2once"|"mrun2once"|"wowrunonce") #机器自动启动项2 RunOnce：仅运行一次
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'|clip
			;;	
			"userrun"|"urun") # 用户自启动项
			echo -n 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'|clip
			;;	
			"userrunonce"|"urunonce") # 用户自启动项：仅运行一次~
			echo -n 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'|clip
			;;
			"mstsc") # 远程桌面会话历史
			echo -n 'HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default'|clip
			;;	
			"image"|"inject") # 映象劫持
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'|clip
			;;
			"desktop"|"wallpaper") #桌面壁纸
			echo -n 'HKEY_CURRENT_USER\CONTROL PANEL\DESKTOP'|clip
			;;
			"clink"|"uclink") #查看clink注入的对应注册表项,较常用（当前用户）：https://github.com/mridgers/clink
			#在任意clink的安装目录下可通过 `clink_x64.exe autorun show` 查看注入注册表的是哪一个版本
			echo -n 'HKEY_CURRENT_USER\Software\Microsoft\Command Processor'|clip
			;;
			"mclink") #查看clink注入的对应注册表项（本地主机）：https://github.com/mridgers/clink
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Command Processor'|clip
			;;
			"autologin") #Windows自动登录注册表项
			echo -n 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'|clip
			;;			
			*)
			echo -n "$1"|clip
			;;	
		esac
	fi
	cmd /c wscript //nologo `cygpath -w $apppath`
}