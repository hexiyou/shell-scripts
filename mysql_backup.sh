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
		IFS=$OLD_IFS
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
	if [ $# -gt 0 ];then
		command="/usr/bin/mysql $@ -e 'show databases;'"
	else
		command="mysql $mysqlOptions -e 'show databases;'"
	fi
	echo "$command"
	eval $command
	#echo "eval退出状态：$?"
	return $?
}

mysql-backup-db() {
	#调用mysqldump按数据库名称备份单个数据库到SQL文件，有别于mysql-backup-all-db
	#注意使用此函数传递MySQL参数时不要将参数选项名与选项值分开（eg:指定mysql用户只能写作 -uroot，不能写作 -u root）
	# -----------------------------
	# eg：
	# -参数指定数据库直接备份： mysql-backup-db huicmf_webman
	# -指定数据库名称的同时指定MySQL参数选项：mysql-backup-db -h127.0.0.1 -uroot -proot huicmf_webman
	# -----------------------------
	# 交互式选择要导出的数据库：
	#  mysql-backup-db   OR    mysql-backup-db -h127.0.0.1 -uroot -proot
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
	print_color "数据库 $dbName 导出完成！"
	print_color 33 "All things Done..."
}
alias mysql-export-db='mysql-backup-db'

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
		print_color "数据库 $db 导出完成！"
	done
	print_color 33 "All things Done..."
	[ -f "$dbListTmpFile" ] && rm -f "$dbListTmpFile"
}