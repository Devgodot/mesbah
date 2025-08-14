from flask import Blueprint, jsonify, request, current_app
from flask_caching import Cache
from confige import db, app, get_sort_by_birthday
from schemas import UserSchema, GroupSchema
from flask_jwt_extended import current_user, jwt_required
from random import randint
import random, os, shutil, requests
from models import User, UserInterface, Group, Planes, Score
import json
from datetime import datetime, timedelta
from sqlalchemy.orm.attributes import flag_modified
import jdatetime
import utils
from enum import Enum

def is_url_image(image_url):
    """
    Checks if a given URL points to an image.

    Args:
        image_url (str): The URL to check.

    Returns:
        bool: True if the URL points to an image, False otherwise.
    """
    image_formats = ("image/png", "image/jpeg", "image/jpg", "image/gif", "image/bmp", "image/webp")
    try:
        r = requests.head(image_url, timeout=5)  # Add a timeout for robustness
        if r.status_code == 200 and r.headers.get("content-type") in image_formats:
            return True
        return False
    except requests.exceptions.RequestException:
        # Handle network errors, invalid URLs, timeouts, etc.
        return False
cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
score_bp = Blueprint("score", __name__)
class HashingMode(Enum):
    ENCODE = 0
    DECODE = 1
words ={ "%": "%00%", "٠": "%zs%", "١": "%p3%", "٢": "%q6%", "٣": "%rz%", "٤": "%pi%", "٥": "%c5%", "٦": "%h5%", "٧": "%xa%", "٨": "%w1%", "٩": "%59%", "*": "%dh%", "$": "%n8%", "^": "%44%", "&": "%ga%", "۱": "%ry%", "۰": "%47%", "۲": "%j8%", "۳": "%4a%", "۴": "%w0%", "۵": "%df%", "۶": "%k5%", "۷": "%cq%", "۸": "%9v%", "۹": "%hu%", "ً": "%97%", "ٌ": "%vr%", "ٍ": "%q9%", "َ": "%8c%", "ُ": "%79%", "ِ": "%24%", "ـ": "%2c%", "؛": "%2v%", "«": "%1p%", "»": "%lz%", "ك": "%yz%", " ": "%08%", "‌": "%e7%", "!": "%6k%", "\"": "%wb%", "\'": "%ka%", "(": "%h7%", ")": "%gh%", "+": "%5g%", ",": "%4u%", "-": "%vb%", ".": "%z6%", "/": "%q7%", "0": "%qz%", "1": "%r6%", "2": "%2b%", "3": "%fj%", "4": "%0g%", "5": "%n3%", "6": "%cr%", "7": "%iz%", "8": "%ki%", "9": "%g5%", ":": "%uu%", ";": "%kq%", "<": "%96%", "=": "%26%", ">": "%sj%", "?": "%3y%", "@": "%19%", "[": "%5b%", "]": "%mf%", "_": "%9a%", "a": "%nx%", "b": "%zu%", "c": "%ir%", "d": "%zh%", "e": "%wi%", "f": "%h8%", "g": "%ue%", "h": "%50%", "i": "%xi%", "j": "%36%", "k": "%jj%", "l": "%wm%", "m": "%5x%", "n": "%7z%", "o": "%k1%", "p": "%c1%", "q": "%8u%", "r": "%n6%", "s": "%x3%", "t": "%91%", "u": "%6v%", "v": "%vs%", "w": "%d0%", "x": "%22%", "y": "%rd%", "z": "%b7%", "{": "%3r%", "}": "%v4%", "،": "%eh%", "؟": "%yv%", "ء": "%j5%", "أ": "%5h%", "ؤ": "%xe%", "إ": "%pj%", "ئ": "%3l%", "ا": "%2l%", "آ": "%dl%", "ب": "%r4%", "ة": "%1s%", "ت": "%c4%", "ث": "%wj%", "ج": "%ar%", "ح": "%x9%", "خ": "%2g%", "د": "%yg%", "ذ": "%7i%", "ر": "%ff%", "ز": "%1l%", "س": "%gy%", "ش": "%gr%", "ص": "%ph%", "ض": "%ap%", "ط": "%kb%", "ظ": "%wn%", "ع": "%mj%", "غ": "%bl%", "ف": "%v3%", "ق": "%04%", "ل": "%8i%", "م": "%9d%", "ن": "%wd%", "ه": "%4e%", "و": "%de%", "ي": "%sh%", "پ": "%x7%", "چ": "%ym%", "ژ": "%66%", "ک": "%8q%", "گ": "%7d%", "ی": "%xl%", "A": "%1h%", "B": "%6s%", "C": "%dv%", "D": "%q1%", "E": "%9k%", "F": "%aq%", "G": "%lm%", "H": "%eb%", "I": "%td%", "J": "%c3%", "K": "%wc%", "L": "%y8%", "M": "%t0%", "N": "%1a%", "O": "%gb%", "P": "%dj%", "Q": "%o9%", "R": "%si%", "S": "%ve%", "T": "%i4%", "U": "%ge%", "V": "%j3%", "W": "%2u%", "X": "%ll%", "Y": "%ob%", "Z": "%5e%" }

