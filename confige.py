from flask import Flask
from flask_jwt_extended import JWTManager
from flask_sqlalchemy import SQLAlchemy
import socket
import os
import datetime
from khayam import TehranTimezone
jwt = JWTManager()
app = Flask(__name__)

app.config['SECRET_KEY'] = 'your_secret_key'  # Replace with a strong secret key

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False  # Disable tracking modifications for better performance
app.config["UPLOAD_FOLDER"] = "static/files"
app.secret_key = 'abscd'

if socket.gethostname() == "mhh83":
    from sshtunnel import SSHTunnelForwarder
    server = SSHTunnelForwarder(("45.138.135.82", 22), ssh_password="haghshenas67", ssh_username="pachim", remote_bind_address=("127.0.0.1", 3306))
    server.start()
    local_host = server.local_bind_port
    app.config["SQLALCHEMY_DATABASE_URI"] = 'mysql://pachim:haghshenas67@127.0.0.1:{}/data'.format(local_host)
else:
    app.config["SQLALCHEMY_DATABASE_URI"] = 'mysql://pachim:haghshenas67@localhost:3306/data'
db = SQLAlchemy(app)




def get_sort_by_birthday(birthday:datetime):
    age_years = (datetime.datetime.now(TehranTimezone) - birthday).days // 365
    if age_years <= 6:
        return 0
    elif 6 < age_years <= 9:
        return 1
    elif 9 < age_years <= 12:
        return 2
    elif 12 < age_years <= 15:
        return 3
    elif 15 < age_years <= 18:
        return 4
    else:
        return 5