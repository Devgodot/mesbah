from werkzeug.security import generate_password_hash, check_password_hash
from flask import jsonify
from confige import db
from sqlalchemy import String, Column, Integer, Text, JSON, URL, DateTime, ForeignKey
from flask_wtf import FlaskForm
from wtforms import FileField, SubmitField, PasswordField
from wtforms.validators import InputRequired, EqualTo, Length
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import relationship
from khayyam import TehranTimezone
from datetime import datetime, timedelta

class Messages(db.Model):
    __tablename__ = "Messages"  # اصلاح نام جدول
    id = db.Column(db.Integer, primary_key=True)
    conversationId = db.Column(db.String(12), nullable=False)
    receiverId = db.Column(db.JSON, nullable=False)
    messages = db.Column(db.JSON, nullable=False)
    createdAt = db.Column(db.DateTime, default=datetime.now(TehranTimezone()))
    updatedAt = db.Column(db.DateTime, default=datetime.now(TehranTimezone()))

    def to_dict(self):
        return {
            "id": self.id,
            "conversationId": self.conversationId,
            "receiverId": self.receiverId,
            "messages": self.messages,
            "createdAt": self.createdAt.isoformat()
        }

class VerificationCode(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(11), nullable=False)
    code = db.Column(db.String(4), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow())

    def is_valid(self):
        return datetime.utcnow() - self.created_at < timedelta(minutes=5)

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(String(10), primary_key=True)
    username = db.Column(String(10), nullable=False, unique=True)
    phone = Column(String(11), nullable=False, default="09")
    password = db.Column(db.Text(), nullable=False)
    tag = Column(Integer(), nullable=False, default=0)
    gender = Column(Integer(), nullable=False, default=0)
    data = db.Column(MutableDict.as_mutable(JSON))

    def __repr__(self):
        return f"<User {self.username}>"

    def set_password(self, password):
        self.password = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password, password)

    @classmethod
    def get_user_by_username(cls, username):
        return cls.query.filter_by(username=username).first()

    @classmethod
    def get_user_by_phone(cls, phone):
        return cls.query.filter_by(phone=phone).first()

    def save(self):
        db.session.add(self)
        db.session.commit()

    def delete(self):
        db.session.delete(self)
        db.session.commit()

    def update(self, data, overwrite=False):
        if overwrite:
            self.data = data
        else:
            self.data.update(data)
        return self.data

class Group(db.Model):
    id = Column(Integer, primary_key=True)
    name = Column(db.String(20), nullable=False, index=True) # Added index=True
    score = Column(db.JSON(), nullable=False, default=0)
    diamonds = Column(db.JSON(), nullable=False, default=0)
    tag = Column(db.Integer(), nullable=False, default=0)
    gender = Column(db.Integer(), nullable=False, default=0)
    icon = Column(String(400), nullable=False)
    users = Column(JSON, nullable=False)  # Assuming users are stored as a list of strings (usernames or IDs)
    def __repr__(self):
        return f"<Group {self.name}>"
    def save(self):
        db.session.add(self)
        db.session.commit()

    def delete(self):
        db.session.delete(self)
        db.session.commit()
    def add_user(self, user):
        # Check if the user is in any other group
        other_groups = Group.query.filter(Group.id != self.id).all()
        for group in other_groups:
            if user in group.users.get("users"):
                return jsonify({"error": "کاربر به گروه دیگری پیوسته است."})
        if len(self.users.get("users", [])) > 4:
            jsonify({"error": "تعداد اعضای گروه بیش از حد مجاز است."})
        users = [user for user in self.users.get("users")]
        # Add the user to the current group if not found in any other group
        if user not in users:
            users.append(user)
        return users
   
    
    @classmethod
    def get_group_by_name(cls, name):
        return cls.query.filter_by(name=name).first()
    def update_score(self, score):
        self.score = score
        for user in self.users.get("users"):
            u = User.get_user_by_phone(user)
            u.data = u.update(data={"group_score": score})
            db.session.commit()
class TokenBlocklist(db.Model):
    id = db.Column(Integer, primary_key=True)
    jti = db.Column(db.String(10), nullable=True)
    create_at = db.Column(db.DateTime(), default=datetime.now(TehranTimezone()))

    def __repr__(self):
        return f"<Token {self.jti}>"
    
    def save(self):
        db.session.add(self)
        db.session.commit()
class UserInterface(db.Model):
    __tablename__ = "game_data"
    id = db.Column(Integer, primary_key=True)
    data = db.Column(db.JSON())
class UserSeenMessages(db.Model):
    __tablename__ = 'user_seen_messages'
    conversationId = db.Column(db.String(12), nullable=False)
    id = Column(Integer, primary_key=True)
    user_id = db.Column(db.String(10))
    message_id = db.Column(db.String(255))
    timestamp = db.Column(db.DateTime, default=datetime.now(TehranTimezone()))

    def __repr__(self):
        return f"<UserSeenMessages(user_id='{self.user_id}', message_id='{self.message_id}')>"

class UserEditLog(db.Model):
    __tablename__ = 'user_edit_log'
    id = Column(Integer, primary_key=True)
    editor_id = Column(String(10), ForeignKey('users.id'))  # ID of the editor
    target_user_id = Column(String(10), ForeignKey('users.id'))  # ID of the user being edited
    timestamp = Column(DateTime, default=datetime.now(TehranTimezone()))
    field_name = Column(String(50))  # Name of the field that was changed
    old_value = Column(Text)  # Previous value
    new_value = Column(Text)  # New value

    editor = relationship("User", foreign_keys=[editor_id])
    target_user = relationship("User", foreign_keys=[target_user_id])

    def __repr__(self):
        return f"<UserEditLog(editor_id='{self.editor_id}', target_user_id='{self.target_user_id}', field_name='{self.field_name}')>"

class GroupEditLog(db.Model):
    __tablename__ = 'group_edit_log'
    id = Column(Integer, primary_key=True)
    editor_id = Column(String(10), ForeignKey('users.id'))  # ID of the editor
    group_name = Column(String(20), ForeignKey('group.name'))  # ID of the group being edited
    timestamp = Column(DateTime, default=datetime.now(TehranTimezone()))
    field_name = Column(String(50))  # Name of the field that was changed
    old_value = Column(Text)  # Previous value
    new_value = Column(Text)  # New value

    editor = relationship("User", foreign_keys=[editor_id])
    group = relationship("Group", foreign_keys=[group_name])

    def __repr__(self):
        return f"<GroupEditLog(editor_id='{self.editor_id}', group_name='{self.group_name}', field_name='{self.field_name}')>"

class ServerMessage(db.Model):
    __tablename__ = 'server_messages'
    id = Column(String(100), primary_key=True)
    message = Column(Text, nullable=False)
    audio = Column(String(255), nullable=True)
    image = Column(String(255), nullable=True)
    receiver = Column(JSON, nullable=False)
    timestamp = Column(DateTime, default=datetime.now(TehranTimezone()))
    def __repr__(self):
        return f"<ServerMessage(message='{self.message}')>"