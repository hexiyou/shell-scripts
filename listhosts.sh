#!/bin/bash
_listhosts() {
	#列出hosts文件被劫持的域名
	local winHosts="$SYSTEMROOT\\System32\\drivers\\etc\\hosts"
	if [[ "${1,,}" == "--all" ]];then
		cat "$winHosts"
	elif [[ "${1,,}" == "-f" || "${1,,}" == "--format" ]];then #格式化输出
		local pyFormatCode=$(cat<<'EOF'
try:
	with open(0, 'rb') as f:
		inpipe = f.read()
	content=inpipe.decode("utf-8")
	print(content.expandtabs(20))
except Exception as e:
	print("read stdin error",e)
EOF
) # <--- 借助Python expandtabs格式化输出！
	local pyTmp=$(mktemp)
		#cat "$winHosts"|dos2unix -q|grep -vE '(^#+|^[ \t]*$)'|tr -s ' '|tr ' ' '\t' # <--- 纯shell格式化输出
		cat>$pyTmp<<<"$pyFormatCode"
		python3 $pyTmp <<<$(cat "$winHosts"|dos2unix -q|grep -vE '(^#+|^[ \t]*$)'|tr -s ' '|tr ' ' '\t')
		[ -f "$pyTmp" ] && rm -f $pyTmp
	elif [[ "${1,,}" == "-s" || "${1,,}" == "--short" ]];then #简略输出
		cat "$winHosts"|dos2unix -q|grep -vE '(^#+|^[ \t]*$)'|tr -s ' '
	else
		cat "$winHosts"|grep -vE '(^#+|^[ \t]*$)'
	fi
}
alias listhosts='_listhosts --format' #格式化输出
alias listhosts0='_listhosts'
alias listhosts1='listhosts'
alias listhosts2='_listhosts --all' # cat 输出hosts文件所有内容
alias listhosts3='_listhosts --short'  #简略输出，缩减空格tab等...