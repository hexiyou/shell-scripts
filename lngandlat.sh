#!/usr/bin/env bash
lngandlat() {
	#经纬度格式转换，传入任意格式的经纬度数据，转换为需要的格式输出，方便一键复制
	#经纬度参数可以分开传递也可以合在一个参数传递（lngandlat 111,222 与 lngandlat 111 222效果相同）；
	#支持 ， # ；| ||  $ @ 等特殊符号作为经纬度分隔符，不限制分隔符字符数（重复无所谓），程序会自动缩减和处理
	# 参数中包含井号(#)和分号(;)时，参数需要用双引号或单引号包裹，其他情况下，引号可以省去
	# 注：awk没有内置求绝对值的函数，借用sqrt曲线救国；
	# See Also：https://zhidao.baidu.com/question/1801649363884678947.html
	# See Also2：https://zhidao.baidu.com/question/304949582658546204.html
	# eg:
	#	 lngandlat -102.995824 22.706189
	#	 lngandlat -102.995824,22.706189
	#    lngandlat 22.706189,-102.995824,
	#    lngandlat ";;102.995824##22.706189"
	#    lngandlat ";;-102.995824##22.706189"
	#------------------------------	
	_print_usage() { #打印帮助信息
		echo -e "lngandlat：\n\t纬度格式转换，传入任意格式的经纬度数据，转换为多种或许需要的格式输出；"
		echo -e "\t【目   的】：有的场景需要经度+纬度的组合，而有的需要纬度+经度组合，手动调换参数较为麻烦，故编写此快捷函数；"
		echo -e "\t【快捷操作】：输出数据后，mintty窗口下可以双击鼠标左键复制当前行文本；"
		echo -e "\t传入经纬度时先后顺序不敏感，分隔符可以为空格、逗号、#号或其他常见特殊字符，字符个数不限，程序会自动过滤处理；"
		echo -e "\t经纬度参数可以分开传递也可以合在一个参数传递（\`lngandlat 111,222\` 与 \`lngandlat 111 222\` 效果相同）；"
		echo -e "\t注：参数数中包含井号(#)和分号(;)时，参数需要用双引号或单引号包裹，其他情况下，引号可以省去；"
		echo -e "\nUsage：\n\tlngandlat  *longitude~and~latitude~paramter\n"
		echo -e "--------------------------------------------------------------"
		echo -e "\nExample：\n\tlngandlat -102.995824 22.706189"
		echo -e "\tlngandlat 22.706189 -102.995824  #参数顺序不敏感，经度可前可后"
		echo -e "\tlngandlat -102.995824,22.706189  #两个参数可以合并传递"
		echo -e "\tlngandlat 22.706189,-102.995824"
		echo -e "\tlngandlat \"22.706189,,#,,-102.995824\"   #分隔符字数不限"
		echo -e "\tlngandlat \"-102.995824;22.706189\"  #参数包含分号需加引号"
		echo -e "\tlngandlat \"#102.995824##22.706189\"  #参数可以包含任意特殊字符作为经度和纬度的分隔符，且分隔符个数不限"
		echo -e "\tlngandlat \";;|\\\$-102.995824##22.706189\\$\\$\" #包含杂乱的分隔符不影响处理,注意包含\$需要转义"
		echo -e "\tlngandlat ';;|\$-102.995824##22.706189\$\$' #使用单引号无需转义\$"
	}
	[ $# -eq 0 ] && echo -e "缺少参数！"
	if [[ $# == 0 || "${*,,}" == "-h" || "${*,,}" == "--help" ]];then	
		_print_usage && return
	fi
	
	#这里借助awk统一在位置1输出经度，位置2输出纬度：
	mapfile -t Coords <<<$(\
		echo "$*"|tr -s ',;#|@$ '|awk -F '[,#;\\|\\$@ ]' '{
			sub(/[^0-9]+?$/,""); /*替换参数结尾的分隔符，否则会影响栏位$NF定位*/
			/*依次向前取到倒数第二个非空字段*/
			/*为了处理分隔符夹分隔符的情况：lngandlat "22.706189,,#,,-102.995824"*/
			findex=NF-1;
			while($findex==""){
				findex=findex-1;
			}
			previous=$findex;
			if(previous<0 && $NF<90){ /*第一个数字小于零，第二个数字小于90，则认定为 经度、纬度格式*/ 
				print previous;
				print $NF;
			}else if($NF<0 && previous<90) { /*第二个数字小于零，第一个数字小于90，则认定为 纬度、经度格式*/ 
				print $NF;
				print previous;
			}else if(sqrt(previous*previous)>65 && sqrt($NF*$NF)>65) { /*两个数字绝对值过大，则认定为错误的经纬度数据(纬度最高为冰岛国的雷克雅未克：64°09′)*/ 
				print "ERROR";
				print "ERROR";
			}else if(sqrt(previous*previous)<65 && sqrt($NF*$NF)>90) { /*对一个参数和第二个参数模糊求绝对值,推测为 纬度、经度格式*/ 
				print $NF;
				print previous;
			}else if(sqrt($NF*$NF)<65) { /*对二个参数模糊求绝对值,默认情况认定为 经度、纬度格式*/ 
				print previous;
				print $NF;
			}
		/*此处不屏蔽错误，保留awk命令原始错误输出结果到屏幕终端，以便于查找原因！*/
		/*复现报错提示可以使用：lngandlat "" */
		}' 2>/dev/tty||echo -e "\033[41;37m输入数据解析有错误，请检查参数！\033[0m" >/dev/tty
	)

	[[ "${Coords[@]}" == "" ]] && return #有错误则直接退出！
	
	local lng="${Coords[0]}" #经度
	local lat="${Coords[1]}" #纬度
	
	printf "原始数据：\n经度：%s\n纬度：%s\n\n" "$lng" "$lat"
	printf "经纬度：\n%s,%s\n\n" $lng $lat
	printf "纬经度：\n%s,%s\n\n" $lat $lng
	#jq命令存在则同时输出格式化的JSON数据：
	[ ! -z $(type -t jq) ] && printf '{"lng":"%s","lat":"%s"}' $lng $lat|jq '.'
}