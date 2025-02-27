from flask import request, jsonify, render_template, redirect, make_response, send_file, current_app
from confige import app, db, jwt
from auth import auth_bp
from users import user_bp
from books import book_bp
from groups import group_bp
from purchase import purchase_bp
from models import User, UploadForm, Levels, UserInterface, ResetPassWord, FlaskForm
from werkzeug.utils import secure_filename
import os
from math import ceil
from flask_jwt_extended import jwt_required, current_user
import random
import requests
from urllib.parse import quote
import json
import base64
import binascii
import numpy as np
from PIL import Image
import io

def post_request(url, payload={}, custom_header={}):
    headers = {
    'content-type': 'application/json'
    }
    for h in custom_header.keys():
        headers[h] = custom_header[h]

    requests.packages.urllib3.disable_warnings()
    session = requests.Session()
    session.verify = False
    session.encoding = "utf8"
    response = session.post(url, headers=headers)
    return (response.text)
def _filter(fil, files):
    if fil and fil != "":
        f = []
        for file in files:
            
            if len(file.split(".")) > 1 and fil in file.split(".")[0]:
                f.append(file)
        return f
    else:
        f = []
        for file in files:
            if len(file.split(".")) > 1:
                f.append(file)
        return f
   


jwt.init_app(app)
# register bluepints
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(book_bp, url_prefix="/books")
app.register_blueprint(user_bp, url_prefix="/users")
app.register_blueprint(group_bp, url_prefix="/groups")
app.register_blueprint(purchase_bp, url_prefix="/purchase")
 # load user
@jwt.user_lookup_loader
def user_lookup_callback(_jwt_headers, jwt_data):
    identity = jwt_data["sub"]
    return User.query.filter_by(username=identity).one_or_none()

@app.route('/download', methods=['GET'])
def download_file():
    if "GodotEngine" in request.headers.get("User-Agent"):
        filename = request.args.get('filename')
        directory = os.path.join(os.path.abspath(os.path.dirname(__file__)), app.config["UPLOAD_FOLDER"], "files")
       
        # Construct the full file path
        file_path = os.path.join(directory, f"{filename}")
        print(file_path)
        # Check if the file exists
        if os.path.exists(file_path):
            return send_file(file_path, as_attachment=True)
        else:
            return jsonify({"message": "File not found"}), 404
    return "شما اجازه دسترسی ندارید", 400

@app.route('/ListFiles', methods=['GET'])
def get_files():
    if "GodotEngine" in request.headers.get("User-Agent"):
        path = request.args.get("path")
        per_page = request.args.get("per_page", None)
        page = request.args.get("page", default=1, type=int)
        filter = request.args.get("filter")
        if path:
            if os.path.exists(os.path.join(os.path.abspath(os.path.dirname(__file__)), app.config["UPLOAD_FOLDER"], path)) :
                files = os.listdir(os.path.join(os.path.abspath(os.path.dirname(__file__)), app.config["UPLOAD_FOLDER"], path))
                f = _filter(filter, files)
                if per_page == None:
                    per_page = len(f)
                    if per_page == 0:
                        return jsonify({"files": []})
                f2 = []
                f3 = []
                for x, file in enumerate(f):
                    if x >= (page - 1) * per_page and x < page * per_page:
                        f2.append(f"{request.host}/static/files/{path}/{quote(file)}")
                        f3.append(file)
                return jsonify({"files": f2, "number_of_page":ceil(len(f) / per_page), "files_name":f3})
            
            else:
               
                os.makedirs(os.path.join(os.path.abspath(os.path.dirname(__file__)), app.config["UPLOAD_FOLDER"], path))
                return jsonify({"files": []})
        else:
            files = os.listdir(os.path.join(os.path.abspath(os.path.dirname(__file__)), app.config["UPLOAD_FOLDER"]))
            f2 = []
            f = _filter(filter, files)
            f3 = []
            if per_page == None:
                per_page = len(f)
                if per_page == 0:
                        return {"message":"فایلی در مسیر وارد شده وجود ندارد"}, 400
            for x, file in enumerate(f):
                if x >= (page - 1) * per_page and x < page * per_page:
                    f2.append(f"{request.host}/static/files/{quote(file)}")
                    f3.append(file)
            return jsonify({"files": f2, "number_of_page":ceil(len(f) / per_page),"files_name":f3})
    return "شما اجازه دسترسی ندارید", 400
