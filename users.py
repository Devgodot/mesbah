from flask import request, Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Group, Messages, UserSeenMessages, UserMessages
from schemas import UserSchema
from sqlalchemy import desc, text
from confige import db
import time, uuid
import datetime, json
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone

user_bp = Blueprint("users", __name__)
from enum import Enum
class HashingMode(Enum):
    ENCODE = 0
    DECODE = 1

words ={ "%": "%00%", "٠": "%zs%", "١": "%p3%", "٢": "%q6%", "٣": "%rz%", "٤": "%pi%", "٥": "%c5%", "٦": "%h5%", "٧": "%xa%", "٨": "%w1%", "٩": "%59%", "*": "%dh%", "$": "%n8%", "^": "%44%", "&": "%ga%", "۱": "%ry%", "۰": "%47%", "۲": "%j8%", "۳": "%4a%", "۴": "%w0%", "۵": "%df%", "۶": "%k5%", "۷": "%cq%", "۸": "%9v%", "۹": "%hu%", "ً": "%97%", "ٌ": "%vr%", "ٍ": "%q9%", "َ": "%8c%", "ُ": "%79%", "ِ": "%24%", "ـ": "%2c%", "؛": "%2v%", "«": "%1p%", "»": "%lz%", "ك": "%yz%", " ": "%08%", "‌": "%e7%", "!": "%6k%", "\"": "%wb%", "\'": "%ka%", "(": "%h7%", ")": "%gh%", "+": "%5g%", ",": "%4u%", "-": "%vb%", ".": "%z6%", "/": "%q7%", "0": "%qz%", "1": "%r6%", "2": "%2b%", "3": "%fj%", "4": "%0g%", "5": "%n3%", "6": "%cr%", "7": "%iz%", "8": "%ki%", "9": "%g5%", ":": "%uu%", ";": "%kq%", "<": "%96%", "=": "%26%", ">": "%sj%", "?": "%3y%", "@": "%19%", "[": "%5b%", "]": "%mf%", "_": "%9a%", "a": "%nx%", "b": "%zu%", "c": "%ir%", "d": "%zh%", "e": "%wi%", "f": "%h8%", "g": "%ue%", "h": "%50%", "i": "%xi%", "j": "%36%", "k": "%jj%", "l": "%wm%", "m": "%5x%", "n": "%7z%", "o": "%k1%", "p": "%c1%", "q": "%8u%", "r": "%n6%", "s": "%x3%", "t": "%91%", "u": "%6v%", "v": "%vs%", "w": "%d0%", "x": "%22%", "y": "%rd%", "z": "%b7%", "{": "%3r%", "}": "%v4%", "،": "%eh%", "؟": "%yv%", "ء": "%j5%", "أ": "%5h%", "ؤ": "%xe%", "إ": "%pj%", "ئ": "%3l%", "ا": "%2l%", "آ": "%dl%", "ب": "%r4%", "ة": "%1s%", "ت": "%c4%", "ث": "%wj%", "ج": "%ar%", "ح": "%x9%", "خ": "%2g%", "د": "%yg%", "ذ": "%7i%", "ر": "%ff%", "ز": "%1l%", "س": "%gy%", "ش": "%gr%", "ص": "%ph%", "ض": "%ap%", "ط": "%kb%", "ظ": "%wn%", "ع": "%mj%", "غ": "%bl%", "ف": "%v3%", "ق": "%04%", "ل": "%8i%", "م": "%9d%", "ن": "%wd%", "ه": "%4e%", "و": "%de%", "ي": "%sh%", "پ": "%x7%", "چ": "%ym%", "ژ": "%66%", "ک": "%8q%", "گ": "%7d%", "ی": "%xl%", "A": "%1h%", "B": "%6s%", "C": "%dv%", "D": "%q1%", "E": "%9k%", "F": "%aq%", "G": "%lm%", "H": "%eb%", "I": "%td%", "J": "%c3%", "K": "%wc%", "L": "%y8%", "M": "%t0%", "N": "%1a%", "O": "%gb%", "P": "%dj%", "Q": "%o9%", "R": "%si%", "S": "%ve%", "T": "%i4%", "U": "%ge%", "V": "%j3%", "W": "%2u%", "X": "%ll%", "Y": "%ob%", "Z": "%5e%" }
gregorian_date = datetime.datetime.now()
jalali_date = JalaliDatetime(gregorian_date+datetime.timedelta(days=7))  # تبدیل به تاریخ شمسی
print()
def find_key_by_value(dictionary, target_value):
    for key, value in dictionary.items():
        if value == target_value:
            return key
    return None
def hashing(mode:HashingMode, text=""):
	if mode == HashingMode.ENCODE:
		hash_text = ""
		for graph in text:
			hash_text += words.get(graph)
		return hash_text
	if mode == HashingMode.DECODE:
		new_text = ''
		graphs = text.split("%")
		for graph in graphs:
			if graph != "" and graph != "%":
				new_text += find_key_by_value(words, "%"+str(graph)+"%")
		return new_text

