from flask import Blueprint, jsonify, request, current_app
from flask_caching import Cache
from confige import db, app
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt,
    current_user,
    get_jwt_identity,
)
from random import randint
import random, os, shutil
from models import User, TokenBlocklist, UserInterface, Levels, Group, JSON
import json
cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
auth_bp = Blueprint("auth", __name__)
import requests, time

def post_request(url, payload={}):
    headers = {
    'content-type': 'application/x-www-form-urlencoded'
    }

    requests.packages.urllib3.disable_warnings()
    session2 = requests.Session()
    session2.verify = False

    response = session2.post(url, data=payload, headers=headers)

    return (response.text)
@auth_bp.post("/check_user")
def check_user():
    data = request.get_json()
    id = data.get("id", "")
    user = User.get_user_by_username(id)
    if user != None:
        return jsonify({"phone":user.phone})
    else:
        return jsonify({"message":"user not exist"})
@auth_bp.post("/verify")
def verify_user():
    data = request.get_json()
    code = str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) 
    cache.set('code', code, timeout=300)
    game = data.get("game", "")
    phone :str= data.get("phone")
    if not phone.startswith("09") or len(phone) != 11:
        return jsonify({"error":"فرمت شماره نامعتبر است"}), 400
    data = {
    'username': "09999876739",
    'password': "0O3LH",
    'to': phone,
    'text': f"با سلام\nبه برنامه {game} خوش آمدید\n کد تائید شما جهت ورود در بازی :\n{code}",
    'from': "", 
    'fromSupportOne': "", 
    'fromSupportTwo': ""
    }
    return jsonify({"message":"در انتظار تائید", "response":post_request(url="https://rest.payamak-panel.com/api/SmartSMS/Send", payload=data)})
    


@auth_bp.post("/register")
def register_user():
    data = request.get_json()
    if data.get("code") == cache.get("code"):
        username = data.get("id", "")
        resulte = 0
        for x, g in enumerate(username):
            if x < 9:
                resulte += int(g) * (len(username) - x)
        correct_username = False
        if resulte % 11 <= 2:
            if (resulte % 11) == int(username[9]):
                correct_username = True
        if resulte % 11 > 2:
            if 11 - (resulte % 11) == int(username[9]):
                correct_username = True
        if len(username) != 10 or correct_username == False:
            return jsonify({"message":"username incorrect"})
        user_p = User.get_user_by_username(username=username)
        if user_p is not None:
            user = User.get_user_by_username(username=username)
            access_token = create_access_token(identity=user.username, expires_delta=False)
            refresh_token = create_refresh_token(identity=user.username)
            return (
                jsonify(
                    {
                        "message": "Logged In ",
                        "tokens": {"access": access_token, "refresh": refresh_token, "id":user.id},
                    }), 200)
        else:
            phone :str= data.get("phone")
            if not phone.startswith("09") or len(phone) != 11:
                return jsonify({"error":"فرمت شماره نامعتبر است"})
            new_user = User(id =username, username=username, phone=data.get("phone"), data=data.get("data", {"phone":phone}), password="1234")
            new_user.save()
            access_token = create_access_token(identity=new_user.username, expires_delta=False)
            refresh_token = create_refresh_token(identity=new_user.username)
            return (
                jsonify(
                    {
                        "message": "sign In ",
                        "tokens": {"access": access_token, "refresh": refresh_token, "id":new_user.id},
                    }), 200)
    else:
        return jsonify({"error":"کد صحیح نمی باشد"}, 400)

@auth_bp.get("/whoami")
@jwt_required()
def whoami():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = {}
        for d in current_user.data.keys():
            data[d] = current_user.data.get(d)
                
        return jsonify(
            {
                "message": "message",
                "user_details": {
                    "username": current_user.username,
                    # Add other user details here if needed
                },
                "data": data
            }
        )
    return "شما اجازه دسترسی ندارید", 400
