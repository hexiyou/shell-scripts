#!/bin/bash 
#Windows 下搜索工具 Everything 系列功能函数；
#功能：一键打开Everything窗口，或打开窗口的同时定位到某个目录路径下进行搜索；
#本函数同时适配Cygwin和WSL环境，可传递Unix风格或Windows风格的路径作为参数，程序会智能判断并转换处理；

declare -F file_exist &>/dev/null || file_exist() {
if [[ "$(uname -o)" == "Cygwin" ]];then     #判断是Cygwin环境
    test -e "$1"
    local retCode=$?
    [ $retCode -eq 0 ] && echo "ok"
    return $retCode
    #elif [[ "$(uname -o)" == "GNU/Linux" ]] && [[ "$(uname -r)" =~ "WSL" ]];then            #判断是WSL环境（貌似仅能适配WSL2）
elif [[ "$(uname -o)" == "GNU/Linux" ]] && [[ "$(uname -r)" =~ "Microsoft" ]];then       #判断是WSL环境（适配WSL1）
    [[ "$1" =~ "\\" ]] && >/dev/tty print_color 40 "【警告】：参数为Windows路径格式，此函数处理结果可能不符合预期，建议重写该函数代码！"
    test -e "${1/\/cygdrive\//\/mnt\/}"
    local retCode=$?
    [ $retCode -eq 0 ] && echo "ok"
    return $retCode
else     #其他环境（Linux环境）
    test -e "$1"
    local retCode=$?
    [ $retCode -eq 0 ] && echo "ok"
    return $retCode
fi
}

if [[ "$(uname -o)" == "GNU/Linux" ]];then
    cygpath() {
        #本功能函数同样可用于转换UNC路径，eg：cygpath -aw '//wsl.localhost/Ubuntu-24.04/home' 或 cygpath -au '\\wsl.localhost\Ubuntu-24.04\home'
        if [ -z "$WSL_DISTRO_NAME" ];then
            _cygpath "$@"
            return
        fi
        if [[ "${@:$#}" =~ ^/tmp/ ]] && [[ "$1" =~ \-[a-z]*w ]];then #处理一些特殊情况（eg：在 Cygwin 临时目录生成临时文件。）
            #echo "/mnt/h/cygwin64${@:$#}"
            local _path="${@:$#}"
            echo '\\wsl.localhost\'$WSL_DISTRO_NAME"${_path//\//\\}"
            #>/dev/tty print_color 40 "TODO：当前WSL下处理特殊路径，路径处理可能错误！"
        elif [[ ! "${@:$#}" =~ ^/mnt/ ]] && ([[ "${@:$#}" =~ ^/ ]] || [ -e "${@:$#}" ]);then  #传递参数路径为Linux下绝对路径，或者已存在文件的相对路径时，自动附加UNC风格的WSL路径前缀;
            local _path="${@:$#}"
            local _path='\\wsl.localhost\'$WSL_DISTRO_NAME"$(realpath $_path)"
            set -- "${@:1:$(($#-1))}" "$_path"
            _cygpath "$@"
        else
            _cygpath "$@"
        fi
    }

    _cygpath() {
        local _cygpath="/mnt/h/cygwin64/bin/cygpath.exe"
        [ -e "$_cygpath" ] || local _cygpath="cygpath.exe"
        if [ ! -t 0 ];then #管道有内容
            if [ ! -z "$(command -v $_cygpath)" ]; then  #判断cygpath命令本身存不存在，不使用type指令是type指令会同时检测function和alias
                #/usr/bin/cygpath "$@" </dev/stdin
                (timeout 1s $_cygpath "$@"|sed 's|/cygdrive/|/mnt/|')< <(cat)
                #cat|$_cygpath "$@"|sed 's|/cygdrive/|/mnt/|'
                #$_cygpath "$@" </dev/stdin
            else
                cat|realpath - 2>/dev/null   #从标准输入中读取内容并转化为绝对路径
            fi
        else
            if [ -f "$_cygpath" ];then
                local _path="${@:$#}"  #取最后一个参数
                [[ "$_path" =~ ^/mnt/ ]] && local _path="${_path/\/mnt\//\/cygdrive\/}"   #还原路径开头的 /mnt/ 前缀为 /cygdrive/
                [ -z "$*" ] && set -- "--help" #没有任何参数时，默认获取帮助信息
                set -- "${@:1:$(($#-1))}" "$_path"
                $_cygpath "$@"|sed 's|/cygdrive/|/mnt/|'
            elif [ $(type -t realpath) = "file" ] && [[ "$1" =~ "\-[a]" ]];then
                realpath "${@:$#}" #取最后一个参数
            else
                echo "$*"
            fi
        fi
    }
