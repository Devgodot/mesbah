from flask import Blueprint, jsonify, request, current_app
from flask_caching import Cache
from confige import db, app
from flask_jwt_extended import current_user
from random import randint
import random, os, shutil
from models import User, TokenBlocklist, UserInterface, Levels, Group, VerificationCode, Messages, UserSeenMessages
import json
from datetime import datetime, timedelta

cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
control_bp = Blueprint("control", __name__)
import requests, time


@control_bp.post("/editor")
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
        for e in game_data.data.get(f"editor_{part}", {}):
            editor.append(e)
        if user.username not in editor:
            editor.append(user.username)
            game_data.data[f"editor_{part}"] = editor
            db.session.commit()
            return jsonify({"data": editor})
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
        for e in game_data.data.get(f"editor_{part}", {}):
            editor.append(e)
        if user.username in editor:
            editor.remove(user.username)
            game_data.data[f"editor_{part}"] = editor
            db.session.commit()
            return jsonify({"data": editor})
        else:
            return jsonify({"error": "این کاربر ویرایشگر نیست"}), 400
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
@control_bp.post("/get_editors")
@jwt_required()
def get_editors():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        game_data = UserInterface.query.first()
        editor = []
        part = data.get("part")
        for e in game_data.data.get(f"editor_{part}", {}):
            editor.append(e)
        for e in editor:
            user = User.get_user_by_username(username=e)
            if user is not None:
                d = {}
                for n in user.data.keys():
                    if n in ["first_name", "last_name", "phone", "user_name", "father_name", "icon", "custom_name"]:
                        d[n] = user.data.get(n, "")
                editor[editor.index(e)] = d
        return jsonify({"data": editor})
    else:
        return jsonify({"error": "شما اجازه دسترسی به این بخش را ندارید"}), 403