@auth_bp.get("/get")
@jwt_required()
def get_data():
    if "GodotEngine" in request.headers.get("User-Agent"):
        name = request.args.get("name", "").split("AND")
        if name != [""]:
            return jsonify({"nums":[current_user.data.get(name2, None) for name2 in name]})
        else:
            return "نام متغییر وارد نشده", 400
    return "شما اجازه دسترسی ندارید", 400
@auth_bp.post("/update")
@jwt_required()
def save_data():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = request.get_json()
        change_data = data
        if change_data.get("name", None):
            _name = change_data.get("name", "").split(" ")
            name = ""
            for t in _name:
                if t not in [" ", ""]:
                    name += t
            change_data["name"] = name
        current_user.data = current_user.update(change_data, False)
        db.session.commit()
        
        return jsonify(
            {
            "message": "اطلاعات زیر بروزرسانی شد",
            "data":change_data
            }
        )
    return "شما اجازه دسترسی ندارید", 400

@auth_bp.get("/refresh")
@jwt_required(refresh=True)
def refresh_access():
    if "GodotEngine" in request.headers.get("User-Agent"):
        identity = get_jwt_identity()

        new_access_token = create_access_token(identity=identity)

        return jsonify({"access_token": new_access_token})
    return "شما اجازه دسترسی ندارید", 400
    


@auth_bp.get('/logout')
@jwt_required(verify_type=False) 
def logout_user():
    if "GodotEngine" in request.headers.get("User-Agent"):
        jwt = get_jwt()
        jti = jwt['jti']
        token_type = jwt['type']
        token_b = TokenBlocklist(jti=jti)
        token_b.save()
        return jsonify({"message": f"{token_type} token revoked successfully"}) , 200
    return "شما اجازه دسترسی ندارید", 400
@auth_bp.get("/remove_message")
@jwt_required()
def remove_message():
    _id = request.args.get("id", "")
    messages = current_user.data.get("message", [])
    for message in messages:
        if message.get("id", "") == _id:
            messages.remove(message)
    current_user.update(data={"message":messages})
    user = User.get_user_by_username(request.args.get("user", ""))
    if user is not None:
        sended_message = user.data.get("users_sended_message", [])
        if current_user.username in sended_message:
            sended_message.remove(current_user.username)
        request_message = user.data.get("users_request", [])
        for u in request_message:
            if current_user.username == u[0]:
                request_message.remove(u)
        user.update(data= {"users_sended_message":sended_message, "users_request":request_message})
    db.session.commit()
    return jsonify({"message":"successe"})

@auth_bp.get("/join_group")
@jwt_required()
def join_group():
    group_name = request.args.get("group", "")
    messages = current_user.data.get("message", [])
    remove_event = []
    for message in messages:
        if message.get("type", "") == "join":
            remove_event.append(message.get("data", {"user":""}).get("user"))
            messages.remove(message)
    group = Group.get_group_by_name(group_name)
    if group is not None:
        users = group.add_user(user=current_user.username)
        group.users = {"users":users, "leader":users[0]}
    db.session.commit()
    request_message = current_user.data.get("users_request", [])
    if len(group.users.get("users", [])) >= 5:
        current_sended_message = group.users.get("leader").data.get("users_sended_message", [])
        for u in current_sended_message:
            user3 = User.get_user_by_username(username=u)
            user_m = user3.data.get("message", [])
            for message in user_m:
                if message.get("data", {"user":""}).get("user") == group.users.get("leader").username:
                    user_m.remove(message)
            user3.update(data={"message":user_m})
        group.users.get("leader").update(data= {"users_sended_message":[]})
        
    for u in request_message:
        user = User.get_user_by_username(u[0])
        user_message = user.data.get("message", [])
        for m in user_message:
            if m.get("id", "") == u[1]:
                user_message.remove(m)
        user.update(data={"message":user_message})
    current_user.update(data={"message":messages, "group_name":group_name, "users_request":[]})
    for u in remove_event:
        user = User.get_user_by_username(u)
        if user is not None:
            sended_message = user.data.get("users_sended_message", [])
            if current_user.username in sended_message:
                sended_message.remove(current_user.username)
            user.update(data= {"users_sended_message":sended_message})
    db.session.commit()
    return jsonify({"message":"successe"})


