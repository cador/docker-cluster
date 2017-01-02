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
#启动zookeeper
for((i=0;i<${#zknodes[@]};i++))
do
	zkno=${zknodes[$i]}
	getctInfo $zkno
	docker exec $ctName su - hadoop -c "zkServer.sh start"
done
#启动hadoop
getctInfo $nn1host
docker exec $ctName su - hadoop -c "hdfs zkfc -formatZK -force"
getctInfo $nn2host
docker exec $ctName su - hadoop -c "hdfs zkfc -formatZK -force"
for((i=0;i<${#qjnodes[@]};i++))
do
	getctInfo ${qjnodes[$i]}
	docker exec $ctName su - hadoop -c "hadoop-daemon.sh start journalnode"
done
sleep $waitformat
MDIR=$(dirname $DIR)
statusfile=$storage/format-status
if [ ! -f "$statusfile" ];then
	getctInfo $nn1host
	docker exec $ctName su - hadoop -c "hdfs namenode -format -force"
	touch $statusfile
	echo '完成格式化！'
fi
#docker exec $ctName su - hadoop -c "hadoop-daemon.sh start namenode"
getctInfo $nn1host
docker exec $ctName su - hadoop -c "start-dfs.sh"
getctInfo $nn2host
docker exec $ctName su - hadoop -c "hdfs namenode -bootstrapStandby -nonInteractive"
docker exec $ctName su - hadoop -c "hadoop-daemon.sh start namenode"

getctInfo $yarnstartid1
docker exec $ctName su - hadoop -c "start-yarn.sh"
getctInfo $yarnstartid2
docker exec $ctName su - hadoop -c "yarn-daemon.sh start resourcemanager"
getctInfo $jobhistoryhost
docker exec $ctName su - hadoop -c "mr-jobhistory-daemon.sh start historyserver;yarn-daemon.sh start timelineserver"
#getctInfo $jobhistoryhost2
#docker exec $ctName su - hadoop -c "mr-jobhistory-daemon.sh start historyserver;yarn-daemon.sh start timelineserver"
#启动hbase
getctInfo $nn1host
docker exec $ctName su - hadoop -c "hbase-daemon.sh start master"
getctInfo $nn2host
docker exec $ctName su - hadoop -c "hbase-daemon.sh start master"
for((i=0;i<${#regionservers[@]};i++))
do
	getctInfo ${regionservers[$i]}
	docker exec $ctName su - hadoop -c "hbase-daemon.sh start regionserver"
done
