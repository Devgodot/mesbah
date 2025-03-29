from flask import Blueprint, jsonify, request, current_app
from flask_caching import Cache
from confige import db, app
from schemas import UserSchema, GroupSchema
from flask_jwt_extended import current_user, jwt_required
from random import randint
import random, os, shutil
from models import User, UserInterface, Group, ServerMessage
import json
from datetime import datetime, timedelta
from sqlalchemy.orm.attributes import flag_modified

cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
control_bp = Blueprint("control", __name__)
import requests, time

@control_bp.post("/add_editor")
@jwt_required()
def editor():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        user = User.get_user_by_username(username=data.get("username", ""))
        if user is None:
            return jsonify({"error": "کاربر وجود ندارد"}), 404
        game_data = UserInterface.query.first()
        editor = []
        part = data.get("part")
        if user.username in game_data.data.get("management", []) and "5100276150" != current_user.username:
            return jsonify({"error": "این کاربر مدیر است"}), 400
        for e in game_data.data.get(f"editor{part}", {}):
            editor.append(e)
        if user.username not in editor:
            editor.append(user.username)
            game_data.data.update({f"editor{part}" : editor})
            flag_modified(game_data, "data")
            db.session.commit()
            for e in editor:
                user2 = User.get_user_by_username(username=e)
                if user2 is not None:
                    d = {}
                    for n in user2.data.keys():
                        if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                            d[n] = user2.data.get(n, "")
                    d["username"] = user2.username
                    d["phone"] = user2.phone
                    if e in game_data.data.get("management", []) or e == current_user.username:
                        d["management"] = True
                    if e != current_user.username and current_user.username == "5100276150":
                        d.pop("management", None)
                    editor[editor.index(e)] = d
            return jsonify({"data": editor, "message": "ویرایشگر با موفقیت اضافه شد."}), 200
        else:
            return jsonify({"error": "این کاربر قبلا اضافه شده است"}), 400
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403

@control_bp.post("/remove_editor")
@jwt_required()
def remove_editor():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        user = User.get_user_by_username(username=data.get("username", ""))
        if user is None:
            return jsonify({"error": "کاربر وجود ندارد"}), 404
        game_data = UserInterface.query.first()
        editor = []
        part = data.get("part")
        
        # فیلتر کردن کلیدهای خاص
        for e in game_data.data.get(f"editor{part}", {}):
            editor.append(e)
        
        if user.username in editor:
            editor.remove(user.username)
            game_data.data.update({f"editor{part}": editor})
            
            # اطلاع دادن به SQLAlchemy که دیکشنری تغییر کرده است
            flag_modified(game_data, "data")
            db.session.commit()
            for e in editor:
                user2 = User.get_user_by_username(username=e)
                if user2 is not None:
                    d = {}
                    for n in user2.data.keys():
                        if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                            d[n] = user2.data.get(n, "")
                    d["username"] = user2.username
                    d["phone"] = user2.phone
                    if e in game_data.data.get("management", []) or e == current_user.username:
                        d["management"] = True
                    if e != current_user.username and current_user.username == "5100276150":
                        d.pop("management", None)
                    editor[editor.index(e)] = d
            return jsonify({"data":editor, "message": "ویرایشگر با موفقیت حذف شد."}), 200
        else:
            return jsonify({"error": "کاربر در لیست ویرایشگران وجود ندارد."}), 400
    else:
        return jsonify({"error": "شما دسترسی لازم را ندارید."}), 403

