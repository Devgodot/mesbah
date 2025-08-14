from sqlalchemy import or_
from flask import Blueprint, jsonify, request, current_app
from flask_caching import Cache
from confige import db, app
from schemas import UserSchema, GroupSchema
from flask_jwt_extended import current_user, jwt_required
from random import randint
import random, os, shutil
from models import User, UserInterface, Group, Planes, Supporter, Conversation
import json
from datetime import datetime, timedelta
from sqlalchemy.orm.attributes import flag_modified
import jdatetime
cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})
plan_bp = Blueprint("planes", __name__)


@plan_bp.get("/get")
@jwt_required()
def get_plan():
    if request.args.get("year") is not None:
        year = request.args.get("year")
        planes = Planes.query.filter_by(year=year).all()
        plan_names = []
        for plan in planes:
            if plan.name not in plan_names:
                plan_names.append(plan.name)
        return jsonify({"planes": plan_names})
    if request.args.get("name") is not None:
        name = request.args.get("name")
        plan = Planes.query.filter_by(name=name).all()
        print(plan)
        if plan is None or len(plan) == 0:
            return jsonify({"error": "برنامه‌ای یافت نشد."}), 404
        subplanes = []
        for subplan in plan:
            editors = []
            for editor in subplan.editors:
                user_data = User.get_user_by_username(editor)
                if user_data is not None:
                    editors.append({"name": user_data.data.get("first_name", "") + " " + user_data.data.get("last_name", "") + " " + user_data.data.get("father_name", ""), "username": editor})
            subplanes.append({
                "name": subplan.subplan,
                "diamond_range": subplan.diamond_range,
                "editors": editors
            })
        return jsonify({"subplanes": subplanes}), 200
@plan_bp.post("/add")
@jwt_required()
def add_plan():
    if current_user.get_username() not in UserInterface.query.first().data.get("management", []):
        return jsonify({"error": "شما دسترسی لازم را ندارید."}), 403
    data = request.get_json()
    if not data or "name" not in data or "subplanes" not in data or data.get("name") == "":
        return jsonify({"error": "اطلاعات ناقص است."}), 400
    name = data["name"]
    year = str(gregorian_to_jalali(datetime.now()).year)
    for subplan in data.get("subplanes"):
        if subplan.get("name") == "":
            continue
        existing_plan = Planes.query.filter_by(name=name, subplan=subplan.get("name")).first()
        if existing_plan:
            return jsonify({"error": "برنامه با این نام و زیر برنامه وجود دارد."}), 400
        new_plan = Planes(name=name, subplan=subplan.get("name"), editors=subplan.get("editors"), diamond_range=subplan.get("diamond_range"), year=year)
        db.session.add(new_plan)
        supporters = Supporter.query.filter_by(part=name + " - " + subplan.get("name")).all()
        for s in supporters:
            if s.username not in subplan.get("editors"):
                db.session.delete(s)
                conversations = Conversation.query.filter(or_(Conversation.user1==s.username, Conversation.user2 == s.username), Conversation.part==name + " - " + subplan.get("name")).all()
                for c in conversations:
                    c.blocked = True
                    db.session.commit()
                db.session.commit()
        for s in subplan.get("editors"):
            supporter = Supporter.query.filter_by(username=s).first()
            user = User.get_user_by_username(s)
            if supporter is None and user is not None:
                new = Supporter(part=name + " - " + subplan.get("name"), gender=user.gender, username=s)
                db.session.add(new)
                conversations = Conversation.query.filter(or_(Conversation.user1==s, Conversation.user2 == s), Conversation.part==name + " - " + subplan.get("name")).all()
                for c in conversations:
                    c.blocked = False
                    db.session.commit()
                db.session.commit()
        db.session.commit()
    return jsonify({"message": "برنامه با موفقیت اضافه شد."}), 201