fi 


declare -F cygpath &>/dev/null || cygpath() {
#适配系统不存在cygpath命令的情况
if [ ! -t 0 ];then #管道有内容
    if [ ! -z "$(command -v /bin/cygpath)" ]; then  #判断cygpath命令本身存不存在，不使用type指令是type指令会同时检测function和alias
        #/usr/bin/cygpath "$@" </dev/stdin
        /usr/bin/cygpath "$@"< <(cat)  #<---20241020修复报错：/v/bin/aliaswinapp: 行 22536: /dev/stdin: No such file or directory
    else
        cat|realpath - 2>/dev/null   #从标准输入中读取内容并转化为绝对路径
    fi
else
    if [ -f /usr/bin/cygpath ];then
        /usr/bin/cygpath "$@"
    elif [ $(type -t realpath) = "file" ] && [[ "$1" =~ "\-[a]" ]];then
        realpath "${@:$#}" #取最后一个参数
    else
        echo "$*"
    fi
fi
}

everything() {
    declare -a apppaths
    #以下变量apppaths保存多个可执行文件的绝对路径（一行一个）；
    IFS=$'\n' apppaths=$(cat<<'EOF'  #<--此处更改IFS以适配路径中包含空格的情况
C:\Users\Administrator\AppData\Local\AcmeKit\Everything.exe
D:\Extra\AcmeKit\Everything.exe
D:\Extra\Everything-1.4.1.1024.x64\Everything.exe
D:\Program Files\Everything-1.4.1.1024.x64\Everything.exe
/mnt/c/Users/Administrator/AppData/Local/AcmeKit/Everything.exe   #WSL适配
/mnt/d/Extra/AcmeKit/Everything.exe   #WSL适配
/mnt/d/Extra/Everything-1.4.1.1024.x64/Everything.exe   #WSL适配
/mnt/d/Program Files/Everything-1.4.1.1024.x64/Everything.e   #WSL适配
EOF
)
for apppath in ${apppaths[@]};
do
    local apppath=$(echo "$apppath"|sed 's/\s*#.*$//')  #<---去掉#号及后面的注释(包含#号前面的多余空格)
    if [ $(file_exist "${apppath}") ];then
        cmd /c start "" "$(cygpath -aw $apppath)" "$@"
        return
    fi
done
echo -e "program not found!\nall paths：\n${apppaths[*]//\\/\\\\} "
}

everything-find() {
    #打开 EveryThing 在某个指定路径下搜寻文件；
    _print_usage(){
        cat<<'EOF'
    everything-find|efind
        调用并打开 Everything 工具窗口，直接在某个路径下搜索文件；
        可传递 $1 参数指定要搜索的目录路径，缺省参数默认搜索Cygwin窗口当前工作目录 $PWD；
    Usage:
        everything-find [target~path]
    Example:
        everything-find                    #打开 Everything 在当前目录下搜索文件
        efind .                            #同上，缩写形式（ efind 为 everything-find 的别名调用）
        everything-find 'H:\Video'         #打开 Everything 在目录 H:\Video 下搜索文件
        everything-find /opt/downloads     #目录路径参数可传递Linux Posix风格的路径
EOF
    }
    [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]] && _print_usage && return
    if [ $# -eq 0 ];then
        local dir="$(pwd)"
    else
        local dir="$1"
    fi
    [ -n "$WSL_DISTRO_NAME" ] && local _cygpathFunc="_cygpath" || local _cygpathFunc="cygpath" #<---同时支持Cygwin或WSL下调用，确保路径转换结果正确；
    [ -n "$WSL_DISTRO_NAME" ] && local dir=$(echo "$dir"|$_cygpathFunc -au -f-) #<---WSL内调用兼容处理
    [ ! -d "$dir" ] && {
        #[ ! "$(file_exist $dir)" ] && {
        echo "Path Not Exist! ==> $dir"
        return
    }
    everything -path "`$_cygpathFunc -aw $dir`"
}
alias efind='everything-find'
