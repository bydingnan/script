#-*- coding=utf-8 -*-
import os
import sys
import ConfigParser
import csv
import codecs

reload(sys)
sys.setdefaultencoding("utf-8")

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

CONTENT_MIME = 'text/html'
ATTACH_MIME = "text/csv"

class SendEMail:
    def __init__(self, time, logger, flag):
        self.time = time
        self.logger = logger

        self.data_base_dir = "/home/talkmate/statistics/data/email/" + flag

        self.mail_to = "nan_ding@talkmate.com"
        #self.mail_to = "david_li@talkmate.com, ricky_cui@talkmate.com, nan_ding@talkmate.com"
        #self.mail_from = "nan_ding@talkmate.com"
        self.mail_from = "talkmate@talkmate.com"
        if "week" in flag:
            self.subject = "业务数据统计[周] " + self.time
        else:
            self.subject = "业务数据统计[日] " + self.time
        self.content_file = "./data/content/mail_content.%s" % self.time
        #self.content_file = "../send_email/email_content/mail_content.%s" % self.time

    def __prepare_sent_data(self, result_map):
        ret = 0
        rule_path = ""
        rule_map = {}
        try:
            # 记录拼接
            send_list_rule = []
            for item in result_map["user_rule"]:
                rule_list = item.split("\t")
                [userid, title, desc1, desc2, words] = rule_list
                send_list_rule.append(rule_list)
                rule_map[userid] = rule_list
 
            # 没有增量, 不发送邮件
        except Exception as e:
            print e
            #self.logger.info("ERROR: __prepare_sent_data %s" % e)
            return {}
        else:
            return rule_map

    def __prepare_mail_content(self):
        try:
            subject = self.subject
            in_fd = open(self.content_file, 'w')
            email_msg = "From: %s \nTo: %s \nSubject: %s \nMime-Version: 1.0\n" % \
                        (self.mail_from, self.mail_to, subject)
            in_fd.write(email_msg)
            content = "<html>\n<head>\n<style type=\"text/css\">\nth{background-color: #A8CDF1}\n" + \
                    '</style>\n</head>\n<body>\n<p style="font-size:130%">Hi, all</p>' + \
                    '<p style="font-size:120%;color:LightCoral"> 目前的统计包含了三个维度，日新增用户统计、周活跃用户相关统计、和全量用户数据统计。其中日和周的用户统计只覆盖了安装或者更新5.21上线的新版本APP的IOS用户和Web用户，未更新的老用户或者Android用户数据只能在全量用户数据中体现。而且目前活跃用户统计是注册量+登录量，没有包含再次打开APP的已登录用户，这个下个版本会添加。</p>' + \
                      "详细结果如下表:<br/>"

            file_list = sorted(os.listdir(self.data_base_dir), key=lambda x:x.split("-")[1])
            for file in file_list:
                with open(self.data_base_dir + "/" + file) as fd:
                    head = next(fd).strip("\n").split("\t")
                    content += '<br\>' + '<b style="font-size:120%;color:green">' + file.split("-")[0] + '</b>' + '\n'
                    content += "<table>\n"
                    for item in head:
                        content += "<th>" + item + "</th>\n"
                    content += "</tr>\n"

                    for line in fd:
                        line_content = line.strip("\n").split("\t")
                        content += "<tr>\n"
                        for item in line_content:
                            content += '<th style="text-align:left">' + item + '</th>\n'
                        content += '</tr>\n'
                    content += "</table>\n"

            content += "</body>\n</html>"

#            content += "<br\>表1\n\
#                    <table>\n\
#                    <tr>\n\
#                    <th>账户ID</th>\n\
#                    <th>words</th>\n\
#                    <th>title</th>\n\
#                    <th>desc1</th>\n\
#                    <th>desc2</th>\n\
#                    </tr>\n"
#            for key in r_map:
#                [userid, title, desc1, desc2, words] = r_map[key]
#                temp = '<tr>\n\
#                        <th style="text-align:left">%s</th>\n\
#                        <th style="text-align:left">%s</th>\n\
#                        <th style="text-align:left">%s</th>\n\
#                        <th style="text-align:left">%s</th>\n\
#                        <th style="text-align:left">%s</th>\n\
#                        </tr>\n' % (userid, words, title, desc1, desc2)
#                content += temp
#            content += "</table>\n"
#
#            content += "</body>\n</html>"
#
#            content += "\n<br\>表1\n\
#                        <table>\n\
#                        <tr>\n\
#                        <th>账户ID</th>\n\
#                        <th>words</th>\n\
#                        <th>title</th>\n\
#                        <th>desc1</th>\n\
#                        <th>desc2</th>\n\
#                        </tr>\n"

            email_msg = 'Content-Type: multipart/mixed; boundary="GvXjxJ+pjyke8COw"\n\n' + \
                        '--GvXjxJ+pjyke8COw\nContent-type: text/html;\n' + \
                        'Content-Disposition: inline\n' + \
                        'Content-Transfer-Encoding: 7bit\n\n' + \
                        content + '\n\n--GvXjxJ+pjyke8COw\n'
            in_fd.write(email_msg)

            # 附件1
#            attach_display_name = os.path.basename(rule_path)
#            email_msg = 'Content-Type: ' + ATTACH_MIME +'\nContent-Disposition:attachement;filename=' \
#                        + attach_display_name + '\n\n'
#            in_fd.write(email_msg)
#            rule_fd = open(rule_path, 'r')
#            for line in rule_fd:
#                in_fd.write(line)
#            rule_fd.close()
#            in_fd.write("\n--GvXjxJ+pjyke8COw\n")

            # 附件2
#            attach_display_name = os.path.basename(rule_path)
#            email_msg = 'Content-Type: ' + ATTACH_MIME +'\nContent-Disposition:attachement;filename=' \
#                        + attach_display_name + '\n\n'
#            in_fd.write(email_msg)
#            url_fd = open(url_path, 'r')
#            for line in url_fd:
#                in_fd.write(line)
#            url_fd.close()

            in_fd.close()
            return 0
        except Exception as e:
            print e
            self.logger.info("ERROR: __prepare_mail_content %s" % e)
            return 1
        finally:
            in_fd.close()

    def send_email(self):
        try:
            #rule_map = self.__prepare_sent_data(result_map)

            ret = self.__prepare_mail_content()
            if ret != 0:
                return ret

            sent_mail_cmd = "cat %s | /usr/lib/sendmail -t" % (self.content_file)
            if 0 == os.system(sent_mail_cmd):
                print "send success"
            else:
                print "send failed"
        except Exception as e:
            return 1
        else:
            return 0

#/* vim: set expandtab ts=4 sw=4 sts=4 tw=100: */