def find_key_by_value(dictionary, target_value):
    for key, value in dictionary.items():
        if value == target_value:
            return key
    return None
def hashing(mode:HashingMode, text=""):
    if mode == HashingMode.ENCODE:
        hash_text = ""
        for graph in text:
            hash_text += words.get(graph, "")
        return hash_text
    if mode == HashingMode.DECODE:
        new_text = ''
        graphs = text.split("%")
        for graph in graphs:
            if graph != "" and graph != "%":
                new_text += find_key_by_value(words, "%"+str(graph)+"%")
        return new_text

@score_bp.get("/get")
@jwt_required()
def get_score():
    user_id = request.args.get("user_id")
    user = User.get_user_by_username(user_id)
    if user is None:
        return jsonify({"error": "کاربر یافت نشد."}), 404
    score = Score.query.filter_by(name=user_id, plan=request.args.get("plan", ""), subplan=request.args.get("subplan", "")).first()
    value = score.score if score else 0
    print(request.args.get("plan", ""), request.args.get("subplan", ""), user_id, score)
    user_data = {
        "name": user.data.get("first_name", "") + " " +  user.data.get("last_name", ""),
        "father_name": user.data.get("father_name", ""),
        "phone": user.phone,
        "username": user.get_username(),
        "icon": user.data.get("icon", "") if is_url_image(user.data.get("icon", "")) else "",
    }
    if user.data.get("custom_name", "") != "" and user.data.get("pro", False):
        user_data["custom_name"] = user.data.get("custom_name", "")
    return jsonify({"score": value, "user": user_data}), 200
@score_bp.post("/add")
@jwt_required()
def add_score():
    if current_user.get_username() not in UserInterface.query.first().data.get("management", []):
        return jsonify({"error": "شما دسترسی لازم را ندارید."}), 403
    data = request.get_json()
    if not data or "name" not in data or "plan" not in data or "subplan" not in data or "score" not in data or "group" not in data:
        return jsonify({"error": "اطلاعات ناقص است."}), 400
    name = data["name"]
    plan = data["plan"]
    subplan = data["subplan"]
    print(plan)
    score_value = data["score"]
    if data["group"] == False:
        user = User.get_user_by_username(name)
        if user is None:
            return jsonify({"error": "کاربر یافت نشد."}), 404
    else:
        group = Group.get_group_by_name(name=name)
        if group is None:
            return jsonify({"error": "گروهی با این نام یافت نشد."}), 404
    existing_score = Score.query.filter_by(name=name, plan=plan, subplan=subplan).first()
    if existing_score:
        existing_score.score = score_value
        plan = Planes.query.filter_by(name=plan, subplan=subplan).first()
        if plan is None:
            return jsonify({"error": "برنامه‌ای یافت نشد."}), 404
        if score_value >= plan.diamond_range:
            existing_score.diamond = 1
        else:
            existing_score.diamond = 0
        db.session.commit()
        return jsonify({"message": "امتیاز به‌روزرسانی شد."}), 200
    year = str(gregorian_to_jalali(datetime.now()).year)
    if data["group"] == False:
        tag = user.tag
        new_score = Score(name=name, plan=plan, subplan=subplan, score=score_value, gender=user.gender, year=year, tag=tag)
        db.session.add(new_score)
        db.session.commit()
    else:
        group = Group.get_group_by_name(name=name)
        if group is None:
            return jsonify({"error": "گروهی یافت نشد."}), 404
        tag = group.tag
        new_score = Score(name=name, plan=plan, subplan=subplan, score=score_value, gender=group.gender, year=year, tag=tag, group=True)
        db.session.add(new_score)
        db.session.commit()
    return jsonify({"message": "امتیاز جدید اضافه شد."}), 201

