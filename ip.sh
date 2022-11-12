#!/bin/bash
#查询指定代理的出口IP（HTTP代理/SOCKS代理）
SCRIPTPATH=$(realpath $0)

display_usage() {
	echo -e "$SCRIPTPATH\n"
    echo -e "\t查询指定代理的出口IP（支持HTTP代理/SOCKS代理）."
	echo -e "\tsocks代理需加上协议前缀。如:socks5://10.10.10.254:1081."
    echo -e "\nUsage:\n\tip addr:port"
	echo -e "Example:\n\tip 10.10.10.254:1081"
}
# if less than two arguments supplied, display usage
if [  $# -lt 1 ]
then
    display_usage
    exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $* == "--help") ||  $* == "-h" ]]
then
    display_usage
    exit 0
fi

## 当传入参数的个数大于1时，合并所有参数为一个参数。便于它处使用alias引用代理服务器ip，缩短用户交互输入
## 如定义：alias ip254='ip 10.10.10.254:'，即可在终端使用`ip254 1081`查询10.10.10.254:1081端口的代理
if [ $# -eq 1 ];then
	proxyAddress=$1
else
	proxyAddress="$1:$2"
	shift 2
	proxyAddress="${proxyAddress}$*"
	proxyAddress=$(echo "$proxyAddress"|tr -d ' '|tr -s ':')
fi

#echo "$proxyAddress"

##检测到常用代理地址时，用户输入参数可省略协议类型，由程序自动补全
if [[ "$proxyAddress" =~ ^10\.10\.10.*\:10.*$ && ! "$proxyAddress" =~ ^(http|socks) ]];then
	proxyAddress="socks5://${proxyAddress}"	
fi

#以下URL接口请自行替换为可用的URL地址（也可以自行搭建）
curl -sSL -x $proxyAddress 'http://ip-api.com/json/?lang=zh-CN'