@app.route('/levels/random', methods=['GET'])
@jwt_required()
def get_random_level():
    if "GodotEngine" in request.headers.get("User-Agent"):
        if current_user.data.get("number_play") == None:
            data = {"number_play":[0, 0, 0, 0, 0, 0]}
            current_user.data = current_user.update(data=data, overwrite=False)
            db.session.commit()
        if current_user.data.get("played_level") == None:
            data = {"played_level": []}
            
            current_user.data = current_user.update(data=data, overwrite=False)
            filter_data = []
            db.session.commit()
        else:
            filter_data = []
            for f in current_user.data['played_level']:
                filter_data.append(f)
            
        type = request.args.get("type", "لیگ")
        part = request.args.get("part", 0)
        
        max_play = UserInterface.query.first().data["laps_allowed"][int(part.split("type_")[1])]
        number_play = []
        for x in current_user.data["number_play"]:
            number_play.append(x)
        if len(number_play) > int(part.split("type_")[1]) and number_play[int(part.split("type_")[1])] < max_play:
            levels = Levels.query.filter_by(type=type, part=part).all()
            l = []
            for lv in levels:
                if not lv.id in filter_data:
                    l.append(lv)
            max_level = len(l)
            level_content = None
            if max_level != 0:
                level = random.randint(0, max_level-1)
                level_content = l[level]
            if level_content:
                number_play[int(part.split("type_")[1])] += 1
                filter_data.append(level_content.id)
                not_play_levels = []
                for x in current_user.data.get('not_play_levels', []):
                    not_play_levels.append(x)
                if current_user.data.get("last_league_level") != None:
                    not_play_levels.append(current_user.data.get("last_league_level"))
                data = {"played_level":filter_data, "number_play":number_play, "last_league_level":level_content.id, "not_play_levels":not_play_levels}
                current_user.data = current_user.update(data=data, overwrite=True)
                db.session.commit()
                return jsonify({"data": level_content.data})
            return jsonify({"message" : "مرحله وجود ندارد"}), 400
        return jsonify({"message" : "تعداد دور بیش از حد مجاز"}), 400
    return "شما اجازه دسترسی ندارید", 400

@app.route('/levels/<_id>', methods=['GET'])
@jwt_required()
def get_level_by_id(_id:int):
    
    level_content = Levels.query.filter_by(id=_id).first()
    part = request.args.get("part",0)
    not_play_level = False
    season = UserInterface.query.first().data.get("season", 1)
    data = current_user.data.get(f"league_levels_{part}_{season}", [[], 0])
    for level in data[0]:
        if int(level["id"]) == int(_id):
            if level["state"] != 0:
                not_play_level = False
            else:
                level["state"] = -1
                not_play_level = True
    current_user.update(data={f"league_levels_{part}_{season}":data}, overwrite=False)
    db.session.commit()
    if level_content and not_play_level:
        return jsonify({"data": level_content.data})
    return jsonify({"message" : "مرحله وجود ندارد"}), 400
@app.route('/levels/get', methods=['GET'])
def get_level():
    if "GodotEngine" in request.headers.get("User-Agent"):
        type = request.args.get("type", "کاوش در منطقه")
        part = request.args.get("part", "شاهین شهر و میمه")
        level = request.args.get("level", 1, int)
        level_content = Levels.query.filter_by(type=type, part=part, level=level).first()
        if level_content:
            return jsonify({"data": level_content.data})
        return jsonify({"message" : "مرحله وجود ندارد"}), 400
    return "شما اجازه دسترسی ندارید", 400
@app.route('/levels/max', methods=['GET'])
def get_max_level():
    if "GodotEngine" in request.headers.get("User-Agent"):
        type = request.args.get("type", "کاوش در منطقه")
        part = request.args.get("part", "شاهین شهر و میمه")
        level_content = Levels.query.filter_by(type=type, part=part).all()
        if level_content:
            return jsonify({"max_level": len(level_content)})
        return jsonify({"message" : "نوع مراحل یا قسمت وارد شده، وجود ندارد"}), 400
    return "شما اجازه دسترسی ندارید", 400
    
@app.route('/levels/create', methods=['POST'])
def create_level():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = request.get_json()
        type = request.args.get("type", "کاوش در منطقه")
        part = request.args.get("part", "شاهین شهر و میمه")
        level = request.args.get("level", 1, int)
        if Levels().get_data(type=type, part=part, level=level):
            return redirect(f"/levels/update?type={type}&part={part}&level={level}")
        new_level = Levels(type=type, part=part, level=level, data=data)
        db.session.add(new_level)
        db.session.commit()
        return jsonify({"message" : "مرحله با موفقیت ساخته شد"}), 201
    return "شما اجازه دسترسی ندارید", 400
    
@app.route('/levels/update', methods=['POST', 'PATCH'])
def update_level():
    if "GodotEngine" in request.headers.get("User-Agent"):
        type = request.args.get("type", "کاوش در منطقه")
        part = request.args.get("part", "شاهین شهر و میمه")
        level = request.args.get("level", 1, int)
        update = Levels().get_data(type=type, part=part, level=level)
        if update:
            update.data = request.get_json()
            db.session.commit()
            return jsonify({"message" : "مرحله با موفقیت بروز شد"}), 200
        return jsonify({"message": "مرحله وجود ندارد"}), 400
    return "شما اجازه دسترسی ندارید", 400
    