@score_bp.get("/sort")
@jwt_required()
def sort_scores():
    plan = request.args.get("plan", "")
    subplan = request.args.get("subplan")
    MAX_MEMBERS = request.args.get("max_members", 10, type=int)
    if subplan is None:
        my_score = Score.query.filter_by(name=current_user.get_username(), plan=plan).first()
        tag = current_user.tag
        if my_score is None:
            scores = Score.query.filter_by(plan=plan, gender=current_user.gender, tag=tag, group=False).all()
        else:
            scores = Score.query.filter_by(plan=plan, gender=my_score.gender, tag=my_score.tag, group=False).all()
        # دیکشنری برای جمع امتیاز و الماس هر کاربر
        user_stats = {}
        for s in scores:
            if s.name not in user_stats:
                user_stats[s.name] = {"score_sum": 0, "diamond_sum": 0}
            user_stats[s.name]["score_sum"] += s.score
            user_stats[s.name]["diamond_sum"] += s.diamond

        # ساخت لیست برای مرتب‌سازی
        result = []
        for name, stats in user_stats.items():
            user = User.get_user_by_username(name)
            if user is None:
                continue
            result.append({
                "name": user.username,
                "first_name": user.data.get("first_name", ""),
                "last_name": user.data.get("last_name", ""),
                "father_name": user.data.get("father_name", ""),
                "icon": utils.hashing(text=user.data.get("icon", ""), mode=utils.HashingMode.ENCODE),
                "custom_name": user.data.get("custom_name", ""),
                "score_sum": stats["score_sum"],
                "diamond_sum": stats["diamond_sum"]
            })

        # مرتب‌سازی: اول بر اساس الماس، بعد امتیاز
        sorted_result = sorted(result, key=lambda x: (x["diamond_sum"], x["score_sum"]), reverse=True)

        # محاسبه جایگاه با در نظر گرفتن رتبه مشترک
        last_score = None
        last_diamond = None
        position = 0
        real_position = 0
        for item in sorted_result:
            real_position += 1
            if last_score == item["score_sum"] and last_diamond == item["diamond_sum"]:
                item["position"] = position
            else:
                position = real_position
                item["position"] = position
                last_score = item["score_sum"]
                last_diamond = item["diamond_sum"]
        # اضافه کردن اطلاعات کاربر خودی
        my_score_info = {
            "name": current_user.get_username(),
            "score_sum": user_stats.get(current_user.get_username(), {}).get("score_sum", 0),
            "diamond_sum": user_stats.get(current_user.get_username(), {}).get("diamond_sum", 0),
            "position": next((item["position"] for item in sorted_result if item["name"] == current_user.username), None)
        }
        
        sorted_result = sorted_result[:MAX_MEMBERS]

        return jsonify({"users": sorted_result, "your_info": my_score_info}), 200

    else:
        # فقط یک زیرطرح خاص
        my_score = Score.query.filter_by(name=current_user.get_username(), plan=plan, subplan=subplan).first()
        tag = current_user.tag
        if my_score is None:
            scores = Score.query.filter_by(plan=plan, subplan=subplan, gender=current_user.gender, tag=tag, group=False).all()
        else:
            scores = Score.query.filter_by(plan=plan, subplan=subplan, gender=my_score.gender, tag=my_score.tag, group=False).all()

        # دیکشنری برای جمع امتیاز و الماس هر کاربر فقط در همین زیرطرح
        user_stats = {}
        for s in scores:
            if s.name not in user_stats:
                user_stats[s.name] = {"score_sum": 0, "diamond_sum": 0}
            user_stats[s.name]["score_sum"] += s.score
            user_stats[s.name]["diamond_sum"] += s.diamond

        # ساخت لیست برای مرتب‌سازی
        result = []
        for name, stats in user_stats.items():
            user_obj = User.get_user_by_username(name)
            if user_obj is None:
                continue
            result.append({
                "name": user_obj.username,
                "first_name": user_obj.data.get("first_name", ""),
                "last_name": user_obj.data.get("last_name", ""),
                "father_name": user_obj.data.get("father_name", ""),
                "icon": utils.hashing(text=user_obj.data.get("icon", ""), mode=utils.HashingMode.ENCODE),
                "custom_name": user_obj.data.get("custom_name", ""),
                "score_sum": stats["score_sum"],
                "diamond_sum": stats["diamond_sum"]
            })

        # مرتب‌سازی: اول بر اساس الماس، بعد امتیاز
        sorted_result = sorted(result, key=lambda x: (x["diamond_sum"], x["score_sum"]), reverse=True)

        # محاسبه جایگاه با در نظر گرفتن رتبه مشترک
        last_score = None
        last_diamond = None
        position = 0
        real_position = 0
        for item in sorted_result:
            real_position += 1
            if last_score == item["score_sum"] and last_diamond == item["diamond_sum"]:
                item["position"] = position
            else:
                position = real_position
                item["position"] = position
                last_score = item["score_sum"]
                last_diamond = item["diamond_sum"]

        # اضافه کردن اطلاعات کاربر خودی
        my_score_info = {
            "name": current_user.get_username(),
            "score_sum": user_stats.get(current_user.get_username(), {}).get("score_sum", 0),
            "diamond_sum": user_stats.get(current_user.get_username(), {}).get("diamond_sum", 0),
            "position": next((item["position"] for item in sorted_result if item["name"] == current_user.username), None)
        }

        sorted_result = sorted_result[:MAX_MEMBERS]

        return jsonify({"users": sorted_result, "your_info": my_score_info}), 200

