#!/usr/bin/env bash
# 一键解决Windows下OpenSSH(win10、win11自带的ssh.exe)密钥文件权限不对的问题
# Cygwin/Msys2下可以直接使用
# 因WSL（WSL2）下无需考虑ssh.exe权限问题，直接按照Linux习惯做相关操作设置即可！

win-list-file-perm() {
	# 列出Windows NTFS系统下某个文件的ACL用户权限
	local file="$1"
	[ -f "$file" ] && local winFile=$(cygpath -aw "$file") || local winFile=$(cygpath -aw "$USERPROFILE\\.ssh\\$file")
	[ ! -f "$winFile" ] && print_color 40 "指定的文件不存在！（$winFile）" && return
	local permissionInfo=$(gsudo cmd /c for /F "usebackq tokens=*" %i in \(\`icacls "$winFile" /Q\`\) do @echo %i)
	echo "$permissionInfo"
}

win-ssh-keyfile-fix() {
	#一键修复Windows（Win10、Win11）下原生ssh.exe使用ssh密钥文件权限不对的问题
	#注：经过测试，Windows下密钥权限以.ssh目录本身没有关系，只以目录下面的密钥文件本身相关（相比较Linux系统也会检查.ssh目录的权限而言）
	#See Also：https://zhuanlan.zhihu.com/p/364189095
	# Icacls微软官方文档：https://learn.microsoft.com/zh-cn/windows-server/administration/windows-commands/icacls
	# 旧版cacls官方文档：https://learn.microsoft.com/zh-cn/windows-server/administration/windows-commands/cacls
	# $1 传递要修复权限的文件名或文件路径(路径尽量不要包含空格和特殊字符，不容易处理！)
	local file="$1"
	[ -z "$file" ] && print_color 40 "缺少参数，请指定要重置权限的文件名或文件完整路径！" && return
	[ -f "$file" ] && local winFile=$(cygpath -aw "$file") || local winFile=$(cygpath -aw "$USERPROFILE\\.ssh\\$file")
	[ ! -f "$winFile" ] && print_color 40 "指定的文件不存在！（$winFile）" && return
	local permissionInfo=$(gsudo cmd /c for /F "usebackq tokens=*" %i in \(\`icacls "$winFile" /Q\`\) do @echo %i)
	local permissionUsers=$(echo "$permissionInfo"|dos2unix -q|iconv -s -f GBK -t UTF-8|awk -v filename="${winFile//\\/\\\\\\\\}" 'BEGIN{IGNORECARE=1}
	{
		if(NR==1) {
			sub(filename,"");
			sub(/^[ \t]+/,"");
		};
		if(match($0,/files$|处理 [0-9]+ 个/)){
			exit; 
		}
		print;
	}')   #<---兼容域控制器或用户名带空格的情况
	[ -z "$permissionUsers" ] && print_color 40 "没有获取到有效的权限信息！" && return

	local tmpBat=$(mktemp --suffix=.bat)    #<---此处生成bat批处理文件一次性执行，否则单条命令一个个修改用户权限进程fork过程可能会很慢！
	
	cat>$tmpBat<<<$(
	echo @echo off
	echo icacls \"$winFile\" /inheritance:d /Q    #禁用继承并复制 ACE（Lonelyer注：记得先禁用继承，否则执行后续的代码有些用户权限删不掉）
	while read -u 0 user;
	do
		echo echo \"清除用户 [ $user ] 的权限 ...\"
		echo icacls \"$winFile\" /remove:g \"$user\" /Q     #注意转义双引号，兼容文件路径或用户名包含空格的情况
		echo icacls \"$winFile\" /remove:d \"$user\" /Q     #注意转义双引号，兼容文件路径或用户名包含空格的情况
	done<<<$(echo "$permissionUsers"|awk -F ':' '{print $1;}'|sed 's/\\/\\\\/g')   #兼容域或用户名带空格的情况,awk输出之后注意给反斜杠增加转义字符
	#echo pause
	)
	#iconv -s -f UTF-8 -t GBK "$tmpBat"|unix2dos -q|tee "$tmpBat" >/dev/null
	cat "$tmpBat"|unix2dos -q|tee "$tmpBat" >/dev/null   #<--暂时不转换编码
	print_color 40 "【清除】清除所有用户的权限..."
	#wsudo -A "$(cygpath -aw $tmpBat)"
	gsudo cmd /c "$(cygpath -aw $tmpBat)"
	#adminrun "$(cygpath -aw $tmpBat)" "" ""
	print_color 33 "查阅文件权限："
	win-list-file-perm "$file"
	print_color 40 "【授予】授予当前用户只读权限..."
	local tmpBat2=$(mktemp --suffix=.bat) 
	cat>$tmpBat2<<EOF
@echo off
icacls.exe "${winFile}" /grant:r $USERNAME:(GR) /Q	
EOF
	iconv -s -f UTF-8 -t GBK "$tmpBat2"|unix2dos -q|tee "$tmpBat2" >/dev/null   #<---转换编码以及换行符适配cmd
	gsudo cmd.exe /c "$(cygpath -aw $tmpBat2)"
	print_color 33 "再次查阅文件权限："
	win-list-file-perm "$file"  #<---处理后再次查阅权限列表
	sleep 2 #<--演示一下再删除Bat文件
	[ -f "$tmpBat" ] && rm -f "$tmpBat"
	[ -f "$tmpBat2" ] && rm -f "$tmpBat2"
}
alias win-ssh-key='win-ssh-keyfile-fix'