#!/bin/bash
#遍历更新所有Git代码库

#排除的仓库列表（哪些仓库不需要更新，请在此处定义）：
#不需要带目录风格符 /
excludeRepo=("business_card" "hefatong")

pushd "$(dirname $0)" &>/dev/null

updateCount=0

for dirRepo in `ls -F |grep '/$'`;
do
	skipRepo=0
	#echo "depth1 => $dirRepo"
	for repo in ${excludeRepo[@]}
	do
		#echo "==> $repo"
		if [[ "${repo}/" == "${dirRepo}" ]];then
			echo -e "\033[42;37m \"${repo}\"位于排除列表，跳过更新... \033[0m\n"
			skipRepo=1
			break #匹配到一个排除项，则跳出比对循环
		fi
	done
	[ $skipRepo -eq 1 ] && continue #跳过需要排除的子目录
	pushd "$dirRepo" &>/dev/null
	[ $? -ne 0 ] && {
		echo "$dirRepo 子目录不存在！绕过..."
		continue
	}
	echo -e "更新仓库：$dirRepo ..."
	git pull
	echo -e "Update Done...\n"
	let updateCount+=1
	popd &>/dev/null
done

echo "累计共更新 $updateCount 个代码仓库..."

popd &>/dev/null
