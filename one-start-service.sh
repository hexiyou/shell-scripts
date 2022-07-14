#!/usr/bin/env bash
#一键启动/停止 Laravel Swoole Redis等相关服务
#开发辅助专用，方便一键操作服务相关进程
# Author：hexiyou <hackkey@qq.com>
# Create @ 20220622
# 本脚本后续根据模块和实际需求，持续完善中...

# Usage：one-start-service.sh [action]
#     可选 action 参数值：start,stop,restart,info|status，缺省默认为start
#
#    eg：one-start-service.sh
#        one-start-service.sh start
#        one-start-service.sh stop
#        ......


#公用函数库文件存在则引入公用函数库
[ -f ./bash_functions ] && source ./bash_functions

#print_color函数补全，兼容函数库不存在的情况
type -t print_color >/dev/null||print_color(){
    [ $# -gt 1 ] && shift
    echo -e "$*"
}

#获取PHP版本信息
checkPHPVersion() {
    local phpVersion="$(php -v 2>/dev/null|awk '{print $2;exit}')"
    echo "$phpVersion"
}

#检查PHP拓展是否已经开启（指定单个）
checkPHPExtension() {
    # $1 ---> 拓展名称
    php -m|grep -i "$1"|grep -v 'grep' &>/dev/null
    return $?
}

#检查PHP拓展开启情况，可一次指定多个
#可指定--forceexit参数在拓展检测失败时退出脚本
#eg： checkPHPExtensionMultiple curl exif gd mysqli pdo_mysql sqlite3 
#    OR
#    checkPHPExtensionMultiple curl exif gd mysqli --forceexit
checkPHPExtensionMultiple() {
    # $1 ---> 拓展名称
    local Extensions=()
    local forceExit=0
    while [ $# -gt 0 ];
    do
        if [[ "${1,,}" == "--forceexit" ]];then
            forceExit=1
            shift && continue
        fi
        Extensions=("${Extensions[@]}" "$1")
        shift
    done
    for Extension in ${Extensions[@]};
    do
        print_color "【检查】：PHP拓展：${Extension} ...\c"
        php -m|grep -i "$Extension"|grep -v 'grep' &>/dev/null
        [ $? -eq 0 ] && print_color " ok" || {
            print_color 9 "failure"
            print_color 4 "【警告】：PHP缺少 ${Extension} 拓展..."
            [ $forceExit -eq 1 ] && {
                print_color 9 "【退出】：程序退出..."
                exit 1
            }
        }
    done
}

#借助awk进行浮点数比较
#See Also：https://stackoverflow.com/questions/8654051/how-can-i-compare-two-floating-point-numbers-in-bash
numCompare() {
    if awk "BEGIN {exit !($1 == $2)}"; then
        return 0 #二者相等
    elif awk "BEGIN {exit !($1 > $2)}";then
        return 1 #前者比后者大
    else
        return 2 #前者比后者小
    fi
}

#检查操作系统版本，目前脚本自动化安装仅支持Ubuntu系列系统，其他系统未适配
checkOSName() {
    local OSName=$(cat /etc/os-release|awk -F '=' '/Name/i{gsub("\"","");print $2;exit}')
    echo "$OSName"
}

#检查是否安装Redis服务
checkRedisService(){
    redis-server --version &>/dev/null
    #echo $?
    return $?
}

#安装Redis服务，目前仅适配Ubuntu/Debian;
installRedisService() {
    sudo apt install -y redis-server redis
    return
}

#停止Swoole服务
stopSwooleService() {
    print_color "【服务】：停止Swoole服务..."
    artisan --version &>/dev/null && \
    (artisan swoole:http stop &>/dev/null &) || \
    (php artisan swoole:http stop &>/dev/null &)
}

#停止Redis服务
stopRedisService() {
    print_color "【服务】：停止Redis服务..."
    pkill redis-server
}

#获取Redis服务运行状态
getStatusRedisService() {
   ps aux|grep -i 'redis-server'|grep -v 'grep' 2>/dev/null
   local ret=$?
   [ $ret -ne 0 ] && print_color 4 "没有发现 Redis 进程..."
   return $ret
}

#获取Swoole服务运行状态
getStatusSwooleService() {
    artisan --version &>/dev/null && \
        artisan swoole:http infos || \
        php artisan swoole:http infos
}


################### 主逻辑开始 ###################

phpVersion=$(checkPHPVersion) #当前PHP版本
requirePHPVersion="8.0" #PHP最低要求版本
redisPort=6379 #Redis默认监听的端口，对应 .env 配置文件的 REDIS_PORT 选项；

controlAction="$1" #脚本支持指定参数 start,stop,restart,info|status；缺省参数默认动作为 start

case $controlAction in
    stop)
        stopSwooleService
        stopRedisService
        exit 0
    ;;
    restart)
        stopSwooleService
        stopRedisService
    ;;
    info|status)
        getStatusRedisService
        getStatusSwooleService
        exit 0
    ;;
    *)
    #do nothing
    ;;
esac

print_color "【开始】：准备检查并启动服务..."
print_color "【检查】：检查PHP版本..."
if [ -z "$phpVersion" ];then
    print_color "PHP不存在，请安装 PHP 或设置 \$PATH 环境变量"
    exit 1
else
    numCompare $phpVersion $requirePHPVersion
    if [ $? -eq 2 ];then
        print_color "PHP版本过低，当前PHP版本 $phpVersion，要求PHP版本不低于：$requirePHPVersion"
        print_color "请升级PHP版本后重试！"
        exit 1
    fi
fi

print_color "【检查】：检查PHP相关拓展..."
checkPHPExtension "swoole"||{
    print_color "Swoole拓展未安装或未配置开启，请检查！"
    exit 1
}

#同时检查多个PHP拓展示例,--forceExit指定检查失败是否退出，默认不退出，仅给出警告
#checkPHPExtensionMultiple curl exif gd mysqli pdo_mysql sqlite3 --forceExit
checkPHPExtensionMultiple curl exif gd mysqli pdo_mysql sqlite3 

print_color "【检查】：检查操作系统发行版版本..."
if [ ! "$(checkOSName)" = "Ubuntu" ];then
    #版本不适配仅给出警告提示，不终止脚本操作
    print_color "【警告】：目前脚本仅适配Ubuntu/Debian系统，其他发行版可能出现兼容性问题"
fi

print_color "【检查】：检查Redis服务..."
#没有安装Redis服务则自动进行安装
checkRedisService||{
    print_color "Redis服务不存在，尝试自动安装..."
    installRedisService
}

#先启动Redis再启动Swoole..
print_color "【服务】：运行Redis进程服务..."
getStatusRedisService >/dev/null||redis-server --port $redisPort >/dev/null &

print_color "【服务】：运行Swoole进程服务..."
#如果artisan劫持函数存在，则优先调用劫持函数；
artisan --version &>/dev/null && \
  (artisan swoole:http start >/dev/null &) || \
  (php artisan swoole:http start >/dev/null &)

getStatusSwooleService
print_color "【完成】：准备就绪..."