@control_bp.get("/get_editors")
@jwt_required()
def get_editors():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.args
        game_data = UserInterface.query.first()
        editor = []
        part = data.get("part")
        for e in game_data.data.get(f"editor{part}", {}):
            editor.append(e)
        for e in editor:
            user = User.get_user_by_username(username=e)
            if user is not None:
                d = {}
                for n in user.data.keys():
                    if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                        d[n] = user.data.get(n, "")
                d["username"] = user.username
                d["phone"] = user.phone
                if e in game_data.data.get("management", []) or e == current_user.username:
                    d["management"] = True
                if e != current_user.username and current_user.username == "5100276150":
                    d.pop("management", None)
                editor[editor.index(e)] = d
        return jsonify({"data": editor})
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
@control_bp.post("/add_supporter")
@jwt_required()
def supporter():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        user = User.get_user_by_username(username=data.get("username", ""))
        if user is None:
            return jsonify({"error": "کاربر وجود ندارد"}), 404
        game_data = UserInterface.query.first()
        supporters = game_data.data.get("supporters", {"male": [], "female": []}).get(["male", "female"][data.get("gender", 0)])[data.get("tag", 0)][data.get("part", 0)]
        if user.username in game_data.data.get("management", []) and "5100276150" != current_user.username:
            return jsonify({"error": "این کاربر مدیر است"}), 400
        if user.username not in supporters:
            supporters.append(user.username)
            all_supporters = {"male": [], "female": []}
            for g in game_data.data.get("supporters", {"male": [], "female": []}).keys():
                for t in game_data.data.get("supporters", {"male": [], "female": []}).get(g, []):
                    l = []
                    for p in t:
                        l2 = []
                        for s in p:
                            l2.append(s)
                        l.append(l2)
                    all_supporters[g].append(l)
            all_supporters.get(["male", "female"][data.get("gender", 0)])[data.get("tag", 0)][data.get("part", 0)] = supporters
            game_data.data.update({"supporters": all_supporters})
            flag_modified(game_data, "data")
            db.session.commit()
            for s in supporters:
                user2 = User.get_user_by_username(username=s)
                if user2 is not None:
                    d = {}
                    for n in user2.data.keys():
                        if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                            d[n] = user2.data.get(n, "")
                    d["username"] = user2.username
                    d["phone"] = user2.phone
                    if s in game_data.data.get("management", []) or s == current_user.username:
                        d["management"] = True
                    if s != current_user.username and current_user.username == "5100276150":
                        d.pop("management", None)
                    supporters[supporters.index(s)] = d
            return jsonify({"data": supporters, "message": "پشتیبان با موفقیت اضافه شد."}), 200
        else:
            return jsonify({"error": "این کاربر قبلا اضافه شده است"}), 400
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
    
@control_bp.post("/remove_supporter")
@jwt_required()
def remove_supporter():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        user = User.get_user_by_username(username=data.get("username", ""))
        if user is None:
            return jsonify({"error": "کاربر وجود ندارد"}), 404
        game_data = UserInterface.query.first()
        supporters = game_data.data.get("supporters", {"male": [], "female": []}).get(["male", "female"][data.get("gender", 0)])[data.get("tag", 0)][data.get("part", 0)]
        if user.username in supporters:
            supporters.remove(user.username)
            all_supporters = {"male": [], "female": []}
            for g in game_data.data.get("supporters", {"male": [], "female": []}).keys():
                for t in game_data.data.get("supporters", {"male": [], "female": []}).get(g, []):
                    l = []
                    for p in t:
                        l2 = []
                        for s in p:
                            l2.append(s)
                        l.append(l2)
                    all_supporters[g].append(l)
            all_supporters.get(["male", "female"][data.get("gender", 0)])[data.get("tag", 0)][data.get("part", 0)] = supporters
            game_data.data.update({"supporters": all_supporters})
            flag_modified(game_data, "data")
            db.session.commit()
            for s in supporters:
                user2 = User.get_user_by_username(username=s)
                if user2 is not None:
                    d = {}
                    for n in user2.data.keys():
                        if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                            d[n] = user2.data.get(n, "")
                    d["username"] = user2.username
                    d["phone"] = user2.phone
                    if s in game_data.data.get("management", []) or s == current_user.username:
                        d["management"] = True
                    if s != current_user.username and current_user.username == "5100276150":
                        d.pop("management", None)
                    supporters[supporters.index(s)] = d
            return jsonify({"data": supporters, "message": "پشتیبان با موفقیت حذف شد."}), 200
        else:
            return jsonify({"error": "این کاربر پشتیبان نمی باشد"}), 400
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403

