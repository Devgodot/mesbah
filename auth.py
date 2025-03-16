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
from models import User, TokenBlocklist, UserInterface, Levels, Group, VerificationCode, Messages, UserSeenMessages
import json
from datetime import datetime, timedelta

cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
auth_bp = Blueprint("auth", __name__)
import requests, time

def post_request(url, payload={}):
    headers = {
    'content-type': 'application/json'
    }

    response = requests.post(url, json=payload, headers=headers)
    return response.json()

def send_sms(phone, game, code):
    url = 'https://console.melipayamak.com/api/send/otp/4e52dc71f69c416dad6f2c7d22628b3d'
   
    params = {

    'to': phone,
    
    }
    response = post_request(url=url, payload=params)
    return response

@auth_bp.post("/verify")
def verify_user():
    data = request.get_json()
    code = str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9))
    game = data.get("game", "")
    phone: str = data.get("phone")
    if not phone.startswith("09") or len(phone) != 11:
        return jsonify({"error": "فرمت شماره نامعتبر است"}), 400
    response = send_sms(phone, game, code)
    verify = VerificationCode.query.filter_by(phone=phone).all()
    
    for v in verify:
        db.session.delete(v)
    db.session.commit()
    verification_code = VerificationCode(phone=phone, code=response.get("code", "0"))
    db.session.add(verification_code)
    db.session.commit()
    return jsonify({"message": "در انتظار تائید", "response": response})


@auth_bp.post("/check_user")
def check_user():
    data = request.get_json()
    id = data.get("id", "")
    user = User.get_user_by_username(id)
    if user != None:
        return jsonify({"phone":user.phone})
    else:
        return jsonify({"message":"user not exist"})
    

@auth_bp.post("/register")
def register_user():
    data = request.get_json()
    phone = data.get("phone")
    code = data.get("code")
    verification_code = VerificationCode.query.filter_by(phone=phone, code=code).first()
    if verification_code and verification_code.is_valid():
        db.session.delete(verification_code)
        db.session.commit()
        username = data.get("id", "")
        if len(username) != 10:
            return jsonify({"message": "username incorrect"})
        user_p = User.get_user_by_username(username=username)
        if user_p is not None:
            user = User.get_user_by_username(username=username)
            access_token = create_access_token(identity=user.username, expires_delta=False)
            refresh_token = create_refresh_token(identity=user.username)
            return (
                jsonify(
                    {
                        "message": "Logged In ",
                        "tokens": {"access": access_token, "refresh": refresh_token, "id": user.id},
                    }), 200)
        else:
            phone: str = data.get("phone")
            if not phone.startswith("09") or len(phone) != 11:
                return jsonify({"error": "فرمت شماره نامعتبر است"})
            editors = {}
            for e in UserInterface.query.first().data.keys():
                if "editor" in e:
                    editors[e] = UserInterface.query.first().data.get(e, [])
            editor = []
            for index, key in enumerate(editors.keys()):
                if username in editors[key]:
                    editor.append(index)
            support = False
            for g in UserInterface.query.first().data.get("supporters").values():
                for r in g:
                    for p in r:
                        for u in p:
                            if u == username:
                                support = True
            new_user = User(id=username, username=username, phone=data.get("phone"), data=data.get("data", {"support":support,"phone": phone, "editor": len(editor) > 0, "part_edit": editor}), password="1234")
            new_user.save()
            access_token = create_access_token(identity=new_user.username, expires_delta=False)
            refresh_token = create_refresh_token(identity=new_user.username)
            return (
                jsonify(
                    {
                        "message": "sign In ",
                        "tokens": {"access": access_token, "refresh": refresh_token, "id": new_user.id},
                    }), 200)
    else:
        return jsonify({"error": "کد صحیح نمی باشد"}, 400)

