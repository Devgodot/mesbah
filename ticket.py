from flask import request, Blueprint, jsonify, make_response, render_template
from flask_jwt_extended import jwt_required, get_jwt, current_user
from models import User, UserInterface, Ticket, UseTicket
from schemas import UserSchema
from sqlalchemy import desc, text
from confige import db, app, get_sort_by_birthday
import time, uuid, os
import datetime, json
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone
import jdatetime

ticket_bp = Blueprint("ticket", __name__)

PERSIAN_WEEKDAYS = {
    'Saturday': 'شنبه',
    'Sunday': 'یکشنبه',
    'Monday': 'دوشنبه',
    'Tuesday': 'سه‌شنبه',
    'Wednesday': 'چهارشنبه',
    'Thursday': 'پنجشنبه',
    'Friday': 'جمعه'
}


@ticket_bp.post("/add_ticket")
@jwt_required()
def add_ticket():
    if current_user.get_username() in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        _time = data.get("time", "1404/03/24 15:00")
        season = UserInterface.query.first().data.get("train_season", 1)
        try:
            date_part, time_part = _time.split(" ")
            year, month, day = map(int, date_part.split("/"))
            hour, minute = map(int, time_part.split(":"))
            miladi_date = jalali_to_gregorian(year, month, day, hour, minute)
        except Exception as e:
            return jsonify({"error": f"فرمت تاریخ اشتباه است: {e}"}), 400
        if Ticket.query.filter_by(season=season, time=miladi_date).first():
            return jsonify({"error": "تیکت با این زمان وجود دارد"}), 400
        if request.get_json().get("tag", []) == []:
            return jsonify({"error": "تگ بلیط نمی‌تواند خالی باشد"}), 400
        ticket = Ticket(time=miladi_date, 
                        users=data.get("users", []),
                        max_users=data.get("max_users", 0),
                        season=season,
                        tag=data.get("tag", []),
                        gender =data.get("gender", 0),
                        nationality=data.get("nationality", 0)
                        )
        db.session.add(ticket)
        db.session.commit()
        return jsonify({"message": "تیکت با موفقیت اضافه شد"}), 201
    else:
        return jsonify({"error": "شما مجاز به اضافه کردن بلیط نیستید"}), 403

@ticket_bp.get("/get_ticket")
@jwt_required()
def get_ticket():
    if current_user.data.get("accept_account", False) != True:
        return jsonify({"error": "حساب شما تایید نشده! لطفاً به مسجد جامع مراجعه فرمایید."}), 403
    season = UserInterface.query.first().data.get("train_season", 1)
    tickets = Ticket.query.filter_by(season=season).all()
    if not tickets:
        return jsonify({"error": "تیکتی وجود ندارد"}), 404
    if current_user.get_username() in UserInterface.query.first().data.get("management", []) and request.args.get("all", "false").lower() == "true":
        tickets_data = []
        for ticket in tickets:
            # رفع اختلاف یک روز: به جای JalaliDatetime(ticket.time) از JalaliDatetime(ticket.time.year, ticket.time.month, ticket.time.day, ticket.time.hour, ticket.time.minute) استفاده کنید
            jalali_datetime = gregorian_to_jalali(ticket.time)
            ticket_data = {
                "time": f"{jalali_datetime.strftime('%Y/%m/%d %H:%M')}",
                "max_users": ticket.max_users,
                "miladi_time": ticket.time.strftime('%Y/%m/%d %H:%M'),
                "users": len(ticket.users),
                "tag": ticket.tag,
                "nationality": ticket.nationality,
                "day": PERSIAN_WEEKDAYS.get(jalali_datetime.strftime('%A'), jalali_datetime.strftime('%A')),
                "gender": ticket.gender
            }
            tickets_data.append(ticket_data)
    else:
        tickets_data = []
        for ticket in tickets:
            jalali_datetime = gregorian_to_jalali(ticket.time)
            if get_sort_by_birthday(current_user.birthday) in ticket.tag and current_user.data.get("nationality", 0) == ticket.nationality and current_user.gender == ticket.gender:
                ticket_data = {
                    "time": f"{jalali_datetime.strftime('%Y/%m/%d %H:%M')}",
                    "max_users": ticket.max_users,
                    "miladi_time": ticket.time.strftime('%Y/%m/%d %H:%M'),
                    "users": len(ticket.users),
                    "day": PERSIAN_WEEKDAYS.get(jalali_datetime.strftime('%A'), jalali_datetime.strftime('%A')),
                    "gender": ticket.gender,
                    "tag": ticket.tag,
                    "nationality": ticket.nationality
                }
                tickets_data.append(ticket_data)
    return jsonify({"data":tickets_data}), 200

