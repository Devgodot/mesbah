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
    data = request.get_json()
    _time = data.get("time", "1404/03/24")
    try:
        miladi_date = JalaliDate(*map(int, _time.split("/"))).todate()
    except Exception as e:
        return jsonify({"error": f"فرمت تاریخ اشتباه است: {e}"}), 400
    ticket = Ticket(time=miladi_date, 
                    users=data.get("users", []),
                    max_users=data.get("max_users", 0),
                    season=data.get("season", 0))
    db.session.add(ticket)
    db.session.commit()
    return jsonify({"message": "تیکت با موفقیت اضافه شد"}), 201
@ticket_bp.get("/get_ticket")
@jwt_required()
def get_ticket():
    ticket = Ticket.query.order_by(desc(Ticket.time)).first()
    if not ticket:
        return jsonify({"error": "تیکتی وجود ندارد"}), 404
    ticket_data = {
        "time": ticket.time.strftime("%Y/%m/%d"),
        "users": ticket.users,
        "max_users": ticket.max_users,
        "season": ticket.season
    }
    return jsonify(ticket_data), 200