@user_bp.get("/me")
@jwt_required()
def get_me():
    sort = request.args.get("sort", "").split("AND")
    users = User.query.all()
    for k in sort:
        if k == "score":
            sort.remove(k)
            gender = current_user.data.get("gender", 0)
            tag = current_user.data.get("tag", 0)
            sort.append(f"score_{gender}_{tag}")
    
    u = []
    for user in users:
        if sort and sort != [] and all(user.data.get(k) is not None for k in sort):
            u.append(user)
        else:
            if not sort or sort == []:
                u.append(user)
    if sort and sort != []:
        u.sort(key=lambda user: tuple(user.data.get(k) for k in sort), reverse=True)
    previous_score = None
    current_position = 0
    for index, user in enumerate(u):
        current_score = tuple(user.data.get(k) for k in sort)
        if current_score != previous_score:
            current_position = index + 1
        user.data['position'] = current_position
        previous_score = current_score
    
    # Check if current_user has any of the sort keys
    if any(current_user.data.get(k) is not None for k in sort):
        for x, user in enumerate(users):
            if user == current_user:
                return jsonify({"message": "موقعیت شما طبق این رتبه بندی به شرح پیوست است", "pos": user.data["position"], "phone": current_user.phone, "nums": [current_user.data.get(k, 0) for k in sort]})
    else:
        return jsonify({"message": "شما در این رتبه بندی وجود ندارید", "pos": 0})
    
    return jsonify({"message": "لطفا پارامتر را مشخص کنید", "error": "sort=?"}), 400

@user_bp.get("/all")
@jwt_required()
def get_all_users():
    filter_data = []
    if request.args.get("filter"):
        filter_data = request.args.get("filter").split("AND")
    sort = request.args.get("sort", "").split("AND")
    page = request.args.get("page", default=1, type=int)
    per_page = request.args.get("per_page")
    gender = current_user.data.get("gender", 0)
    tag = current_user.data.get("tag", 0)
    users = User.query.all()
    if per_page is None:
        per_page = len(users)
    else:
        per_page = int(float(per_page))
    for k in sort:
        if k == "score":
            sort.remove(k)
            sort.append(f"score_{gender}_{tag}")
    for k in filter_data:
        if k == "score":
            filter_data.remove(k)
            filter_data.append(f"score_{gender}_{tag}")
    u = []
    for user in users:
        if sort and sort != [''] and  all(user.data.get(k) is not None for k in sort):
            u.append(user)
    
    if not sort or sort == ['']:
        u = users
    
    if sort and sort != []:
        u.sort(key=lambda user: tuple(user.data.get(k) for k in sort), reverse=True)
    u2 = []
    for x, user in enumerate(u):
        if x >= (page - 1) * per_page and x < page * per_page:
            u2.append(user)
    if filter_data:
        for user in u2:
            d = {}
            for key in filter_data:
                k = key
                if user.data.get(k) is not None:
                    if key == "icon":
                        d["icon"] = hashing(mode=HashingMode.ENCODE, text=user.data.get("icon", ""))
                    elif key == f"score_{gender}_{tag}":
                        d["score"] = user.data.get(f"score_{gender}_{tag}")
                    else:
                        d[key] = user.data.get(k)
            user.data = d
            user.id = hashing(mode=HashingMode.ENCODE, text=user.id)
            user.phone = hashing(mode=HashingMode.ENCODE, text=user.phone)
            user.username = hashing(mode=HashingMode.ENCODE, text=user.username)
    for k in sort:
        if k == f"score_{gender}_{tag}":
            sort.remove(k)
            sort.append(f"score")
    previous_score = None
    current_position = 0
    for index, user in enumerate(u2):
        current_score = tuple(user.data.get(k) for k in sort)
        if current_score != previous_score:
            current_position = index + 1
        user.data['position'] = current_position
        previous_score = current_score
    result = UserSchema().dump(u2, many=True)
    if len(u2) > 0:
        return (
            jsonify(
                {
                    "users": result,
                }
            ),
            200,
        )
    else:
        return jsonify({"message": "چنین رتبه بندی وجود ندارد"})

