#!/bin/bash 
#定时检查Linux主机维护是否结束，主机连接是否恢复

pushd $(dirname $0) &>/dev/null

#set -o interactive-comments
shopt -s expand_aliases

source /v/bin/aliaswinapp

checkLog="tmhhost-check-log.log"

#检测天莫寒主机连通性！
ssh -J none -o ConnectTimeout=5 racknerd 'exit 0' && {
	if [ ! -s "$checkLog" ];then #只在第一次检测成功时报警提醒，后续检测成功则忽略！
		cat >$checkLog<<<"Check At $(\\date +'%F %T') successed!"
		trans-cn "请注意，RackNerd VPS主机已恢复" 3
	fi
	
} || cat /dev/null >$checkLog


popd &>/dev/null