mysql() {
	# mysql同名Hook命令，在Laravel项目根目录时，自动读取.env配置文件中MySQL账密配置信息连接数据库；
	# 在非Laravel环境下则尝试使用默认用户名和密码连接本地MySQL主机；
	# MySQL 8.0 Release Note：https://dev.mysql.com/doc/relnotes/mysql/8.0/en/
	# MySQL 5.7 Release Note：https://dev.mysql.com/doc/relnotes/mysql/5.7/en/
	# MySQL 5.6 Release Note：https://dev.mysql.com/doc/relnotes/mysql/5.6/en/
	if [ $# -ne 0 ];then
		OLD_IFS=$IFS
		IFS=$(echo -e "\n") #兼容参数值带空格的情况：eg：mysql -h127.0.0.1 -uroot -proot -e 'show databases;'
		/usr/bin/mysql $@
		local ret=$?
		IFS=$OLD_IFS
		return $ret
	elif [ -f ./composer.json -a -f ./.env ];then #判断是否在Laravel项目的根目录路径下
		local dbHost=$(cat .env|awk -F '=' '/DB_HOST/{gsub(" ","");print $2;exit}')
		local dbPort=$(cat .env|awk -F '=' '/DB_PORT/{gsub(" ","");print $2;exit}')
		local dbName=$(cat .env|awk -F '=' '/DB_DATABASE/{gsub(" ","");print $2;exit}')
		local dbUser=$(cat .env|awk -F '=' '/DB_USERNAME/{gsub(" ","");print $2;exit}')
		local dbPasswd=$(cat .env|awk -F '=' '/DB_PASSWORD/{gsub(" ","");print $2;exit}')
		print_color 40 "/usr/bin/mysql -h${dbHost} -P${dbPort} -u${dbUser} -p${dbPasswd} -D ${dbName} -A"
		/usr/bin/mysql -h${dbHost} -P${dbPort} -u${dbUser} -p${dbPasswd} -D ${dbName} -A
		return
	else
		/usr/bin/mysql -h127.0.0.1 -uroot -proot
	fi
}

mysql-list-db() {
	#列出数据库：查看指定的MySQL服务器端有哪些数据库
	local mysqlOptions="-h127.0.0.1 -uroot -proot"
	local command
	local options=( )
	local noBanner
	local retList
	local retCode=0
	while [ $# -gt 0 ];
	do
		if [ "${1,,}" == "--nobanner" ];then
			noBanner="1"
		else
			options=(${options[@]} "$1")
		fi
		shift
	done
	set -- "${options[@]}"
	if [ $# -gt 0 ];then
		command="/usr/bin/mysql $@ -e 'show databases;'"
	else
		command="mysql $mysqlOptions -e 'show databases;'"
	fi
	echo "$command"
	if [ -z "$noBanner" ];then
		eval $command 
		retCode=$?
	else
		retList=$(eval "$command" 2>/dev/tty)
		[ -z "$retList" ] && return 2
		echo "$retList"|sed '1d'
	fi
	#echo "eval退出状态：$retCode"
	return $retCode
}

_mysql-backup-db() {
	#调用mysqldump按数据库名称备份单个数据库到SQL文件，有别于mysql-backup-all-db
	#注意使用此函数传递MySQL参数时不要将参数选项名与选项值分开（eg:指定mysql用户只能写作 -uroot，不能写作 -u root）
	# -----------------------------
	# eg：
	# -参数指定数据库直接备份： mysql-backup-db huicmf_webman
	# -指定数据库名称的同时指定MySQL参数选项：mysql-backup-db -h127.0.0.1 -uroot -proot huicmf_webman
	# -----------------------------
	# 交互式选择要导出的数据库：
	#  mysql-backup-db   OR    mysql-backup-db -h127.0.0.1 -uroot -proot
	# -----------------------------
	# 如何同时备份多个数据库？
	# eg：
	#  seq 1 1 10|xargs -i mybash --login -c "mysql-backup-db<<<{}"      #依次备份序号1~10的数据库
	#  echo {1,2,3,5,8}|tr ' ' '\n'|xargs -i mybash --login -c "mysql-backup-db<<<{}"      #依次备份序号为1、2、3、5、8的数据库
	#  echo {1,2,3,5,8}|tr ' ' '\n'|xargs -i /bin/env ASMyBash=true bash --login -c 'echo "==>{}"'   #使用原生bash，不使用mybash
	local mysqlOptions="-h127.0.0.1 -uroot -proot"
	local options=( )
	local dbName
	local sqlFilePrefix=""  #导出SQL备份文件名的前缀;eg：localhost_
	local sqlFileName="{prefix}{db}_{datetime}.sql"   #导出SQL文件名的命名格式
	
	if [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo -e "mysql-backup-db|mysql-export-db：\n\t导出某个数据库到SQL备份文件（可参数指定数据库名称或交互式选择）；"
		echo -e "\t注意：传递mysql参数选项时，选项名与选项值不可分开，eg：指定用户名用\`-uroot\`而不可用\`-u root\`；"
		echo -e "\nUsage：\n\tmysql-backup-db [mysqldump~options...] [dbname]"
		echo -e "\nExample：\n\tmysql-backup-db"
		echo -e "\tmysql-backup-db information_schema"
		echo -e "\tmysql-backup-db -h127.0.0.1 -uroot -proot"
		echo -e "\tmysql-backup-db -h127.0.0.1 -uroot -proot information_schema"
		echo -e "\nTips：\t如何同时备份多个数据库？"
		echo -e "    首先：\n\t\`mysql-list-db\` 查看有哪些数据库；\n    再次："
		echo -e "\tseq 1 1 10|xargs -i mybash --login -c \"mysql-backup-db<<<{}\""
		echo -e "\techo {1,2,3,5,8}|tr ' ' '\\\n'|xargs -i mybash --login -c \"mysql-backup-db<<<{}\""
		echo -e "\techo {1..5}|tr ' ' '\\\n'|xargs -i mybash --login -c \"mysql-backup-db<<<{}\""
		echo -e "\techo {1,2,3,5,8}|tr ' ' '\\\n'|xargs -i /bin/env ASMyBash=true bash --login -c \"mysql-backup-db<<<{}\""
		return
	fi

	while [ $# -gt 0 ];
	do	
		if [[ "$1" =~ ^\- ]];then #以短横线开头的参数视为MySQL命令行选项
			options=(${options[@]} "$1")
		else
			dbName="$1"
		fi
		shift
	done
	[ ! -z "${options[*]}" ] && mysqlOptions="${options[*]}"
	#[ -z "$dbName" ] && print_color 40 "请指定要备份的数据库名称！" && return
	if [ -z "$dbName" ];then #参数没有指定数据库名称，则提供交互式选择！
		local selectDB
		local dbList=$(mysql-list-db $mysqlOptions||echo "-1") #查询失败返回-1
		[ "$(echo "$dbList"|tail -n 1)" = "-1" ] && print_color 9 "获取数据库列表失败，请检查MySQL连接参数（服务器地址、用户名、密码等）是否正确！" && return
		dbList=$(echo "$dbList"|sed '1,2d')
		echo "请选择要备份的数据库："
		echo "$dbList"|awk '{print NR")："$0}'
		while [ -z "$selectDB" ];
		do
			read -p "输入序号选择（输入 0 或 q 退出操作，p 再次打印数据库清单）：" selectDB
			if [ -z "$selectDB" ];then
				continue
			elif [[ "${selectDB,,}" == "0" || "${selectDB,,}" == "q" ]];then
				print_color 40 "退出操作..."
				return
			elif [[ "${selectDB,,}" == "p" || "${selectDB,,}" == "l" ]];then #再次打印数据库列表
				echo "$dbList"|awk '{print NR")："$0}'
				selectDB="" && continue
			fi
			dbName=$(echo "$dbList"|awk 'NR=='"${selectDB}"'{print $0;exit}' 2>/dev/null||selectDB="")
			#echo "dbName：$dbName"
			[ -z "$dbName" ] && print_color 40 "无效选择！" && selectDB=""
		done
	fi
	local sqlFile=$(echo "$sqlFileName"|\
	sed -e "s/{prefix}/${sqlFilePrefix}/g" \
		-e "s/{db}/${dbName}/g" \
		-e "s/{datetime}/$(date +'%Y%m%d_%H%M')/g" \
	) #按导出文件名命令规则生成文件名
	echo "备份数据库：$dbName => $sqlFile"
	/usr/bin/mysqldump $mysqlOptions --opt --single-transaction $dbName >$sqlFile
	if [ $? -eq 0 ];then
		print_color "数据库 $dbName 导出完成！"
	else
		print_color 40 "警告：$dbName 导出失败！"
	fi
	print_color 33 "All things Done..."
}
alias mysql-export-db='mysql-backup-db'

_mysql-backup-db-by-name() {
	#调用mysqldump按数据库名称备份单个数据库到SQL文件，有别于mysql-backup-all-db
	#注意使用此函数传递MySQL参数时不要将参数选项名与选项值分开（eg:指定mysql用户只能写作 -uroot，不能写作 -u root）
	# -----------------------------
	# eg：
	# -参数指定数据库直接备份： mysql-backup-db huicmf_webman
	# -指定数据库名称的同时指定MySQL参数选项：mysql-backup-db -h127.0.0.1 -uroot -proot huicmf_webman
	# -----------------------------
	# 交互式选择要导出的数据库：
	#  mysql-backup-db   OR    mysql-backup-db -h127.0.0.1 -uroot -proot
	# -----------------------------
	# 如何通过名称同时备份多个数据库？
	# eg：
	# mysql-backup-db-by-name <dblist.txt
	local mysqlOptions="-h127.0.0.1 -uroot -proot"
	local options=( )
	local dbName
	local sqlFilePrefix=""  #导出SQL备份文件名的前缀;eg：localhost_
	local sqlFileName="{prefix}{db}_{datetime}.sql"   #导出SQL文件名的命名格式
	
	if [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		echo -e "mysql-backup-db-by-name：\n\t导出某个数据库到SQL备份文件（可通过管道导入数据库名称一次性备份多个库）；"
		echo -e "\t注意：传递mysql参数选项时，选项名与选项值不可分开，eg：指定用户名用\`-uroot\`而不可用\`-u root\`；"
		echo -e "\nUsage：\n\tmysql-backup-db-by-name [mysqldump~options...] [dbname]"
		echo -e "\nExample：\n\tmysql-backup-db-by-name"
		echo -e "\tmysql-backup-db-by-name information_schema"
		echo -e "\tmysql-backup-db-by-name -h127.0.0.1 -uroot -proot"
		echo -e "\tmysql-backup-db-by-name -h127.0.0.1 -uroot -proot information_schema"
		echo -e "\nTips：\t已知数据库名称，同时备份多个数据库？"
		echo -e "\t一行一个名称，保存至临时文件或剪贴板，通过命令行管道传递给 \`mysql-backup-db-by-name\` 函数即可；"
		cat <<-'EOF'
`cat>dblist.txt<<EOF`
information_schema
mysql
performance_schema
EOF 
---
`mysql-backup-db-by-name <dblist.txt`
或：
`mysql-backup-db-by-name </dev/clipboard`
EOF
		return
	fi

	while [ $# -gt 0 ];
	do	
		if [[ "$1" =~ ^\- ]];then #以短横线开头的参数视为MySQL命令行选项
			options=(${options[@]} "$1")
		else
			dbName="$1"
		fi
		shift
	done
	[ ! -z "${options[*]}" ] && mysqlOptions="${options[*]}"
	#[ -z "$dbName" ] && print_color 40 "请指定要备份的数据库名称！" && return
	if [ -z "$dbName" ];then #参数没有指定数据库名称，则提供交互式选择！
		local selectDB
		local dbList=$(mysql-list-db $mysqlOptions||echo "-1") #查询失败返回-1
		[ $(echo "$dbList"|tail -n 1) = "-1" ] && print_color 9 "获取数据库列表失败，请检查MySQL连接参数（服务器地址、用户名、密码等）是否正确！" && return
		dbList=$(echo "$dbList"|sed '1,2d')
		if [ -t 0 ];then #无管道数据传入时才显示数据库列表
			echo "当前服务器可用的数据库："
			echo "$dbList"|awk '{print NR")："$0}'
		fi
		while [ -z "$selectDB" ];
		do
			read -p "输入数据库名称(注意：不是序号！)选择（输入 0 或 q 退出操作，p 再次打印数据库清单）：" selectDB
			if [ -z "$selectDB" ];then
				continue
			elif [[ "${selectDB,,}" == "0" || "${selectDB,,}" == "q" ]];then
				print_color 40 "退出操作..."
				return
			elif [[ "${selectDB,,}" == "p" || "${selectDB,,}" == "l" ]];then #再次打印数据库列表
				echo "$dbList"|awk '{print NR")："$0}'
				selectDB="" && continue
			fi
			dbName=$(echo "$dbList"|awk '{if($0=="'"${selectDB,,}"'"){print;exit}}'||selectDB="")
			if [ -z "$dbName" ];then
				print_color 40 "无效选择，数据库 $selectDB 不存在！"
				selectDB=""
				if [ ! -t 0 ];then
					return
				fi
			fi
		done
	fi
	local sqlFile=$(echo "$sqlFileName"|\
	sed -e "s/{prefix}/${sqlFilePrefix}/g" \
		-e "s/{db}/${dbName}/g" \
		-e "s/{datetime}/$(date +'%Y%m%d_%H%M')/g" \
	) #按导出文件名命令规则生成文件名
	echo "备份数据库：$dbName => $sqlFile"
	/usr/bin/mysqldump $mysqlOptions --opt --single-transaction $dbName >$sqlFile
	if [ $? -eq 0 ];then
		print_color "数据库 $dbName 导出完成！"
	else
		print_color 40 "警告：$dbName 导出失败！"
	fi
	print_color 33 "All things Done..."
}
alias mysql-backup-db2='_mysql-backup-db-by-name'

mysql-backup-db() {
	#wrapper函数，自动判断按序号还是按数据库名导出数据库
	if [ -t 0 ];then
		_mysql-backup-db $@
	else #有管道数据传入
		local stdin=$(cat)
		expr $stdin + 0 &>/dev/null
		if [ $? -eq 0 ];then
			_mysql-backup-db $@ </dev/stdin   #按序号备份文件夹
		else
			#_mysql-backup-db-by-name $@ </dev/stdin #按数据库名称备份文件夹
			for db in `echo "$stdin"|dos2unix -q|tr -d ' '`; #兼容性处理
			do
				_mysql-backup-db-by-name $@ <<<"$db"
			done
		fi
	fi
}

mysql-backup-all-db() {
	#调用mysqldump按数据库名称依次备份所有数据库到SQL文件
	local defaultDB=$(cat <<'EOF'
information_schema
mysql
performance_schema
sys
EOF
) #MySQL默认自带的数据库，无需备份
	local mysqlOptions="-h127.0.0.1 -uroot -proot"
	local sqlFilePrefix=""  #导出SQL备份文件名的前缀;eg：localhost_
	local sqlFileName="{prefix}{db}_{datetime}.sql"   #导出SQL文件名的命名格式
	local dbList
	local availableDB
	local failureDB=( )  #导出失败的数据库
	local dbListTmpFile
	if [ $# -gt 0 ];then
		mysqlOptions="$*"
		dbList=$(/usr/bin/mysql "$@" -e 'show databases;' 2>/dev/null|tee|sed '1d')
	else
		dbList=$(mysql $mysqlOptions -e 'show databases;' 2>/dev/null|tee|sed '1d')
	fi
	if [ -z "$dbList" ];then
		print_color 40 "连接MySQL服务器失败，可能是服务器地址错误或用户名密码无效，请检查！"
		return
	fi
	dbListTmpFile=$(mktemp)
	cat >$dbListTmpFile<<<"$dbList"
	availableDB=$(echo "$defaultDB"|grep -vwf - $dbListTmpFile) #借助grep排除MySQL默认数据库，获取需要备份的所有数据库名称
	print_color 40 "需要备份的数据库："
	echo -e "${availableDB}\n---------"
	print_color 40 "开始依次备份数据库："
	for db in `echo "${availableDB}"`;
	do
		local sqlFile=$(echo "$sqlFileName"|\
		sed -e "s/{prefix}/${sqlFilePrefix}/g" \
			-e "s/{db}/${db}/g" \
			-e "s/{datetime}/$(date +'%Y%m%d_%H%M')/g" \
		) #按导出文件名命令规则生成文件名
		echo "备份数据库：$db => $sqlFile"
		/usr/bin/mysqldump $mysqlOptions --opt --single-transaction $db >$sqlFile
		if [ $? -eq 0 ];then
			print_color "数据库 $db 导出完成！"
		else
			print_color 40 "数据库 $db 导出失败 ..."
			failureDB=(${failureDB[@]} "$db")
		fi
	done
	print_color 33 "All things Done..."
	if [ ! -z "${failureDB[*]}" ];then
		print_color 40 "警告：以下 ${#failureDB[*]} 个数据库导出失败："
		echo "${failureDB[@]}"|tr ' ' '\n'
	fi
	[ -f "$dbListTmpFile" ] && rm -f "$dbListTmpFile"
}

mysql-import-all-db() {
	#导入所有（多个）SQL备份文件到MySQL
	echo "TODO ..."
	return
}

_get_unix_pid_by_port() {
	#通过监听端口，获取相关联的unix进程pid，Windows pid转Unix pid
	# $1 ---> 要查询的端口号；$2 [--full] 是否返回Cygwin完整进程信息
	local port="$1"
	[ -z "$1" ] && echo "缺少参数 \$1,请传递要查询的端口号！" && return
	local psInfo=$(cmd /c netstat -ano -p TCP|dos2unix -q|grep -E ":${port}\b"|grep 'LISTENING')
	if [ -z "$psInfo" ];then
		#echo "没有相关进程！"
		return 1
	fi
	local winPid=$(echo "$psInfo"|awk '{print $NF;exit}')
	#echo "winPid：$winPid"
	local unixPs=$(ps -ae|grep -E "\b${winPid}\b")
	if [ -z "$unixPs" ];then
		#echo "已找到 port：$port 相关进程，但该进程不是Cygwin进程！"
		return 2
	fi
	if [[ "${2,,}" == "--full" ]];then #$2指定参数--full时，返回完整的进程信息，而不是pid
		echo "$unixPs"
		return 0
	fi
	local pid=$(echo "$unixPs"|awk '{if($4=='"${winPid}"'){print $1;exit}}')
	echo "$pid"
}

mysql-backup-db-via-ssh() {
	#通过SSH隧道备份服务器上MySQL某个数据库
	#默认映射服务器3306端口到本地4306端口，mysql直接连接127.0.0.1:4306即可；
	#------------------------------------------
	# $1 ---> 要连接的主机名称（在~/.ssh/config中事先配置）
	# $2...$n 其余为MySQL用的选项参数，传递给mysql-backup-db函数
	
	local targetHost         #第一个非短横线（-）开始的参数视为目标主机
	local dbName	         #第二个非短横线（-）开始的参数视为数据库名称
	local localAddr="127.0.0.1" #绑定的本地地址。默认127.0.0.1，若要局域网可访问，可设置绑定地址为0.0.0.0
	local localPort=4306   #MySQL映射到本地要使用的本地端口
	local remotePort=3306  #MySQL服务器的远程端口
	local sshOptions=""    #连接SSH服务器使用的选项，传递给/usr/bin/ssh，默认为空
	local newSshTunnel=1    #是否创建新的SSH隧道（记录已有占用端口SSH隧道的操作）
	local sshOnly=0    #是否仅创建SSH隧道端口映射，不进行数据库备份;0-否、1-是
	local killSshPS=0      #备份完毕是否杀死SSH隧道进程，0-保留，1-杀死
	local localMysqlOptions="-h127.0.0.1 -P4306 -uroot -p"  #连接本地MySQL端口使用参数
	
	_print_usage() {
		echo -e "mysql-backup-db-via-ssh：\n\t连接远程服务器，通过SSH隧道映射远程MySQL端口到本机端口，并备份（导出）某个数据库到SQL文件；"
		echo -e "\t默认隧道仅绑定127.0.0.1，仅可本机访问，局域网、外网不可访问，如需允许它机访问，请使用 \`-b\` 参数（eg：\`-b 0.0.0.0\`）；"
		echo -e "\t注意：传递mysql参数选项时，选项名与选项值不可分开，eg：指定用户名用\`-uroot\`而不可用\`-u root\`；"
		echo -e "\nUsage：\n\tmysql-backup-db-via-ssh [-p localport] [-rp remoteport] [-b local~bind-address] [-so ssh~options] [-lo local~mysql~options] *targethost [dbname]\n"
		echo -e "--------------------------------------------------------------"
		echo -e "\t-p       指定映射到本地使用的端口，（连接MySQL时，使用127.0.0.1：port）；"
		echo -e "\t-rp      指定远程主机MySQL端口，（默认3306，如果MySQL服务更改了端口则需要指定此参数）；"
		echo -e "\t-b       本地绑定的网卡接口，（默认127.0.0.1）；"
		echo -e "\t-so      传递给ssh命令的选项参数，请用引号包裹完整的参数值：eg：-so '-J vps1'（更多参数说明请查询ssh手册\`man ssh\`）；"
		echo -e "\t-lo|-mo  传递给mysql命令的选项参数，用于指定连接本地所用的MySQL主机地址、用户名、密码等信息，会替换localMysqlOptions变量，端口信息（-P）自动维护，无需填写；"
		echo -e "\t--kill   备份完成后，是否杀死SSH隧道进程（默认不终结进程）；"
		echo -e "\t--sshonly 仅为MySQL创建本地端口映射（SSH隧道），不进行数据库备份；"
		echo -e "\t*targetHost 【必需】要连接的主机名称，在~/.ssh/config中配置，也可以使用临时主机形式 \`root@192.168.1.100\`"
		echo -e "\tdbName  【可选】要备份的数据库名称，缺省时可输入序号进行交互式选择；"
		echo -e "--------------------------------------------------------------"
		echo -e "\nExample：\n\tmysql-backup-db-via-ssh kunming"
		echo -e "\tmysql-backup-db-via-ssh kunming wordpress"
		echo -e "\tmysql-backup-db-via-ssh -so '-J honkongvps' kunming wordpress"
		echo -e "\tmysql-backup-db-via-ssh -lo '-h127.0.0.1 -uroot -proot' kunming"
		echo -e "\tmysql-backup-db-via-ssh -p 4306 -lo '-h127.0.0.1 -uroot -proot' kunming"
		echo -e "\tmysql-backup-db-via-ssh -p 4306 -rp 3307 -lo '-h127.0.0.1 -uroot -proot' kunming information_schema"		
	}
	
	if [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then	
		_print_usage && return
	fi
	
	while [ $# -gt 0 ];
	do
		if [[ "$1" == "-p" ]];then #是否指定了本地端口
			localPort=$2
			shift 2
		elif [[ "$1" == "-rp" ]];then #是否指定了远程端口
			remotePort="$2"
			shift 2
		elif [[ "$1" == "-b" ]];then #是否指定了本地绑定地址
			localAddr="$2"
			shift 2
		elif [[ "$1" == "-lo" || "$1" == "-mo" ]];then #是否本地MySQL选项（lo==local option|mo == mysql option）
			localMysqlOptions="$2"
			shift 2
		elif [[ "$1" == "-so" ]];then #是否有SSH选项（so==ssh option）
			sshOptions="$2"
			shift 2
		elif [[ "$1" == "--killssh" ]];then #是否杀死SSH隧道进程
			killSshPS=1
			shift 1
		elif [[ "$1" == "--sshonly" ]];then #是否仅创建SSH隧道
			sshOnly=1
			shift 1
		fi
		if [[ ! "$1" =~ ^\- ]];then #处理非短横线-开头的参数；
			if [ -z "$targetHost" ];then
				targetHost="$1"
			elif [ -z "$dbName" ];then
				dbName="$1"
			else
				break #如果还有多余的参数，丢掉，暂时用不到
			fi
			shift 1
		fi
	done
	
	[ -z "$targetHost" ] && print_color 40 "请指定要连接的主机名！" && _print_usage && return
	while :;
	do
		#检测本地端口是否已经被占用！
		/usr/bin/nc -w 2 -v 127.0.0.1 $localPort &>/dev/null
		if [ $? -eq 0 ];then   #本地端口被占用，按情况区分是ssh进程占用，还是其他进程占用;
			local localPortInfo=$(_get_unix_pid_by_port $localPort --full 2>/dev/null)
			if [ -z "$localPortInfo" ];then #Windows进程端口占用
				echo "$localPort端口被其他Windows进程（非Cygwin进程）占用！自动更换其他端口！"
				let localPort+=1 
				print_color "localPort ==> $localPort"
				continue
			else  #有其他Cygwin进程占用端口的情况
				echo "$localPortInfo"
				echo "$localPortInfo"|grep -iE 'ssh\b' &>/dev/null
				if [ $? -eq 0 ];then
					print_color 40 "已有占用端口的SSH隧道存在！"
					read -p "是否杀死隧道进程或跳过SSH连接（使用已有的SSH隧道）？Kill/continue/quit（k/c/q，默认c）" operateTunnel
					if [[ "${operateTunnel,,}" == "quit" || "${operateTunnel,,}" == "q" ]];then
						print_color 40 "退出操作..."
						return
					elif [[ "${operateTunnel,,}" == "kill" || "${operateTunnel,,}" == "k" ]];then
						local pid=$(_get_unix_pid_by_port $localPort)
						print_color 40 "终止进程 pid：$pid ..."
						kill -9 $pid
						break
					else
						newSshTunnel=0
						break
					fi
				else
					print_color 40 "$localPort端口被Cygwin进程占用，自动更换端口号！"
					let localPort+=1 
					print_color "localPort ==> $localPort"
					continue
				fi
			fi
			return
		fi
		break
	done
	if [ $newSshTunnel -eq 1 ];then
		print_color 40 "连接到 $targetHost，并创建SSH隧道..."
		#echo /usr/bin/ssh $sshOptions -C -N -f -g -L $localAddr:$localPort:127.0.0.1:$remotePort $targetHost #127.0.0.1仅绑定本地网口，禁止局域网或外网访问
		sshCommand="/usr/bin/ssh $sshOptions -C -N -f -g -L $localAddr:$localPort:127.0.0.1:$remotePort $targetHost"
		#echo "$sshCommand"
		
		#使用eval可在命令字符串中包含函数名并调用（比如，运行ssh、ssh2函数，而非ssh原生命令）#
		#Bug：但使用eval会导致_get_unix_pid_by_port取不到进程号，取到的可能是已销毁的eval本身的进程！
		#eval $sshCommand 
		
		$sshCommand 
		/usr/bin/nc -w 3 -v 127.0.0.1 $localPort &>/dev/null
		if [ $? -ne 0 ];then
			print_color 9 "本地端口测试失败，可能是SSH没有登录成功，请检查！"
			return
		fi
	fi
	localMysqlOptions=$(echo "$localMysqlOptions"|sed -r 's/\-P[^ ]+ /-P'"${localPort}"' /')    #防止端口占用时，动态切换端口后，端口号不对
	if [ $sshOnly -eq 1 ];then
		print_color 40 "MySQL服务本地SSH隧道已创建，请使用以下参数进行连接："
		echo "mysql $localMysqlOptions"
		echo "mysqldump --opt --single-transaction -A $localMysqlOptions"
		return
	fi
	print_color 40 "连接本地MySQL端口备份数据..."
	if [ -t 0 ];then
		mysql-backup-db $localMysqlOptions
	else #有管道数据输入
		mysql-backup-db $localMysqlOptions </dev/stdin
	fi
	[ $killSshPS -eq 1 ] && {
		killall ssh  #TODO：由于目前进程号取不准，默认杀死所有ssh进程！
	}
}
alias ssh-backup-db='mysql-backup-db-via-ssh'
alias ssh-export-db='mysql-backup-db-via-ssh'