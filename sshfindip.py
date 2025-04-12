#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#根据主机ip查找openSSH配置文件~/.ssh/config对应主机配置项
#自用sshfindip命令python实现版本
#原始sshfindip为shell脚本实现，参看：/v/bin/sshfindip
import sys
import os
import re

sshConfigFile="~/.ssh/config"
sshConfigFile=os.path.expanduser(sshConfigFile)

if len(sys.argv)<2 or (len(sys.argv)==2 and (str(sys.argv[1]).lower()=="--help" or str(sys.argv[1]).lower()=="-h")):
	print("""
	/v/bin/sshfindip.py
	使用主机IP或部分IP关键字查找主机配置项信息，查找 ~/.ssh/config 文件内容.
	注：当用不完全IP关键字匹配时，会输出包含此IP关键字的多台主机信息

Usage:
        sshfindip.py [ipstr]
Example:
        sshfindip.py 114.114.114.114
        sshfindip.py 14.128.60.202 all  #即便IP被注释，依然对其进行搜索
	
	""")
	sys.exit(0)
else:
	ipstr=str(sys.argv[1]).strip()

#是否查找注释掉的IP
findCommentIP=False

if len(sys.argv)==3 and str(sys.argv[2]).lower()=="all":
	findCommentIP=True

ipstr=ipstr.replace(".","\.").replace("-","\-")
foundCount=False

with open(sshConfigFile,"r") as read_f:
	Tag=False
	findIp=False
	allHostInfo=[]
	HostInfo=[]
	for num,line in enumerate(read_f.readlines(),1):
		if Tag==True and re.match(r'[ ]*Host ',line,re.I):
			Tag=False
			if findIp==True:
				allHostInfo.append(HostInfo)
				findIp=False
		if Tag==False and re.match(r'Host .*',line,re.I):
			Tag=True
			HostInfo=[]
			HostInfo.append(line)
			continue
		if Tag==True:
			if findCommentIP==False:
				if re.match(r'.*[^#]HostName [ ]*'+ipstr+'.*',line,re.I):
					findIp=True
					foundCount+=1
			else:
				#同时查找带#注释掉的IP
				if re.match(r'.*HostName [ ]*'+ipstr+'.*',line,re.I):
					findIp=True
					foundCount+=1
			HostInfo.append(line)

for Host in allHostInfo:
	print("".join(Host))
	
if foundCount>1:
	print("共找到主机 %s 个"%foundCount)
	
print("\nsshfindip.py 执行完毕；Python版本:%s"%sys.version)