@auth_bp.get("/whoami")
@jwt_required()
def whoami():
    if "GodotEngine" in request.headers.get("User-Agent"):
        
        editors = {}
        for e in UserInterface.query.first().data.keys():
            if "editor" in e:
                editors[e] = UserInterface.query.first().data.get(e, [])
        editor = []
        for index, key in enumerate(editors.keys()):
            if current_user.username in editors[key]:
                editor.append(index)
        support = False
        for g in UserInterface.query.first().data.get("supporters").values():
            for r in g:
                for p in r:
                    for u in p:
                        if u == current_user.username:
                            support = True
        if not support:
            for x in range(3):
                messages = Messages.query.filter_by(conversationId=current_user.username+"_"+str(x)).first()
                supporters = UserInterface.query.first().data.get("supporters").get(["male", "female"][current_user.data.get("gender", 0)])[current_user.data.get("tag", 0)][x]
                if messages is None:
                    message = Messages(conversationId=current_user.username+"_"+str(x), messages=[], receiverId=supporters)
                    db.session.add(message)
                    db.session.commit()
        current_user.update(data={"editor":len(editor) > 0, "part_edit":editor, "support":support})
        db.session.commit()
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
            if "message" in name:
                message: list = current_user.data.get("message", [])
                seen_message_ids = [
                    msg.message_id
                    for msg in UserSeenMessages.query.filter_by(
                        user_id=current_user.id
                    ).all()
                ]
                for m in message:
                    if m.get("id", "") not in seen_message_ids:
                        seen_message_ids.append(m.get("id", ""))
                        seen_message = UserSeenMessages(user_id=current_user.id, message_id=m.get("id", ""), conversationId=current_user.id)
                        db.session.add(seen_message)
                db.session.commit()
            return jsonify(
                {"nums": [current_user.data.get(name2, None) for name2 in name]}
            )
        else:
            return "نام متغییر وارد نشده", 400
    return "شما اجازه دسترسی ندارید", 400
@auth_bp.post("/update")
@jwt_required()
def save_data():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = request.get_json()
        change_data :dict= data
        for c in change_data.keys():
            if c not in ["first_name", "last_name", "father_name", "birthday", "icon", "tag", "gender", "custom_name"]:
                change_data.pop(c)
        
        
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
        if isinstance(users, list) and len(users) != 0:
            leader = users[0]
            group.users = {"users":users, "leader":leader}
            db.session.commit()
        else:
            db.session.commit()
            return users
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
    return jsonify({"message":"موفقیت آمیز بود."})
@auth_bp.post("/seen_message")
@jwt_required()
def seen():
    _id = request.get_json().get("id", [])
    message_ids = [m.get("id") for message in Messages.query.filter_by(conversationId=request.get_json().get("conversationId", "")).all() for m in message.messages]
   
    for m in UserSeenMessages.query.filter_by(conversationId=request.get_json().get("conversationId", "")).all():
        if m.message_id not in message_ids:
            db.session.delete(m)
    for i in _id:
        # Check if the message is already marked as seen by the user
        existing_record = UserSeenMessages.query.filter_by(user_id=current_user.id, message_id=i).first()
        if not existing_record and request.get_json().get("conversationId", "") != "":
            # If not seen, create a new record
            seen_message = UserSeenMessages(user_id=current_user.id, message_id=i, conversationId=request.get_json().get("conversationId", ""))
            db.session.add(seen_message)
    db.session.commit()
    return jsonify({"message": 'موفقیت آمیز بود'})
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
        if isinstance(users, list) and len(users) != 0:
            leader = users[0]
            group.users = {"users":users, "leader":leader}
            db.session.commit()
        else:
            db.session.commit()
            return users
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
    return jsonify({"message":"کاربر به گروه اضافه شد"})

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
    current_user.update(data={"group_name":"", "message":messages, "users_sended_message": []})
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
@auth_bp.get("/unseen_message")
@jwt_required()
def unseen_message():
    message = []
    part = request.args.get("p", 0)
    if part == 0:
        # Fetch all message IDs for the current user
        seen_message_ids = [msg.message_id for msg in UserSeenMessages.query.filter_by(user_id=current_user.id).all()]
        for m in current_user.data.get("message", []):
            if m.get("id", "") not in seen_message_ids:
                message.append(m)
    else:
        # Fetch all message IDs for the current user
        seen_message_ids = [msg.message_id for msg in UserSeenMessages.query.filter_by(user_id=current_user.id).all()]
        for x in range(3):
            messages = Messages.query.filter_by(conversationId=current_user.username+"_"+str(x)).first()
            if messages is not None:
                for m in messages.messages:
                    if m.get("id", "") not in seen_message_ids:
                        message.append(m)
    return jsonify({"num":len(message)})