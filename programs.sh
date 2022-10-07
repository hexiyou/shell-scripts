#!/bin/bash
#查询在/v/bin/aliaswinapp中已经定义的Win程序快捷方式
SCRIPTPATH=$(realpath $0)
# shellcheck source=/dev/null
. /v/bin/aliaswinapp
programs=$(declare -F|awk "{print \$NF}"|grep -vE "^_")

#echo "programs: $programs"

display_usage() {
	echo -e "$SCRIPTPATH\n"
    echo -e "\t查询或列出 /v/bin/aliaswinapp 定义的功能函数."
	echo -e "\tNotice：programs -h/--help 显示本帮助信息."
    echo -e "\nUsage:\n\tprograms \t\t#横向列出所有的函数功能，每行四个；"
	echo -e "\tprograms xxx \t\t#搜索包含xxx字符串的功能函数（不区分大小写）；"
	echo -e "\tprograms -l \t\t#纵向列出所有的函数功能，每行仅显示一个（类似 ls -l）；"
	echo -e "\tprograms -a|all \t#列出所有的功能函数及其当前会话所有alias名称；"
	echo -e "\tprograms -a|all|find xxx   #搜索包含xxx的函数名称和alias，没有结果则尝试whereis查找；"
	echo -e "\tprograms -d|-f|define name   #查询名为name的函数在aliaswinapp文件中的定义原文（即函数源代码）；"
	echo -e "\tprograms -L|-F \t\t#列出所有的函数和alias定义原文，并尽可能按合理顺序排序；"
	echo -e "\tprograms -A \t\t#等同于programs -a,区别：-A支持grep原生选项，会把后续\$*直接传递给grep处理；"
	echo -e "\t\t\t\teg：高级搜索，区分大小写：programs -A  'Wget'"	
	echo -e "\t\t\t\teg：高级搜索，使用正则表达式：programs -A -E '^t'"	
	echo -e "\t\t\t\teg：高级搜索，统计个数（不区分大小写）：programs -A -ci 'wget'"	
	echo -e "\tprograms [*grep origin options]\t#查找所有函数（不包含alias），同上，\$*接受grep原生选项过滤查找；"
}

