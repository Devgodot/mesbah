from flask import Blueprint, jsonify, request
from sqlalchemy import or_
from confige import db, app
from flask_jwt_extended import current_user, jwt_required
from models import User, UserInterface, Group, ServerMessage, Planes, Supporter, Messages, Conversation
from datetime import datetime, timedelta
from sqlalchemy.orm.attributes import flag_modified
import jdatetime
from khayyam import TehranTimezone

message_bp = Blueprint("messages", __name__)

@message_bp.get("/get")
@jwt_required()
def get_message():
    time = request.args.get("time", default=0, type=int)
    managements = UserInterface.query.first().data.get("management", [])
    username = current_user.get_username()
    managements = UserInterface.query.first().data.get("management", [])
    print(datetime.fromtimestamp(time))
    
    messages = Messages.query.filter(
        or_(
            Messages.conversationId.like(f"{username}%"),
            Messages.conversationId.like(f"%{username}"),
            username in managements
        ),
        or_(
            Messages.createdAt > datetime.fromtimestamp(time),
            Messages.updatedAt > datetime.fromtimestamp(time),
            Messages.seen > datetime.fromtimestamp(time),
            Messages.deleted > datetime.fromtimestamp(time)
        )
    ).all()
    if not messages:
        return jsonify({"error": "پیامی یافت نشد."}), 404
    Conversations = {}
    for msg in messages:
        if msg.conversationId+msg.part not in Conversations:
            Conversations[msg.conversationId+msg.part] = {}
    
    for conversationId in Conversations.keys():
        length = len(conversationId)
        conversation = Conversation.query.filter(
            Conversation.conversationId == conversationId[0:20],
            Conversation.part == conversationId[20:length]
            ).first()
        if conversation is not None:
            Conversations[conversationId] = {
                "part": conversation.part,
                "username": conversation.user2 if conversation.user1 == current_user.id else conversation.user1,
                "last_seen": conversation.last_seen2 if conversation.user1 == current_user.id else conversation.last_seen1,
                "state": conversation.state2 if conversation.user1 == current_user.id else conversation.state1,
                "blocked": conversation.blocked,
                "icon": User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1).data.get("icon", "") if User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1) is not None else "",
                "name": User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1).data.get("first_name", "") + " " + User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1).data.get("last_name", "") if User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1) is not None else "کاربر حذف شده",
                "custom_name": User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1).data.get("custom_name", "") if User.get_user_by_username(conversation.user2 if conversation.user1 == current_user.id else conversation.user1) is not None else "",
                "add": [], 
                "delete": []
            }
    add_message = []
    deleted_message = []
    for msg in messages:
        user = User.get_user_by_username(username=msg.sender)
        if user is None:
            sender = "کاربر حذف شده"
        else:
            sender = user.data.get("first_name", "") + " " + user.data.get("last_name", "") if msg.sender != current_user.get_username() else "شما"
        key = msg.conversationId + msg.part
        if msg.deleted is None:
            Conversations[key]["add"].append({
                "id": msg.id,
                "part": msg.part,
                "conversationId": msg.conversationId,
                "messages": msg.messages,
                "time": msg.time,
                "sender_name": sender,
                "sender": msg.sender,
                "seen": msg.seen.timestamp() if msg.seen is not None else None,
                "response": msg.response,
                "updatedAt": msg.updatedAt.timestamp() if msg.updatedAt is not None else 0,
                "createdAt": msg.createdAt.timestamp() if msg.createdAt is not None else 0
            })
        else:
            # اطمینان از وجود کلید و لیست "delete"
            if key not in Conversations:
                Conversations[key] = {"delete": []}
            if "delete" not in Conversations[key]:
                Conversations[key]["delete"] = []
            Conversations[key]["delete"].append(msg.id)
    return jsonify({"conversations":Conversations, "time":datetime.now(tz=TehranTimezone()).timestamp()}), 200

@message_bp.get('/state_user')
@jwt_required()
def get_state_user():
    username = request.args.get("user")
    if username is not None:
        if username == "all":
            users = []
            if current_user.id in UserInterface.query.first().data.get("management", []):
                conversations = Conversation.query.all()
            else:
                conversations = Conversation.query.filter(
                    or_ (Conversation.user1 == current_user.id,
                        Conversation.user2 == current_user.id)
                    ).all()
            for c in conversations:
                otherUser = c.user2 if c.user1 == current_user.id else c.user1
                if otherUser not in users:
                    users.append(otherUser)
            last_seen = []
            for user in users:
                _conversation = Conversation.query.filter(or_(Conversation.user1 == user, Conversation.user2 == user), Conversation.last_seen1 is not None if user == Conversation.user1 else Conversation.last_seen2 is not None).first()
                if _conversation:
                    user_data = User.get_user_by_username(user).data
                    last_seen.append({"user": {"icon": user_data.get("icon", ""), "name":user_data.get("first_name", "") + " " + user_data.get("last_name", ""), "custom_name": user_data.get("custom_name", ""), "username":user}, "last_seen": _conversation.last_seen1 if _conversation.user1 == user else _conversation.last_seen2, "state": _conversation.state1 if _conversation.user1 == user else _conversation.state2, "blocked":_conversation.blocked})
            return jsonify({"users": last_seen}), 200
        else:
            user_data = User.get_user_by_username(username).data
            _conversation = Conversation.query.filter(or_(Conversation.user1 == username, Conversation.user2 == username), Conversation.last_seen1 is not None if username == Conversation.user1 else Conversation.last_seen2 is not None).first()
            return jsonify({"user": {"icon": user_data.get("icon", ""), "name":user_data.get("first_name", "") + " " + user_data.get("last_name", ""), "custom_name": user_data.get("custom_name", ""), "username":username}, "last_seen": _conversation.last_seen1 if _conversation.user1 == username else _conversation.last_seen2, "state":_conversation.state1 if _conversation.user1 == username else _conversation.state2, "blocked":_conversation.blocked}), 200
    return jsonify({"error": "نام کاربری مشخص نشده است."}), 400

@message_bp.get("/supporters")
@jwt_required()
def get_supporters():
    supporters = Supporter.query.filter_by(gender=current_user.gender).all()
    users = []
    for s in supporters:
        
        conversation = Conversation.query.filter(
            or_ (Conversation.user1 == current_user.id,
                Conversation.user2 == current_user.id),
            or_ (Conversation.user1 == s.username,
                Conversation.user2 == s.username),
            Conversation.part == s.part
            ).first()
        if conversation is None and s.username != current_user.id:
            users.append(s)
    supporters_data = []
    for s in users:
        user_data = User.get_user_by_username(s.username).data
        supporters_data.append({"icon": user_data.get("icon", ""), "name":user_data.get("first_name", "") + " " + user_data.get("last_name", ""), "custom_name": user_data.get("custom_name", ""), "username":s.username, "part":s.part})
    return jsonify({"supporters":supporters_data})
def jalali_to_gregorian(jy, jm, jd, hour=0, minute=0):
    gdate = jdatetime.datetime(jy, jm, jd, hour, minute).togregorian()
    return gdate

# تبدیل میلادی به جلالی
def gregorian_to_jalali(dt):
    jdate = jdatetime.datetime.fromgregorian(datetime=dt)
    return jdate

