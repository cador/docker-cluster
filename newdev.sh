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
#创建k[0-99].hadoop容器
#(1)判断storage目录是否存在，若不存在则创建，否则忽略此步
if [ ! -d "$storage" ];then
	mkdir "$storage"
	for((i=1;i<=$nodesize;i++))
	do
		getctInfo $i
		t0=$ctName
		if [ ! -d "$storage/$t0" ];then
			mkdir "$storage/$t0"
			mkdir "$storage/$t0/hadoop"
			mkdir "$storage/$t0/hadoop/hdfs"
			mkdir "$storage/$t0/hadoop/tmp"
			mkdir "$storage/$t0/hadoop/hdfs/data"
			mkdir "$storage/$t0/hadoop/hdfs/journal"
			mkdir "$storage/$t0/hadoop/hdfs/name"
			mkdir "$storage/$t0/hadoop/logs"
			mkdir "$storage/$t0/zookeeper"
			mkdir "$storage/$t0/zookeeper/data"
			mkdir "$storage/$t0/zookeeper/logs"
		fi
	done
	chown -R hadoop $storage
	chgrp -R hadoop $storage
fi
#(2)根据镜像启动docker容器
dstHost=hosts.$RANDOM
for((i=1;i<=$nodesize;i++))
do
	getctInfo $i
	containerno=$ctNO
	containername=$ctName
	echo $containername
	out=$(docker run -d -h $containername --name=$containername -v $storage/$containername/hadoop/hdfs:/home/hadoop/hdfs -v $storage/$containername/hadoop/tmp:/home/hadoop/tmp  -v /tmp/$dstHost:/tmp/$dstHost -v $storage/$containername/zookeeper/data:/home/hadoop/zkdata -v $storage/$containername/zookeeper/logs:/home/hadoop/zklogs $image /usr/sbin/sshd -D)
	docker exec $containername chown -R  hadoop /home/hadoop/hdfs
	docker exec $containername chown -R  hadoop /home/hadoop/tmp
	docker exec $containername chown -R  hadoop /home/hadoop/zkdata
	docker exec $containername chown -R  hadoop /home/hadoop/zklogs
	docker exec $containername chgrp -R  hadoop /home/hadoop/hdfs
	docker exec $containername chgrp -R  hadoop /home/hadoop/tmp
	docker exec $containername chgrp -R  hadoop /home/hadoop/zkdata
	docker exec $containername chgrp -R  hadoop /home/hadoop/zklogs
	getctIP $out
	echo -e "$innerIP\t$containername" >> /tmp/$dstHost/hosts
done
echo -e "127.0.0.1\tlocalhost" >> /tmp/$dstHost/hosts
#分发hosts
for((i=1;i<=$nodesize;i++))
do
	getctInfo $i
	docker exec $ctName \cp  -rf /tmp/$dstHost/hosts /etc/hosts
done
\cp  -rf /tmp/$dstHost/hosts /etc/hosts
