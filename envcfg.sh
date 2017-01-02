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
#配置zookeeper
zoocfg=/home/hadoop/zookeeper-3.4.9/conf/zoo.cfg
for((i=0;i<${#zknodes[@]};i++))
do
	zkno=${zknodes[$i]}
	getctInfo $zkno
	echo $ctName
	docker exec $ctName su - hadoop  -c "cp /home/hadoop/zookeeper-3.4.9/conf/zoo_sample.cfg $zoocfg"
	docker exec $ctName su - hadoop  -c  "sed '/dataDir=/'d $zoocfg > $zoocfg.tmp;mv $zoocfg.tmp $zoocfg"
	docker exec $ctName su - hadoop  -c  "echo "dataDir=/home/hadoop/zkdata" >> $zoocfg"
	docker exec $ctName su - hadoop  -c  "echo "dataLogDir=/home/hadoop/zklogs" >> $zoocfg"
	((sid=$i+1))
	docker exec $ctName su - hadoop  -c  "echo $sid > /home/hadoop/zkdata/myid"
	mainhost=$ctName
	for((k=0;k<${#zknodes[@]};k++))
	do
		zknosub=${zknodes[$k]}
		getctInfo $zknosub
		((sid=$k+1))
		docker exec $mainhost su - hadoop  -c  "echo "server.$sid=$ctName:2888:3888" >> $zoocfg"
	done
done
echo '配置zookeeper节点成功！'
#配置hadoop
dsttemp=/tmp/hd.temp.$RANDOM
mkdir $dsttemp
\cp -rf $DIR/hd.template/* $dsttemp
#[1]core-site.xml生成
sed -i "s/\[halogical\]/$halogical/g" $dsttemp/core-site.xml.lte
sed -i "s/\[iobuffersize\]/$iobuffersize/g" $dsttemp/core-site.xml.lte
getzklist
sed -i "s/\[zklist\]/$zklist/g" $dsttemp/core-site.xml.lte
mv $dsttemp/core-site.xml.lte $dsttemp/core-site.xml
#[2]hadoop-env.sh生成
sed -i "s/\[hadoopheapsize\]/$hadoopheapsize/g" $dsttemp/hadoop-env.sh.lte 
mv $dsttemp/hadoop-env.sh.lte $dsttemp/hadoop-env.sh
#[3]hdfs-site.xml生成
sed -i "s/\[dfsmutileno\]/$dfsmutileno/g" $dsttemp/hdfs-site.xml.lte
getctInfo $nn1host
sed -i "s/\[nn1host\]/$ctName/g" $dsttemp/hdfs-site.xml.lte
getctInfo $nn2host
sed -i "s/\[nn2host\]/$ctName/g" $dsttemp/hdfs-site.xml.lte
getqjlist
sed -i "s/\[qjlist\]/$qjlist/g" $dsttemp/hdfs-site.xml.lte
sed -i "s/\[halogical\]/$halogical/g" $dsttemp/hdfs-site.xml.lte
mv $dsttemp/hdfs-site.xml.lte $dsttemp/hdfs-site.xml
#[4]mapred-site.xml生成
getctInfo $jobhistoryhost
sed -i "s/\[jobhistoryhost\]/$ctName/g" $dsttemp/mapred-site.xml.lte
sed -i "s/\[mrchildmb\]/$mrchildmb/g" $dsttemp/mapred-site.xml.lte
sed -i "s/\[mrmapmemorymb\]/$mrmapmemorymb/g" $dsttemp/mapred-site.xml.lte
sed -i "s/\[mrreducememorymb\]/$mrreducememorymb/g" $dsttemp/mapred-site.xml.lte
sed -i "s/\[mrmapmb\]/$mrmapmb/g" $dsttemp/mapred-site.xml.lte
mv $dsttemp/mapred-site.xml.lte $dsttemp/mapred-site.xml
#[5]yarn-env.sh生成
sed -i "s/\[yarnjavaheapmax\]/$yarnjavaheapmax/g" $dsttemp/yarn-env.sh.lte 
mv $dsttemp/yarn-env.sh.lte $dsttemp/yarn-env.sh
#[6]yarn-site.xml生成
getctInfo $nn1host
sed -i "s/\[nn1host\]/$ctName/g" $dsttemp/yarn-site.xml.lte 
getctInfo $nn2host
sed -i "s/\[nn2host\]/$ctName/g" $dsttemp/yarn-site.xml.lte
sed -i "s/\[halogical\]/$halogical/g" $dsttemp/yarn-site.xml.lte
sed -i "s/\[zklist\]/$zklist/g" $dsttemp/yarn-site.xml.lte
sed -i "s/\[yarnvmemratio\]/$yarnvmemratio/g" $dsttemp/yarn-site.xml.lte
sed -i "s/\[yarnvmemcheck\]/$yarnvmemcheck/g" $dsttemp/yarn-site.xml.lte
sed -i "s/\[yarnminalloc\]/$yarnminalloc/g" $dsttemp/yarn-site.xml.lte
mv $dsttemp/yarn-site.xml.lte $dsttemp/yarn-site.xml
#[7]生成slaves
for((i=1;i<=$nodesize;i++))
do
	if [ ! $i -eq $nn1host -a ! $i -eq $nn2host ];then
		getctInfo $i
		echo $ctName >> $dsttemp/slaves
	fi
done
#同步文件
chown -R hadoop $dsttemp
chgrp -R hadoop $dsttemp
for((i=1;i<=$nodesize;i++))
do
	getctInfo $i
	su - hadoop -c "scp -r -o 'StrictHostKeyChecking no' $dsttemp/* $ctName:/home/hadoop/hadoop-2.7.3/etc/hadoop"
done
echo '配置hadoop节点成功！'
#配置hbase
dsttemp=/tmp/hbase.temp.$RANDOM
#dsttemp2=/tmp/hbase.temp.$RANDOM
mkdir $dsttemp
#mkdir $dsttemp2
\cp -rf $DIR/hbase.template/* $dsttemp
#\cp -rf $DIR/hbase.cover/* $dsttemp2
#[1]hbase-site.xml生成
sed -i "s/\[halogical\]/$halogical/g" $dsttemp/hbase-site.xml.lte
getctInfo $hmaster
sed -i "s/\[hmaster\]/$ctName/g" $dsttemp/hbase-site.xml.lte
getzklist
sed -i "s/\[zklist\]/$zklist/g" $dsttemp/hbase-site.xml.lte
mv $dsttemp/hbase-site.xml.lte $dsttemp/hbase-site.xml
#[2]生成regionservers
touch $dsttemp/regionservers
for((k=0;k<${#regionservers[@]};k++))
do
	rsno=${regionservers[$k]}
	getctInfo $rsno
	echo $ctName >> $dsttemp/regionservers
done
#同步文件
chown -R hadoop $dsttemp
chgrp -R hadoop $dsttemp
for((i=1;i<=$nodesize;i++))
do
	getctInfo $i
	su - hadoop -c "scp -r -o 'StrictHostKeyChecking no' $dsttemp/* $ctName:/home/hadoop/hbase-1.2.4/conf"
#	su - hadoop -c "scp -r -o 'StrictHostKeyChecking no' $dsttemp2/* $ctName:/home/hadoop/hbase-1.2.4/lib"
done
echo '配置hbase节点成功！'
