from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Group
from schemas import UserSchema, GroupSchema
from sqlalchemy import desc, text
import time, uuid
from confige import db
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone
group_bp = Blueprint("groups", __name__)
from enum import Enum
from datetime import datetime
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

@group_bp.get("/me")
@jwt_required()
def get_me_groups():
    my_group = current_user.data.get("group_name", "")
    if my_group == "":
        return jsonify({"message": "شما در گروهی وجود ندارید.", "pos": 0})

    gender = current_user.data.get("gender", 0)
    tag = current_user.data.get("tag", 0)
    groups = Group.query.filter_by(tag=tag, gender=gender).all()
    
    # رتبه‌بندی گروه‌ها بر اساس مجموع مقادیر دیکشنری diamonds و سپس امتیاز
    groups.sort(key=lambda group: (sum(group.diamonds.values()), sum(group.score.values())), reverse=True)
    
    previous_score = None
    current_position = 0
    for index, group in enumerate(groups):
        current_score = (sum(group.diamonds.values()), sum(group.score.values()))
        if current_score != previous_score:
            current_position = index + 1
        group.position = current_position
        previous_score = current_score
    for group in groups:
        if group.name == my_group:
            return jsonify({"pos": group.position, "nums": [sum(group.diamonds.values()), sum(group.score.values())], "icon": group.icon, "name": group.name})
    
    return jsonify({"message": "شما در گروهی وجود ندارید.", "pos": 0})

@group_bp.get("/all")
@jwt_required()
def get_all_groups():
    page = request.args.get("page", default=1, type=int)
    per_page = request.args.get("per_page")
    gender = current_user.data.get("gender", 0)
    tag = current_user.data.get("tag", 0)
    groups = Group.query.filter_by(tag=tag, gender=gender).all()
    if per_page is None:
        per_page = len(groups)
    else:
        per_page = int(float(per_page))
    # رتبه‌بندی گروه‌ها بر اساس مجموع مقادیر دیکشنری diamonds و سپس امتیاز
    groups.sort(key=lambda group: (sum(group.diamonds.values()), sum(group.score.values())), reverse=True)
    
    g = []
    for x, group in enumerate(groups):
        if x >= (page - 1) * per_page and x < page * per_page:
            g.append(group)
    previous_score = None
    current_position = 0
    for index, group in enumerate(g):
        current_score = (sum(group.diamonds.values()), sum(group.score.values()))
        if current_score != previous_score:
            current_position = index + 1
        group.position = current_position
        group.score = sum(group.score.values())
        group.diamonds = sum(group.diamonds.values())
        group.icon = hashing(mode=HashingMode.ENCODE, text=group.icon)
        previous_score = current_score
    result = GroupSchema().dump(g, many=True)
    return jsonify({"result": result})
@group_bp.get("/names")
@jwt_required()
def get_names():
    groups = Group.query.all()
    data = []
    for group in groups:
        leader = hashing(mode=HashingMode.ENCODE,text=group.users.get("leader", ""))
        icon =  hashing(mode=HashingMode.ENCODE, text=group.icon)
        data.append([group.name, len(group.users.get("users", [])), group.tag, group.gender, icon, leader])
    return jsonify({"data": data})

@group_bp.post("/create")
@jwt_required()
def create():
    data = request.get_json()
    groups = Group.query.all()
    group_names = [group.name for group in groups]
    _name = data.get("group_name")
    if _name and not _name in group_names:
        users = {"users": [current_user.username], "leader": current_user.username}
        new_group = Group(name=_name, gender=current_user.data.get("gender", 0), tag=current_user.data.get("tag", 0), score={f"score{x}" : 0 for x in range(3)}, diamonds={f"diamond{x}":0 for x in range(3)}, users=users, icon=data.get("icon", ""))
        new_group.save()
        remove_event = []
        messages = current_user.data.get("message", [])
        for message in messages:
            if message.get("type", "") == "join":
                remove_event.append(message.get("data", {"user": ""}).get("user"))
                messages.remove(message)
        users_sended_message = current_user.data.get("users_sended_message", [])
        request_message = current_user.data.get("users_request", [])
        for u in request_message:
            user2 = User.get_user_by_username(u[0])
            user_message = user2.data.get("message", [])
            for m in user_message:
                if m.get("id", "") == u[1]:
                    user_message.remove(m)
            user2.update(data={"message": user_message})
        for u in data.get("event_user", []):
            user = User.get_user_by_username(u)
            if user is not None:
                message = user.data.get("message", [])
                gregorian_date = datetime.now()  # تاریخ میلادی فعلی
                jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
                messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "")
                message.append({"text":f"{messager_neme} شما را به عضویت در گروه {_name} دعوت کرده است. آیا این دعوت را می پذیرید؟ ", "data":{"group_name": _name, "time":str(jalali_date), "user":current_user.username}, "time":time.time(), "id":str(uuid.uuid4()), "sender":"کاربر", "type":"join"})
                user.data = user.update(data={"message": message})
                users_sended_message.append(user.username)
        for u in remove_event:
            user2 = User.get_user_by_username(u)
            if user2 is not None:
                sended_message = user2.data.get("users_sended_message", [])
                if current_user.username in sended_message:
                    sended_message.remove(current_user.username)
                user2.update(data={"users_sended_message": sended_message})
        current_user.update(data={"group_name": _name, "users_sended_message": users_sended_message, "message": messages, "users_request": []})
        db.session.commit()
        return jsonify({"message": "successe"})
    return jsonify({"message": "GROUP name exist"})

@group_bp.get("/get")
def get_group():
    group = Group.get_group_by_name(request.args.get("name", ""))
    if group is not None:
        return jsonify({"users": [hashing(text=user, mode=HashingMode.ENCODE) for user in group.users.get("users", [])] , "leader": hashing(mode=HashingMode.ENCODE, text=group.users.get("leader", "")), "users_info": [{"name": User.get_user_by_username(username=user).data.get("first_name", "") + " " + User.get_user_by_username(username=user).data.get("last_name") + " " + User.get_user_by_username(username=user).data.get("father_name")} for user in group.users.get("users")], "icon": hashing(mode=HashingMode.ENCODE ,text=group.icon), "diamonds":group.diamonds, "scores":group.score})
    return jsonify({"message": "گروه وجود ندارد"}), 400

@group_bp.post("/icon")
@jwt_required()
def change_icon():
    data = request.get_json()
    group = Group.get_group_by_name(name=data.get("name", ""))
    if group is not None:
        group.icon = data.get("icon", "")
        db.session.commit()
        return jsonify({"message": "icon updated!"}), 200
    return jsonify({"message": "group not exist"}), 400

@group_bp.post("/update")
@jwt_required()
def update_group():
    name = request.get_json().get("name", "")
    group = Group.get_group_by_name(name=name)
    if current_user.data.get("editor", False):
        if group is not None:
            group.diamonds = request.get_json().get("diamonds", {})
            group.score = request.get_json().get("scores", {})
            db.session.commit()
            return jsonify({"message":"گروه با موفقیت بروزرسانی شد."})
        else:
            return jsonify({"error":"گروه وجود ندارد"}), 400
    else:
        return jsonify({"error":"شما ویرایشگر نیستید"}), 400

@group_bp.get("/length")
@jwt_required()
def lenght():
    return jsonify({"length":len(Group.query.all())})