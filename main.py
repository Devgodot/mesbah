import datetime
from flask import request, jsonify, render_template, redirect, make_response, send_file, current_app
from confige import app, db, jwt
from auth import auth_bp
from users import user_bp
from groups import group_bp
from control import control_bp
from ticket import ticket_bp
from planes import plan_bp
from score import score_bp
from messages import message_bp
from models import User, UserInterface, FlaskForm, Group, Score
from werkzeug.utils import secure_filename
import os, git
from math import ceil
from flask_jwt_extended import jwt_required, current_user
import requests
from urllib.parse import quote
import json
import numpy as np
from PIL import Image
import io
import utils
import uuid
from khayyam import JalaliDate, JalaliDatetime, TehranTimezone
def set_birthday():
    groups = Group.query.all()
    for group in groups:
        user = group.users.get("leader", "") 
        if user != "":
            user = User.get_user_by_username(user)
            if user is not None:
                birthday = user.birthday
                if birthday != "":
                    try:
                        group.leader_birthday = birthday
                        db.session.commit()
                    except Exception as e:
                        print(f"Error converting date for user {user.username}: {e}")
       


RESOURCE_INDEX_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static", "files", "resource", "resource_index.json")
RESOURCE_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static", "files", "resource")

def build_resource_index():
    """
    Build or update a dictionary mapping uuid to filenames in the resource folder.
    If resource_index.json exists, keep uuids for unchanged files.
    """
    index = {}
    # Load existing index if exists
    if os.path.exists(RESOURCE_INDEX_PATH):
        try:
            with open(RESOURCE_INDEX_PATH, 'r', encoding='utf-8') as f:
                index = json.load(f)
        except Exception:
            index = {}
    # Reverse mapping for quick lookup
    filename_to_uuid = {v: k for k, v in index.items()}
    new_index = {}
    for fname in os.listdir(RESOURCE_DIR):
        fpath = os.path.join(RESOURCE_DIR, fname)
        if os.path.isfile(fpath):
            if fname in filename_to_uuid:
                new_index[filename_to_uuid[fname]] = fname
            else:
                new_index[str(uuid.uuid4())] = fname
    # Save new index
    with open(RESOURCE_INDEX_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_index, f, ensure_ascii=False, indent=2)
    return new_index

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
   

def score_add_to_table():
    users = Group.query.all()
    for user in users:
        for x, key in enumerate(user.score):
            
            score = user.score.get(key, 0)
            part = ["سلامت معنوی", "سلامت جسمانی", "سلامت فکری"][int(x)]
            new_score = Score(plan="رمضان 1403-1404", subplan=part, gender=user.gender, tag=user.tag, year=1404, name=user.name, score=score, group=True)
            db.session.add(new_score)
            db.session.commit()
            print(f"Added score for {user.name} in {part}: {score}")
jwt.init_app(app)
# register bluepints
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(user_bp, url_prefix="/users")
app.register_blueprint(group_bp, url_prefix="/groups")
app.register_blueprint(control_bp, url_prefix="/control")
app.register_blueprint(ticket_bp, url_prefix="/ticket")
app.register_blueprint(plan_bp, url_prefix="/planes")
app.register_blueprint(score_bp, url_prefix="/score")
app.register_blueprint(message_bp, url_prefix="/messages")
 # load user
@jwt.user_lookup_loader
def user_lookup_callback(_jwt_headers, jwt_data):
    identity = jwt_data["sub"]
    return User.query.filter_by(username=identity).first()
@app.route("/publish_live")
def publish():
    return render_template("live.html")
@app.route("/view_live")
def view():
    return redirect("https://live.messbah403.ir/WebRTCApp/play.html?id=stream1")



@app.route('/git-pull', methods=['GET'])
def git_pull():
    try:
        repo_path = '/home/pachim/messbah403.ir'  # مسیر پروژه روی سرور
        repo = git.Repo(repo_path)
        # ذخیره وضعیت فعلی قبل از pull
        original_commit = repo.head.commit.hexsha
        
        # انجام pull
        origin = repo.remotes.origin
        origin.pull()
        
        # پیدا کردن فایل‌های تغییر کرده
        new_commit = repo.head.commit.hexsha
        changed_files = []
        
        # مقایسه commit قدیم و جدید
        diff_index = repo.git.diff(original_commit, new_commit, name_only=True)
        changed_files = diff_index.split('\n') if diff_index else []
        
        # فیلتر کردن فایل‌های خالی
        changed_files = [f for f in changed_files if f]
        
        return jsonify({
            'status': 'success',
            'changed_files': changed_files,
            'previous_commit': original_commit,
            'current_commit': new_commit
        }), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/check_resource', methods=['POST'])
def get_resource_index():
    time:float= float(request.get_json().get("time"))
    
    add = []
    delete = []
    pack = []
    file = request.get_json().get("file", "")
    if file != "":
        file = secure_filename(file)
        with open(file, "r") as hash_list:
            _list :dict= json.load(hash_list)
            for n, t in _list.items():
                if float(t) > time :
                    add.append(n)
        with open("pack.json", "r") as pack_list:
            _list :dict= json.load(pack_list)
            for n, t in _list.items():
                if float(t) > time :
                    pack.append(n)
        return jsonify({"add":add, "delete":delete, "pack":pack, "time":datetime.datetime.now(tz=TehranTimezone()).timestamp() * 1000}), 200
    else:
        return jsonify({"error":"فایلی برای بررسی وجود ندارد"}), 400
@app.route("/get_hash", methods=["GET"])
def get_hash():
    with open("hash_list2.json", "r") as hash_list:
        _list :dict= json.load(hash_list)
        for x in _list.keys():
            if x == request.args.get("name", ""):
                return jsonify({"result":_list[x]})
    return jsonify({"result":""})

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
    if request.get_json().get("type", "") == "face":
        path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "faces")
        if not os.path.exists(path):
            os.makedirs(path)
        name = current_user.username + ".webp"
    else:
        # Define the path to save the image
        path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "users", str(current_user.phone))
        if not os.path.exists(path):
            os.makedirs(path)
        if group_name != "" and name.startswith(group_name):
            for filename in os.listdir(path):
                if filename.startswith(group_name):
                    os.remove(os.path.join(path, filename))
        if name.startswith(current_user.get_username()):
            for filename in os.listdir(path):
                if filename.startswith(current_user.get_username()):
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
    # compute APK sizes for download menu
    base = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static", "files", "app")
    apk_files = {
        'arm64': 'messbah_arm64-v8a.apk',
        'arm32': 'messbah_armeabi-v7a.apk',
        'x86_64': 'messbah_x86 64.apk',
        'x86': 'messbah_x86.apk',
        'universal': 'messbah.apk'
        
    }
    def fmt_size(n):
        if n is None:
            return 'ناموجود'
        n = float(n)
        for unit in ['B','KB','MB','GB','TB']:
            if n < 1024.0 or unit == 'TB':
                if unit == 'B':
                    return f"{int(n)} {unit}"
                # n has already been scaled to the current unit
                return f"{n:.2f} {unit}"
            n /= 1024.0

    apk_sizes = {}
    for k, fname in apk_files.items():
        path = os.path.join(base, fname)
        try:
            if os.path.exists(path) and os.path.isfile(path):
                size = os.path.getsize(path)
            else:
                size = None
        except Exception:
            size = None
        apk_sizes[k] = fmt_size(size)

    response = make_response(render_template("home.html", apk_sizes=apk_sizes), 200)
    return response


if __name__ == "__main__":
    with app.app_context():
        db.create_all()
   
    app.run(debug=True)
    





