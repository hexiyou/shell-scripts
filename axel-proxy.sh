#!/bin/sh -e

# axel-proxy 0.1
# written by Sam Watkins, 2009

# Run axel-proxy from inetd, e.g. in /etc/inetd.conf:
# 444	stream	tcp	nowait	someuser	/usr/bin/axel-proxy	axel-proxy

# make sure /etc/hosts.allow contains the line:
# ALL: LOCAL

# You need to mkdir "$cache_dir" and touch "$log_file", they should be owned by "someuser"

# axel-proxy uses "HEAD" from libwww-perl, wget, axel

# warning - do not restart inetd from a shell where you have already changed
# http_proxy to use axel-proxy, or it will recurse!

axel_connection_per=16384
axel_max_connections=24
cache_dir="/var/cache/axel-proxy"
log_file="/var/log/axel-proxy"
agent="Mozilla/5.0 (X11; U; Linux i586; en-US; rv:1.5) Gecko/20031007 Firebird/0.7"

if [ ! -w "$log_file" -o ! -d "$cache_dir" -o ! -w "$cache_dir" ]; then
	echo 500 Internal Server Error
	echo Content-Type: text/plain
	echo
	echo "axel-proxy's cache dir / log file are not writable."
	exit
fi

exec 2>>"$log_file"

error() {
	echo HTTP/1.0 404 Not Found
	echo Content-Type: text/plain
	echo
	cat "$errors"
	rm "$errors"
	exit
}

cd "$cache_dir"

read line
req=${line%% *}
line=${line#* }
addy=${line%% *}
proto=${line#* }

perl -ne '/^[\r\n]*$/ && exit'

# work out filename
file="$addy"
test="${file#*://}"
test1="${test%/*}"
if [ "$test" = "$test1" ]; then
	file="$file/"
fi
case "$file" in
*/)
	file="${file}index.html"
	;;
esac


case "$file" in
http://*|ftp://*) # no https at the moment
	dir="`dirname "$file"`"
	base="`basename "$file"`"
	mkdir -p "$dir"
	if [ \! -f "$file" ]; then
		errors="$dir/.errors-$base"
		headers="$dir/.headers-$base"
		body="$dir/.body-$base"
		if [ -e "$body" ] && fuser "$body" 2>/dev/null; then
			while [ ! -f "$file" -o -e "$body" ]; do
				sleep 1
			done
			cat < "$file"
		else
			rm -f "$headers" "$errors"
			if [ ! -e "$body.st" ]; then
				rm -f "$body"
			fi
			HEAD "$addy" > "$headers" 2>"$errors" && [ -s "$headers" ] || error  # TODO should check code
			length=`perl -ne 'if (/^Content-Length: (\d+)$/) { print "$1"; exit }' < "$headers"`
			axel_n_connections=$(( ${length:-0} / $axel_connection_per ))
			if [ "$axel_n_connections" -lt 2 ]; then
				rm "$headers"
				wget -q -U"$agent" --save-headers -O"$file" -- "$addy" >"$errors" 2>&1 || error
				cat < "$file"
			else
				if [ "$axel_n_connections" -gt "$axel_max_connections" ]; then
					axel_n_connections="$axel_max_connections"
				fi
				echo -n "HTTP/1.0 "
				cat "$headers"
				# TODO pass outgoing headers, would need to hack axel
				axel -q -n $axel_n_connections -o "$body" "$addy" 2>"$errors" && [ ! -e "$body.st" ] || error
				echo -n "HTTP/1.0 " > "$file"
				cat "$headers" "$body" >> "$file"
				cat < "$body"
				rm "$headers" "$body"
			fi
			rm "$errors"
		fi
	else
		cat < "$file"
	fi
	;;
*)
	echo HTTP/1.0 404 Not Found
	echo
	;;
esac

exit
