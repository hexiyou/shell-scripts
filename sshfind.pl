#!/usr/bin/perl -W
#用途：命令行传递主机名称关键字搜索~/.ssh/config的主机配置项
#参数说明：
#     $1 ---  主机名称搜索关键字
#     $2 ---  要显示主机的个数限制
#Usage：
#     sshfind.pl racknerd      #查找主机名包含racknerd的主机
#     sshfind.pl racknerd 1    #查找主机名包含racknerd的主机，仅列出一个
#     sshfind.pl . 5           #查找主任意关键字主机，仅列出前5个

use strict;

my $hostName=$ARGV[0]?$ARGV[0]:"";               #要搜索的SSH主机名
my $maxCount=$ARGV[1]?$ARGV[1]:0;                #至多列出的主机个数，默认为0即不限制（列出所有匹配的主机）
my $showLine=0;                                  #SSH Config行打印标记开关
my $foundCount=0;                                #查找到的主机个数，同一关键字可能匹配到多个主机
my $sshConfigFile="$ENV{'HOME'}/.ssh/config";    #SSH配置文件路径：(~/.ssh/config)

if(! "$hostName"){
	print "缺少搜索关键字，将列出 ~/.ssh/config 全部主机！\n";
}

$hostName =~ s/[\^\$]/\\b/g if $hostName;         #支持在搜索模式中使用^或$进行边界匹配（匹配主机名开始或结束，更精确筛选结果，二者亦可以同时使用）

open(SSHCONFIG,"<$sshConfigFile") or die "$sshConfigFile 文件无法打开, $!";

while (<SSHCONFIG>) {
	if(/^[\s\t]*Host[\s\t]+.*($hostName).*/i){
		$showLine=1;
		$foundCount+=1;
		printf "\n" if $foundCount>1;
	}
	elsif(/^[\s\t]*Host[\s\t]+.*$/i){
		$showLine=0;
	}
	last if $maxCount>0 and $foundCount==$maxCount+1 and $foundCount--;
	print if $showLine==1;	
}

print "\n找到主机 $foundCount 个\n";

