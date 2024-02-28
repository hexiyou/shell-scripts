#!/usr/bin/env bash

filesize() {
	#借助Ruby获取文件格式化的大小尺寸；
	#See Also：https://stackoverflow.com/questions/16026048/pretty-file-size-in-ruby
	_usage() {
		cat <<'EOF'
filesize
	借助Ruby获取文件的大小（格式化为可读数据，B、kb、MB，etc）,可一次指定多个文件；
Usage:
	filesize file1 [file2] [file3]...
	filesize *
Example:
	filesize test1.txt /tmp/tmptest.tmp test2.txt
	filesize *.txt
	filesize *
EOF
	}
	[[ "$*" == "-h" ]] || [[ "$*" == "--help" ]] && local func=":" || local func=print_color
	[ $# -eq 0 ] || [[ "$*" == "-h" ]] || [[ "$*" == "--help" ]] && $func 40 "filesize 请指定要检测大小的文件路径(可指定多个)！" && _usage && return
	ruby -- - "$@"<<EOF
class Integer
  def to_filesize
    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(self.to_f / (s / 1024)).round(3)} #{e}" if self < s }  #保留三位小数
  end
end
ARGV.each do |file|
	puts "#{File.absolute_path(file)} => #{File.size(file).to_filesize}"
end
EOF
}