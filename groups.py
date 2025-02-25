from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Group
from schemas import UserSchema
from sqlalchemy import desc, text
import time, uuid
from confige import db
group_bp = Blueprint("groups", __name__)
@group_bp.get("/names")
@jwt_required()
def get_names():
    tag = current_user.data.get("tag", 0)
    gender = current_user.data.get("gender", 0)
    groups = Group.query.all()
    data = [[group.name, len(group.users.get("users", [])), group.tag, group.gender, group.icon, group.users.get("leader", "")] for group in groups]
    return jsonify({"data":data})

@group_bp.post("/create")
@jwt_required()
def create():
    
    data = request.get_json()
    groups = Group.query.all()
    group_names = [group.name for group in groups]
    _name = data.get("group_name")
    if _name and not _name in group_names:
        users = {"users":[current_user.username], "leader":current_user.username}
        new_group = Group(name=_name, gender=current_user.data.get("gender", 0), tag=current_user.data.get("tag", 0), score=0, diamonds=0 , users=users, icon=data.get("icon", ""))
        new_group.save()
        remove_event = []
        messages = current_user.data.get("message", [])
        for message in messages:
            if message.get("type", "") == "join":
                remove_event.append(message.get("data", {"user":""}).get("user"))
                messages.remove(message)
        users_sended_message = current_user.data.get("users_sended_message", [])
        request_message = current_user.data.get("users_request", [])
        for u in request_message:
            user2 = User.get_user_by_username(u[0])
            user_message = user2.data.get("message", [])
            for m in user_message:
                if m.get("id", "") == u[1]:
                    user_message.remove(m)
            user2.update(data={"message":user_message})
        for u in data.get("event_user", []):
            user = User.get_user_by_username(u.get("username", ""))
            if user is not None:
                message = user.data.get("message", [])
                messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "")
                message.append({"text":f"{messager_neme} شما را به عضویت در گروه {_name} دعوت کرده است. آیا این دعوت را می پذیرید؟ پس از آن خروج از گروه ممکن نیست", "data":{"group_name": _name}, "time":time.time(), "id":str(uuid.uuid4()), "sender":"کاربر"})
                user.data = user.update(data={"message":message})
                users_sended_message.append(user.username)
        for u in remove_event:
            user2 = User.get_user_by_username(u)
            if user2 is not None:
                sended_message = user2.data.get("users_sended_message", [])
                if current_user.username in sended_message:
                    sended_message.remove(current_user.username)
                user2.update(data= {"users_sended_message":sended_message})
        current_user.update(data={"group_name":_name, "users_sended_message":users_sended_message, "message":messages, "users_request":[]})
        db.session.commit()
        return jsonify({"message":"successe"})
    return jsonify({"message":"GROUP name exist"})

@group_bp.get("/get")
def get_group():
    group = Group.get_group_by_name(request.args.get("name", ""))
    if group is not None:
        return jsonify({"users":group.users.get("users", []), "leader":group.users.get("leader", ""), "users_info":[{"name": User.get_user_by_username(username=user).data.get("first_name", "") + " " + User.get_user_by_username(username=user).data.get("last_name") + " "+ User.get_user_by_username(username=user).data.get("father_name")}  for user in group.users.get("users")], "icon":group.icon})
    return jsonify({"message":"group not exist"}), 400

@group_bp.post("/icon")
@jwt_required()
def change_icon():
    data = request.get_json()
    group = Group.get_group_by_name(name=data.get("name", ""))
    if group is not None:
        group.icon = data.get("icon", "")
        db.session.commit()
        return jsonify({"message":"icon updated!"}), 200
    return jsonify({"message":"group not exist"}), 400