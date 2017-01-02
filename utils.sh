#!/bin/bash
#设置参数
nodesize=5
#storage=/home/cador/docker.home/storage
storage=/media/cador/docker.storage
image=centos.cluster:0.2
zknodes=(1 2 3 4 5)
halogical=kedian
iobuffersize=2048
hadoopheapsize=4096
dfsmutileno=2
nn1host=1
nn2host=2
qjnodes=(3 4 5)
jobhistoryhost=1
yarnstartid1=1
yarnstartid2=2
#mapred.child.java.opts
mrchildmb=6192
#mapreduce.map.memory.mb
mrmapmemorymb=6192
#mapreduce.reduce.memory.mb
mrreducememorymb=6192
#mapreduce.map.java.opts
mrmapmb=4144
#JAVA_HEAP_MAX
yarnjavaheapmax=1000
#yarn.nodemanager.vmem-pmem-ratio
yarnvmemratio=10
#yarn.nodemanager.vmem-check-enabled
yarnvmemcheck=false
#yarn.scheduler.minimum-allocation-mb
yarnminalloc=4000
hmaster=1
regionservers=(3 4 5)
waitformat=60
#根据序号获得容器名称和标记
getctInfo()
{
	if(($1 < 10))
	then
		ctName=k0$1.hadoop
		ctNO=k0$1
	else
		ctName=k$1.hadoop
		ctNO=k$1
	fi
}
#根据docker窗口ID获得IP
getctIP()
{
	innerIP=$(docker inspect $1 | grep IPAddress)
	innerIP=(${innerIP//,/})
	innerIP=${innerIP[1]}
	innerIP=${innerIP//\"/}
}
#获得zklist
getzklist()
{
	zklist=""
	for((i=0;i<${#zknodes[@]};i++))
	do
		zkno=${zknodes[$i]}
		getctInfo $zkno
		zklist="$zklist,$ctName:2181"
	done
	zklist=${zklist:1}
}
#获得qjlist
getqjlist()
{
	qjlist=""
	for((i=0;i<${#qjnodes[@]};i++))
	do
		qjno=${qjnodes[$i]}
		getctInfo $qjno
		qjlist="$qjlist;$ctName:8485"
	done
	qjlist=${qjlist:1}
}

