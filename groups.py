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
    data = [[group.name, len(group.users.get("users", []), group.tag, group.gender, group.icon)] for group in groups]
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
        new_group = Group(name=_name, gender=current_user.data.get("gender", 0), tag=current_user.data.get("tag", 0), score=0, diamonds=0 , users=users)
        new_group.save()
       
        users_sended_message = current_user.data.get("users_sended_message", [])
        for u in data.get("event_user", []):
            user = User.get_user_by_username(u.get("username", ""))
            if user is not None:
                message = user.data.get("message", [])
                messager_neme = [" آقای", " خانم"][current_user.data.get("gender", 0)] + " " + current_user.data.get("first_name", "") + " " + current_user.data.get("last_name", "")
                message.append({"text":f"{messager_neme} شما را به عضویت در گروه {_name} دعوت کرده است. آیا این دعوت را می پذیرید؟ پس از آن خروج از گروه ممکن نیست", "data":{"group_name": _name}, "time":time.time(), "id":str(uuid.uuid4()), "sender":"کاربر"})
                user.data = user.update(data={"message":message})
                users_sended_message.append(user.username)
        current_user.update(data={"group_name":_name, "users_sended_message":users_sended_message})
        db.session.commit()
        return jsonify({"message":"successe"})
    return jsonify({"message":"GROUP name exist"})

@group_bp.get("/get")
def get_group():
    group = Group.get_group_by_name(request.args.get("name", ""))
    if group is not None:
        return jsonify({"users":group.users.get("users", []), "leader":group.users.get("leader", ""), "users_info":[{"name": User.get_user_by_username(username=user).data.get("first_name", "") + " " + User.get_user_by_username(username=user).data.get("last_name") + " "+ User.get_user_by_username(username=user).data.get("father_name")}  for user in group.users.get("users")]})
    return jsonify({"message":"group not exist"}), 400