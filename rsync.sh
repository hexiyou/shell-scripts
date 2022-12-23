#!/usr/bin/env bash
#劫持rsync同名命令，自动转换Windows格式路径为Unix风格的路径

rsync() {
	#劫持rsync同名命令，转换参数中的Windows路径为Unix路径;
	#目的：适配在Windows Terminal拖动文件的情况
	local Options=()
	while [ $# -gt 0 ];
	do
		if [[ "${1,,}" =~ ^\- ]];then
			Options=("${Options[@]}" "$1")
		elif [ -f "$1" ] && [[ "$1" =~ "\\" ]];then
			Options=("${Options[@]}" "$(cygpath -u $1)")
		else
			Options=("${Options[@]}" "$1")
		fi
		shift
	done
	set -- "${Options[@]}"
	/usr/bin/rsync "$@"
}