##仿ls，横向列出
if [ $# -lt 1 ] || ([ $# -eq 1 ] && ([[ "$1" == "ls" ]] || [[ "$1" == "-s" ]]));then
	#echo -e "$programs"|tr '\n' '\t'
	str=$(echo -e "$programs"|tr '\n' '\t'|sed -r 's/[ \t]*$//g')
	#借助python格式化输出列表
	/usr/bin/env python3 /v/bin/python-formater.py "${str}"
	exit 0
##显示帮助信息
elif [ $# -eq 1 ] && ([[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]);then
	display_usage
	exit 0
##仿ls -l，纵向列出
elif [ $# -eq 1 ] && ([[ "$1" == "ll" ]] || [[ "$1" == "-l" ]]);then
	echo "$programs"
	exit 0
##列出全部，包括所有alias定义定义的值
elif [ $# -eq 1 ] && ([[ "$1" == "all" ]] || [[ "$1" == "-a" ]]);then
	# shellcheck source=/dev/null
	. ~/.bash_profile >/dev/null
	allAlias=$(alias -p|grep -iE '^alias '|awk -F '[ =]' '{print $2}')
	programs=$(echo -e "$programs\n$allAlias"|sort -d)
	echo "$programs"
	exit 0
##列出全部，包括所有alias定义定义的值,并且以关键字查找,$2为要查找的关键字
##本功能和-A分支的区别在于本分支还提供 whereis 查找，另本分支查找参数可省略（省略时列出全部），不支持grep原生选项
## -A 分支查找参数是必须的，且提供grep原生接口，可以实现正则表达式查找等其他功能；
elif [ $# -eq 2 ] && ([[ "$1" == "all" ]] || [[ "$1" == "find" ]] || [[ "$1" == "-a" ]]) && [ ! -z "$2" ];then
	# shellcheck source=/dev/null
	. ~/.bash_profile >/dev/null
	allAlias=$(alias -p|grep -iE '^alias '|awk -F '[ =]' '{print $2}')
	programs=$(echo -e "$programs\n$allAlias"|sort -d)
	programFind=$(echo "$programs"|grep -i "$2")
	#如果aliaswinapp和alias均未找到结果，则通过whereis再次查找
	if [ -z "$programFind" ];then
		whereis $2
	else
		echo "$programFind"
	fi
	exit 0
##查找aliaswinapp中具名function的定义
elif [ $# -eq 2 ] && ([[ "$1" == "-d" ]] || [[ "$1" == "define" ]] || [[ "$1" == "-f" ]]) && [ ! -z "$2" ];then
	fn_defined=$(declare -f $2)
	#如果 aliaswinapp 找不到已有定义，则更深一步去查询 alias 记录
	[ -z "${fn_defined}" ] && {
		# shellcheck source=/dev/null
		. ~/.bash_profile >/dev/null
		# shellcheck source=/dev/null
		. ~/.bashrc >/dev/null
		alias "$2" 2>/dev/null
		exit 0
	}
	echo "${fn_defined}"
	## 以下输出 $apppath 路径到终端，供Ctrl+鼠标左键单击快捷打开对应目录
	if [ ! -z "${fn_defined}" ];
	then
		findappPath=$(echo "${fn_defined}"|grep -i 'apppath='|tac|grep -v -m1 '#')
		if [ ! -z "$findappPath" ];
		then
			if [[ "$findappPath" =~ "cygpath " ]]; #如果路径包含cygpath命令则不再进行解析；
			then
				exit 0
			fi
			echo "---------------------------------"
			findappPath=$(echo "$findappPath"|sed -r 's/^.*\=["|'\'']([^"'\'']+).*$/\1/')
			# eval展开环境变量 %APPDATA% 等~
			findappPath=$(eval echo "${findappPath//\\/\\\\}")
			## 以下注意：经过测试，路径带有小括号等特殊符号时即便经过转义任然不奏效，无法在mintty窗口鼠标单击打开，空格没问题
			## 这是 mintty本身的问题，只能修改mintty原生代码，无法曲线解决
			cygpath -u "$findappPath"|sed -r 's/( |\t|\(|\)|（|）|\[|\])/\\\1/g'
			OLD_IFS=$IFS #临时更改IFS为适配路径中带空格的情况
			IFS=$(echo -e "\n")
			cygpath -u `dirname "$findappPath"`|sed -r 's/( |\t|\(|\)|（|）|\[|\])/\\\1/g'
			IFS=$OLD_IFS
		fi
	fi
	exit 0
##关键词查找，不区分大小写
elif [ $# -eq 1 ] && [[ ! "$1" =~ ^\-[a-zA-Z]$ ]];then
	programFind=$(echo "$programs"|grep -i "$1")
	#如果aliaswinapp未找到结果，则通过whereis再次查找
	if [ -z "$programFind" ];then
		echo -e "not found in /v/bin/aliaswinapp;"
		whereis $1
	else
		#echo "$programFind"
		#借助python格式化输出列表
		/usr/bin/env python3 /v/bin/python-formater.py "`echo "$programFind"|tr '\n' '\t'`"
	fi
	exit 0
elif [[ "$1" == "-L" ]] || [[ "$1" == "-F" ]];then
	#列出所有的函数和alias详细内容，并尽可能按合理顺序排序，grep时同时也在alias内容中查找
	#妙用1：programs -L alias.*wget
	#妙用2：programs -L alias.*ssh
	shift
	# shellcheck source=/dev/null
	. ~/.bash_profile >/dev/null
	# shellcheck source=/dev/null
	. ~/.bashrc >/dev/null
	allAlias=$(alias -p|grep -iE '^alias ')
	programs=$(echo -e "$programs"|sed 's/^/function=/g')
	programs=$(echo -e "$programs\n$allAlias"|sort -t '=' -k 2 -d|sed -r '/^[!a-zA-Z]/!d'|sed 's/^function=//')
	if [ $# -eq 0 ];then
		echo "$programs"
	elif [ $# -eq 1 ];then
		echo "$programs"|grep -i $1
	else
		echo "$programs"|grep "$@"
	fi
	exit 0
##以下情况向grep直接传递参数,直接接收grep原生各项参数
elif [[ "$1" == "-A" ]];then
	##查询所有，包含aliaswinapp内函数定义和用户alias别名，查找参数必不可少，grep时仅仅在alias名称中查找
	##注意区分和-a（小写a）分支的区别
	shift
	# shellcheck source=/dev/null
	. ~/.bash_profile >/dev/null
	# shellcheck source=/dev/null
	. ~/.bashrc >/dev/null
	allAlias=$(alias -p|grep -iE '^alias '|awk -F '[ =]' '{print $2}')
	programs=$(echo -e "$programs\n$allAlias"|sort -d)
	echo "$programs"|grep "$@"
	exit 0
else
	#仅列出/v/bin/aliaswinapp中函数定义，并供grep原生参数查找
	echo "$programs"|grep "$@"
fi