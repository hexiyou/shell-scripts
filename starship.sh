#!/usr/bin/env bash
#对StarShip的封装，允许在Cygwin中用不同方式打开starship
#有关starship的具体说明请参看官网：
#	https://starship.rs/zh-cn/

starship() {
    ## Run starship From cygwin [另一跨平台终端工具]
	## 官网：https://starship.rs/zh-CN/
	## 中文手册：https://starship.rs/zh-CN/guide/
	## Github：https://github.com/starship/starship
	local apppath="/v/windows/starship/starship.exe"
	if [ -e "${apppath}" ];then
		if [ $# -eq 0 ];then     #在新标签页中加载StarShip
			LOADSTARSHIP=true cygwin.bat
		elif [[ "${1,,}" == "inner" || "${1,,}" == "in" ]];   #在当前窗口加载StarShip
		then
			eval "$($apppath init bash)"
		elif [[ "${1,,}" == "--show" ]]; #只显示Hook代码，不加载starship
		then
			"$apppath" init bash
		else  #传递starship.exe的其他命令行选项，eg：starship --help
			"$apppath" "$@"
		fi
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 