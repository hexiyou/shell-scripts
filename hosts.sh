#!/bin/bash
[[ $(type -t hosts) == "alias" ]] && unalias hosts
hosts() {
	#记事本一键打开hosts文件以供编辑；
	local winHosts="$SYSTEMROOT\\System32\\drivers\\etc\\hosts"
	local fileMode=$(stat -c '%a' "$winHosts") #当前权限
	#local fileUser=$(stat -c '%U' "$winHosts") #归属用户
	#local fileGroup=$(stat -c '%G' "$winHosts") #归属用户组
	ASMyBash=True mysudo chmod -v 777 "$winHosts"
	gsudo cmd /c notepad "$winHosts"
	ASMyBash=True mysudo chmod -v $fileMode "$winHosts"
}