@control_bp.get("/get_supporters")
@jwt_required()
def get_supporters():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.args
        game_data = UserInterface.query.first()
        supporters = game_data.data.get("supporters", {"male": [], "female": []}).get(["male", "female"][int(data.get("gender", 0))])[int(data.get("tag", 0))][int(data.get("part", 0))]
        if (supporters is not None) or (len(supporters) != 0):
            for s in supporters:
                user2 = User.get_user_by_username(username=s)
                if user2 is not None:
                    d = {}
                    for n in user2.data.keys():
                        if n in ["first_name", "last_name", "father_name", "icon", "custom_name"]:
                            d[n] = user2.data.get(n, "")
                    d["username"] = user2.username
                    d["phone"] = user2.phone
                    if s in game_data.data.get("management", []) or s == current_user.username:
                        d["management"] = True
                    if s != current_user.username and current_user.username == "5100276150":
                        d.pop("management", None)
                    supporters[supporters.index(s)] = d
            return jsonify({"data": supporters, "message": "پشتیبان با موفقیت اضافه شد."}), 200
        else:
            return jsonify({"error": "پشتیبانی در این بخش وجود ندارد"}), 400
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403

@control_bp.get("/get_users")
@jwt_required()
def get_users():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        users = User.query.all()
        filter_users = []
        for user in users:
            name = user.data.get("first_name", "") + " " + user.data.get("last_name", "")
            if request.args.get("name") is not None:
                if request.args.get("name") in name:
                    filter_users.append(user)
            if request.args.get("phone") is not None:
                if request.args.get("phone") in user.phone:
                    filter_users.append(user)
            if request.args.get("username") is not None:
                if request.args.get("username") in user.username:
                    filter_users.append(user)
        for user in filter_users:
            d = {}
            gender = user.data.get("gender", 0)
            tag = user.data.get("tag", 0)
            for n in user.data.keys():
                if n in ["first_name", "last_name", "father_name", "icon", "custom_name", "pro", f"score_{gender}_{tag}", "diamonds", "block", "tag", "gender"]:
                    d[n] = user.data.get(n, "")
            d["username"] = user.username
            d["phone"] = user.phone
            filter_users[filter_users.index(user)] = d
            
        if len(filter_users) == 0:
            return jsonify({"error": "کاربری با این مشخصات یافت نشد."}), 404
        return jsonify({"data": filter_users}), 200
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
@control_bp.get("/get_group")
@jwt_required()
def get_group():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        group = Group.query.filter_by(name=request.args.get("name")).first()
        if group is None:
            return jsonify({"error": "گروهی با این نام وجود ندارد"}), 404
        users = group.users.get("users", [])
        data = []
        for user in users:
            user = User.get_user_by_username(username=user)
            if user is not None:
                d = {}
                for n in user.data.keys():
                    if n in ["first_name", "last_name", "father_name", "custom_name"]:
                        d[n] = user.data.get(n, "")
                d["username"] = user.username
                d["phone"] = user.phone
                data.append(d)
        return jsonify({"data": data, "diamonds":sum(group.diamonds.values()), "score":sum(group.score.values()), "leader":group.users.get("leader", ""), "icon":group.icon}), 200
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403

