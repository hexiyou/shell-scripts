#!/bin/sh
# Code From：https://stackoverflow.com/questions/370075/command-line-world-clock
# More Clock：https://www.timeanddate.com/worldclock/
#-----------------------------------------------------
# 使用举例：
#   timeall    #获取当前时刻的世界时
#   timeall -d "20211225 12:33:23"     
#   		   #获取某个时刻的各地世界时（以当前时区为准，当前时区依你系统设置而定，比如中国就是北京时区）
#-----------------------------------------------------


timeStampStr=""
#脚本支持 -d 'yyyymmdd xx:xx:xx' 指定特定日期时间：
#-d支持三种格式的参数值：yyyymmdd (20221125) 【年月日】
#                        yyyymmdd HH:ii (20221125 10:32) 【年月日 时:分】
#                        yyyymmdd HH:ii:ss (20221125 10:32:18)【年月日 时:分:秒】
[[ "$*" =~ ^\-d[\ ]+[0-9]{8}([\ ]+[0-9]{2}:[0-9]{2}(:[0-9]{2})?)?$ ]] && {
	timeStampStr="-d $(date -d "$2" +'@%s')"
	#echo -e "使用时间戳参数：$timeStampStr"
	echo -e "显示北京时间【$2】的世界时刻：\n"
}

CN=`env TZ=Asia/Shanghai date $timeStampStr`
MY=`env TZ=Asia/Yangon date $timeStampStr`
JP=`env TZ=Asia/Tokyo date $timeStampStr`
SP=`env TZ=Singapore date $timeStampStr`
PH=`env TZ=Asia/Manila date $timeStampStr`
MS=`env TZ=Europe/Moscow date $timeStampStr`
#QT=`env TZ=UTC-3 date $timeStampStr`
QT=`env TZ=Asia/Qatar date $timeStampStr`
GM=`env TZ=GMT date $timeStampStr`
UT=`env TZ=UTC date $timeStampStr`
NY=`env TZ=America/New_York date $timeStampStr`
LO=`env TZ=America/Los_Angeles date $timeStampStr`
PT=`env TZ=US/Pacific date $timeStampStr`
CT=`env TZ=US/Central date $timeStampStr`
AT=`env TZ=Australia/Melbourne date $timeStampStr`

echo "北京时间       $CN"
echo "缅甸时间       $MY"
echo "东京时间       $JP"
echo "新加坡时间     $SP"
echo "菲律宾时间     $PH"
echo "莫斯科时间     $MS"
echo "卡塔尔时间     $QT"
echo "GMT Time       $GM"
echo "UTC Time       $UT"
echo "New York       $NY"
echo "Los_Angeles    $LO"
echo "Santa Clara    $PT"
echo "Central        $CT"
echo "Melbourne      $AT"