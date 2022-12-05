#!/usr/bin/env bash

#检查OpenWrt由于 AdGuardHome等广告过滤插件带来的问题（表现：通常对HTTPS无影响，但会阻断http连接）

[ -f /v/bin/aliaswinapp ] && source /v/bin/aliaswinapp

[ -z "$(type -t print_color)" ] && print_color() {
		[ $# -gt 1 ] && shift
		echo -e "$*"
	}
	
#curl() {
#	#统计设置UserAgent
#	\\curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -v "$@"
#}

successCount=0
failureCount=0

echo -e "\n检查网易163HTTP..."
url="http://www.163.com/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查网易图片资源HTTP..."
url="http://cms-bucket.ws.126.net/2022/1204/24deb860p00rmcdi7000nc000s600e3c.png?imageView&thumbnail=185y116&quality=100&quality=100"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查搜狐门户HTTP..."
url="http://www.sohu.com/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}

echo -e "\n检查搜狐博客HTTP..."
url="http://r1.suc.itc.cn/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查搜狐博客图片资源HTTP..."
url="http://i2.itc.cn/20170621/a75_59713a26_c0d6_13c5_3afb_4e12bda9f752_1.jpg"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查搜狐视频栏目页HTTP..."
url="http://tv.sohu.com/s2019/dashjs2019/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}

echo -e "\n检查新浪体育HTTP..."
url="http://sports.sina.com.cn/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查新浪帮助图片资源HTTP..."
## 浏览器查看：http://help.sina.com.cn/
url="http://n.sinaimg.cn/customer/260/w1280h580/20200901/cccf-iypetiv2384303.png"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查爱奇艺首页HTTP..."
url="http://www.iqiyi.com/"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查爱奇艺在线客服HTTP..."
url="http://cserver.iqiyi.com/index?e=1"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查爱奇艺登录HTTP..."
url="http://www.iqiyi.com/iframe/loginreg?show_back=1&redirect_url=https%3A%2F%2Fcserver.iqiyi.com%2Fchat.html%3Fentry%3Dpc-zh%26e%3D1&__PHP=1&from_url=https%3A%2F%2Fcserver.iqiyi.com%2Fchat.html%3Fentry%3Dpc-zh%26e%3D1"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


echo -e "\n检查百度贴吧HTTP..."
url="http://tieba.baidu.com/p/8170405143?frwh=index"
echo "test URL：$url"
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" -sSI --connect-timeout 3 "$url"
[ $? -eq 0 ] && {
	print_color "33" "OK!" && let successCount+=1
	} || { 
	print_color 9 "Failure..." && let failureCount+=1
}


print_color 40 "成功次数："
echo "$successCount"
print_color 40 "失败次数："
echo "$failureCount"
