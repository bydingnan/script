#!/bin/bash
#===============================================================================
#
#          FILE:  1.sh
# 
#         USAGE:  ./1.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 2016年05月25日 14时31分12秒 CST
#      REVISION:  ---
#===============================================================================
source /home/talkmate/.bashrc

DATA_PATH=/home/talkmate/statistics/data
DATA_PATH_DB=/home/talkmate/statistics/data/db
DATA_PATH_LOG=/home/talkmate/statistics/data/log
DATA_PATH_EMAIL_WEEKLY=/home/talkmate/statistics/data/email/weekly
HADOOP_PATH=/home/talkmate/softwares/hadoop-2.6.4/bin

if [ ! -d $DATA_PATH_DB ];then
	mkdir -p $DATA_PATH_DB
fi
if [ ! -d $DATA_PATH_LOG ];then
	mkdir -p $DATA_PATH_LOG
fi
if [ ! -d $DATA_PATH_EMAIL_WEEKLY ];then
	mkdir -p $DATA_PATH_EMAIL_WEEKLY
fi

today=`date +%Y%m%d`
yesterday=`date -d '1 day ago' +%Y%m%d`
lan_code=(ENG JPN SPA CAN KOR FRE RUS GER ITA THA KAZ CHI POL FAR DAN POR DUT TIB VIE ARA URD ICE RUM HUN UYG HIN TUR SIN UKR NOR SWE MAY IND HRV SER ALB)

#全量用户
$HADOOP_PATH/hadoop fs -getmerge /talkmate/db/user_info/$today/ $DATA_PATH_DB/users
total_user_num=`wc -l $DATA_PATH_DB/users | awk '{print $1}'`

timestamp=`date -d '7 day ago' +%Y%m%d`

