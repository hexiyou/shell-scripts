#!/usr/bin/env bash
# ucase、lcase快捷函数：
#借助Perl转换字符串为大写或小写

ucase() {
	#借助Perl转换所有字符串中的字母为大写
	if [ -t 0 ];then
		#echo "无管道输入"
		clip1|perl -lpe 's/^.*$/\U$&/'
	else
		#echo "有管道输入"
		perl -lpe 's/^.*$/\U$&/'
	fi
}

lcase() {
	#借助Perl转换所有字符串中的字母为小写
	if [ -t 0 ];then
		clip1|perl -lpe 's/^.*$/\L$&/'
	else
		perl -lpe 's/^.*$/\L$&/'
	fi
	return
}