@ticket_bp.post("/remove_user")
@jwt_required()
def remove_user():
    if current_user.get_username() in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        ticket_time = data.get("time")
        user_id = data.get("username")
        date_part, time_part = ticket_time.split(" ")
        year, month, day = map(int, date_part.split("/"))
        hour, minute = map(int, time_part.split(":"))
        miladi_date = jalali_to_gregorian(year, month, day, hour, minute)
        ticket = Ticket.query.filter_by(time=miladi_date).first()
        if not ticket:
            return jsonify({"error": "تیکتی با این زمان وجود ندارد"}), 404
        if user_id not in ticket.users:
            return jsonify({"error": "کاربر در این بلیط وجود ندارد"}), 400
        users = [user for user in ticket.users if user != user_id]
        ticket.users = users
        db.session.commit()
        return jsonify({"message": "کاربر با موفقیت از بلیط حذف شد"}), 200
    else:
        return jsonify({"error": "شما مجاز به حذف کاربر از بلیط نیستید"}), 403
@ticket_bp.post('/delete_ticket')
@jwt_required()
def delete_ticket():
    if current_user.get_username() in UserInterface.query.first().data.get("management", []) :
        _time = request.get_json().get("time", "2024/03/24 15:00")
        try:
            date_part, time_part = _time.split(" ")
            year, month, day = map(int, date_part.split("/"))
            hour, minute = map(int, time_part.split(":"))
            miladi_date = datetime.datetime(year, month, day, hour, minute)
        except Exception as e:
            return jsonify({"error": f"فرمت تاریخ اشتباه است: {e}"}), 400
        ticket = Ticket.query.filter_by(time=miladi_date).first()
        if not ticket:
            return jsonify({"error": "تیکتی با این زمان وجود ندارد"}), 404
        db.session.delete(ticket)
        db.session.commit()
        return jsonify({"message": "تیکت با موفقیت حذف شد"}), 200
    else:
        return jsonify({"error": "شما مجاز به حذف بلیط نیستید"}), 403
@ticket_bp.post("/add_user_to_ticket")
@jwt_required()
def add_user_to_ticket():
    data = request.get_json()
    ticket_time = data.get("time")
    date_part, time_part = ticket_time.split(" ")
    year, month, day = map(int, date_part.split("/"))
    hour, minute = map(int, time_part.split(":"))
    miladi_date = jalali_to_gregorian(year, month, day, hour, minute)
    user_id = current_user.get_username()
    ticket = Ticket.query.filter_by(time=miladi_date).first()
    tickets = Ticket.query.filter_by(season=UserInterface.query.first().data.get("train_season", 1)).all()
    if not ticket:
        return jsonify({"error": "تیکتی وجود ندارد"}), 404
    if current_user.data.get("accept_account", False) != True:
        return jsonify({"error": "حساب شما تایید نشده! لطفاً به پشتیبانی مراجعه فرمایید."}), 403
    if get_sort_by_birthday(current_user.birthday) not in ticket.tag and current_user.data.get("nationality", 0) != ticket.nationality and current_user.gender != ticket.gender:
        return jsonify({"error": "شما مجاز به اضافه شدن به این بلیط نیستید"}), 403
    for t in tickets:
        if user_id in t.users:
            return jsonify({"error": "این کاربر قبلا به این بلیط اضافه شده است"}), 400
    if len(ticket.users) >= ticket.max_users:
        return jsonify({"error": "ظرفیت بلیط پر است"}), 400
    users = [user for user in ticket.users]
    users.append(user_id)
    ticket.users = users
    db.session.commit()
    print(int(datetime.datetime.now(TehranTimezone()).timestamp()) * 1000)
    return jsonify({"message": "کاربر با موفقیت به بلیط اضافه شد", "current_time":int(datetime.datetime.now().timestamp()) * 1000, "unixtime":int(ticket.time.timestamp()) * 1000, "miladi_time":ticket.time, "time":ticket_time}), 200