@control_bp.post("change_user")
@jwt_required()
def change_user():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        user = User.get_user_by_username(username=data.get("username", ""))
        if user is None:
            return jsonify({"error": "کاربر وجود ندارد"}), 404
        for u in user.data.get("users_sended_message", []):
            messages = User.get_user_by_username(username=u).data.get("message", [])
            for message in messages:
                if message.get("data", {"user":""}).get("user") == user.username:
                    messages.remove(message)
            User.get_user_by_username(username=u).update(data={"message":messages})
        user_join_messages = user.data.get("message", [])
        remove_event = []
        for message in user_join_messages:
            if message.get("type", "") == "join":
                remove_event.append(message.get("data", {"user":""}).get("user"))
                user_join_messages.remove(message)
        group_name = user.data.get("group_name", "")
        group = Group.get_group_by_name(name=group_name)
        if group is not None:
            group.users.get("users", []).remove(user.username)
            if len(group.users.get("users", [])) == 0:
                db.session.delete(group)
            else:
                group.users["leader"] = group.users.get("users", [])[0]
                flag_modified(group, "users")
            db.session.commit()
        request_message = user.data.get("users_request", [])
        for u in request_message:
            user2 = User.get_user_by_username(u[0])
            user_message = user2.data.get("message", [])
            for m in user_message:
                if m.get("id", "") == u[1]:
                    user_message.remove(m)
            user2.update(data={"message":user_message})
        tag = data.get("tag")
        gender = data.get("gender")
        last_gender = user.data.get("gender", 0)
        last_tag = user.data.get("tag", 0)
        score = current_user.data.get(f"score_{last_gender}_{last_tag}", 0)
        score_0 = current_user.data.get(f"score_{last_gender}_{last_tag}_0", 0)
        score_1 = current_user.data.get(f"score_{last_gender}_{last_tag}_1", 0)
        score_2 = current_user.data.get(f"score_{last_gender}_{last_tag}_2", 0)
        user.tag = tag if tag is not None else last_tag
        user.gender = gender if gender is not None else last_gender
        user.update(data={"message":user_join_messages, "group_name":"", "users_request":[], "tag": tag if tag is not None else user.data.get("tag"), "gender": gender if gender is not None else user.data.get("gender"), f"score_{gender}_{tag}": score, f"score_{gender}_{tag}_0": score_0, f"score_{gender}_{tag}_1": score_1, f"score_{gender}_{tag}_2": score_2})
        user.data.pop(f"score_{last_gender}_{last_tag}", None)
        user.data.pop(f"score_{last_gender}_{last_tag}_0", None)
        user.data.pop(f"score_{last_gender}_{last_tag}_1", None)
        user.data.pop(f"score_{last_gender}_{last_tag}_2", None)
        
        for u in remove_event:
            user2 = User.get_user_by_username(u)
            if user2 is not None:
                sended_message = user2.data.get("users_sended_message", [])
                if user.username in sended_message:
                    sended_message.remove(user.username)
                user2.update(data= {"users_sended_message":sended_message})
        db.session.commit()
        return jsonify({"message": "کاربر با موفقیت تغییر یافت."}), 200
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403

@control_bp.get("/left_group")
@jwt_required()
def left_group():
    delete_user = request.get_json().get("user")
    if delete_user is None:
        return jsonify({"error": "کاربر وجود ندارد"})
    group = Group.get_group_by_name(delete_user.data.get("group_name", ""))
    if group is None:
        return jsonify({"error": "گروه وجود ندارد"})
    users = []
    for user in group.users.get("users", []):
        if user != delete_user.username:
            users.append(user)
    
    for user in delete_user.data.get("users_sended_message", []):
        messages = User.get_user_by_username(username=user).data.get("message", [])
        for message in messages:
            if message.get("data", {"user":""}).get("user") == delete_user.username:
                messages.remove(message)
        User.get_user_by_username(username=user).update(data={"message":messages})
    messages = delete_user.data.get("message", [])
    for message in messages:
        if message.get("type", "") == "request":
            user = User.get_user_by_username(username=message.get("data", {"user":""}).get("user"))
            request_message = user.data.get("users_request", [])
            for r in request_message:
                if r[0] == delete_user.username:
                    request_message.remove(r)
            user.update(data={"users_request":request_message})
            messages.remove(message)
    delete_user.update(data={"group_name":"", "message":messages, "users_sended_message": []})
    db.session.commit()
    if len(users) > 0:
        leader = group.users.get("leader", "") if group.users.get("leader", "") != delete_user.username else users[0]
        if group.users.get("leader", "") == delete_user.username:
            if group.icon != "":
                path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users")
                phone = User.get_user_by_username(username=users[0]).phone
                for file in os.listdir(path=os.path.join(path , str(delete_user.phone))):
                    if file.startswith(group.name):
                        group.icon = f"http://messbah403.ir/static/files/users/{phone}/{file}"
                        shutil.move(os.path.join(path, str(delete_user.phone), file), os.path.join(path, phone, file))
    else:
        path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users")
        for file in os.listdir(path=os.path.join(path , str(delete_user.phone))):
            if file.startswith(group.name):
                os.remove(os.path.join(path , str(delete_user.phone), file))
        db.session.delete(group)
        db.session.commit()
        return jsonify({"message":"گروه حذف شد"})
    group.users = {"users":users, "leader":leader}
    db.session.commit()
    return jsonify({"message":"کاربر با موفقیت حذف شد"})