@score_bp.get("/group_sort")
@jwt_required()
def group_sort():
    group = Group.get_group_by_name(current_user.data.get("group_name", ""))
    plan = request.args.get("plan", "")
    subplan = request.args.get("subplan")
    MAX_MEMBERS = request.args.get("max_members", 10, type=int)
    if subplan is None:
        my_score = None
        if group:
            my_score = Score.query.filter_by(name=group.name, plan=plan).first()
            tag = group.tag
        else:
            tag = current_user.tag
        if my_score is None:
            scores = Score.query.filter_by(plan=plan, gender=current_user.gender, tag=tag, group=True).all()
        else:
            scores = Score.query.filter_by(plan=plan, gender=my_score.gender, tag=my_score.tag, group=True).all()
        # دیکشنری برای جمع امتیاز و الماس هر کاربر
        user_stats = {}
        for s in scores:
            if s.name not in user_stats:
                user_stats[s.name] = {"score_sum": 0, "diamond_sum": 0}
            user_stats[s.name]["score_sum"] += s.score
            user_stats[s.name]["diamond_sum"] += s.diamond

        # ساخت لیست برای مرتب‌سازی
        result = []
        for name, stats in user_stats.items():
            group_user = Group.get_group_by_name(name)
            if group_user is None:
                continue
            result.append({
                "name": group_user.name,
                "icon": utils.hashing(text=group_user.icon, mode=utils.HashingMode.ENCODE),
                "score_sum": stats["score_sum"],
                "diamond_sum": stats["diamond_sum"]
            })

        # مرتب‌سازی: اول بر اساس الماس، بعد امتیاز
        sorted_result = sorted(result, key=lambda x: (x["diamond_sum"], x["score_sum"]), reverse=True)

        # محاسبه جایگاه با در نظر گرفتن رتبه مشترک
        last_score = None
        last_diamond = None
        position = 0
        real_position = 0
        for item in sorted_result:
            real_position += 1
            if last_score == item["score_sum"] and last_diamond == item["diamond_sum"]:
                item["position"] = position
            else:
                position = real_position
                item["position"] = position
                last_score = item["score_sum"]
                last_diamond = item["diamond_sum"]
        
        # اضافه کردن اطلاعات کاربر خودی
        if group:
            my_score_info = {
                "name": group.name,
                "icon":group.icon,
                "score_sum": user_stats.get(group.name, {}).get("score_sum", 0),
                "diamond_sum": user_stats.get(group.name, {}).get("diamond_sum", 0),
                "position": next((item["position"] for item in sorted_result if item["name"] == group.name), None)
            }
        else:
            my_score_info = None
        
        sorted_result = sorted_result[:MAX_MEMBERS]
        return jsonify({"groups": sorted_result, "your_info": my_score_info}), 200

    else:
        # فقط یک زیرطرح خاص برای گروه‌ها
        group = Group.get_group_by_name(current_user.data.get("group_name", ""))
        plan = request.args.get("plan", "")
        subplan = request.args.get("subplan")
        MAX_MEMBERS = request.args.get("max_members", 10, type=int)

        my_score = None
        if group:
            my_score = Score.query.filter_by(name=group.name, plan=plan, subplan=subplan).first()
            tag = get_sort_by_birthday(group.leader_birthday)
        else:
            tag = get_sort_by_birthday(current_user.birthday)

        if my_score is None:
            scores = Score.query.filter_by(plan=plan, subplan=subplan, gender=current_user.gender, tag=tag, group=True).all()
        else:
            scores = Score.query.filter_by(plan=plan, subplan=subplan, gender=my_score.gender, tag=my_score.tag, group=True).all()

        # دیکشنری برای جمع امتیاز و الماس هر گروه فقط در همین زیرطرح
        user_stats = {}
        for s in scores:
            if s.name not in user_stats:
                user_stats[s.name] = {"score_sum": 0, "diamond_sum": 0}
            user_stats[s.name]["score_sum"] += s.score
            user_stats[s.name]["diamond_sum"] += s.diamond

        # ساخت لیست برای مرتب‌سازی
        result = []
        for name, stats in user_stats.items():
            group_user = Group.get_group_by_name(name)
            if group_user is None:
                continue
            result.append({
                "name": group_user.name,
                "icon": utils.hashing(text=group_user.icon, mode=utils.HashingMode.ENCODE),
                "score_sum": stats["score_sum"],
                "diamond_sum": stats["diamond_sum"]
            })

        # مرتب‌سازی: اول بر اساس الماس، بعد امتیاز
        sorted_result = sorted(result, key=lambda x: (x["diamond_sum"], x["score_sum"]), reverse=True)

        # محاسبه جایگاه با در نظر گرفتن رتبه مشترک
        last_score = None
        last_diamond = None
        position = 0
        real_position = 0
        for item in sorted_result:
            real_position += 1
            if last_score == item["score_sum"] and last_diamond == item["diamond_sum"]:
                item["position"] = position
            else:
                position = real_position
                item["position"] = position
                last_score = item["score_sum"]
                last_diamond = item["diamond_sum"]

        # اضافه کردن اطلاعات گروه خودی
        if group:
            my_score_info = {
                "name": group.name,
                "icon":group.icon,
                "score_sum": user_stats.get(group.name, {}).get("score_sum", 0),
                "diamond_sum": user_stats.get(group.name, {}).get("diamond_sum", 0),
                "position": next((item["position"] for item in sorted_result if item["name"] == group.name), None)
            }
        else:
            my_score_info = None

        sorted_result = sorted_result[:MAX_MEMBERS]

        return jsonify({"groups": sorted_result, "your_info": my_score_info}), 200

