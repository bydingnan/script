#!/bin/bash
export LC_ALL=zh_CN.UTF-8

today=`date +%Y%m%d`
cd /home/talkmate/statistics
echo "statistics_weekly.sh"
bash statistics_weekly.sh
sleep 3
echo "python mongo.py"
python mongo.py
sleep 3
echo "send mail"
python run_send_mail.py log_weekly $today weekly
cd -
