#!/bin/bash
lftp-proxy() {
	# 使用代理调用lftp命令
	# 经测试，此处lftp仅支持HTTP代理，socks代理Cygwin下测试无效，Linux系统未知
	# 没有设置代理则提示信息：
	if [ -z "${LFTPPROXYOPTS}" ];
	then
		echo -e "Notice：当前未设置代理！"
		/usr/bin/lftp $@
		return
	fi
	local opts=$(echo "${LFTPPROXYOPTS}"|tr -d ';')
	if [ $# -eq 0 ];
	then
		echo -e "缺少站点连接地址，代理配置可能无法使用！"
		echo -e "请率先指定FTP服务器后本函数代理设置指令(${opts})方可生效!"
		echo -e "用户名和密码可在后续交互中使用 user xxxx password 指定..."
		echo -e "Example："
		echo -e "\tlftpp ftp.xxx.com"
		echo -e "\tlftpp -p 2121 ftp.xxx.com"
		echo -e "\tlftpp -u user,password -p 2121 ftp.xxx.com"
	fi
	#http_proxy="" https_proxy="" /usr/bin/lftp -e "${opts}" $@
	# 特别注意，连接时必须使用站点地址作为后续参数，最少一个参数，否则代理设置无法生效，
	# 会报错：【不支持的操作: 400 Invalid request received from client (GET)】
	# 即最短命令必须形似：lftpp ftp.xxx.com
	/usr/bin/lftp -e "${opts}" $@
}
alias lftpp=lftp-proxy