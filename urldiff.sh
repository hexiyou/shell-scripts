#!/usr/bin/env bash
# 函数：urldiff
# 功能：快速比较两个URL内容是否相同（下载url内容到临时文件，根据指定的工具按行比较差异，并自动删除临时文件）

urldiff() {
	#快速比较两个URL内容是否相同
	#通常用来比较两个JS或CSS网址的内容是否一样（仿站、拷贝静态站点来修改时常用！）
	declare -a urlArr  #保存传递进来的网址，目前仅使用前两个元素（索引为0和1的元素），其余元素将被忽略
	declare -a tmpArr  #存储生成临时文件的文件名，目前仅使用前两个元素
	declare -a options    #存储命令行选项
	local diffTool=diff   #用来比较差异的命令行工具，默认为diff，也可以换成其他工具，如：icdiff
	local noDelete=0      #<------是否删除临时文件，0为删除，其他数值为保留
	
	_print_usage() {  #打印帮助信息
		echo -e "urldiff：\n\t快速比较两个URL内容是否相同（常用来比较两个JS或CSS网址的内容是否一样）；\n"
		echo -e "Usage:"
		echo -e "\turldiff url1 url2"
		echo -e "\turldiff url1 url2 [-t|--tool] diff~tool   #指定差异对比工具：默认使用\`diff\`命令；"
		echo -e "\turldiff url1 url2 [-t|--tool] diff~tool [--nodelete|--nodel]  #是否保留临时文件不删除（默认不保留）"
		echo -e "Example:"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js -t icdiff"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js -t 'icdiff --strip-trailing-cr'"
		echo -e "\t\t\t\t\t\t\t\t\t\t#使用 icdiff 比较时，忽略换行符的差异；"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js -t vimdiff"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js --nodel"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js --nodelete"
		echo -e "\turldiff http://www.example.com/static/common.js http://www.baidu.com/static/common.js -t icdiff --nodel"
	}
	[ $# -eq 0 ] || [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]] && _print_usage && return
	while [ $# -gt 0 ];
	do
		if [[ "${1,,}" == "--tool" || "${1,,}" == "-t" ]];then
			diffTool="$2" && shift
		elif [[ "${1,,}" == "--nodelete" || "${1,,}" == "--nodel" ]];then  #以短横线开头的参数即识别为命令行选项
			noDelete=1
		elif [[ "${1,,}" =~ ^\- ]];then  #以短横线开头的参数即识别为命令行选项
			options[${#options[@]}]="$1"
		else
			urlArr[${#urlArr[@]}]="$1"
		fi
		shift
	done
	for num in ${!urlArr[@]}
	do
		tmpArr[$num]=$(mktemp)
		print_color "保存文件 ${urlArr[$num]} => ${tmpArr[$num]} ..."
		wget -O "${tmpArr[$num]}" "${urlArr[$num]}"
	done
	print_color 33 "比较文件..."
	#eval $diffTool "${tmpArr[@]}"
	eval "$diffTool" "${tmpArr[@]}"
	[ "$noDelete" != "0" ] && print_color 40 "Notice：保留临时文件并退出..." && return
	for tmpFile in ${tmpArr[@]}  #<---清除临时文件
	do
		[ -f "$tmpFile" ] && rm -vf "$tmpFile" >/dev/null   #<--删除成功时隐藏信息，报错时显示报错提示
	done
}

alias urldiff-vim='urldiff -t vimdiff'  #使用vim比较差异
alias urldiff-icdiff='urldiff -t icdiff'   #使用icdiff比较差异，系统上需要事先安装icdiff