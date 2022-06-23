#!/bin/bash 
SCRIPTPATH=$(realpath $0)
#SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#SCRIPTPATH=$(dirname $(readlink -f "$0"))

display_usage() {
	echo -e "$SCRIPTPATH\n"
    echo -e "\t自动拷贝本地~/.ssh/config中指定主机配置项和对应私钥到远程主机."
	echo -e "\t目的：方便在远程主机上通过ssh免密码连接另一台服务器"
    echo -e "\nUsage:\n\tssh-host-remote-copy [connect hostname] [copy target host]"
	echo -e "Example:\n\tssh-host-remote-copy racknerd kunming"
	echo -e "\n\t妙用：拷贝本地所有的主机配置和私钥到远程服务器可以使用以下命令(.号匹配所有主机)："
	echo -e "\tssh-host-remote-copy racknerd ."
}
# if less than two arguments supplied, display usage
if [  $# -lt 2 ]
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

sshHost=$1
copyTarget=$2

hostInfo=$(/v/bin/sshfind.py $copyTarget)

findCount=$(echo "$hostInfo"|grep -ci 'Host ')

if [ $findCount -gt 1 ];
then
	echo "拷贝目标找到多个匹配，请注意拷贝动作是否符合预期！"
fi

sshConfigFile="/tmp/ssh_config_tmp.$$"
trap "rm -f $sshConfigFile" 0
#清除配置文件多余行
hostInfoFormat=$(echo "$hostInfo"|awk '/^[0-9]+$/{next};/sshfind/{exit};/以上为全字匹配结果/{exit};/^$/{next};{print}')
echo "$hostInfoFormat">$sshConfigFile

IdentityFile=$(echo "$hostInfoFormat"|awk '/IdentityFile/{print $NF}')
#echo "$IdentityFile"
ssh $sshHost 'mkdir -p ~/.ssh/'
echo -e "Copy Key Files to remote server..."
keyFiles=$(echo -e "$IdentityFile"|tr '\n' ' ')
eval scp $keyFiles $sshHost:~/.ssh/
echo -e "Copy SSH Config temp file to remote server..."
scp $sshConfigFile $sshHost:$sshConfigFile
echo -e "Configure ssh config for user..."
ssh $sshHost 'touch ~/.ssh/config;chmod 600 ~/.ssh/*;\
	awk  '\''BEGIN{while(getline line<"'$sshConfigFile'"){print line}}{print}'\'' ~/.ssh/config|tee ~/.ssh/config >/dev/null;\
	rm -f /tmp/ssh_config_tmp*'
echo -e "Done..."