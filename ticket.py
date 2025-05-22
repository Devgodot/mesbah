from flask import request, Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Ticket
from schemas import UserSchema
from sqlalchemy import desc, text
from confige import db, app
import time, uuid, os
import datetime, json
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone

ticket_bp = Blueprint("ticket", __name__)


@ticket_bp.post("/add_ticket")
@jwt_required()
def add_ticket():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        _time = data.get("time", "1404/03/24 15:00")
        season = UserInterface.query.first().data.get("train_season", 1)
        try:
            date_part, time_part = _time.split(" ")
            year, month, day = map(int, date_part.split("/"))
            hour, minute = map(int, time_part.split(":"))
            miladi_date = JalaliDatetime(year, month, day, hour, minute).todatetime()
        except Exception as e:
            return jsonify({"error": f"فرمت تاریخ اشتباه است: {e}"}), 400
        if Ticket.query.filter_by(season=season, time=miladi_date).first():
            return jsonify({"error": "تیکت با این زمان وجود دارد"}), 400
        ticket = Ticket(time=miladi_date, 
                        users=data.get("users", []),
                        max_users=data.get("max_users", 0),
                        season=season)
        db.session.add(ticket)
        db.session.commit()
        return jsonify({"message": "تیکت با موفقیت اضافه شد"}), 201
    else:
        return jsonify({"error": "شما مجاز به اضافه کردن بلیط نیستید"}), 403

@ticket_bp.get("/get_ticket")
@jwt_required()
def get_ticket():
    if current_user.data.get("accept_account", False) != True:
        return jsonify({"error": "حساب شما تایید نشده! لطفاً به پشتیبانی مراجعه فرمایید."}), 403
    season = UserInterface.query.first().data.get("train_season", 1)
    tickets = Ticket.query.filter_by(season=season).all()
    if not tickets:
        return jsonify({"error": "تیکتی وجود ندارد"}), 404
    tickets_data = []
    for ticket in tickets:
        # تبدیل تاریخ میلادی به جلالی و ساخت رشته خروجی
        jalali_datetime = JalaliDatetime(ticket.time)
        ticket_data = {
            "time": f"{jalali_datetime.strftime('%Y/%m/%d %H:%M')}",
            "max_users": ticket.max_users,
            "miladi_time": ticket.time.strftime('%Y/%m/%d %H:%M'),
            "users": len(ticket.users),
        }
        tickets_data.append(ticket_data)
    return jsonify({"data":tickets_data}), 200

@ticket_bp.post("/add_user_to_ticket")
@jwt_required()
def add_user_to_ticket():
    data = request.get_json()
    ticket_time = data.get("time")
    date_part, time_part = ticket_time.split(" ")
    year, month, day = map(int, date_part.split("/"))
    hour, minute = map(int, time_part.split(":"))
    miladi_date = JalaliDatetime(year, month, day, hour, minute).todatetime()
    user_id = current_user.username
    ticket = Ticket.query.filter_by(time=miladi_date).first()
    tickets = Ticket.query.filter_by(season=UserInterface.query.first().data.get("train_season", 1)).all()
    if not ticket:
        return jsonify({"error": "تیکتی وجود ندارد"}), 404
    for t in tickets:
        if user_id in t.users:
            return jsonify({"error": "این کاربر قبلا به این بلیط اضافه شده است"}), 400
    if len(ticket.users) >= ticket.max_users:
        return jsonify({"error": "ظرفیت بلیط پر است"}), 400
    users = [user for user in ticket.users]
    users.append(user_id)
    ticket.users = users
    db.session.commit()
    return jsonify({"message": "کاربر با موفقیت به بلیط اضافه شد"}), 200

@ticket_bp.post("change_ticket")
@jwt_required()
def change_ticket():
    if current_user.username in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        ticket_time = data.get("time")
        date_part, time_part = ticket_time.split(" ")
        year, month, day = map(int, date_part.split("/"))
        hour, minute = map(int, time_part.split(":"))
        miladi_date = JalaliDatetime(year, month, day, hour, minute).todatetime()
        ticket = Ticket.query.filter_by(time=miladi_date).first()
        new_time = data.get("new_time", "")
        if not ticket:
            return jsonify({"error": "تیکتی وجود ندارد"}), 404
        if new_time != "":
            try:
                date_part, time_part = new_time.split(" ")
                year, month, day = map(int, date_part.split("/"))
                hour, minute = map(int, time_part.split(":"))
                new_miladi_date = JalaliDatetime(year, month, day, hour, minute).todatetime()
            except Exception as e:
                return jsonify({"error": f"فرمت تاریخ اشتباه است: {e}"}), 400
            ticket.time = new_miladi_date
        if data.get("max_users", 0) != 0:
            ticket.max_users = data.get("max_users", 0)
        db.session.commit()
        return jsonify({"message": "تیکت با موفقیت تغییر کرد"}), 200
    else:
        return jsonify({"error": "شما مجاز به تغییر بلیط نیستید"}), 403

@ticket_bp.get("/get_user_ticket")
@jwt_required()
def get_user_ticket():
    if current_user.data.get("accept_account", False) != True:
        return jsonify({"error": "حساب شما تایید نشده! لطفاً به پشتیبانی مراجعه فرمایید."}), 403
    user_id = current_user.username
    tickets = Ticket.query.filter_by(season=UserInterface.query.first().data.get("train_season", 1)).all()
    user_ticket = {}
    for ticket in tickets:
        if user_id in ticket.users:
            jalali_datetime = JalaliDatetime(ticket.time)
            user_ticket = {
                "time": jalali_datetime.strftime('%Y/%m/%d %H:%M'),
                "unixtime": ticket.time.timestamp(),
                "miladi_time": ticket.time.strftime('%Y/%m/%d %H:%M'),
                "current_time": time.time().timestamp()
            }
    if not user_ticket:
        return jsonify({"error": "کاربر بلیطی ندارد"}), 404
    return jsonify({"ticket":user_ticket}), 200