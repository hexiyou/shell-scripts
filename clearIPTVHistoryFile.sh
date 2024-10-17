#!/bin/bash 
#清理N天前的IPTV播放列表备份文件，可在.bash_profile中加入函数名自动调用

clearIPTVHistoryFile() {
	#清理/v/m3u8/playlist/yunnan-telecom/history/目录下多余的IPTV播放列表备份文件（仅保留N天内生成的新文件）
	local keep_days=30   #保留多少天的新文件（默认30天）
	[ ! -z "$1" ] && expr "$1" + 0 &>/dev/null && local keep_days=$1
	print_color 40 "是否清理 $keep_days 天前备份的IPTV播放列表文件？(Y/yes|N/no，默认为no)"
	read -p "> " goClear
	[[ ! "${goClear,,}" == "y" && ! "${goClear,,}" == "yes" ]] && print_color 40 "取消清理..." && return
	ruby <<EOF
keep_days=${keep_days}       #保留多少天内生成的文件不删除
current_num=0                #标记当前已检查的有效的备份文件个数
delete_num=0                 #标记已删除的文件个数
ONE_DAY_SECONDS = 60*60*24   #一天有多少秒

Dir.glob("/v/m3u8/playlist/yunnan-telecom/history/*") do |file|
	#puts "#{File.basename(file)}，size：#{File.size(file)}"
	#if Time.now.to_i-File.mtime(file).to_i < keep_days*ONE_DAY_SECONDS and File.size(file)>100  #<--同时检查文件大小
	if Time.now.to_i-File.mtime(file).to_i < keep_days*ONE_DAY_SECONDS
		#puts "文件 #{File.basename(file)} 在有效期内，保留之..."
		current_num+=1
		next
	end
	puts "删除过期备份文件 #{File.basename(file)} ..."
	#puts "删除冗余备份文件 #{File.expand_path(file)} ..."
	File.delete File.expand_path(file)
	delete_num+=1
	#puts "#{file} => #{File.mtime(file)} => #{File.ctime(file)}"
end
puts "删除了 #{delete_num} 个文件，保留最新的 #{current_num} 个备份文件..." if delete_num>0
puts "\033[33m无可清理文件！\033[0m" if delete_num==0
EOF
}
