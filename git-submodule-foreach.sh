git-submodule-count-all() {
	#不进入子模块目录来统计子模块下每个人的代码提交（具体见git-count-all函数），支持同时指定多个模块目录；
	# eg:git-submodule-count-all Modules/Hello Modules/Two
	# Git使用的环境变量请参看：https://git-scm.com/book/zh/v2/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F
	#----------------------------------------------------
	[ $# -eq 0 ] || ([[ "$*" == "-h" || "$*" == "--help" ]]) && {
			[ $# -eq 0 ] && print_color 9 "缺少参数！请指定子模块目录！"
			print_color 40 "git-submodule-count-all：\n\t自动切换到Git仓库子模块目录，统计子模块每个人的代码提交行数（即：git-count-all ...）"
			echo -e "Usage："
			echo -e "\tgit-submodule-count-all Modules/Helloworld"
			echo -e "\tgit-submodule-count-all Modules/Helloworld Modules/SecondsModule ..."
			return
		}
		
	while [ $# -gt 0 ];
	do
		[ -d "$1" ] && {
				pushd "$1" &>/dev/null
				echo "$1："
				git-count-all --email
				echo -e "——————————————————————————————————————————————————————————————————————————————————————————————"
				popd &>/dev/null
			} || {
				print_color 9 "请指定有效的子模块路径：$1 !"
			}
		shift
	done
}

git-submodule-count-all-auto() {
	#自动搜索并进入子模块目录来统计子模块下每个人的代码提交（功能同git-submodule-count-all，但不用指定子模块路径，程序自动从.gitmodules中读取）；
	# eg：git-submodule-count-all-auto
	# Git使用的环境变量请参看：https://git-scm.com/book/zh/v2/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F
	#----------------------------------------------------
	([[ "$*" == "-h" || "$*" == "--help" ]]) && {
			print_color 40 "git-submodule-count-all-auto：\n\t自动从.gitmodules中读取注册的子模块，并自动进入子模块目录统计代码提交行数！"
			echo -e "Usage："
			echo -e "\tgit-submodule-count-all-auto"
			return
	}
	
	if [ ! -d "./.git" ];then
		print_color 40 "没有发现版本库目录.git，请在GIT仓库根目录运行此命令！"
		return
	elif [ ! -e "./.gitmodules" ];then
		print_color 40 "当前仓库不包含子模块（请检查是否存在.gitmodules文件），程序退出后续操作..."
		return
	fi

	local subModules=$(cat .gitmodules|dos2unix -q|awk -F '=' 'BEGIN{IGNORECARE=1}\
		/\[submodule .*\]/{\
				getline;if(match($0,/^[ \t]*path[ \t]*=/)){gsub(" ","",$2);print $2;}\
		}')
	#echo "$subModules"
	set -- $(echo "$subModules"|tr '\n' ' ')  #将获取到的子模块路径转换为$@数组
	#echo "$# => $@"
		
	while [ $# -gt 0 ];
	do
		[ -d "$1" ] && {
				pushd "$1" &>/dev/null
				echo "$1："
				git-count-all --email
				echo -e "——————————————————————————————————————————————————————————————————————————————————————————————"
				popd &>/dev/null
			} || {
				print_color 9 "请指定有效的子模块路径：$1 !"
			}
		shift
	done
}

git-submodule-foreach() {
	#自动搜索并进入子模块目录执行自定义的函数或Alias别名，作用类似于Git原生命令 git submodule foreach ...；
	#（场景说明：因 git submodule foreach xxxx 仅支持调用真实存在的命令，无法调用函数或Alias，故写此辅助函数）；
	# eg：git-submodule-foreach gtoday
	#     git-submodule-foreach git-log-today
	#     git-submodule-foreach git-plog-today
	#     git-submodule-foreach git-lines-today
	#     git-submodule-foreach git-show-yesterday -s --pretty="%cN\<%cE\>\ %cd\ %s"
	#     git-submodule-foreach 'git-show-yesterday -s --pretty="%cN<%cE> %cd %s"'   #用单引号包含完整的命令行则可以省去转义过程
	#     git-submodule-foreach 'git-log-yesterday|wc -l'    #支持子命令中使用管道符（需用单引号包裹命令行....）
	# Git使用的环境变量请参看：https://git-scm.com/book/zh/v2/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F
	#----------------------------------------------------
	([[ "$*" == "-h" || "$*" == "--help" ]]) && {
			print_color 40 "git-submodule-foreach：\n\t自动从.gitmodules中读取注册的子模块，并自动进入子模块执行自定义的（命令/函数/Alias指令）！"
			echo -e "Usage："
			echo -e "\tgit-submodule-foreach"
			return
	}
	
	if [ ! -d "./.git" ];then
		print_color 40 "没有发现版本库目录.git，请在GIT仓库根目录运行此命令！"
		return
	elif [ ! -e "./.gitmodules" ];then
		print_color 40 "当前仓库不包含子模块（请检查是否存在.gitmodules文件），程序退出后续操作..."
		return
	fi

	local subModules=$(cat .gitmodules|dos2unix -q|awk -F '=' 'BEGIN{IGNORECARE=1}\
		/\[submodule .*\]/{\
				getline;if(match($0,/^[ \t]*path[ \t]*=/)){gsub(" ","",$2);print $2;}\
		}')
	
	local subModulesPath=($(echo "$subModules"|tr '\n' ' '))
	
	[ -z "$*" ] && set -- "pwd"  #没有指定任何附加参数则打印当前工作目录的绝对路径（pwd）
		
	for subPath in ${subModulesPath[@]};
	do
		[ -d "$subPath" ] && {
				pushd "$subPath" &>/dev/null
				echo "$subPath："
				eval "$@"  #<---常规模式传递参数注意特殊字符需要转义（如重定向符号<、>等...）；你可以用单引号包裹完整的命令行以避免转义的麻烦
				local subRetCode=$?
				echo -e "——————————————————————————————————————————————————————————————————————————————————————————————"
				popd &>/dev/null 
				[ $subRetCode -ne 0 ] && break #子命令返回失败值则退出函数，不再循环向后执行...（测试命令：git-submodule-foreach git-show-yesterday -s --pretty="%cN<%cE> %cd %s" 或  git-submodule-foreach test 1 -eq 2）
				command :  #为了避免输出错误到下一个语句块
			} || {
				print_color 9 "子模块路径：$subPath 不存在，自动跳过!"
			}
	done
	[ $subRetCode -ne 0 ] && print_color 40 "警告：因子模块调用的命令以非零状态退出，未对所有模块执行命令！"
}