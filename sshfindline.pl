#!/usr/bin/perl -W
#用途：命令行传递主机名称关键字搜索~/.ssh/config的主机配置项，并打印匹配到的配置文件的起始行号，供 `sshedit` 等其他命令使用；
#优先全字匹配，全字匹配到主机信息则打印该主机信息（有且只有一个），否则进行模糊匹配，打印匹配到的多个主机信息；
#参数说明：
#     $1 ---  主机名称搜索关键字
#Usage：
#     sshfindline.pl racknerd      #查找主机名包含racknerd的主机
#     sshfindline.pl hkwin

use strict;

my $hostName=$ARGV[0]?$ARGV[0]:"";                        #要搜索的SSH主机名
my $showLine=0;                                           #SSH Config行打印标记开关
my $foundCount=0;                                         #查找到的主机个数，同一关键字可能匹配到多个主机
my $foundTarget=0;                                        #标记是否找到全字匹配的主机（有且只会有一个）
my @matchLines=([], [], [], []);                          #存储匹配到的主机项（信息打印行），前三个元素保存全字匹配到的主机信息行（如果有），最后一个元素保存关键字模糊匹配到的项；
my $pushIndex=0;                                          #标记打印行要添加到的数组下标；
my $sshConfigFile="$ENV{'HOME'}/.ssh/config";             #SSH配置文件路径：(~/.ssh/config)

if(! "$hostName"){
	print "缺少搜索关键字，将列出 ~/.ssh/config 全部主机！\n";
}

open(SSHCONFIG,"<$sshConfigFile") or die "$sshConfigFile 文件无法打开, $!";

while (<SSHCONFIG>) {
	if (/Host .*[\s|\b]$hostName(\s|$).*$/i){  #匹配尾
		$showLine=1;
		$foundTarget=1; 
		$pushIndex=1;		
		#print "$.\n" and print and next;
		push @{$matchLines[$pushIndex-1]}, "$.\n" and push @{$matchLines[$pushIndex-1]}, $_ and next;
	}
	elsif(/Host ([^-\w]*)$hostName(\s|$).*$/i){ #匹配头
		$showLine=1;
		$foundTarget=1; 
		$pushIndex=2; 
		#print "$.\n" and print and next;
		push @{$matchLines[$pushIndex-1]}, "$.\n" and push @{$matchLines[$pushIndex-1]}, $_ and next;
	}
	elsif(/Host .*\s$hostName(\s|$).*$/i){ #匹配中部（全字匹配）
		$showLine=1;
		$foundTarget=1; 
		$pushIndex=3; 
		#print "$.\n" and print and next;
		push @{$matchLines[$pushIndex-1]}, "$.\n" and push @{$matchLines[$pushIndex-1]}, $_ and next;
	}
	elsif(/Host .*\b$hostName\b.*$/i or /Host .*$hostName.*$/i){ #模糊匹配
		$showLine=1; 
		$pushIndex=4;
		$foundCount+=1;
		#print "$.\n" and print and next;
		push @{$matchLines[$pushIndex-1]}, "$.\n" and push @{$matchLines[$pushIndex-1]}, $_ and next;		
	}
	
	$showLine=0 if /Host .+$/i;	
	push @{$matchLines[$pushIndex-1]}, $_ if $showLine==1;
}


if (@{$matchLines[0]}) {
	print join "", @{$matchLines[0]};;
}
elsif (@{$matchLines[1]}) {	
	print join "", @{$matchLines[1]};
}
elsif (@{$matchLines[2]}) {	
	print join "", @{$matchLines[2]};
}
elsif (@{$matchLines[3]}) {	
	print join "", @{$matchLines[3]};
}

print "\n以上为全字匹配结果！\n" if $foundTarget;
print "\n模糊匹配 “$hostName” ，共找到 $foundCount 个主机！\n" if not $foundTarget and $foundCount>0;

