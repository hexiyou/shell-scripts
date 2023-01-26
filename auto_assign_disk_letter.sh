#!/usr/bin/env bash
#自动调整Windows硬盘分配的各个盘符

print_color () 
{ 
    :  <<EOF
echo -e "\033[字背景颜色;文字颜色m字符串\033[0m"
例如: 
echo -e "\033[47;30m I love Android！ \033[0m"
	 其中47的位置代表背景色, 30的位置是代表字体颜色，需要使用参数-e，man  echo 可以知道-e     enable interpretation of backslash escapes。
	 ----------
See Also：
https://www.cnblogs.com/fengliu-/p/10128088.html
更多颜色代码：
https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
https://en.wikipedia.org/wiki/ANSI_escape_code
EOF

    if [ $# -eq 0 ]; then
        echo -e "\033[30m 黑色字 \033[0m"
        echo -e "\033[31m 红色字 \033[0m";
        echo -e "\033[32m 绿色字 \033[0m";
        echo -e "\033[33m 黄色字 \033[0m";
        echo -e "\033[34m 蓝色字 \033[0m";
        echo -e "\033[35m 紫色字 \033[0m";
        echo -e "\033[36m 天蓝字 \033[0m";
        echo -e "\033[37m 白色字 \033[0m";
        echo -e "\033[40;37m 黑底白字 \033[0m";
        echo -e "\033[41;37m 红底白字 \033[0m";
        echo -e "\033[42;37m 绿底白字 \033[0m";
        echo -e "\033[43;37m 黄底白字 \033[0m";
        echo -e "\033[44;37m 蓝底白字 \033[0m";
        echo -e "\033[45;37m 紫底白字 \033[0m";
        echo -e "\033[46;37m 天蓝底白字 \033[0m";
        echo -e "\033[47;30m 白底黑字 \033[0m";
        echo;
        echo -e "See Also：\n\thttps://www.cnblogs.com/fengliu-/p/10128088.html";
        return;
    fi;
    local color=3;
    if [ $# -ge 2 ]; then
        expr $1 "+" 10 &> /dev/null;
        if [ $? -eq 0 ]; then
            local color=$1;
            shift;
        fi;
    fi;
    local str="$*";
    case $color in 
        1)
            echo -e "\033[30m${str}\033[0m"
        ;;
        2)
            echo -e "\033[31m${str}\033[0m"
        ;;
        3)
            echo -e "\033[32m${str}\033[0m"
        ;;
        4)
            echo -e "\033[33m${str}\033[0m"
        ;;
        5)
            echo -e "\033[34m${str}\033[0m"
        ;;
        6)
		
		echo -e "\033[35m${str}\033[0m"
        ;;
        7)
            echo -e "\033[36m${str}\033[0m"
        ;;
        8)
            echo -e "\033[37m${str}\033[0m"
        ;;
        9)
            echo -e "\033[41;37m${str}\033[0m"
        ;;
        10)
            echo -e "\033[47;30m${str}\033[0m"
        ;;
        33)
            echo -e "\033[42;33m${str}\033[0m"
        ;;
        37)
            echo -e "\033[44;37m${str}\033[0m"
        ;;
        40)
            echo -e "\033[40;33m${str}\033[0m"
        ;;
        41)
            echo -e "\033[41;33m${str}\033[0m"
        ;;
        *)
            echo -e "\033[44;37m${str}\033[0m"
        ;;
    esac
}

auto_assign_letter() {
	#调用diskpart重新分配错乱的硬盘符卷标
	#See Also：https://www.sysgeek.cn/windows-10-assign-drive-letter/
	#See Also2：https://learn.microsoft.com/zh-cn/windows-server/administration/windows-commands/diskpart-scripts-and-examples
	#——————————————————————————————————————————————————————————————————————
	:<<'EOF'
SELECT VOLUME 8
ASSIGN LETTER=H NOERR
SELECT VOLUME 9
ASSIGN LETTER=I
SELECT VOLUME 10
ASSIGN LETTER=J
SELECT VOLUME 11
ASSIGN LETTER=K
SELECT VOLUME 12
ASSIGN LETTER=M	
EOF
	local tmpScriptFile=$(mktemp --suffix=.txt)
	local tmpDiskPartOutput=$(mktemp)
	
	_run_diskpart_script(){  #运行diskpart脚本，脚本内容作为$*参数传递给本函数即可；
		local tmpScriptContext="$*"
		cat>$tmpScriptFile<<<"$tmpScriptContext"
		gsudo "diskpart.exe /s $(cygpath -aw $tmpScriptFile) >$(cygpath -aw $tmpDiskPartOutput)"
	}
	_get_diskpart_result(){  #获取diskpart脚本运行结果
		[ -f "$tmpDiskPartOutput" ] && dos2unix -q $tmpDiskPartOutput
		#cat $tmpDiskPartOutput 2>/dev/null || return 1
		cat $tmpDiskPartOutput|iconv -s -f GBK -t UTF-8
	}

	declare -a volumLetters=(H I J K M)
	declare -a volumIndexes
	_run_diskpart_script "LIST VOLUME"
	local diskpartInfo=$(_get_diskpart_result)
	local hcygwinIndex=$(echo "$diskpartInfo"|awk '/TOSHIBA EXT/{print $2;exit}')
	local hcygwinLetter=$(echo "$diskpartInfo"|awk '/TOSHIBA EXT/{print $3;exit}')
	[ "$hcygwinLetter" = "H" ] && print_color 3 "Cygwin所在盘卷标已是H，符合预期，不再进行后续的盘符识别和更改！" && return
	for index in {1..5};
	do
		volumIndexes=(${volumIndexes[@]} $hcygwinIndex)
		let hcygwinIndex+=1
	done
	
	local tmpScriptContext
	for label in `seq 0 $((${#volumIndexes[@]}-1))`
	do
		#echo "deal with ${volumIndexes[$label]} => ${volumLetters[$label]} "
		tmpScriptContext="$tmpScriptContext"$'\n'"SELECT VOLUME ${volumIndexes[$label]}"$'\n'"ASSIGN LETTER=${volumLetters[$label]} NOERR"
	done
	#echo -e "-----\n$tmpScriptContext\n----"
	print_color 3 "准备修正硬盘盘符分配......"
	_run_diskpart_script "$tmpScriptContext"
	[ $? -ne 0 ] && print_color 40 "_run_diskpart_script返回非零状态码，请检查diskpart命令执行结果是否符合预期..."
	print_color 33 "All Things Done..."
	[ -f "$tmpScriptFile" ] && rm -f "$tmpScriptFile"
	[ -f "$tmpDiskPartOutput" ] && rm -f "$tmpDiskPartOutput"
}


##调用函数体：
auto_assign_letter