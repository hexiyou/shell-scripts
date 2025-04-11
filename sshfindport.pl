#!/usr/bin/perl -W
#用途：命令行传递端口号搜索~/.ssh/config的主机配置项，支持模糊搜索端口号，比如搜索24会同时列出8024端口的主机
#参数说明：
#     $1 ---  搜索的端口号
#     $2 ---  要显示主机的个数限制
#Usage：
#     sshfindport.pl 2022      #查找SSH端口号包含2022的主机（模糊查找）
#     sshfindport.pl 2022 1    #查找SSH端口号包含2022的主机（模糊查找），仅列出一个
#     sshfindport.pl ^2022$    #查找SSH端口号为2022的主机（精确查找）
#     sshfindport.pl . 5       #查找任意SSH端口号主机，仅列出前5个
#

use strict;

my $hostPort=$ARGV[0]?$ARGV[0]:"";               #要搜索的SSH端口号;
my $maxCount=$ARGV[1]?$ARGV[1]:0;                #至多列出的主机个数，默认为0即不限制（列出所有匹配的主机）
my $foundPort=0;                                 #标记是否找到了需要的端口号;
my @hostLines=();                                #缓冲数组，临时存储主机配置项的每一行;
my $foundCount=0;                                #查找到的主机个数，同一端口号可能匹配到多个主机;
my $sshConfigFile="$ENV{'HOME'}/.ssh/config";    #SSH配置文件路径：(~/.ssh/config)

if(! "$hostPort"){
	print "缺少搜索的端口号，将列出 ~/.ssh/config 全部主机！\n";
}

$hostPort =~ s/[\^\$]/\\b/g if $hostPort;         #支持在搜索模式中使用^或$进行边界匹配（匹配端口号开始或结束，更精确筛选结果，二者亦可以同时使用）

open(SSHCONFIG,"<$sshConfigFile") or die "$sshConfigFile 文件无法打开, $!";

while (<SSHCONFIG>) {
	if(/^[\s\t]*Host[\s\t]+.*$/i){
		if(@hostLines) {
			if ($foundPort){
				print "@hostLines";
				#$foundPort = 0;  #<---加入此行会忽略掉没有显式配置Port选项的主机，默认情况下，不配置Port选项，即端口默认都为22
				printf "\n" if $foundCount>=1;
			}
			@hostLines=();
		}
	}
	#if (/^[\s\t]*Port[\s\t]+($hostPort)[\s\t]*$/i) {   #<---仅支持端口号精确匹配；
	if (/^[\s\t]*Port[\s\t]+[0-9]*($hostPort)[0-9]*[\s\t]*$/i) {   #<---支持端口号模糊匹配；
		$foundPort = 1;
		$foundCount+=1;
	} elsif (/^[\s\t]*Port[\s\t]+[0-9]{2,5}[\s\t]*$/i) {
		$foundPort = 0;
	}
	push(@hostLines, $_);
	last if $maxCount>0 and $foundCount==$maxCount+1 and $foundCount--;
}

print "\n找到主机 $foundCount 个\n";