@user_bp.post("/event")
@jwt_required()
def event():
    data = request.get_json()
    _name = data.get("group_name")
    group = Group.get_group_by_name(name=_name)
    print(group)
    if group is not None:
        user = User.get_user_by_username(data.get("user", ""))
        users_sended_message = current_user.data.get("users_sended_message", [])
        if user is not None:
            message = user.data.get("message", [])
            gregorian_date = datetime.datetime.now()  # تاریخ میلادی فعلی
            jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
            messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "")
            message.append({"text":f"{messager_neme} شما را به عضویت در گروه {_name} دعوت کرده است. آیا این دعوت را می پذیرید؟ ", "data":{"group_name": _name, "time":str(jalali_date), "user":current_user.username}, "time":time.time(), "id":str(uuid.uuid4()), "sender":"کاربر", "type":"join"})
            user.data = user.update(data={"message":message})
            users_sended_message.append(user.username)
        current_user.update(data={"users_sended_message":users_sended_message})
        db.session.commit()
        return jsonify({"message":"successe"})
    return jsonify({"message":"GROUP name exist"})

@user_bp.get("/request")
@jwt_required()
def user_request():
    data = request.args  # Corrected here
    _name = data.get("group_name")
    group = Group.query.filter_by(name=_name).first()
    if group is not None:
        user = User.get_user_by_username(group.users.get("leader"))
        users_sended_message = current_user.data.get("users_request", [])
        if user is not None:
            message = user.data.get("message", [])
            gregorian_date = datetime.datetime.now()  # تاریخ میلادی فعلی
            jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
            _id = str(uuid.uuid4())
            messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "") + " " + current_user.data.get("father_name", "")
            message.append({"text":f"{messager_neme} درخواست عضویت در گروه شما را دارد. آیا این درخواست را می پذیرید؟ پس از آن امکان حذف عضو وجود ندارد.", "data":{"group_name": _name, "time":str(jalali_date), "user":current_user.username}, "time":time.time(), "id":_id, "sender":"کاربر", "type":"request"})
            user.data = user.update(data={"message":message})
            users_sended_message.append([user.username, _id])
        current_user.update(data={"users_request":users_sended_message})
        db.session.commit()
        return jsonify({"message":"successe"})
    return jsonify({"message":"GROUP name exist"})

@user_bp.get("/get")
@jwt_required()
def get_user():
    username = request.args.get("username", "")
    user = User.get_user_by_username(username=username)
    if current_user.data.get("editor", False):
        if user is not None:
            data = user.data
            gender = data.get("gender", 0)
            tag = data.get("tag", 0)
            return jsonify({"name":data.get("first_name", "") + " " + data.get("last_name", ""), "father_name":data.get("father_name", ""), "phone":user.phone, "scores":[data.get(f"score_{gender}_{tag}_{x}", 0) for x in range(3)], "diamonds":[data.get(f"diamonds{x}", 0) for x in range(3)], "icon":data.get("icon", ""), "gender":data.get("gender", 0), "tag":data.get("tag", 0)})
        else:
            return jsonify({"message":"کاربر وجود ندارد"})
    else:
        return jsonify({"message":"شما ویرایشگر نیستید"})
@user_bp.post("/update")
@jwt_required()
def update_user():
    username = request.get_json().get("username", "")
    user = User.get_user_by_username(username=username)
    if current_user.data.get("editor", False):
        if user is not None:
            user.update(data=request.get_json().get("data", {}))
            db.session.commit()
            return jsonify({"message":"کاربر با موفقیت بروزرسانی شد."})
        else:
            return jsonify({"error":"کاربر وجود ندارد"})
    else:
        return jsonify({"error":"شما ویرایشگر نیستید"})

@user_bp.get("/length")
@jwt_required()
def lenght():
    return jsonify({"length":len(User.query.all())})
@user_bp.get("/icon")
@jwt_required()
def icon():
    user = User.get_user_by_username(username=request.args.get("username", ""))
    if user is not None:
        return jsonify({"icon":user.data.get("icon", "")})
    return jsonify({"message":"کاربر وجود ندارد"})

@user_bp.post("/server_message")
def server_message():
    users = request.get_json().get("users")
    filter_m = request.get_json().get("filter")
    _id = str(uuid.uuid4())
    text = request.get_json().get("text", "")
    sound = request.get_json().get("sound")
    image = request.get_json().get("image")
    gregorian_date = datetime.datetime.now()  # تاریخ میلادی فعلی
    jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
    message_data = {"text": text, "data": {"time": str(jalali_date)}, "id": _id, "sender": "پشتیبانی", "type": "guid"}
    if sound:
        message_data["sound"] = sound
    if image:
        message_data["image"] = image
    # Check the type of 'users' variable
    if isinstance(users, str):
        if users == "all":
            if filter_m is None:
                for user in User.query.all():
                    message = user.data.get("message", [])
                    message.append(message_data)
                    user.data = user.update(data={"message":message})
                    db.session.commit()
            else:
                all_users = User.query.all()
                filter_users = []
                for user in all_users:
                    all_true = True
                    for f in filter_m.keys():
                        if user.data.get(f) != filter_m.get(f):
                            all_true = False
                    if all_true:
                        filter_users.append(user)
                for user in filter_users:
                    message = user.data.get("message", [])
                    message.append(message_data)
                    user.data = user.update(data={"message":message})
                    db.session.commit()
        
        else:
            # Assuming 'users' is a string but not equal to "all"
            # Handle this case accordingly, e.g., raise an error or return a message
            return jsonify({"error": "Invalid value for 'users' parameter."}), 400
    
    elif isinstance(users, list):
        # Assuming 'users' is a list of usernames
        for username in users:
            user = User.get_user_by_username(username)
            if user:
                message = user.data.get("message", [])
                message.append(message_data)
                user.data = user.update(data={"message": message})
                db.session.commit()
            else:
                # Handle the case where the user is not found
                print(f"User with username '{username}' not found.")
                
    else:
        return jsonify({"error": "The 'users' parameter must be a string ('all') or a list of usernames."}), 400
    
    return "پیام با موفقیت ارسال شد"