@app.route('/upload', methods=['POST'])
@jwt_required()
def upload_file():
    name = request.get_json().get("name", "")
    file_data = request.get_json().get("data", "")
    group_name = current_user.data.get("group_name", "")
    
    # Ensure file_data is a list
    if not isinstance(json.loads(file_data), list):
        return jsonify({"error": "Invalid data format"}), 400
    
    # Convert the list to bytes
    try:
        byte_data = bytes(json.loads(file_data))
    except ValueError as e:
        current_app.logger.error(f"Error converting list to bytes: {e}")
        return jsonify({"error": "Error converting list to bytes"}), 400
    
    # Convert the bytes to an image
    try:
        image = Image.open(io.BytesIO(byte_data))
    except IOError as e:
        current_app.logger.error(f"Error converting data to image: {e}")
        return jsonify({"error": "Error converting data to image"}), 400
    
    # Define the path to save the image
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users", str(current_user.phone))
    if not os.path.exists(path):
        os.makedirs(path)
    if group_name != "" and name.startswith(group_name):
        for filename in os.listdir(path):
            if filename.startswith(group_name):
                os.remove(os.path.join(path, filename))
    if name.startswith(current_user.username):
        for filename in os.listdir(path):
            if filename.startswith(current_user.username):
                os.remove(os.path.join(path, filename))
    # Save the image
    file_path = os.path.join(path, (name))
    try:
        image.save(file_path, format='webp')
    except IOError as e:
        current_app.logger.error(f"Failed to write image data to file: {e}")
        return jsonify({"error": "Failed to save image"}), 500
    
    return jsonify({"message": f"{(name)} uploaded!"}), 200

@app.route('/gallery/upload', methods=['POST'])
def upload_gallery():
    name = request.get_json().get("name", "")
    file_data = request.get_json().get("data", "")
    # Ensure file_data is a list
    if not isinstance(json.loads(file_data), list):
        return jsonify({"error": "Invalid data format"}), 400
    # Convert the list to bytes
    try:
        byte_data = bytes(json.loads(file_data))
    except ValueError as e:
        current_app.logger.error(f"Error converting list to bytes: {e}")
        return jsonify({"error": "Error converting list to bytes"}), 400
    
    # Convert the bytes to an image
    try:
        image = Image.open(io.BytesIO(byte_data))
    except IOError as e:
        current_app.logger.error(f"Error converting data to image: {e}")
        return jsonify({"error": "Error converting data to image"}), 400
    
    # Define the path to save the image
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "app", request.get_json().get("path", ""))
    if not os.path.exists(path):
        os.makedirs(path)
    # Save the image
    file_path = os.path.join(path, name)
    try:
        image.save(file_path, format='webp')
    except IOError as e:
        current_app.logger.error(f"Failed to write image data to file: {e}")
        return jsonify({"error": "Failed to save image"}), 500
    return jsonify({"message": f"{(name)} uploaded!"}), 200
@app.route('/gallery/remove', methods=['GET'])
def remove_gallery():
    name = request.args.get("name", "")
    p = request.args.get("path", "")
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "app", p)
    file_path = os.path.join(path, name)
    if os.path.exists(file_path):
        os.remove(file_path)
    return jsonify({"message": f"{(name)} removed!"}), 200

@app.route("/")
def home():
    response = make_response(render_template("home.html"), 200)
    return response
@app.route("/game/data", methods=["GET"])
@jwt_required()
def get_interface():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = UserInterface.query.first().data
        return jsonify({"data":data})
    return "شما اجازه دسترسی ندارید", 400
    


@app.route("/gamedata/create", methods=["POST"])
def create_interface():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = request.get_json()
        game_data = UserInterface(data=data)
        db.session.add(game_data)
        db.session.commit()
        return jsonify({"data":data})
    return "شما اجازه دسترسی ندارید", 400
    

@app.route("/gamedata/update", methods=["PUT"])
def update_interface():
    if "GodotEngine" in request.headers.get("User-Agent"):
        data = request.get_json()
        game_data = UserInterface.query.first()
        for key in game_data.data.keys():
            if not data.get(key):
                data[key] = game_data.data.get(key)
        game_data.data = data
        db.session.commit()
        return jsonify({"data":data})
    return "شما اجازه دسترسی ندارید", 400
    

@app.route("/gamedata/delete", methods=["DELETE"])
def delete_interface():
    if "GodotEngine" in request.headers.get("User-Agent"):
        id = request.args.get("id")
        game_data = UserInterface.query.all()
        for data in game_data:
            if data.id == id:
                db.session.delete(data)
        db.session.commit()
        return jsonify({"message": "با موفقیت حذف شد"})
    return "شما اجازه دسترسی ندارید", 400
    


if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(debug=True)




