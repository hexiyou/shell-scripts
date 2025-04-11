#!/bin/bash
#favorite-dirs plus+增强版，支持进入bash子shell对每个目录进行操作
#子shell允许调用全局登录函数和alias别名，Ctrl+D退回选择菜单进行下一步操作；
favorite-dirs() {
	#使用资源管理器快速打开Windows系统常用文件夹
	# See Also：Windows SpecialFolders Property：
	# https://docs.microsoft.com/en-us/previous-versions//0ea7b5xe(v=vs.85)?redirectedfrom=MSDN
	# See Also 2 Shell.NameSpace:
	# https://docs.microsoft.com/zh-cn/windows/win32/shell/shell-namespace?redirectedfrom=MSDN
	# See Also 3：Getting special Folder path for a given user in Jscript
	# https://stackoverflow.com/questions/5571747/getting-special-folder-path-for-a-given-user-in-jscript
	local mydirs=$(cat<<EOF
	Shell:downloads
	Shell:documents
	Shell:Sendto
	Shell:Recent
	Shell:Desktop
	Shell:Favorites
	Shell:Quick Launch
	Shell:AppsFolder
	Shell:AppData
	%LocalAppdata%
	Shell:startup
	Shell:common startup
	Shell:programfiles
	Shell:programfilesx86
	Shell:AllUsersDesktop
	Shell:AllUsersStartMenu
	Shell:AllUsersPrograms
	Shell:AllUsersStartup
	Shell:Fonts
	Shell:MyDocuments
	Shell:NetHood
	Shell:PrintHood
	Shell:Programs
	Shell:StartMenu
	Shell:Startup
	Shell:Templates
	%UserProfile%
	%UserProfile%\.ssh
	%ALLUSERSPROFILE%
	%PUBLIC%
	Shell:ProgramFiles\git
	Shell:ProgramFiles\git\etc
	Shell:AppData\Google
	Shell:programfilesx86\NetSarang
	%ProgramFiles%
	%ProgramFiles(x86)%
	%ProgramData%
	%ProgramW6432%
	%PSModulePath%
	%SCOOP%
	%SCOOP_GLOBAL%
	%GIT_INSTALL_ROOT%
	%TEMP%
	D:\MySelf\shell-scripts
	D:\Work\Documents
EOF
)
	#追加paths/d函数使用的书签文件到本函数目录列表；
	local mydirs="$mydirs"$'\n'"$(cat /v/bin/dirs.conf)"
	mydirs=$(echo "$mydirs"|awk '{gsub(/^\s*/,"");print}') #去除目录名称开头的空格
	local openerTool="explorer.exe"
	local directPath  #标识传入的$1是否是一个真实存在的路径（如果是，直接打开目标路径，跳过交互式选择!）
	while :;
	do
		#如果传入了$1参数，则对目录列表进行关键字搜索，而后仅列出匹配关键字的结果
		if [ $# -eq 1 -a ! -z "$1" ];then
			local mydirs=$(echo "$mydirs"|grep -i "$1")
			if [ ! -z "$mydirs" -a -e "$1" -a $(echo "$mydirs"|wc -l) = 1 ];then
				#echo "仅有一个匹配选项！"
				directPath=1
			elif [ -z "$mydirs" ];then
				echo "没有任何匹配的选项！"
				return
			fi
			break
		elif [ $# -ge 1 ] && [[ "${1,,}" == "--open" ]];then #指定了额外程序替代资源管理器的情况
			shift
			if [ ! -z "$1" ] && [[ ! "$1" =~ ^\- ]];then
				local openerTool="$1"
				echo "使用 $openerTool 打开文件夹 ..."
				shift
			fi
		elif [ $# -ge 1 ];then
			local mydirs=$(echo "$mydirs"|grep $@)
			break
		else
			break
		fi
	done
	#echo "跳出参数解析..."
	#输出选择菜单：
	echo "$mydirs"|awk '{printf NR"): ";print}'
	set -f #关闭通配符拓展
	while :;
	do
		if [[ "$directPath" == 1 ]];then
			read -p "请输入序号选择,可一次性输入多个选项[用空格隔开](输入 0 退出选择,输入 p 再次打印目录选项)：" dirChoose <<<"1 0"
		else
			read -p "请输入序号选择,可一次性输入多个选项[用空格隔开](输入 0 退出选择,输入 p 再次打印目录选项)：" dirChoose
		fi
		if [ ! -z "$dirChoose" ];then
			if [[ "${dirChoose,,}" == "p" ]];then
				echo "$mydirs"|awk '{printf NR"): ";print}'
				continue
			fi
			if [[ "$dirChoose" == "0" || "${dirChoose,,}" == "q" ]];then
				echo "exit..."
				break
			fi
			open-single-dir() {
				#local targetDir=$(echo "$mydirs"|awk "NR==$dirChoose"'{gsub(/^\s*/,"");print;exit}')
				local targetDir=$(echo "$mydirs"|awk "NR==$1"'{gsub(/^\s*/,"");print;exit}')
				if [ ! -z "$targetDir" ];then
					#echo "Open Dir $targetDir ..."
					#cmd /c explorer.exe "$targetDir"
					if [[ "${targetDir,,}" =~ ^shell: ]];then #如果文件夹路径是 WshShell SpecialFolders，则用VBS先进行转换；
						#echo "转换Shell路径到常规路径..."
						local vbsShellApplication=$(cygpath -aw "/v/vbs/Get-Shell-Application.vbs")
						local _targetDir=$(cscript.exe //nologo "$vbsShellApplication" "$targetDir"|dos2unix -q|iconv -f GBK -t UTF-8)
						[ ! -z "$_targetDir" ] && local targetDir="$_targetDir" || print_color 9 "WARNING：转换shell路径（$targetDir）失败！" #只有在获取到有效的转换后路径才修改原始路径变量
					fi
					if [[ "$targetDir" =~ ^[a-zA-Z]:\\ || "$targetDir" =~ ^/cygdrive/ || "$targetDir" =~ ^/ ]];then #常规路径模式下判断文件夹是否存在
						if [ ! -e "$targetDir" ];then
							#echo -e "targetDir not exist!\n==>$targetDir"
							print_color 9 "targetDir not exist! ==> $targetDir"
						else
							echo "Open Dir $targetDir ..."
							if [[ "${openerTool,,}" == "bash" ]];then #指定工具为bash时，登录子shell对每个目录进行操作！
								local subAlias="/tmp/sub-shell-alias.sh"
								if [ ! -f "$subAlias" ];then 
									cat>$subAlias<<<$(cat ~/.bash_profile ~/.bashrc|grep -iE '^[^a-z0-9#]*alias'|grep -v '\\$') #去掉带#注释行alias，去掉多行的alias
								fi
								local PS1Str='export PS1="\[\e]0;[@favorite-dirs]:\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\[\e[33m\]@favorite-dirs\[\e[0m\]\n\$ "'
								cat>/tmp/sub-shell.sh<<<$'#!/bin/bash\necho \"加载配置...\";\n. /v/bin/aliaswinapp;\n'". $subAlias;$PS1Str"
								_T="$targetDir" ASMyBash=true bash --login -c '\
												#echo "你已进入子Shell...";
												pwd_gbk=$(pwd|iconv -s -f utf-8 -t GBK); \
												export PS1="\[\e]0;[@favorite-dirs]:${pwd_gbk}\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\[\e[33m\]@favorite-dirs\[\e[0m\]\n\$ "; \
												/bin/bash --rcfile /tmp/sub-shell.sh;\
												'
								echo "你已退出 $targetDir @favorite-dirs 子 shell ..."
							elif [[ "${openerTool,,}" == "wt" || "${openerTool,,}" == "windowsterminal" ]];then #用Windows Terminal打开指定目录
								_T="$targetDir" eval wt
							elif [[ "${openerTool,,}" == "cygwin" ]];then #用Cygwin打开指定目录(自动识别宿主窗口是Mintty还是Windows Terminal)
								_T="$targetDir" eval cygwin "${targetDir//\\/\\\\}"
							else
								#cmd /c explorer.exe `cygpath -aw "$targetDir"`
								cmd /c "$openerTool" `cygpath -aw "$targetDir"`
							fi
						fi
					else #适配Shell:模式或Windows原生环境变量模式；
						echo "Open Dir $targetDir ..."
						#cmd /c explorer.exe "$targetDir"
						[[ "${openerTool,,}" == "cygwin" || "${openerTool,,}" == "bash" ]] && targetDir="${targetDir//\\/\\\\}"
						cmd /c "$openerTool" "$targetDir"
					fi
				else
					echo "targetDir is empty!"
				fi
			}
			if [[ "$dirChoose" == "*" ]];then #打开当前列表所有文件夹
				local dirCount=$(echo "$mydirs"|wc -l)
				for dir in `seq 1 1 $dirCount`;
				do 
					open-single-dir $dir
				done
				##以下这行接收到通配符即退出函数，为了方便在命令行执行 `dvscode 'Work\\Company' <<<"*"`这样的命令
				break
			else
				mapfile -t -d $' ' myDirArr<<<"$dirChoose"
			
				for dir in ${myDirArr[@]};
				do 
					#echo "open dir:$dir"
					[[ "$dir" == "0" ]] && { echo "exit...";set +f;return; }
					open-single-dir $dir
				done	
			fi					
		else
			echo "Have No Choice...!"
		fi
	done
	set +f #还原通配符拓展
}
alias mydirs='favorite-dirs'
alias d3='favorite-dirs'
alias dtc='favorite-dirs --open tcopen.bat'
alias d4='favorite-dirs --open tcopen.bat'
alias dcr='favorite-dirs --open tcopen.bat'
alias dcl='favorite-dirs --open tcopen-left.bat'
#alias deverything='favorite-dirs --open D:\\Extra\\AcmeKit\\Everything.exe -p'
alias deverything='favorite-dirs --open openeverything.bat'
alias d5='deverything'
alias ds='deverything'
alias dcmd='favorite-dirs --open cmd-dir.bat'
alias d6='favorite-dirs --open cmd-dir.bat'
alias dvscode='favorite-dirs --open vscode.bat'
alias dcygwin='favorite-dirs --open cygwin-dir.bat'
alias dmintty='favorite-dirs --open cygwin-dir.bat'
alias dbash='favorite-dirs --open bash'
alias d7='favorite-dirs --open bash'
alias dpwsh='favorite-dirs --open powershell-dir.bat'