@score_bp.get("/group")
@jwt_required()
def get_group():
    name = request.args.get("name")
    group = Group.get_group_by_name(name=name)
    if group is not None:
        if is_url_image(group.icon) == False:
            group.icon = ""
            db.session.commit()
        plan = request.args.get("plan")
        subplan = request.args.get("subplan")
        score = 0
        group_scores = Score.query.filter_by(plan=plan, subplan=subplan, group=True, name=name).first()
        print(group_scores)
        if group_scores is not None:
            score = group_scores.score
        data = {"users": [user if len(user) > 10 else hashing(HashingMode.ENCODE, text=user) for user in group.users.get("users", [])] , "leader": group.users.get("leader", "") if len(group.users.get("leader", "")) > 10 else hashing(HashingMode.ENCODE, text=group.users.get("leader", "")), "icon": hashing(mode=HashingMode.ENCODE ,text=group.icon)}
        users_info = []
        for username in group.users.get("users"):
            if len(username) == 10:
                user = User.get_user_by_username(username=username)
            else:
                user = User.query.filter_by(username=username).first()
            if user is not None:
                user_info = {"name":user.data.get("first_name", "") + " " + user.data.get("last_name") + " " + user.data.get("father_name")}
                if user.data.get("custom_name") is not None:
                    user_info["custom_name"] = user.data.get("custom_name") + " " + user.data.get("father_name")
                users_info.append(user_info)
        data["users_info"] = users_info
        data["score"] = score
        return jsonify(data)
    return jsonify({"message": "گروه وجود ندارد"}), 400
def jalali_to_gregorian(jy, jm, jd, hour=0, minute=0):
    gdate = jdatetime.datetime(jy, jm, jd, hour, minute).togregorian()
    return gdate

# تبدیل میلادی به جلالی
def gregorian_to_jalali(dt):
    jdate = jdatetime.datetime.fromgregorian(datetime=dt)
    return jdate

