sshlocalnetwork() {
	#交互式选择要创建供服务器使用的本地网络代理隧道
	local cmdOptions=$(cat<<'EOF'
echo "这是一串供evel测试的命令"                 #测试
sshlocalnetworktunnel 127.0.0.1:1080 $@         #本地xxx网络端口
sshlocalnetworktunnel 10.10.10.254:1081 $@      #openWrt SOCKS端口
sshlocalnetworktunnel 10.10.10.254:8121 $@      #openWrt HTTP端口
EOF
)
	echo "$cmdOptions"|awk '{print NR" )："$0}'
	while :;
	do
		read -p "请输入序号选择要创建的网络代理隧道（ 0 或 q 退出操作）：" chooseCmd
		if [[ "${chooseCmd,,}" == "0" || "${chooseCmd,,}" == "q" ]];then
			print_color 40 "退出操作..."
			return
		elif [ -z "$chooseCmd" ];then
			print_color 40 "选择为空，请重新选择..."
		else
			local prepareCommand=$(echo "$cmdOptions"|awk 'NR=='${chooseCmd}'{print;exit}' 2>/dev/null)
			[ -z "$prepareCommand" ] && print_color 40 "选择无效，请重新选择...." || break
		fi
	done
	prepareCommand=$(echo "$prepareCommand"|tr -s '[\t ]') #缩减重叠的多个空格或Tab为一个

	if [[ "$prepareCommand" =~ '$@' ]];then
		if [ $# -eq 0 ];then #运行函数没有传递后续参数则提示输入
			read -p "请为命令 “${prepareCommand%%\$*}” 输入后续参数："$'\n倘若无须参数请直接回车：' additionalParams
			set -- "$additionalParams"
		fi
		prepareCommand="${prepareCommand/\$@/$@}"
	fi
	print_color 40 "执行命令 \`${prepareCommand%%#*}\` ..."
	local stdoutTmp=$(mktemp)
	#local responseStdOut=$(eval $prepareCommand 2>&1|tee /dev/tty)
	local responseStdOut=$(eval $prepareCommand 2>$stdoutTmp|tee /dev/tty)

	if [[ "$prepareCommand" =~ "sshlocalnetwork" ]];then
		#echo "获取Port"
		local remotePort=$(cat $stdoutTmp|tee /dev/tty|awk '/Updating allowed port/{print $5;exit}')
		#echo "$remotePort"
		[ -f $stdoutTmp ] && rm -f $stdoutTmp
		local tipHeader=$'\033[40;33m请在服务器端使用以下命令导出环境变量以使用代理：\033[0m'
		cat <<EOF
============
$tipHeader
export http_proxy=127.0.0.1:$remotePort
export https_proxy=127.0.0.1:$remotePort
export all_proxy=127.0.0.1:$remotePort
EOF
	fi
}
alias server-proxy='sshlocalnetwork'
alias server-proxy-racknerd='sshlocalnetwork racknerd' #创建本地网络到Racknerd VPS的代理隧道
alias server-proxy-tencent='sshlocalnetwork tencent' #创建本地网络到腾讯云 VPS的代理隧道