from werkzeug.utils import secure_filename
from PIL import Image  # برای تبدیل تصاویر به فرمت webp
from pydub import AudioSegment  # برای تبدیل صدا به فرمت mp3
import io
import uuid
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone

ALLOWED_IMAGE_EXTENSIONS = {"png", "jpg", "jpeg", "webp"}
ALLOWED_AUDIO_EXTENSIONS = {"wav", "ogg", "mp3"}

def allowed_file(filename, allowed_extensions):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in allowed_extensions

@control_bp.post("/send_message")
@jwt_required()
def send_message_with_media():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        audio_url = None
        image_url = None
        # دریافت داده‌ها
        audiofile = request.get_json().get("audioname")
        audio_data = request.get_json().get("audiodata")
        imagefile = request.get_json().get("imagename")
        image_data = request.get_json().get("imagedata")
        if imagefile is not None and allowed_file(imagefile, ALLOWED_IMAGE_EXTENSIONS):
            # Convert the list to bytes
            if not isinstance(json.loads(image_data), list):
                return jsonify({"error": "فرمت تصویر پشتیبانی نمی شود"}), 400
            try:
                byte_data = bytes(json.loads(image_data))
            except ValueError as e:
                current_app.logger.error(f"Error converting list to bytes: {e}")
                return jsonify({"error": "خطایی در بارگیری تصویر به وجود آمد"}), 400
            
            # Convert the bytes to an image
            try:
                image = Image.open(io.BytesIO(byte_data))
            except IOError as e:
                current_app.logger.error(f"Error converting data to image: {e}")
                return jsonify({"error": "خطایی در تبدیل تصویر به وجود آمد"}), 400
            
            # Define the path to save the image
            path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "management")
            if not os.path.exists(path):
                os.makedirs(path)
            time = datetime.now(TehranTimezone())
            save_path = os.path.join(path, f"{time.strftime('%Y%m%d%H%M%S')}.webp")
            image.save(save_path, "webp")
            image_url = f"https://messbah403.ir/static/files/management/{os.path.basename(save_path)}"
        if audiofile is not None and allowed_file(audiofile, ALLOWED_AUDIO_EXTENSIONS):
            # Convert the list to bytes
            if not isinstance(json.loads(audio_data), list):
                return jsonify({"error": "فرمت صدا پشتیبانی نمی شود"}), 400
            try:
                byte_data = bytes(json.loads(audio_data))
            except ValueError as e:
                current_app.logger.error(f"Error converting list to bytes: {e}")
                return jsonify({"error": "خطایی در بارگیری داده های صدا به وجود آمد"}), 400
            
            # Convert the bytes to an audio
            try:
                audio = AudioSegment.from_file(io.BytesIO(byte_data))
            except IOError as e:
                current_app.logger.error(f"Error converting data to audio: {e}")
                return jsonify({"error": "خطایی در تبدیل صدا به وجود آمد"}), 400
            
            # Define the path to save the audio
            path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "management")
            if not os.path.exists(path):
                os.makedirs(path)
            time = datetime.now(TehranTimezone())
            save_path = os.path.join(path, f"{time.strftime('%Y%m%d%H%M%S')}.mp3")
            audio.export(save_path, format="mp3")
            audio_url = f"https://messbah403.ir/static/files/management/{os.path.basename(save_path)}"
        else:
            if audiofile is not None or imagefile is not None:
                return jsonify({"error": "فرمت فایل پشتیبانی نمی‌شود"}), 400
        
        
        users = request.get_json().get("users")
        filter_m = request.get_json().get("filter")
        _id = str(uuid.uuid4())
        text = request.get_json().get("text", "")
        gregorian_date = datetime.now(TehranTimezone())  # تاریخ میلادی فعلی
        jalali_date = JalaliDatetime(gregorian_date)  # تبدیل به تاریخ شمسی
        message_data = {"text": text, "data": {"time": str(jalali_date)}, "id": _id, "sender": "پشتیبانی", "type": request.get_json().get("type", "guid")}
        if audio_url:
            message_data["sound"] = audio_url
        if image_url:
            message_data["image"] = image_url
        server_message = ServerMessage(id=_id, image=image_url, audio=audio_url, message=text, receiver={"users": users, "filter": filter_m})
        db.session.add(server_message)
        db.session.commit()
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
                            if f != "tag":
                                if user.data.get(f) != filter_m.get(f):
                                    all_true = False
                            else:
                                all_true = False
                                for t in filter_m.get("tag"):
                                    if user.data.get("tag", 0) == t:
                                        all_true = True
                                        break
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
                    print(f"کاربری با کد ملی '{username}' پیدا نشد.")
        else:
            return jsonify({"error": "The 'users' parameter must be a string ('all') or a list of usernames."}), 400
        
        return jsonify({"message": "پیام با موفقیت ارسال شد"}), 200
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
@control_bp.get("/get_messages")
@jwt_required()
def get_messages():
    messages = ServerMessage.query.all()
    data = []
    for message in messages:
        jalali_date = JalaliDatetime(message.timestamp)
        data.append({"id":message.id, "text":message.message, "time":str(jalali_date), "receiver":message.receiver})
    return jsonify({"data":data}), 200

