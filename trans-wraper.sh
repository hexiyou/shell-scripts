#!/usr/bin/env bash
trans() {
	#劫持trans同名命令，缺省详细参数时自动判断需要中翻英还是英翻中
	#执行脚本：/v/bin/trans
	# Github：https://github.com/soimort/translate-shell
	# Tips： clip1|trans 或 cat /dev/clipboard|trans  （从剪贴板读取文本并翻译）
	local header=$(cat<<EOF
# trans 同名劫持函数
# 执行脚本：/v/bin/trans
# Github：https://github.com/soimort/translate-shell
# 小技巧：支持从管道符导入需要翻译的内容：
# eg：cat text.txt|trans
#     clip1|trans 或 cat /dev/clipboard|trans  （从剪贴板读取文本并翻译）
-----------
# 你可以使用以下别名翻译为不同目标语言：
`alias|grep 'alias trans-'`
EOF
)
	[ $# -eq 0 ] && [ -t 0 ] && echo "$header" && /v/bin/trans --shell && return
	OLD_IFS=$IFS
	IFS=$(echo -e "\n")
	local audioFile=""
	local audioPlayCount=1 #翻译的语音文件播放次数，默认为1
	local pointLang=0 #参数中是否指定了特定的翻译语言，1为已指定，0为未指定
	local originOptions=( $@ )
	local inputTmpFile="/tmp/text-to-translate-tmp.txt"
	local inputFileOptions=( )
	
	while [ $# -gt 0 ];
	do
		if [[ "${1,,}" == "-download-audio-as" ]];then
			audioFile="$2"
		elif [[ "${1,,}" =~ ^: ]];then
			pointLang=1
		fi
		shift
	done
	if [ ! -t 0 ];then
		#cat >"$inputTmpFile"
		cat|dos2unix -q|tr '\n' ' ' >"$inputTmpFile" # <-- 干掉换行
		inputFileOptions=("-i" "$inputTmpFile")
	fi
	#判断最后一个参数是否是纯数字，如果是，则认定为循环播放音频的次数
	expr ${originOptions[$#-1]} + 0 &>/dev/null   #也可以使用 "${@:$#}" OR ${originOptions[@]:$(($#-1))}
	if [ $? -eq 0 ];then
		audioPlayCount="${originOptions[$#-1]}"
		unset originOptions[$#-1]
	fi
	set -- ${inputFileOptions[@]} ${originOptions[@]}
	#判断参数起始字符是否是中文字符，从而决定中翻英还是英翻中
	if [ $pointLang -eq 0 ] && [[ "${1,,}" =~ ^[^0-9a-z\-] ]];then
		/v/bin/trans :en "$@"
	else
		/v/bin/trans "$@"
	fi
	IFS=$OLD_IFS
	#是否自动播放语音文件（依赖于/v/bin/playaudio,实际调用程序cmdmp3）
	#命令行播放音频第三方程序：cmdmp3（https://lawlessguy.wordpress.com/2015/06/27/update-to-a-command-line-mp3-player-for-windows/）
	if [[ "$*" =~ "-download-audio-as" ]] && [ -f "$audioFile" ];then
		print_color "播放语音文件..."  #注意：翻译文本过长可能导致生成的语音文件无效，具体限制未知，尽量缩短文本，控制在40s以内；（可能是脚本处理过程错误，并非官方限制）
		local i=1
		while [ $i -le $audioPlayCount ];
		do
			playaudio $audioFile
			#cygstart $audioFile
			let i+=1
		done
		[ -f "$audioFile" ] && rm -vf $audioFile
	fi
}
alias trans0=trans
alias fy2=trans # <--- fy已指定其他程序(/usr/local/bin/fy.exe)
alias fy=trans

trans1() {
	#翻译的同时自动下载语音文件到本地临时文件进行播放
	#alias trans1='trans -download-audio-as /tmp/textaudio.mp3' # <--- alias由于传参顺序不对，暂时弃用...
	local transTarget="" #<--翻译的目标语言
	#如果参数$1指定了翻译的目标语种，则调换参数顺序，以便为trans1创建多语种别名，同时保证trans函数良好执行
	#eg： trans1 邵氏影院 :fr
	#	  等效于
	#	  trans1 :fr 邵氏影院   （指定翻译目标语种为法语）
	#支持管道调用翻译并朗读语音；
	# eg：  clip1|trans1 :en 或者 clip1|trans-en （翻译为英文并朗读）
	#-------------------
	# 别名调用示例（翻译为法语并朗读）：trans-fa 邵氏影院
	if [[ "$1" =~ ^\: ]];then  
		#echo "需要调换参数顺序..."
		transTarget="$1" && shift
	fi
	set -- "$transTarget" "$@" # <--- 注意 $@ 加双引号，否则英文句子会被分成多个参数传递
	#set -x
	OLD_IFS=$IFS
	IFS=$(echo -e "\n")
	if [ ! -t 0 ];then
		#echo "有管道内容"
		trans -download-audio-as /tmp/textaudio.mp3 "$@" <<<$(cat)
	else
		#echo "无管道内容"
		trans -download-audio-as /tmp/textaudio.mp3 "$@" </dev/null
	fi
	IFS=$OLD_IFS
	#set +x
}
alias fy3=trans1
alias cfy='clip1|trans1' #翻译剪贴板中的内容
#翻译支持的语言：https://github.com/soimort/translate-shell/wiki/Languages
alias trans-fa='trans1 :fr' #翻译为法语
alias trans-de='trans1 :de' #翻译为德语
alias trans-en='trans1 :en' #翻译为英语
alias trans-es='trans1 :es' #翻译为西班牙语
alias trans-spa=trans-es
alias trans-it='trans1 :it' #翻译为意大利语
alias trans-yi=trans-it
alias trans-ja='trans1 :ja' #翻译为日语
alias trans-ri=trans-ja
alias trans-ko='trans1 :ko' #翻译为韩语
alias trans-han=trans-ko
alias trans-ms='trans1 :ms' #翻译为马来语
alias trans-malai=trans-ms
alias trans-my='trans1 :my' #翻译为缅甸语
alias trans-mian=trans-my
alias trans-vi='trans1 :vi' #翻译为越南语
alias trans-yn=trans-vi
alias trans-th='trans1 :th' #翻译为泰语
alias trans-tai=trans-th
alias trans-tl='trans1 :tl' #翻译为菲律宾语
alias trans-fei=trans-tl
alias trans-zh='trans1 :zh-CN' #翻译为简体中文
alias trans-cn=trans-zh
alias trans-zhft='trans1 :zh-TW' #翻译为繁体中文
alias trans-yue='trans1 :yue' #翻译为粤语