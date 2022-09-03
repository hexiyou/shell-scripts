wmysql() {
	#在mintty中使用Windows版MySQL的命令行链接Windows MySQL主机
	#需要此函数原因是使用Cygwin版本的mysql连接到Windows mysqld后无法输入和粘贴中文；
	local apppath="D:\UPUPW_ANK_W64\Modules\MySQL\bin\mysql.exe"
	[ ! -z "$MYSQLBIN" ] && apppath="$MYSQLBIN"  ## 环境变量存在值则使用环境变量作为mysql.exe路径
	if [ -e "${apppath}" ];then
		#`cygpath -au "$apppath"` $@
		`cygpath -au "$apppath"` --default-character-set=utf8mb4 $@	
	else
		local MySQLDBIN=$(wmicps mysqld.exe 2>/dev/null|dos2unix -q|iconv -f GBK -t utf-8|awk -F '=' '/ExecutablePath=/{sub($1"=","");print $0;exit;}')
		if [ -e "$MySQLDBIN" ];then
			`cygpath -au "${MySQLDBIN/mysqld.exe/mysql.exe}"` $@
			return
		fi
		echo -e "program not found!\npath：${apppath//\\/\\\\} "
	fi
}
alias wmysql2='wmysql -h127.0.0.1 -uroot -proot'
alias wmysqluser='wmysql2'