@auth_bp.get("/accept_group")
@jwt_required()
def accept_group():
    user_name = request.args.get("user", "")
    user = User.get_user_by_username(username=user_name)
    messages = current_user.data.get("message", [])
    user_join_messages = user.data.get("message", [])
    remove_event = []
    for message in messages:
        if message.get("data", {"user":""}).get("user") == user_name:
            messages.remove(message)
    current_user.update(data={"message":messages})
    for message in user_join_messages:
        if message.get("type", "") == "join":
            remove_event.append(message.get("data", {"user":""}).get("user"))
            user_join_messages.remove(message)
    group_name = current_user.data.get("group_name", "")
    group = Group.get_group_by_name(group_name)
    if group is not None:
        users = group.add_user(user=user.username)
        group.users = {"users":users, "leader":users[0]}
    db.session.commit()
    if len(group.users.get("users", [])) >= 5:
        current_sended_message = current_user.data.get("users_sended_message", [])
        for u in current_sended_message:
            user3 = User.get_user_by_username(username=u)
            user_m = user3.data.get("message", [])
            for message in user_m:
                if message.get("data", {"user":""}).get("user") == current_user.username:
                    user_m.remove(message)
            user3.update(data={"message":user_m})
        current_user.update(data= {"users_sended_message":[]})
    
    request_message = user.data.get("users_request", [])
    for u in request_message:
        user2 = User.get_user_by_username(u[0])
        user_message = user2.data.get("message", [])
        for m in user_message:
            if m.get("id", "") == u[1]:
                user_message.remove(m)
        user2.update(data={"message":user_message})
    
    user.update(data={"message":user_join_messages, "group_name":group_name, "users_request":[]})
    for u in remove_event:
        user2 = User.get_user_by_username(u)
        if user2 is not None:
            sended_message = user2.data.get("users_sended_message", [])
            if user.username in sended_message:
                sended_message.remove(user.username)
            user2.update(data= {"users_sended_message":sended_message})
    db.session.commit()
    return jsonify({"message":"successe"})

@auth_bp.get("/left_group")
@jwt_required()
def left_group():
    group = Group.get_group_by_name(current_user.data.get("group_name", ""))
    users = []
    for user in group.users.get("users", []):
        if user != current_user.username:
            users.append(user)
    
    for user in current_user.data.get("users_sended_message", []):
        messages = User.get_user_by_username(username=user).data.get("message", [])
        for message in messages:
            if message.get("data", {"user":""}).get("user") == current_user.username:
                messages.remove(message)
        User.get_user_by_username(username=user).update(data={"message":messages})
    messages = current_user.data.get("message", [])
    for message in messages:
        if message.get("type", "") == "request":
            user = User.get_user_by_username(username=message.get("data", {"user":""}).get("user"))
            request_message = user.data.get("users_request", [])
            for r in request_message:
                if r[0] == current_user.username:
                    request_message.remove(r)
            user.update(data={"users_request":request_message})
            messages.remove(message)
    current_user.update(data={"group_name":"", "message":messages})
    db.session.commit()
    if len(users) > 0:
        leader = group.users.get("leader", "") if group.users.get("leader", "") != current_user.username else users[0]
        if group.users.get("leader", "") == current_user.username:
            if group.icon != "":
                path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users")
                phone = User.get_user_by_username(username=users[0]).phone
                for file in os.listdir(path=os.path.join(path , str(current_user.phone))):
                    if file.startswith(group.name):
                        group.icon = f"http://messbah403.ir/static/files/users/{phone}/{file}"
                        shutil.move(os.path.join(path, str(current_user.phone), file), os.path.join(path, phone, file))
    else:
        path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users")
        for file in os.listdir(path=os.path.join(path , str(current_user.phone))):
            if file.startswith(group.name):
                os.remove(os.path.join(path , str(current_user.phone), file))
        db.session.delete(group)
        db.session.commit()
        return jsonify({"message":"گروه حذف شد"})
    group.users = {"users":users, "leader":leader}
    db.session.commit()
    return jsonify({"message":"successe"})
