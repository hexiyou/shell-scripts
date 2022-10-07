mysql-import-db() {
	#恢复备份：导入SQL文件到MySQL服务器（导入单个数据库）；
	local mysqlOptions="-h127.0.0.1 -uroot -proot"
	local options=( )
	local dbName
	local sqlFile
	local forceImport  #不询问覆盖与否，直接导入
	
	_print_usage() {
		echo -e "mysql-import-db|mysql-restore-db：\n\t还原MySQL数据库：导入SQL文件到某个数据库（可参数指定目标数据库和SQL文件，也可交互式选择）；"
		echo -e "\t注意：传递mysql参数选项时，选项名与选项值不可分开，eg：指定用户名用\`-uroot\`而不可用\`-u root\`；"
		echo -e "\t指定\`--yes\`参数导入时不进行询问，直接导入文件强制覆盖数据；"
		echo -e "\nUsage：\n\tmysql-import-db [mysql~commandline~options...] [-D/--db dbname]|[dbname] [-f sqlfile]|[sqlfile] [--yes]"
		echo -e "\nExample：\n\tmysql-import-db"
		echo -e "\tmysql-import-db example_db"
		echo -e "\tmysql-import-db example_db export_0011.sql"
		echo -e "\tmysql-import-db example_db export_0011.sql --yes"
		echo -e "\tmysql-import-db -D example_db"
		echo -e "\tmysql-import-db --db example_db -f export_0011.sql"
		echo -e "\tmysql-import-db -h127.0.0.1 -P3307 -uroot -proot"
		echo -e "\tmysql-import-db -h127.0.0.1 -uroot -proot example_db"
		echo -e "\tmysql-import-db -h127.0.0.1 -uroot -proot example_db export_0011.sql"
	}
	
	if [[ "${*,,}" == "-h" || "${*,,}" == "--help" ]];then
		_print_usage && return
	fi

	while [ $# -gt 0 ];  #以下参数选项判断条件需注意顺序
	do	
		if [[ "$1" == "-D" || "$1" == "--db" ]];then #可-D/--db指定目标数据库名称
			dbName="$2"
			shift 2
		elif [[ "$1" == "-f" ]];then #可-f指定导入的sql文件名称
			sqlFile="$2"
			shift 2
		elif [[ "${1,,}" == "--yes" ]];then #是否不询问，强制导入文件
			forceImport="yes"
			shift 1
		elif [[ "$1" =~ ^\- ]];then #以短横线开头的参数视为MySQL命令行选项
			options=(${options[@]} "$1")
			shift
		elif [ -z "$dbName" ];then #第一个非短横线开头的参数作为数据库名
			dbName="$1" && shift
		elif [ -z "$sqlFile" ];then #第二个非短横线开头的参数作为SQL文件名或文件路径
			sqlFile="$1" && shift
		else
			shift
		fi
	done
	#子函数：创建MySQL数据库
	_mysql_create_database() {
		#$1 --> 数据库名称；$* -->其他mysql选项
		local db="$1" && shift
		/usr/bin/mysql "$@" -e "create database ${db};"
	}
	[ ! -z "${options[*]}" ] && mysqlOptions="${options[*]}"
	if [ -z "$dbName" ];then #参数没有指定数据库名称，则提供交互式选择！
		local selectDB
		local dbList=$(mysql-list-db $mysqlOptions||echo "-1") #查询失败返回-1
		[ "$(echo "$dbList"|tail -n 1)" = "-1" ] && print_color 9 "获取数据库列表失败，请检查MySQL连接参数（服务器地址、用户名、密码等）是否正确！" && return
		dbList=$(echo "$dbList"|sed '1,2d')
		print_color 3 "请选择要恢复的数据库："
		echo "$dbList"|awk '{print NR")："$0}'
		while [ -z "$selectDB" ];
		do
			read -p "输入序号选择（输入 0 或 q 退出操作，p/l 再次打印数据库清单）："$'\n'"你也可以直接输入数据库名称创建新数据库：" selectDB
			if [ -z "$selectDB" ];then
				continue
			elif [[ "${selectDB,,}" == "0" || "${selectDB,,}" == "q" ]];then
				print_color 40 "退出操作..."
				return
			elif [[ "${selectDB,,}" == "p" || "${selectDB,,}" == "l" ]];then #再次打印数据库列表
				echo "$dbList"|awk '{print NR")："$0}'
				selectDB="" && continue
			fi
			expr "$selectDB" + 0 &>/dev/null
			if [ $? -eq 0 ];then #如果输入的是纯数字
				dbName=$(echo "$dbList"|awk 'NR=='"${selectDB}"'{print $0;exit}' 2>/dev/null||selectDB="")
				[ -z "$dbName" ] && print_color 40 "无效选择！" && selectDB=""
			else #非纯数字则代表需按输入参数为名称创建新数据库
				print_color 40 "创建数据库：$selectDB ..."
				dbName="$selectDB"
				_mysql_create_database "$dbName" ${mysqlOptions[*]}
				[ $? -ne 0 ] && {
					print_color 9 "错误：创建数据库 $dbName 失败！"
					dbName=""
				}
			fi
		done
	fi
	print_color 3 "目标数据库: => $dbName"
	if [ -z "$sqlFile" ];then #参数没有指定SQL文件名称，则提供交互式选择！
		local selectSQL
		local sqlFileList=$(ls *.{sql,.sql.gz} 2>/dev/null) #获取当前目录下所有的sql文件
		local sqlPromptText="输入序号选择（输入 0 或 q 退出操作，p/l 再次打印文件清单）："$'\n'"你也可以直接指定SQL文件名称或文件绝对路径："
		if [ ! -z "$sqlFileList" ];then
			print_color 3 "请选择要导入的SQL文件："
			echo "$sqlFileList"|awk '{print NR")："$0}'
		else
			sqlPromptText="请指定要导入SQL文件名(当前工作目录)或文件绝对路径（输入 0 或 q 退出操作）："
		fi
		while [ -z "$selectSQL" ];
		do
			read -p "$sqlPromptText" selectSQL
			if [ -z "$selectSQL" ];then
				continue
			elif [[ "${selectSQL,,}" == "0" || "${selectSQL,,}" == "q" ]];then
				print_color 40 "退出操作..."
				return
			elif [[ "${selectSQL,,}" == "p" || "${selectSQL,,}" == "l" ]];then #再次打印SQL文件列表
				if [ -z "$sqlFileList" ];then
					print_color 40 "没有可用的SQL文件，请直接指定SQL文件的绝对路径！"
				else
					echo "$sqlFileList"|awk '{print NR")："$0}'
				fi
				selectSQL="" && continue
			fi
			expr "$selectSQL" + 0 &>/dev/null
			if [ $? -eq 0 ];then  #如果输入的是纯数字
				sqlFile=$(echo "$sqlFileList"|awk 'NR=='"${selectSQL}"'{print $0;exit}' 2>/dev/null||selectSQL="")
				[ -z "$sqlFile" ] && print_color 40 "无效选择！" && selectSQL=""
			else  #非纯数字则代表指定了SQL文件的位置；
				print_color "指定SQL文件：$selectSQL ..."
				if [ ! -f "$selectSQL" ];then
					print_color 9 "错误：文件 $selectSQL 不存在！"
				else
					sqlFile="$selectSQL"
				fi
			fi
		done
	fi
	print_color 40 "执行导入：导入 $(cygpath -aw $sqlFile) 到 $dbName ..."
	[ -z "$forceImport" ] && read -p "是否确认导入（原有数据将被覆盖）[y/yes OR n](默认为n)？" confirmImport
	if [[ "$forceImport" == "yes" || "${confirmImport,,}" == "yes" || "${confirmImport,,}" == "y" ]];then
		sqlFile=$(cygpath -au "$sqlFile")
		print_color "导入数据，请稍等......"
		eval mysql ${mysqlOptions[*]} "$dbName" <$sqlFile
		if [ $? -eq 0 ];then
			print_color 33 "$dbName 数据库导入成功！"
		else
			print_color 9 "错误：数据导入失败！$dbName <== $sqlFile"
		fi
	else
		print_color 40 "取消导入..."
	fi
}
alias mysql-restore-db='mysql-import-db --yes'
alias mysql-import-db2='mysql-import-db --yes' #不提示覆盖与否，直接导入

mysql-import-all-db() {
	#恢复备份：导入所有（多个）SQL备份文件到MySQL
	echo "TODO ..."
	return
}

mysqlimport() {
	#劫持mysqlimport命令；
	#See Also：https://www.runoob.com/mysql/mysql-database-import.html
	# eg：
	# mysqlimport -u root -p --local mytbl dump.txt
	# mysqlimport -u root -p --local --fields-terminated-by=":" \
	#	--lines-terminated-by="\r\n"  mytbl dump.txt
	# mysqlimport -u root -p --local --columns=b,c,a \
    #	mytbl dump.txt
	/usr/bin/mysqlimport "$@"
}