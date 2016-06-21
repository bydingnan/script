#encoding=utf-8
import sys
import os
import json

reload(sys)
sys.setdefaultencoding('utf-8')

lan_level = {}
lan_unit = {}
lan_chapter = {}
user_phone = {}
user_email = {}
user_nickname = {}

for lan_code in open("list"):
    last_level = ""
    last_unit = ""
    last_chapter = ""
    for line in open("course_" + lan_code.strip().lower() + ".csv"):
        json_dict = json.loads(line.strip())
        level = json_dict["level"]
        unit = json_dict["unit"]
        chapter = json_dict["chapter"]
        if level >= last_level:
            last_level = level
            if unit >= last_unit:
                last_unit = unit
                if chapter >= last_chapter:
                    last_chapter = chapter
    lan_level[lan_code.strip()] = last_level
    lan_unit[lan_code.strip()] = last_unit
    lan_chapter[lan_code.strip()] = last_chapter

for line in open("users.csv"):
    json_dict = json.loads(line.strip())
    user_id = json_dict["_id"]["$oid"].encode("utf-8")
    phonenumber = json_dict.get("phonenumber", "")
    email = json_dict.get("email", "")
    nickname = json_dict.get("nickname", "")
    user_phone[user_id] = phonenumber
    user_email[user_id] = email
    user_nickname[user_id] = nickname

for line in open("course_progress_v2.csv"):
    try:
        json_dict = json.loads(line.strip())
        lan_code = json_dict["language"].encode("utf-8")
        user_id = json_dict["user_id"]
        chapter = json_dict["chapter"]
        unit = json_dict["unit"]
        level = json_dict["level"]
        phonenumber = user_phone.get(user_id, "")
        email = user_email.get(user_id, "")
        nickname = user_nickname.get(user_id, "")
        if level == lan_level[lan_code] and unit == lan_unit[lan_code] and chapter == lan_chapter[lan_code]:
            print "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (user_id, nickname, phonenumber, email, lan_code, level, unit, chapter)
    except Exception as e:
        continue