@ticket_bp.post("change_ticket")
@jwt_required()
def change_ticket():
    if current_user.get_username() in UserInterface.query.first().data.get("management", []):
        data = request.get_json()
        ticket_time = data.get("time")
        date_part, time_part = ticket_time.split(" ")
        year, month, day = map(int, date_part.split("/"))
        hour, minute = map(int, time_part.split(":"))
        miladi_date = jalali_to_gregorian(year, month, day, hour, minute)
        ticket = Ticket.query.filter_by(time=miladi_date).first()
        new_time = data.get("new_time", "")
        if not ticket:
            return jsonify({"error": "تیکتی وجود ندارد"}), 404
        if new_time != "":
            try:
                date_part, time_part = new_time.split(" ")
                year, month, day = map(int, date_part.split("/"))
                hour, minute = map(int, time_part.split(":"))
                new_miladi_date = jalali_to_gregorian(year, month, day, hour, minute)
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
        return jsonify({"error": "حساب شما تایید نشده! لطفاً به مسجد جامع مراجعه فرمایید."}), 403
    user_id = current_user.get_username()
    tickets = Ticket.query.filter_by(season=UserInterface.query.first().data.get("train_season", 1)).all()
    user_ticket = {}
    for ticket in tickets:
        if user_id in ticket.users:
            jalali_datetime = gregorian_to_jalali(ticket.time)
            miladi_time = ticket.time
            user_ticket = {
                "time": jalali_datetime.strftime('%Y/%m/%d %H:%M'),
                "unixtime": int(ticket.time.timestamp()) * 1000,
                "miladi_time": miladi_time.strftime('%Y-%m-%d %H:%M'),
                "current_time": int(datetime.datetime.now().timestamp()) * 1000,
            }
    if not user_ticket:
        return jsonify({"error": "کاربر بلیطی ندارد"}), 404
    return jsonify({"ticket":user_ticket}), 200
@ticket_bp.get("/check")
def check():
    user = request.args.get("user", "")
    season = UserInterface.query.first().data.get("train_season", 1)
    user_ticket = None
    for ticket in Ticket.query.filter_by(season=season).all():
        if user in ticket.users:
            user_ticket = ticket
            break
    state = {}
    if user_ticket and UseTicket.query.filter_by(id=user).first() is None:
        now = datetime.datetime.now(TehranTimezone())
        # اطمینان از اینکه birthday هم timezone-aware باشد
        if ticket.time.tzinfo is None:
            ticket.time = ticket.time.replace(tzinfo=TehranTimezone())
        seconds = (now.timestamp() - ticket.time.timestamp())
        if seconds < 0:
            state["status"] = "هنوز زمان بلیط فرا نرسیده"
        if seconds > 0:
            if seconds > 60 * 30:
                state["status"] = "زمان بلیط منقضی شده"
            else:
                state["status"] = "بلیط استفاده شد"
                use_ticket = UseTicket(id=user, season=season)
                db.session.add(use_ticket)
                db.session.commit()
    else:
        if user_ticket is None:
            state["status"] = "کاربر بلیطی ندارد"
        else:
            state["status"] = "بلیط قبلاً استفاده شده"
    current_user = User.get_user_by_username(user)
    if current_user:
        state["name"] = current_user.data("first_name", "")+" "+current_user.data.get("last_name", "")
        state["username"] = user
        state["father"] = current_user.data.get("father_name", "")
        response = make_response(render_template("check_ticket.html", state=state), 200)
    else:
        return "کاربر وجود ندارد"
    return response

# راه دیگر برای تبدیل تاریخ جلالی به میلادی و بالعکس بدون khayyam:
# استفاده از کتابخانه jdatetime (اگر نصب باشد)

# تبدیل جلالی به میلادی
def jalali_to_gregorian(jy, jm, jd, hour=0, minute=0):
    gdate = jdatetime.datetime(jy, jm, jd, hour, minute).togregorian()
    return gdate

# تبدیل میلادی به جلالی
def gregorian_to_jalali(dt):
    jdate = jdatetime.datetime.fromgregorian(datetime=dt)
    return jdate