@control_bp.get("/sort_users")
@jwt_required()
def sort_users():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        filter_data = []
        if request.args.get("filter"):
            filter_data = request.args.get("filter").split("AND")
        sort = request.args.get("sort", "").split("AND")
        page = request.args.get("page", default=1, type=int)
        per_page = request.args.get("per_page")
        users = User.query.all()
        if per_page is None or int(per_page) == 0:
            per_page = len(users)
        else:
            per_page = int(float(per_page))
        u = []
        for user in users:
            if sort and sort != [''] and  all(user.data.get(k) is not None for k in sort):
                u.append(user)
            elif not sort or sort == ['']:
                return jsonify({"error": "لطفا فیلتری برای مرتب سازی انتخاب کنید"}), 400
        
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
            return jsonify({"error": "چنین رتبه بندی وجود ندارد"})
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
@control_bp.get("/sort_group")
@jwt_required()
def sort_group():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        filter_data = []
        if request.args.get("filter"):
            filter_data = request.args.get("filter").split("AND")
        page = request.args.get("page", default=1, type=int)
        per_page = request.args.get("per_page")
        groups = Group.query.filter_by(gender=request.args.get("gender", 0, int), tag=request.args.get("tag", 0, int)).all()
       
        if per_page is None or int(per_page) == 0:
            per_page = len(groups)
        else:
            per_page = int(float(per_page))
        
        groups.sort(key=lambda group: (sum(group.diamonds.values()), sum(group.score.values())), reverse=True)
        u2 = []
        for x, group in enumerate(groups):
            if x >= (page - 1) * per_page and x < page * per_page:
                u2.append(group)
        print(u2)
        previous_score = None
        current_position = 0
        for index, group in enumerate(u2):
            current_score = (sum(group.diamonds.values()), sum(group.score.values()))
            if current_score != previous_score:
                current_position = index + 1
            group.position = current_position
            group.score = sum(group.score.values())
            group.diamonds = sum(group.diamonds.values())
            if filter_data:
                for username in group.users.get("users", []):
                    user = User.get_user_by_username(username=username)
                    d = {}
                    for key in filter_data:
                        k = key
                        if user.data.get(k) is not None:
                            d[key] = user.data.get(k)
                    user.data = d
                    user.data["username"] = username
                    user.data["phone"] = user.phone
                    group.users["users"][group.users.get("users", []).index(username)] = user.data
            previous_score = current_score
        result = GroupSchema().dump(u2, many=True)
        if len(u2) > 0:
            return (
                jsonify(
                    {
                        "groups": result,
                    }
                ),
                200,
            )
        else:
            return jsonify({"error": "چنین رتبه بندی وجود ندارد"})
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403