from flask import request, Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Group
from schemas import UserSchema
from sqlalchemy import desc, text
from confige import db
import time, uuid
import datetime
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone

user_bp = Blueprint("users", __name__)

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
                    print(k)
                    if key == f"score_{gender}_{tag}":
                        d["score"] = user.data.get(k)
                    else:
                        d[key] = user.data.get(k)
            user.data = d
    
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
            print(user)
            message = user.data.get("message", [])
            gregorian_date = datetime.datetime.now()  # تاریخ میلادی فعلی
            jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
            messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "")
            message.append({"text":f"{messager_neme} شما را به عضویت در گروه {_name} دعوت کرده است. آیا این دعوت را می پذیرید؟ پس از آن خروج از گروه ممکن نیست", "data":{"group_name": _name, "time":str(jalali_date), "user":current_user.username}, "time":time.time(), "id":str(uuid.uuid4()), "sender":"کاربر", "type":"join"})
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