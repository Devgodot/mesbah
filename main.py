from flask import request, jsonify, render_template, redirect, make_response, send_file, current_app
from confige import app, db, jwt
from auth import auth_bp
from users import user_bp
from groups import group_bp
from control import control_bp
from models import User, UserInterface, FlaskForm
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
import uuid

from deepface import DeepFace

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

@app.route('/resource_index', methods=['GET'])
def get_resource_index():
    """
    Returns the current resource index (uuid: filename) as JSON.
    Automatically rebuilds if files changed.
    """
    index = build_resource_index()
    return jsonify(index)

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
app.register_blueprint(user_bp, url_prefix="/users")
app.register_blueprint(group_bp, url_prefix="/groups")
app.register_blueprint(control_bp, url_prefix="/control")
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

@app.route('/recognize', methods=['POST'])
@jwt_required()
def recognize():
    # بارگذاری تصاویر چهره‌های ذخیره‌شده و استخراج ویژگی‌ها
    known_names = []
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), current_app.config["UPLOAD_FOLDER"], "faces")
    for file in os.listdir(path):
        if file.endswith('.webp'):
            known_names.append(file)
    file_data = request.get_json().get("data", "")
    if not isinstance(json.loads(file_data), list):
        return jsonify({"error": "Invalid data format"}), 400
    try:
        byte_data = bytes(json.loads(file_data))
    except ValueError as e:
        current_app.logger.error(f"Error converting list to bytes: {e}")
        return jsonify({"error": "Error converting list to bytes"}), 400
    try:
        image = Image.open(io.BytesIO(byte_data))
        img_path = os.path.join(path, f"{current_user.username}_temp_input_image.webp")
        image.save(img_path, format='webp')
    except Exception as e:
        current_app.logger.error(f"Error loading image: {e}, data length: {len(byte_data)}")
        return jsonify({"error": "Error loading image"}), 400

    # بررسی ابعاد تصویر
    if image.mode not in ["RGB", "L"]:
        current_app.logger.error(f"Unsupported image mode: {image.mode}")
        os.remove(img_path)
        return jsonify({"error": "Unsupported image mode"}), 400

    # مقایسه با deepface و مدل arcface
    for idx, known_file in enumerate(known_names):
        try:
            result = DeepFace.verify(img1_path=img_path, img2_path=os.path.join(path, known_file), model_name='ArcFace', enforce_detection=True)
            if result['verified']:
                os.remove(img_path)
                return jsonify({'result': 'matched', 'name': known_file})
        except Exception as e:
            current_app.logger.error(f"DeepFace error: {e}")
            continue
    os.remove(img_path)
    return jsonify({'result': 'not_matched'})

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


if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(debug=True)




