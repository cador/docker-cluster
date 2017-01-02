#!/bin/bash
arg=$0
fstr=${arg:0:1}
if [ "$fstr" = "/" ];then
	DIR=$0
else
	DIR=$PWD/$0
fi
DIR=$(dirname $DIR)
source $DIR/utils.sh
#停止并删除名为 k[0-90].hadoop的容器
isrm=0
for((i=1;i<=$nodesize;i++))
do
	getctInfo $i
	t1=$(docker ps -a | grep $ctName | awk '{print $1}')
	if((${#t1}>0))
	then
		docker stop $t1
		docker rm $t1
		isrm=1
	fi
done
if(($isrm==1))
then
	echo '停止并删除历史容器成功！'
fi