@plan_bp.post("/edit")
@jwt_required()
def edit_plan():
    if current_user.get_username() not in UserInterface.query.first().data.get("management", []):
        return jsonify({"error": "شما دسترسی لازم را ندارید."}), 403
    data = request.get_json()
    if not data or "name" not in data or "subplanes" not in data:
        return jsonify({"error": "اطلاعات ناقص است."}), 400
    name = data["name"]
    year = str(gregorian_to_jalali(datetime.now()).year)
    for subplan in data.get("subplanes"):
        if subplan.get("name") == "":
            continue
        existing_plan = Planes.query.filter_by(name=name, subplan=subplan.get("name")).first()
        if existing_plan:
            existing_plan.editors = subplan.get("editors")
            existing_plan.diamond_range = subplan.get("diamond_range")
            db.session.commit()
        else:
            new_plan = Planes(name=name, subplan=subplan.get("name"), editors=subplan.get("editors"), diamond_range=subplan.get("diamond_range"), year=year)
            db.session.add(new_plan)
            db.session.commit()
        supporters = Supporter.query.filter_by(part=name + " - " + subplan.get("name")).all()
        for s in supporters:
            if s.username not in subplan.get("editors"):
                db.session.delete(s)
                conversations = Conversation.query.filter(or_(Conversation.user1==s.username, Conversation.user2 == s.username), Conversation.part==name + " - " + subplan.get("name")).all()
                for c in conversations:
                    c.blocked = True
                    db.session.commit()
                db.session.commit()
        for s in subplan.get("editors"):
            supporter = Supporter.query.filter_by(username=s, part=name + " - " + subplan.get("name")).first()
            user = User.get_user_by_username(s)
            if supporter is None and user is not None:
                new = Supporter(part=name + " - " + subplan.get("name"), gender=user.gender, username=s)
                db.session.add(new)
                conversations = Conversation.query.filter(or_(Conversation.user1==s, Conversation.user2 == s), Conversation.part==name + " - " + subplan.get("name")).all()
                for c in conversations:
                    c.blocked = False
                    db.session.commit()
                db.session.commit()
    for subplan in Planes.query.filter_by(name=name).all():
        if data.get("subplanes") and subplan.subplan not in [sp.get("name") for sp in data.get("subplanes")]:
            supporters = Supporter.query.filter_by(part=name + " - " + subplan.get("name")).all()
            for s in supporters:
                db.session.delete(s)
                conversations = Conversation.query.filter(or_(Conversation.user1==s.username, Conversation.user2 == s.username), Conversation.part==name + " - " + subplan.get("name")).all()
                for c in conversations:
                    c.blocked = True
                    db.session.commit()
                db.session.commit()
            db.session.delete(subplan)
            db.session.commit()
            
    return jsonify({"message": "برنامه با موفقیت ویرایش شد."}), 200

@plan_bp.get("/my_planes")
@jwt_required()
def get_my_planes():
    username = current_user.get_username()
    planes = Planes.query.filter(Planes.editors.contains(username)).all()
    if not planes:
        return jsonify({"error": "هیچ برنامه‌ای برای شما یافت نشد."}), 404
    return jsonify({"planes": [{"name": plan.name, "subplan": plan.subplan} for plan in planes]}), 200


@plan_bp.get("/all")
@jwt_required()
def get_all():
    planes = Planes.query.all()
    data = {}
    for plan in planes:
        if plan.name not in data.keys():
            data[plan.name] = [plan.subplan]
        else:
            if plan.subplan not in data[plan.name]:
                data[plan.name].append(plan.subplan)
    return jsonify(data)

def jalali_to_gregorian(jy, jm, jd, hour=0, minute=0):
    gdate = jdatetime.datetime(jy, jm, jd, hour, minute).togregorian()
    return gdate

# تبدیل میلادی به جلالی
def gregorian_to_jalali(dt):
    jdate = jdatetime.datetime.fromgregorian(datetime=dt)
    return jdate

