#!/usr/bin/env bash
#对StarShip的封装，允许在Cygwin中用不同方式打开starship
#有关starship的具体说明请参看官网：
#	https://starship.rs/zh-cn/

__init_starship() {
	#初始化starship，从Cygwin拷贝starship配置文件到Windows配置文件目录(%USERPROFILE%\.config)
	[ -f ~/.config/starship.toml ] && [ ! -f "$USERPROFILE\\.config\\starship.toml" ] && {
		cp ~/.config/starship.toml "$USERPROFILE\\.config\\starship.toml"
	}
	return
}

starship() {
    ## Run starship From cygwin [另一跨平台终端工具]
	## 官网：https://starship.rs/zh-CN/
	## 中文手册：https://starship.rs/zh-CN/guide/
	## Github：https://github.com/starship/starship
	## ---------------------------------------------
	## eg：
	## starship
	## starship inner
	## starship --clean
	## starship --refresh
	## starship --refresh inner
	## starship --help
	local apppath="/v/windows/starship/starship.exe"
	if [ -e "${apppath}" ];then
		__init_starship #初始化自定义配置文件
		if [ $# -eq 0 ];then     #在新标签页中加载StarShip
			#LOADSTARSHIP=true cygwin.bat
			LOADSTARSHIP=true cygwin-dir.bat "$_T"  #打开新标签时允许指定工作目录：eg：`_T=H:\\ starship`
		elif [[ "${1,,}" == "inner" || "${1,,}" == "in" ]];   #在当前窗口加载StarShip
		then
			eval "$($apppath init bash)"
		elif [[ "${1,,}" == "--show" ]]; #只显示Hook代码，不加载starship
		then
			"$apppath" init bash
		elif [[ "${1,,}" == "--catconfig" ]]; #查看starship配置文件
		then
			[ -f "$USERPROFILE\\.config\\starship.toml" ] && cat "$USERPROFILE\\.config\\starship.toml" && return
			[ -f ~/.config/starship.toml ] && print_color 40 "Windows配置文件不存在，但Cygwin配置文件存在!" && cat ~/.config/starship.toml && return
			print_color 9 "Starship 配置文件不存在！"
		elif [[ "${1,,}" == "--clean" ]]; #清除Windows下starship的配置文件，下一次运行会从Cygwin拷贝新的配置文件到Windows .config
		then
			[ -f "$USERPROFILE\\.config\\starship.toml" ] && rm -f "$USERPROFILE\\.config\\starship.toml"
			echo "Remove .config/starship.toml File Done..."
		elif [[ "${1,,}" == "--refresh" ]]; #刷新starship配置：清除Windows下starship的配置文件后运行starship
		then
			starship --clean
			shift && starship "$@" && return #刷新配置文件并运行starship：`starship --refresh`、`starship --refresh inner`
		else  #传递starship.exe的其他命令行选项，eg：starship --help
			"$apppath" "$@"
		fi
	else
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
} 