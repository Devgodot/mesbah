from flask import Blueprint, jsonify, request
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
import random
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
    


@auth_bp.get("/random_levels")
@jwt_required()
def get_random_levels():
    if "GodotEngine" in request.headers.get("User-Agent"):
        season = UserInterface.query.first().data.get("season", "1")
        part = request.args.get("part", 0)
        num_levels = UserInterface.query.first().data.get("laps_allowed"+str(season))[int(part)]
        # Query all levels from the database
        all_levels = Levels.query.filter_by(part=str(part), type="لیگ").all()
        # Get the list of level IDs already in league_levels
        existing_level_ids = current_user.data.get(f"league_levels_{part}_{season}", [[], 0])[0]
        level_ids = [int(level.get("id", 0)) for level in existing_level_ids]
        # Filter out levels that are already in the league_levels list
        available_levels = [level for level in all_levels if level.id not in level_ids]
        random_levels = [Levels.query.filter_by(id=id).first() for id in level_ids]
        # If the number of selected levels is less than num_levels, add additional levels
        while len(random_levels) < num_levels:
            if len(available_levels) == 0:
                break
            random_levels.append(random.choice(available_levels))
        while len(random_levels) > num_levels:
            random_levels.pop()
        random_levels = list(set(random_levels))
        level_data = []
        for x, level in enumerate(random_levels):
            level_info = {
                "id": level.id,
                "state": current_user.data.get(f"league_levels_{part}_{season}", [[], 0])[0][x].get("state", 0) if len(current_user.data.get(f"league_levels_{part}_{season}", [[], 0])[0]) > x else 0,
                "score": current_user.data.get(f"league_levels_{part}_{season}", [[], 0])[0][x].get("score", 0) if len(current_user.data.get(f"league_levels_{part}_{season}", [[], 0])[0]) > x else 0
            }
            level_data.append(level_info)
        total_score = sum(json.loads(hashing(HashingMode.DECODE, level.data.get("data"))).get("score", 0) for level in random_levels)

        current_user.data = current_user.update(data={f"league_levels_{part}_{season}":[level_data, total_score]}, overwrite=False)
        db.session.commit()
        return jsonify({"level_data": level_data, "total_score": total_score})
    return "شما اجازه دسترسی ندارید", 400
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
            new_user = User(id =username, username=username, phone=data.get("phone"), data=data.get("data", {}), password="1234")
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
        user.update(data= {"users_sended_message":sended_message})
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
        print(users)
        group.users = {"users":users, "leader":users[0]}
    print(group.users)
    db.session.commit()
    current_user.update(data={"message":messages, "group_name":group_name})
    for u in remove_event:
        user = User.get_user_by_username(u)
        if user is not None:
            sended_message = user.data.get("users_sended_message", [])
            if current_user.username in sended_message:
                sended_message.remove(current_user.username)
            user.update(data= {"users_sended_message":sended_message})
    
    db.session.commit()
    return jsonify({"message":"successe"})