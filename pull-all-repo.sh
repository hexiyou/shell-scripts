#!/bin/bash
#遍历更新所有Git代码库

#排除的仓库列表（哪些仓库不需要更新，请在此处定义）：
#不需要带目录风格符 /
excludeRepo=("business_card" "business_card_controller" "cargo_bridge" "cargo_bridge_service")

pushd "$(dirname $0)" &>/dev/null

skipCount=0  #忽略执行更新操作的仓库个数
updateCount=0  #发起更新的仓库总的个数
conentUpdate=0  #有内容更新的仓库个数
errorRepo=0   #拉取出错的仓库个数

noConentUpdate="已经是最新的"
contentRepo=() #有内容更新的Repo集合
errContentRepo=() #更新出错的Repo集合

tempTestRepo=("Repo1/" "repo2/" "repo3/" "repo4/" "repo5/" "shell-scripts/")

#for dirRepo in ${tempTestRepo[@]};
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
			let skipCount+=1
			break #匹配到一个排除项，则跳出比对循环
		fi
	done
	[ $skipRepo -eq 1 ] && continue #跳过需要排除的子目录
	pushd "$dirRepo" &>/dev/null
	[ $? -ne 0 ] && {
		echo "$dirRepo 子目录不存在！绕过..."
		continue
	}
	echo -e "更新第 $((updateCount+1)) 个仓库：$dirRepo ..."
	pullFlag=0
	pullLog=$(/usr/bin/git pull|tee /dev/tty||echo "git command error"|tee /dev/tty)
	[ -z "$pullLog" ] && {
		pullFlag=1
		errContentRepo=(${errContentRepo[@]} "$dirRepo")
		let errorRepo+=1
	}
	#echo "Git返回码：$pullFlag"
	if [ $pullFlag -eq 0 ] && [[ $(echo "$pullLog"|grep -v "$noConentUpdate") ]];then
		contentRepo=(${contentRepo[@]} "$dirRepo")
		let conentUpdate+=1
	fi
	echo -e "Update Done...\n"
	let updateCount+=1
	popd &>/dev/null
done

echo "累计共请求更新 $updateCount 个代码仓库，跳过更新 $skipCount 个仓库，有 $conentUpdate 个有内容更新，有 $errorRepo 个更新出错..."
[ $conentUpdate -gt 0 ] && echo "有内容更新的仓库：${contentRepo[*]} ..."
[ $errorRepo -gt 0 ] && echo "更新出错的仓库：${errContentRepo[*]} ..."

popd &>/dev/null
