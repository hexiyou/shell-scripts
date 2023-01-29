#!/bin/sh
#一键控制向日葵开机智能插座
#博客文章介绍：https://www.cnblogs.com/cnhack/p/17073052.html

SCRIPTPATH="$(dirname $0)"

requestTimeOut=3   #请求超时时间（单位：秒）

controlHostURL="http://192.168.1.105:6767"    #发送的主机地址，可抓包获取，也可以指定插座联网的局域网IP地址，端口通常为6767
controlTime="01270152"    #接收端需要的参数time，可抓包获取
controlKey="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"   #接收端需要的参数key，可抓包获取


statusUrl="${controlHostURL}/plug?_api=get_plug_status&index=0&time=${controlTime}&key=${controlKey}"
cntdownUrl="${controlHostURL}/plug?_api=plug_cntdown_get&time=${controlTime}&key=${controlKey}&index=0"
checkVersionUrl="${controlHostURL}/plug?key=${controlKey}&_api=get_plug_version&time=${controlTime}"
electricUrl="${controlHostURL}/plug?key=${controlKey}&_api=get_plug_electric&time=${controlTime}"
powerOnUrl="${controlHostURL}/plug?_api=set_plug_status&index=0&time=${controlTime}&key=${controlKey}&status=1"
powerOffUrl="${controlHostURL}/plug?_api=set_plug_status&index=0&time=${controlTime}&key=${controlKey}&status=0"

_sendRequest() {
	local url="$1"
	local responseData=$(curl -sSf --connect-timeout $requestTimeOut "$url" 2>/dev/null)
	[ ! -z "$responseData" ] && echo "$responseData" || echo "{}"
}

#远端返回错误代码时调用（即result!=0）,非请求过程本身的错误
responseInvolid() {
	local msg="【失败】：请求失败，请检查key是否已过期！"
	echo "$msg"
	cat >>$SCRIPTPATH/sunlogin-error.log<<<"[$(date +'%Y%m%d %H:%M:%S')] ${msg}"
	#exit 255
	return 255
}

appendErrorLog() {
	local logFile="$SCRIPTPATH/sunlogin-error.log"
	echo "$*"
	cat >>$logFile<<<"[$(date +'%Y-%m-%d %H:%M:%S')] appendErrorLog：$*"
}

getPlugStatus() {
	local json=$(_sendRequest "$statusUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	local plugStatus=$(echo "$json"|jq '.response[]|.status')
	if [[ "${1,,}" == "--flag" ]];then  #仅返回状态标志：1->开关开启; 2->开关关闭
		echo "$plugStatus"
	else  #返回可读的信息提示文本
		if [ $plugStatus -eq 1 ];then
			echo "【开启】电源开关处在开启状态！"
		elif [];then
			echo "【关闭】电源开关处在关闭状态！"
		else
			echo "【错误】开关状态未知！"
		fi
	fi
}

getPlugVersion() {
	#获取插座固件版本信息
	local json=$(_sendRequest "$checkVersionUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	echo "$json"
}

getPlugPower() {
	#获取插座当前的耗电功率！
	local json=$(_sendRequest "$electricUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	if [[ "${1,,}" == "--raw" ]];then  #返回原始JSON数据
		echo "$json"
	else  #返回可读的信息提示文本
		local power=$(echo "$json"|jq -r '.power')    #当前电功率
		local current=$(echo "$json"|jq -r '.curr')   #当前电流
		local volume=$(echo "$json"|jq -r '.vol')     #当前电量
		printf "【耗电】当前电功率：%s W/h，电流：%s mA，电量：%s \n" $(echo "scale=2;$power/1000"|bc) $(echo "scale=2;$current/1000"|bc) $volume
	fi
	
}

getPlugOpenCount() {
	#获取插座今日开启次数
	#注：此接口功能待定（暂时不知道是干嘛用的...）
	local json=$(_sendRequest "$cntdownUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	if [[ "${1,,}" == "--raw" ]];then  #返回原始JSON数据
		echo "$json"
	else  #返回可读的信息提示文本
		#echo "TODO..."
		echo "$json"
	fi
}

getPlugPowerTime() {
	#获取插座今日通电时长！
	local url="https://sl-api.oray.com/smartplugs/xxxxxxxxxxxx/electric?date=2023-1-27&r=0.39320349774540664"  #注意此URL可通过抓包网页控制面板获取
	local json=$(_sendRequest "$url")
	echo "$json"
}

powerOnPlug() {
	#开启插座
	local json=$(_sendRequest "$powerOnUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	if [[ "${1,,}" == "--raw" ]];then  #返回原始JSON数据
		echo "$json"
	else  #返回可读的信息提示文本
		local setStatus=$(echo "$json"|jq -r '.result' 2>/dev/null||echo "1")
		[ "$setStatus" = "0" ] && echo "【成功】开启插座成功！" || echo "【失败】开启插座失败！"
	fi
	
}

powerOffPlug() {
	#关闭插座
	local json=$(_sendRequest "$powerOffUrl")
	local status=$(echo "$json"|jq -r '.result' 2>/dev/null)
	if [ -z "$status" -o "$status" = "null" ];then
		appendErrorLog "【请求错误】：请求的地址无效，请检查被控主机配置是否正确，并确保被控设备已接入网络！"
		return 99
	elif [ $status -ne 0 ];then
		responseInvolid && return
	fi
	if [[ "${1,,}" == "--raw" ]];then  #返回原始JSON数据
		echo "$json"
	else  #返回可读的信息提示文本
		local setStatus=$(echo "$json"|jq -r '.result' 2>/dev/null||echo "1")
		[ "$setStatus" = "0" ] && echo "【成功】关闭插座成功！" || echo "【失败】关闭插座失败！"
	fi
	
}

powerRebootPlug() {
	#重开插座（关闭插座后再次开启，中间间隔30秒）
	powerOffPlug
	echo "延时等待中..."
	sleep 30
	powerOnPlug
}


#——————————————————————————————————————————————————————————————
#主逻辑开始：功能函数调用：

#getPlugStatus   #获取插座开关所处状态
#getPlugOpenCount
#getPlugPower   #获取插座当前功率
#powerOnPlug    #开启插座
#powerOffPlug    #关闭插座
#powerRebootPlug  #重启插座

case "${1,,}" in 
	"on")
		echo "开启插座..."
		powerOnPlug 
	;;
	"off")
		echo "关闭插座..."
		powerOffPlug
	;;
	"reboot")
		echo "重启插座电源..."
		powerRebootPlug
	;;
	"status")
		echo "获取插座开关状态..."
		getPlugStatus
	;;
	"version")
		echo "获取插座固件版本..."
		getPlugVersion
	;;
	"power")
		echo "获取插座耗电功耗..."
		getPlugPower
	;;
	"count")
		echo "获取插座开关机次数..."
		getPlugOpenCount
	;;
	"time")
		echo "获取插座今日使用时长..."
		getPlugPowerTime
	;;
	*)
	:
	#echo "Do Nothing"
	;;
esac