#周用户注册信息统计
rm $DATA_PATH_LOG/week_user_register
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_register | grep user_register | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_register/$i/* >> $DATA_PATH_LOG/week_user_register
    fi
done
#rm $DATA_PATH_LOG/user_bind_activity
#for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_bind_activity | grep user_bind | awk -F"/" '{print $NF}'`
#do
#    if [ $i -gt $timestamp ];then
#        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_bind_activity/$i/* >> $DATA_PATH_LOG/user_bind_activity
#    fi
#done

week_user_register_num=`cat $DATA_PATH_LOG/week_user_register | wc -l`
week_verify_email_num=`awk -F"\t" 'ARGIND==1{if($21=="Y"){arr[$1]}}ARGIND==2{if($1 in arr){print 2}}' $DATA_PATH_DB/users $DATA_PATH_LOG/week_user_register | wc -l`
week_bind_weixin=`awk -F"\t" '{print $9}' $DATA_PATH_LOG/week_user_register | grep -i weixin | wc -l`
week_bind_qq=`awk -F"\t" '{print $9}' $DATA_PATH_LOG/week_user_register | grep -i qq | wc -l`
week_bind_weibo=`awk -F"\t" '{print $9}' $DATA_PATH_LOG/week_user_register | grep -i weibo | wc -l`
week_bind_fb=`awk -F"\t" '{print $9}' $DATA_PATH_LOG/week_user_register | grep -i fb | wc -l`
week_email_register=`awk -F"\t" '{print $2}' $DATA_PATH_LOG/week_user_register | grep -i email | wc -l`
week_phone_register=`echo "$week_user_register_num - $week_email_register" | bc`
week_email_register_rate=""
week_phone_register_rate=""
if [ $week_user_register_num -gt 0 ];then
    week_email_register_rate=`echo "scale=4;$week_email_register / $week_user_register_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    week_phone_register_rate=`echo "scale=4;$week_phone_register / $week_user_register_num * 100" | bc | awk '{printf "%.2f%", $0}'`
fi
echo -e "一周新增用户数\t验证邮箱数\t绑定微信数\t绑定QQ数\t绑定微博数\t绑定FB数\t邮箱注册占比\t手机号注册占比" > $DATA_PATH_EMAIL_WEEKLY/"用户注册信息统计[周]-1"
echo -e $week_user_register_num"\t"$week_verify_email_num"\t"$week_bind_weixin"\t"$week_bind_qq"\t"$week_bind_weibo"\t"$week_bind_fb"\t"$week_email_register_rate"\t"$week_phone_register_rate >> $DATA_PATH_EMAIL_WEEKLY/"用户注册信息统计[周]-1"


#周活跃用户
rm $DATA_PATH_LOG/week_user_login
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_login | grep user_login | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_login/$i/* >> $DATA_PATH_LOG/week_user_login
    fi
done
rm $DATA_PATH_LOG/week_user_open_app
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_open_app | grep open_app | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_open_app/$i/* >> $DATA_PATH_LOG/week_user_open_app
    fi
done
awk -F"\t" '{if(!($1 in arr)){print $1"\t"$4;arr[$1]}}' $DATA_PATH_LOG/week_user_login > $DATA_PATH_LOG/week_user_active_org
awk -F"\t" '{if(!($1 in arr)){print $1"\t"$7;arr[$1]}}' $DATA_PATH_LOG/week_user_register >> $DATA_PATH_LOG/week_user_active_org
awk -F"\t" '{if(!($1 in arr)){print $1"\t"$2;arr[$1]}}' $DATA_PATH_LOG/week_user_open_app >> $DATA_PATH_LOG/week_user_active_org
awk -F"\t" '{if(!($1 in arr)){print $1"\t"$2;arr[$1]}}' $DATA_PATH_LOG/week_user_active_org > $DATA_PATH_LOG/week_user_active
week_user_active_num=`wc -l $DATA_PATH_LOG/week_user_active | awk '{print $1}'`

#作业
homework_submit=""
rm $DATA_PATH_LOG/user_homework_submit
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_homework_submit | grep homework_submit | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_homework_submit/$i/* >> $DATA_PATH_LOG/user_homework_submit
    fi
done

rm $DATA_PATH_LOG/user_group_homework_submit
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_group_homework_submit | grep homework_submit | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_group_homework_submit/$i/* >> $DATA_PATH_LOG/user_group_homework_submit
    fi
done

rm $DATA_PATH_LOG/user_homework_modify
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_homework_modify | grep homework_modify | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_homework_modify/$i/* >> $DATA_PATH_LOG/user_homework_modify
    fi
done

#总数
#homework_user_num=`awk -F"\t" 'ARGIND==1{homeworkid[$2];print $1}ARGIND==2{if($2 in homeworkid){print $1}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | sort -u | wc -l`
homework_submit_num=`awk -F"\t" '{print $2}' $DATA_PATH_LOG/user_homework_submit | sort -u | wc -l`
homework_reply_num=`awk -F"\t" 'ARGIND==1{homeworkid[$2]}ARGIND==2{if($2 in homeworkid){print 1}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | wc -l`
homework_did_modify_num=`awk -F"\t" 'ARGIND==1{homeworkid[$2]}ARGIND==2{if($2 in homeworkid){print $2}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | sort -u | wc -l`
homework_not_modify_num=`echo $homework_submit_num - $homework_did_modify_num | bc`
homework_submit_avg=""
homework_reply_avg=""
user_reply_avg=""
homework_not_modify_rate=""
if [ $week_user_active_num -gt 0 ];then
    homework_submit_avg=`echo "scale=2;$homework_submit_num / $week_user_active_num" | bc | awk '{printf "%.2f", $0}'`
    user_reply_avg=`echo "scale=2;$homework_reply_num / $week_user_active_num" | bc | awk '{printf "%.2f", $0}'`
fi
if [ $homework_submit_num -gt 0 ];then
    homework_reply_avg=`echo "scale=2;$homework_reply_num / $homework_submit_num" | bc | awk '{printf "%.2f", $0}'`
    homework_not_modify_rate=`echo "scale=4;$homework_not_modify_num / $homework_submit_num * 100" | bc | awk '{printf "%.2f%", $0}'`
fi

echo -e "语言\t活跃用户数\t提交作业总数\t作业留言总数\t平均每人作业数\t平均每条作业留言数\t平均每人留言数\t未批改作业占比" > $DATA_PATH_EMAIL_WEEKLY/"作业使用情况统计[周活跃]-4"
echo -e "总计\t"$week_user_active_num"\t"$homework_submit_num"\t"$homework_reply_num"\t"$homework_submit_avg"\t"$homework_reply_avg"\t"$user_reply_avg"\t"$homework_not_modify_rate >> $DATA_PATH_EMAIL_WEEKLY/"作业使用情况统计[周活跃]-4"

#按语言区分
for lan in ${lan_code[@]}
do
    lan_name=`awk -F"\t" -vlan=$lan '{arr[$1]=$2}END{if(lan in arr){print arr[lan]}}' $DATA_PATH/lan_code`
    homework_submit_num=`awk -F"\t" -vlan=$lan '$3==lan{print $2}' $DATA_PATH_LOG/user_homework_submit | sort -u | wc -l`
    homework_reply_num=`awk -F"\t" -vlan=$lan 'ARGIND==1 && $3==lan{homeworkid[$2]}ARGIND==2{if($2 in homeworkid){print 1}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | wc -l`
    homework_did_modify_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$3==lan{homeworkid[$2]}ARGIND==2{if($2 in homeworkid){print $2}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | sort -u | wc -l`

    homework_not_modify_num=`echo $homework_submit_num - $homework_did_modify_num | bc`
    #homework_user_num=`awk -F"\t" -vlan=$lan 'ARGIND==1 && $3==lan{homeworkid[$2];print $1}ARGIND==2{if($2 in homeworkid){print $1}}' $DATA_PATH_LOG/user_homework_submit $DATA_PATH_LOG/user_homework_modify | sort -u | wc -l`
    homework_submit_avg=""
    homework_reply_avg=""
    user_reply_avg=""
    homework_not_modify_rate=""
    if [ $week_user_active_num -gt 0 ];then
        homework_submit_avg=`echo "scale=2;$homework_submit_num / $week_user_active_num" | bc | awk '{printf "%.2f", $0}'`
        user_reply_avg=`echo "scale=2;$homework_reply_num / $week_user_active_num" | bc | awk '{printf "%.2f", $0}'`
    fi
    if [ $homework_submit_num -gt 0 ];then
        homework_reply_avg=`echo "scale=2;$homework_reply_num / $homework_submit_num" | bc | awk '{printf "%.2f", $0}'`
        homework_not_modify_rate=`echo "scale=4;$homework_not_modify_num / $homework_submit_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    fi
	user_active_lan_num=`awk -F"\t" 'ARGIND==1{arr[$1]}ARGIND==2{if($1 in arr)print $22}' $DATA_PATH_LOG/week_user_active $DATA_PATH_DB/users | grep $lan | wc -l`
    echo -e $lan_name"\t"$user_active_lan_num"\t"$homework_submit_num"\t"$homework_reply_num"\t"$homework_submit_avg"\t"$homework_reply_avg"\t"$user_reply_avg"\t"$homework_not_modify_rate >> $DATA_PATH_EMAIL_WEEKLY/"作业使用情况统计[周活跃]-4"
done

#班级统计
rm $DATA_PATH_LOG/group_create
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/group_create | grep group_create | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/group_create/$i/* >> $DATA_PATH_LOG/group_create
    fi
done

rm $DATA_PATH_LOG/user_join_group
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_join_group | grep join_group | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_join_group/$i/* >> $DATA_PATH_LOG/user_join_group
    fi
done

rm $DATA_PATH_LOG/group_morning_reading_create
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/group_morning_reading_create | grep group_morning | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/group_morning_reading_create/$i/* >> $DATA_PATH_LOG/group_morning_reading_create
    fi
done

rm $DATA_PATH_LOG/user_morning_reading_activity
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/user_morning_reading_activity | grep morning_reading | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/user_morning_reading_activity/$i/* >> $DATA_PATH_LOG/user_morning_reading_activity
    fi
done

rm $DATA_PATH_LOG/group_morning_reading_comment
for i in `$HADOOP_PATH/hadoop fs -ls /talkmate/logs/group_morning_reading_comment | grep morning_reading | awk -F"/" '{print $NF}'`
do
    if [ $i -gt $timestamp ];then
        $HADOOP_PATH/hadoop fs -cat /talkmate/logs/group_morning_reading_comment/$i/* >> $DATA_PATH_LOG/group_morning_reading_comment
    fi
done

#总数
group_create_num=`cat $DATA_PATH_LOG/group_create | wc -l`
group_user_num=`awk -F"\t" 'ARGIND==1{groupid[$1];print $4}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/user_join_group | sort -u | wc -l`
group_user_join_num=`awk -F"\t" 'ARGIND==1{groupid[$1]}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/user_join_group | wc -l`
group_morning_reading_num=`awk -F"\t" 'ARGIND==1{groupid[$1]}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create | wc -l`
group_user_join_avg=""
group_morning_reading_avg=""
if [ $group_create_num -gt 0 ];then
    group_user_join_avg=`echo "scale=2;$group_user_join_num / $group_create_num" | bc | awk '{printf "%.2f", $0}'`
    group_morning_reading_avg=`echo "scale=2;$group_morning_reading_num / $group_create_num" | bc | awk '{printf "%.2f", $0}'`
fi
group_morning_reading_following_num=`awk -F"\t" 'ARGIND==1{groupid[$1]}ARGIND==2{if($1 in groupid){readingid[$3]}}ARGIND==3{if($1 in readingid){print $3}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create $DATA_PATH_LOG/user_morning_reading_activity | wc -l`
group_morning_reading_following_avg=""
if [ $group_morning_reading_num -gt 0 ];then
    group_morning_reading_following_avg=`echo "scale=2;$group_morning_reading_following_num / $group_morning_reading_num" | bc | awk '{printf "%.2f", $0}'`
fi
group_morning_reading_comment_num=`awk -F"\t" 'ARGIND==1{groupid[$1]}ARGIND==2{if($1 in groupid){readingid[$3]}}ARGIND==3{if($1 in readingid){print $4}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create $DATA_PATH_LOG/user_morning_reading_comment | wc -l`
group_morning_reading_comment_avg=""
if [ $group_morning_reading_following_num -gt 0 ];then
    group_morning_reading_comment_avg=`echo "scale=2;$group_morning_reading_comment_num / $group_morning_reading_following_num" | bc | awk '{printf "%.2f", $0}'`
fi
group_user_rate=""
if [ $week_user_active_num -gt 0 ];then
	group_user_rate=`echo "scale=4;$group_user_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
fi
echo -e "语言\t活跃用户数\t一周内创建班级总数\t添加/创建班级人数\t一周内创建的班级平均成员数\t一周内创建班级平均晨读数\t一周内发布晨读平均跟读数\t一周内发布的跟读平均评论数" > $DATA_PATH_EMAIL_WEEKLY/"班级使用情况统计[周活跃]-5"
echo -e "总计\t"$week_user_active_num"\t"$group_create_num"\t"$group_user_rate"\t"$group_user_join_avg"\t"$group_morning_reading_avg"\t"$group_morning_reading_following_avg"\t"$group_morning_reading_comment_avg >> $DATA_PATH_EMAIL_WEEKLY/"班级使用情况统计[周活跃]-5"

#按语言区分
for lan in ${lan_code[@]}
do
    lan_name=`awk -F"\t" -vlan=$lan '{arr[$1]=$2}END{if(lan in arr){print arr[lan]}}' $DATA_PATH/lan_code`
    group_create_num=`cat $DATA_PATH_LOG/group_create | grep $lan | wc -l`
    group_user_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$2==lan{groupid[$1];print $4}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/user_join_group | sort -u | wc -l`
    group_user_join_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$2==lan{groupid[$1]}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/user_join_group | wc -l`
    group_morning_reading_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$2==lan{groupid[$1]}ARGIND==2{if($1 in groupid){print $2}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create | wc -l`
    group_user_join_avg=""
    group_morning_reading_avg=""
    if [ $group_create_num -gt 0 ];then
        group_user_join_avg=`echo "scale=2;$group_user_join_num / $group_create_num" | bc | awk '{printf "%.2f", $0}'`
        group_morning_reading_avg=`echo "scale=2;$group_morning_reading_num / $group_create_num" | bc | awk '{printf "%.2f", $0}'`
    fi
    group_morning_reading_following_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$2==lan{groupid[$1]}ARGIND==2{if($1 in groupid){readingid[$3]}}ARGIND==3{if($1 in readingid){print $3}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create $DATA_PATH_LOG/user_morning_reading_activity | wc -l`
    group_morning_reading_following_avg=""
    if [ $group_morning_reading_num -gt 0 ];then
        group_morning_reading_following_avg=`echo "scale=2;$group_morning_reading_following_num / $group_morning_reading_num" | bc | awk '{printf "%.2f", $0}'`
    fi
    group_morning_reading_comment_num=`awk -F"\t" -vlan=$lan 'ARGIND==1&&$2==lan{groupid[$1]}ARGIND==2{if($1 in groupid){readingid[$3]}}ARGIND==3{if($1 in readingid){print $4}}' $DATA_PATH_LOG/group_create $DATA_PATH_LOG/group_morning_reading_create $DATA_PATH_LOG/user_morning_reading_comment | wc -l`
    group_morning_reading_comment_avg=""
    if [ $group_morning_reading_following_num -gt 0 ];then
        group_morning_reading_comment_avg=`echo "scale=2;$group_morning_reading_comment_num / $group_morning_reading_following_num" | bc | awk '{printf "%.2f", $0}'`
    fi

	user_active_lan_num=`awk -F"\t" 'ARGIND==1{arr[$1]}ARGIND==2{if($1 in arr)print $22}' $DATA_PATH_LOG/week_user_active $DATA_PATH_DB/users | grep $lan | wc -l`
	group_user_lan_rate=""
	if [ $user_active_lan_num -gt 0 ];then
		group_user_lan_rate=`echo "scale=4;$group_user_num / $user_active_lan_num * 100" | bc | awk '{printf "%.2f%", $0}'`
	fi

    echo -e $lan_name"\t"$user_active_lan_num"\t"$group_create_num"\t"$group_user_lan_rate"\t"$group_user_join_avg"\t"$group_morning_reading_avg"\t"$group_morning_reading_following_avg"\t"$group_morning_reading_comment_avg >> $DATA_PATH_EMAIL_WEEKLY/"班级使用情况统计[周活跃]-5"
done




#个人信息完善统计
complete_personal_info_rate=""
has_thumbnail_rate=""
has_talkmateid_rate=""
has_gender_rate=""
has_age_rate=""
has_country_rate=""
has_description_rate=""
complete_personal_info_num=`awk -F"\t" '$20=="Y"' $DATA_PATH_DB/users | wc -l`
has_thumbnail_num=`awk -F"\t" '$12=="Y"' $DATA_PATH_DB/users | wc -l`
has_talkmateid_num=`awk -F"\t" '$3!=""' $DATA_PATH_DB/users | wc -l`
has_gender_num=`awk -F"\t" '$4!=""' $DATA_PATH_DB/users | wc -l`
has_age_num=`awk -F"\t" '$5>0' $DATA_PATH_DB/users | wc -l`
has_country_num=`awk -F"\t" '$9!=""' $DATA_PATH_DB/users | wc -l`
has_description_num=`awk -F"\t" '$11!=""' $DATA_PATH_DB/users | wc -l`
if [ $total_user_num -gt 0 ];then
    complete_personal_info_rate=`echo "scale=4;$complete_personal_info_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_thumbnail_rate=`echo "scale=4;$has_thumbnail_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_talkmateid_rate=`echo "scale=4;$has_talkmateid_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_gender_rate=`echo "scale=4;$has_gender_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_age_rate=`echo "scale=4;$has_age_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_country_rate=`echo "scale=4;$has_country_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_description_rate=`echo "scale=4;$has_description_num / $total_user_num * 100" | bc | awk '{printf "%.2f%", $0}'`

fi
echo -e "用户总数\t有头像用户占比\t有TalkmateID用户占比\t完善性别信息用户占比\t完善年龄信息用户占比\t完善地区信息用户占比\t完善个人介绍用户占比" > $DATA_PATH_EMAIL_WEEKLY/"个人完善信息统计-3"
echo -e $total_user_num"\t"$has_thumbnail_rate"\t"$has_talkmateid_rate"\t"$has_gender_rate"\t"$has_age_rate"\t"$has_country_rate"\t"$has_description_rate >> $DATA_PATH_EMAIL_WEEKLY/"个人完善信息统计-3"

#个人信息完善统计[周活跃]
awk -F"\t" 'ARGIND==1{arr[$1]}ARGIND==2{if($1 in arr){OFS="\t";print $0}}' $DATA_PATH_LOG/week_user_active $DATA_PATH_DB/users > $DATA_PATH_DB/users_active
complete_personal_info_num=`awk -F"\t" '$20=="Y"' $DATA_PATH_DB/users_active | wc -l`
has_thumbnail_num=`awk -F"\t" '$12=="Y"' $DATA_PATH_DB/users_active | wc -l`
has_talkmateid_num=`awk -F"\t" '$3!=""' $DATA_PATH_DB/users_active | wc -l`
has_gender_num=`awk -F"\t" '$4!=""' $DATA_PATH_DB/users_active | wc -l`
has_age_num=`awk -F"\t" '$5>0' $DATA_PATH_DB/users_active | wc -l`
has_country_num=`awk -F"\t" '$9!=""' $DATA_PATH_DB/users_active | wc -l`
has_description_num=`awk -F"\t" '$11!=""' $DATA_PATH_DB/users_active | wc -l`

complete_personal_info_rate=""
has_thumbnail_rate=""
has_talkmateid_rate=""
has_gender_rate=""
has_age_rate=""
has_country_rate=""
has_description_rate=""
if [ $week_user_active_num -gt 0 ];then
    complete_personal_info_rate=`echo "scale=4;$complete_personal_info_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_thumbnail_rate=`echo "scale=4;$has_thumbnail_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_talkmateid_rate=`echo "scale=4;$has_talkmateid_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_talkmateid_rate=`echo "scale=4;$has_talkmateid_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f", $0}'`
    has_gender_rate=`echo "scale=4;$has_gender_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_age_rate=`echo "scale=4;$has_age_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_country_rate=`echo "scale=4;$has_country_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`
    has_description_rate=`echo "scale=4;$has_description_num / $week_user_active_num * 100" | bc | awk '{printf "%.2f%", $0}'`

fi
echo -e "一周活跃用户总数\t有头像用户占比\t有TalkmateID用户占比\t完善性别信息用户占比\t完善年龄信息用户占比\t完善地区信息用户占比\t完善个人介绍用户占比" > $DATA_PATH_EMAIL_WEEKLY/"个人完善信息统计[周活跃]-2"
echo -e $week_user_active_num"\t"$has_thumbnail_rate"\t"$has_talkmateid_rate"\t"$has_gender_rate"\t"$has_age_rate"\t"$has_country_rate"\t"$has_description_rate >> $DATA_PATH_EMAIL_WEEKLY/"个人完善信息统计[周活跃]-2"