@user_bp.post("/delete_message")
def delete_message():
    for user in User.query.all():
        message = user.data.get("message", [])
        for m in message:
            if m.get("id", "") == request.get_json().get("id"):
                message.remove(m)
        user.data = user.update(data={"message":message})
        db.session.commit()
        
    return "پیام با موفقیت حذف شد"

@user_bp.get("/check")
@jwt_required()
def check():
    username = request.args.get("username", "")
    user = User.get_user_by_username(username=username)
    if user is not None:
        if user != current_user:
            if user.data.get("group_name", "") == "":
                if user.data.get("gender", 0) == current_user.data.get("gender", 0):
                    if user.data.get("tag", 0) == current_user.data.get("tag", 0):
                        return jsonify({"result":True})
                    else:
                        return jsonify({"message":"تفاوت رده"})
                else:
                    return jsonify({"message":"تفاوت جنسیت"})
            else:
                return jsonify({"message":"عضو گروه است"})
        else:
            return jsonify({"message":"خودتان هستید"})
    else:
        return jsonify({"message":"وجود ندارد"})

@user_bp.get("/supporters")
@jwt_required()
def support():
    gender = current_user.data.get("gender", 0)
    tag = current_user.data.get("tag", 0)
    part = request.args.get("part", 0)
    s = UserInterface.query.first()
    supporters = s.data.get("supporters")
    return jsonify({"supporters":[hashing(text=supporter, mode=HashingMode.ENCODE) for supporter in supporters.get(["male", "female"][int(gender)])[int(tag)][int(part)]]})
@user_bp.get("/support_message")
@jwt_required()
def support_message():
    
    user_name = current_user.username
    part = request.args.get("part", 0)
    message = Messages.query.filter_by(conversationId=user_name+"_"+str(part)).first()
    if message is not None:
        return jsonify({"messages":message.messages})
    return jsonify({"messages":[]})

@user_bp.get("/users_message")
@jwt_required()
def users_message():
    user_name = current_user.username
    messages = Messages.query.all()
    users = []
    for m in messages:
        new_message = 0
        if user_name in m.receiverId and len(m.messages) > 0:
            for message in m.messages:
                if message.get("id") not in current_user.data.get("seen_message", []):
                    new_message += 1
            user = User.get_user_by_username(username=m.conversationId.split("_")[0])
            last_message_time = m.messages[-1].get("timestamp") if m.messages else None
            if last_message_time:
                last_message_time = datetime.datetime.strptime(last_message_time, "%Y/%m/%d %H:%M:%S")
            print(last_message_time)
            users.append({
                "name": user.data.get("first_name", "") + " " + user.data.get("last_name", ""),
                "username": user.username,
                "phone": user.phone,
                "conversationId": m.conversationId,
                "new": new_message,
                "icon": user.data.get("icon", ""),
                "last_message_time": last_message_time
            })
    # Sort users by the last message time in descending order
    users.sort(key=lambda x: x["last_message_time"], reverse=True)
    
    # Convert last_message_time back to string
    for user in users:
        if user["last_message_time"]:
            user["last_message_time"] = user["last_message_time"].isoformat()
    
    return jsonify({"users": users})

@user_bp.post("/user_message")
@jwt_required()
def user_message():
    message = Messages.query.filter_by(conversationId=request.args.get("id", "")).first()
    last_messages = request.get_json().get("messages")
    add = []
    remove = []
    for m in message.messages:
        if m not in last_messages:
            add.append(m)
    for m in last_messages:
        if m not in message.messages:
            remove.append(m)
    _id = [m.get("id", "") for m in message.messages]
    for i in _id:
        # Check if the message is already marked as seen by the user
        existing_record = UserSeenMessages.query.filter_by(user_id=current_user.id, message_id=i).first()
        if not existing_record:
            # If not seen, create a new record
            seen_message = UserSeenMessages(user_id=current_user.id, message_id=i)
            db.session.add(seen_message)
    return jsonify({"receiverId": message.receiverId, "add":add, "delete":remove})

