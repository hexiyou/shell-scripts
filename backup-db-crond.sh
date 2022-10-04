#!/usr/bin/env bash
#调用封装好的备份功能函数通过ssh隧道备份MySQL数据库
#记得引入Bash公用函数库文件：/v/bin/aliaswinapp
# -----------------------------
# 用到的封装函数：
# ssh-backup-db | mysql-backup-db-via-ssh
# mysql-list-db
# mysql-backup-db
# -----------------------------

pushd $(dirname $0) &>/dev/null

#set -o interactive-comments
shopt -s expand_aliases

source /v/bin/aliaswinapp

MySQLROOTPWD="123456789"  #定义 MySQL ROOT 密码，其他普通用户密码也可，修改以下代码中的用户名为对应用户，但注意确认该用户是否有足够的权限
DBHost="racknerd" #定义要连接的目标主机，在~/.ssh/config中定义
RemoteIP="" #远程主机的IP，方便备份完成后对网络连接相关进程进行过滤查找，并终止隧道进程！
SQLPREFIX="" #导出SQL文件的前缀，比如可用server_online_区分本地数据还是线上数据，默认为空
DBName="exampledb_1" #定义要备份的数据库名称
DBNames=("exampledb_1" "information_schema" "performance_schema") #定义数据，备份多个数据库的名称


echo "终止已有的 ssh 进程..."
killall ssh

#eg：备份单个数据库
ssh-backup-db -so '-J kunming' -lo '-h127.0.0.1 -P4306 -uroot -p'"$MySQLROOTPWD" --prefix "$SQLPREFIX" $DBHost <<<"$DBName"

#eg：备份多个数据库：
#ssh-backup-db -so '-J kunming' -lo '-h127.0.0.1 -P4306 -uroot -p'"$MySQLROOTPWD"  --prefix "$SQLPREFIX" $DBHost <<<"0"
#mysql-list-db -h127.0.0.1 -P4306 -uroot -p${MySQLROOTPWD}
#for db in ${DBNames[@]};
#do
#	mysql-backup-db -h127.0.0.1 -P4306 -uroot -p${MySQLROOTPWD} <<<"$db"
#done

#killall ssh

echo "终止隧道进程..."
#findport 4306 <<<"yes"
[ ! -z "$RemoteIP" ] && findremoteip $RemoteIP ssh <<<"yes"

echo "Gzip 压缩SQL文件..."
gzip *.sql

echo "Execute All Backup Task Done..."

popd &>/dev/null