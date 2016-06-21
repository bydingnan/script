
OUTPUT="output/gen/"
log=""
for line in `cat mapping_file_log`
do
    if [ -z "$log" ];then
        log=`echo $line | cut -d "_" -f 3`
    else
        log=`echo $line | cut -d "_" -f 3`" "$log
    fi
done

db=""
for line in `cat mapping_file_db`
do
    if [ -z "$db" ];then
        db=$line
    else
        db=$line" "$db
    fi
done

total="$db $log"

log_array=($log)
db_array=($db)
total_array=($total)

#gen header file
if [ ! -d $OUTPUT/header ];then
    mkdir -p $OUTPUT/header
else
    rm -rf $OUTPUT/header/*
fi
for name in ${log_array[@]}
do
    echo "field=$name" > $OUTPUT/header/$name
done


#gen flume conf
CONF_FILE_NAME=hdfs_server.conf
AGENT_NAME="agent1"

if [ -f $OUTPUT/$CONF_FILE_NAME ];then
    rm $OUTPUT/$CONF_FILE_NAME
fi

function append() {
    echo "$1" >> $OUTPUT/$CONF_FILE_NAME
}

SOURCE_DB="source_db"
SOURCE_LOG="source_log"
append "# Name the components on this agent"
append "$AGENT_NAME.sources = $SOURCE_DB $SOURCE_LOG"

total_sink_prefix=""
for name in ${total_array[@]}
do
    if [ -z total_sink_prefix ];then
        total_sink_prefix=$name
    else
        total_sink_prefix="sink_"$name" "$total_sink_prefix
    fi
done
append "$AGENT_NAME.sinks = $total_sink_prefix"

total_channel_prefix=""
for name in ${total_array[@]}
do
    if [ -z total_channel_prefix ];then
        total_channel_prefix=$name
    else
        total_channel_prefix="channel_"$name" "$total_channel_prefix
    fi
done

append "$AGENT_NAME.channels = $total_channel_prefix"
append

db_channel_prefix=""
for name in ${db_array[@]}
do
    if [ -z db_channel_prefix ];then
        db_channel_prefix=$name
    else
        db_channel_prefix="channel_"$name" "$db_channel_prefix
    fi
done

append "# Describe/configure the $SOURCE_DB"
append "$AGENT_NAME.sources.$SOURCE_DB.type = avro"
append "$AGENT_NAME.sources.$SOURCE_DB.bind = localhost"
append "$AGENT_NAME.sources.$SOURCE_DB.port = 55555"
append "$AGENT_NAME.sources.$SOURCE_DB.channels = $db_channel_prefix"
append

log_channel_prefix=""
for name in ${log_array[@]}
do
    if [ -z log_channel_prefix ];then
        log_channel_prefix=$name
    else
        log_channel_prefix="channel_"$name" "$log_channel_prefix
    fi
done

append "# Describe/configure the $SOURCE_LOG"
append "$AGENT_NAME.sources.$SOURCE_LOG.type = avro"
append "$AGENT_NAME.sources.$SOURCE_LOG.bind = localhost"
append "$AGENT_NAME.sources.$SOURCE_LOG.port = 44444"
append "$AGENT_NAME.sources.$SOURCE_LOG.channels = $log_channel_prefix"
append

append "$AGENT_NAME.sources.$SOURCE_DB.selector.type = multiplexing"
append "$AGENT_NAME.sources.$SOURCE_DB.selector.header = field"
for name in ${db_array[@]}
do
    append "$AGENT_NAME.sources.$SOURCE_DB.selector.mapping.$name = channel_$name"
done
append

append "$AGENT_NAME.sources.$SOURCE_LOG.selector.type = multiplexing"
append "$AGENT_NAME.sources.$SOURCE_LOG.selector.header = field"
for name in ${log_array[@]}
do
    append "$AGENT_NAME.sources.$SOURCE_LOG.selector.mapping.$name = channel_$name"
done
append

append "# Describe db sink"
for name in ${db_array[@]}
do
    lower_name=`echo $name | sed -E 's/([A-Z])/_\l&/g' | sed 's/_//'`
    append "$AGENT_NAME.sinks.sink_$name.type = hdfs"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.path = hdfs://NameNode:8020/talkmate/db/$lower_name"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollInterval = 0"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.fileType = DataStream"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollSize = 50000000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.batchSize = 2000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollCount = 100000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.useLocalTimeStamp = true"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.writeFormat = Text"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.filePrefix = $lower_name"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.inUseSuffix = .tmp"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.idleTimeout = 30"
    append
done

append "# Describe log sink"
for name in ${log_array[@]}
do
    lower_name=`echo $name | sed -E 's/([A-Z])/_\l&/g' | sed 's/_//'`
    append "$AGENT_NAME.sinks.sink_$name.type = hdfs"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.path = hdfs://NameNode:8020/talkmate/logs/$lower_name"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollInterval = 0"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.fileType = DataStream"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollSize = 50000000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.batchSize = 2000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.rollCount = 100000"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.addSaveTime = true"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.useLocalTimeStamp = true"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.writeFormat = Text"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.filePrefix = $lower_name"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.inUseSuffix = .tmp"
    append "$AGENT_NAME.sinks.sink_$name.hdfs.idleTimeout = 30"
    append
done

append "# agent FileChannel"
for name in ${total_array[@]}
do
    append "$AGENT_NAME.channels.channel_$name.type = file"
    append "$AGENT_NAME.channels.channel_$name.checkpointDir = /home/talkmate/Deploy/fchannel/$name/checkpoint"
    append "$AGENT_NAME.channels.channel_$name.dataDirs = /home/talkmate/Deploy/fchannel/$name/data"
    append "$AGENT_NAME.channels.channel_$name.capacity = 1000000"
    append "$AGENT_NAME.channels.channel_$name.keep-alive = 30"
    append "$AGENT_NAME.channels.channel_$name.transactionCapacity = 2000"
    append "$AGENT_NAME.channels.channel_$name.write-timeout = 30"
    append "$AGENT_NAME.channels.channel_$name.checkpoint-timeout=600"
    append
done

append "# Bind the source and sink to the channel"
for name in ${total_array[@]}
do
    append "$AGENT_NAME.sinks.sink_$name.channel = channel_$name"
done


#gen run server script
echo "./bin/flume-ng agent -n $AGENT_NAME -c ./conf -f ./conf/$CONF_FILE_NAME  > logs/runtime.log 2>&1" > $OUTPUT/run.sh

#gen push_log script
echo "export JAVA_HOME=/home/talkmate/softwares/jdk1.8.0_91" > $OUTPUT/push_log.sh
echo >> $OUTPUT/push_log.sh
echo "dir_array=($log)" >> $OUTPUT/push_log.sh
echo 'for dir in ${dir_array[@]}' >> $OUTPUT/push_log.sh
echo "do" >> $OUTPUT/push_log.sh
echo '    if [ -d /home/talkmate/Deploy/daily_log/data/$dir ];then' >> $OUTPUT/push_log.sh
echo '        rm /home/talkmate/Deploy/daily_log/data/$dir/*.COMPLETED' >> $OUTPUT/push_log.sh
echo '        ./bin/flume-ng avro-client -H localhost -p 44444 --dirname /home/talkmate/Deploy/daily_log/data/$dir --headerFile header/$dir -Dflume.root.logger=DEBUG,console --conf conf' >> $OUTPUT/push_log.sh
echo '        sleep 2' >> $OUTPUT/push_log.sh
echo '    fi' >> $OUTPUT/push_log.sh
echo 'done' >> $OUTPUT/push_log.sh

#gen push_db script
echo "export JAVA_HOME=/home/talkmate/softwares/jdk1.8.0_91" > $OUTPUT/push_db.sh
echo >> $OUTPUT/push_db.sh
for name in ${db_array[@]}
do
    echo "rm /home/talkmate/Deploy/log_parser/output/$name/*.COMPLETED" >> $OUTPUT/push_db.sh
    echo "./bin/flume-ng avro-client -H localhost -p 55555 --dirname /home/talkmate/Deploy/log_parser/output/$name --headerFile header/$name -Dflume.root.logger=DEBUG,console --conf conf" >> $OUTPUT/push_db.sh
    echo "sleep 10" >> $OUTPUT/push_db.sh
done
