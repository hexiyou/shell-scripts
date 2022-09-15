rename() {
	#优化renname命令，使其支持类似CMD下`ren *.txt *.mp3`类似的操作
	#更改文件拓展名快速操作：
	#为避免通配符展开，使用本函数时应省略通配符，可以直接执行 rename .txt .mp3；
	#也可以使用引号包裹带通配符的参数：eg：rename '*.txt' '*.mp3'
	if [ $# -eq 2 -a -e "$1" ];then
		/usr/bin/mv -v "$@"
	elif [ $# -eq 2 ] && [[ "$1" =~ ^\*?\. && "$2" =~ ^\*?\. ]];then #批量更改文件拓展名；
		/cygdrive/${SYSTEMDRIVE/:/}/Windows/system32/cmd.exe /c  \
		'echo 批量更改拓展名 '"$1"' 为 '"$2"'...&' \
		ren '*'"${1//\*/}" '*'"${2//\*/}"
	else
		/usr/bin/rename "$@"
	fi
}
alias ren='rename' #别名ren，与CMD下ren命令同名，遵循DOS CMD下的使用习惯；