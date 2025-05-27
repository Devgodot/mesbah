extends Node2D
signal get_image_finished
signal download_progress
signal start_download
var save_path = "user://data.cfg"
var token = ""
var id = ""
var protocol = "https://"
var subdomin = "messbah403.ir"
var part = 0
var gallary_part = ""
var current_user = 0
var last_user = 0
var online_supporter = [0, 0, 0]
var texture = TextureRect.new()
var p_scene
var socket = WebSocketPeer.new()
var set_user = false
var plugin
var seen = 0
var microphone :AudioStreamPlayer2D
var speaker :AudioStreamPlayer2D
var messages = []
var list_users = []
@onready var change_scene = {"main":"start", "control":"main","menu1":"main", "setting":"main", "messages":"main", "menu2":"menu1", "editname":"setting", "gallary":p_scene, "positions":p_scene}
func get_header() -> Array:
	return [
		"Content-Type: application/json",
		"Authorization: Bearer %s"%token
	]
func change(_name):
	if _name == "positions" or _name == "gallary":
		change_scene[_name] = p_scene
	if change_scene[_name]:
		get_tree().change_scene_to_file("res://scenes/"+change_scene[_name]+".tscn")
func update_resource():
	var http = HTTPRequest.new()
	add_child(http)
	var hash_list:Dictionary = load_game("hash_list", {})
	http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":hash_list}))
	var d = await http.request_completed
	http.timeout = 10
	while d[3].size() == 0:
		http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":hash_list}))
		d = await http.request_completed
	http.queue_free()
	var data = get_json(d[3])
	if data:
		print(data)
		if not DirAccess.dir_exists_absolute("user://resource"):
			DirAccess.make_dir_absolute("user://resource")
		if data.add.size() > 0:
			get_tree().get_root().add_child(load_scene("download.tscn"))
		var index = 0
		start_download.emit(data.add.size())
		
		for file in data.add:
			var f = await request("/static/files/resource/"+file[0], HTTPClient.METHOD_GET, {}, 1)
			download_progress.emit(index)
			var new_file = FileAccess.open("user://resource/"+file[0], FileAccess.WRITE)
			new_file.store_buffer(f)
			new_file.close()
			hash_list[file[0]] = file[1]
			save("hash_list", hash_list, false)
			index += 1
		for file in data.delete:
			DirAccess.remove_absolute("user://resource/"+file[0])
			hash_list.erase(file[0])
			save("hash_list", hash_list, false)
	await get_tree().create_timer(0.5).timeout

func get_cost(_id):
	var u =protocol+subdomin+"/purchase/cost?id="+str(_id)
	var d = await request(u)
	if d.has("num"):
		return d.num
	else:
		return 0
func _ready() -> void:
	
	get_tree().get_root().window_input.connect(func(event):
		if event is InputEventScreenTouch:
			if get_global_mouse_position().x < 0 or get_global_mouse_position().y < 0:
				DisplayServer.virtual_keyboard_hide())
	
	if load_game("user_name") != "":
		socket.connect_to_url("ws://shirinasalgame.ir")
	current_user = load_game("current_user", 0)
	last_user = load_game("last_user", 0)
	texture.z_index = 5
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.size = Vector2(400, 400)
	texture.pivot_offset = Vector2(200, 200)
	texture.position = Vector2(300, 800)
	texture.scale = Vector2.ZERO
	add_child(texture)
func _process(delta: float) -> void:
	socket.poll()
	if socket.get_ready_state() == 3 and load_game("user_name") != "":
		socket.connect_to_url("ws://shirinasalgame.ir")
		set_user = false
	if socket.get_ready_state() == 1:
		if not set_user:
			set_user = true
			socket.send(JSON.stringify({ "type": 'register', "username":load_game("user_name", "") }).to_utf8_buffer())
		if !get_tree().has_group("scene_message"):
			while socket.get_available_packet_count():
				var d = get_json(socket.get_packet())
				if load_game("support", false):
					if d.has("type") and d.type == "delete":
						change_user(d.conversationId, {"last_message_time":d.last_time_messages})
					if d.has("message") and d.has("id"):
						save_user_messages(d.id, {"add":[d.message], "receiverId":d.receiverId, "delete":[]})
						if not change_user(d.id, {"last_message_time":d.message.timestamp}, 1):
							var r = HTTPRequest.new()
							add_child(r)
							r.request(protocol+subdomin+"/users/users_message", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"users":load_list_user()}))
							r.request_completed.connect(func(result, respons, header, body):
								var new_data = get_json(body)
								save_list_user(new_data)
								r.queue_free())
				if !load_game("support", false):
					if d.has("type") and d.type == "delete":
						for z in range(3):
							var delete = []
							for n in messages[z]:
								if n.id == d.message:
									delete.append(n)
							if delete.size() > 0:
								messages[z].erase(delete[0])
					elif d.has("message"):
						messages[int(d.id.right(1))].append(d.message)
				if d.has("type") and d.type == "onlineUsers":
					online_supporter = d.count
				if d.has("message") and not d.has("type") and load_game("show_notif", true):
					seen += 1
					if !load_game("support", false):
						Notification.add_notif("پیام شما پاسخ داده شد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
					else:
						if d.message.sender in d.receiverId:
							Notification.add_notif("یک مربی پیامی داده است", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
						else:
							
							Notification.add_notif("کاربری پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
						
func load_user():
	var d = null
	if FileAccess.file_exists("user://session.dat"):
		var file = FileAccess.open("user://session.dat", FileAccess.READ)
		d = file.get_var()
		if d is Dictionary:
			token = d.access
			
			id = d.id
			return true
		if d is Array and d.size() - 1 >= current_user:
			token = d[current_user].access
			id = d[current_user].id
			return true
			
	return false
func random_level(pa, _data={}):
	var q = "part=%s"%pa.uri_encode()
	var u =protocol+subdomin+"/levels/random?"+q
	var d = await request(u)
	if d and d.has("data"):
		_data = d.data
	return _data

func request(url, method=HTTPClient.METHOD_GET,_data={}, result_mode=0):
	var http = HTTPRequest.new()
	add_child(http)
	var header = [
		"Content-Type: application/json",
		"Authorization: Bearer %s"%token
	]
	if _data.keys().size() > 0:
		http.request(protocol+subdomin+url, header, method)
	else:
		http.request(protocol+subdomin+url, header, method, JSON.stringify(_data))
	var d = await http.request_completed
	http.timeout = 10
	while d[3].size() == 0:
		if _data.keys().size() > 0:
			http.request(protocol+subdomin+url, header, method)
		else:
			http.request(protocol+subdomin+url, header, method, JSON.stringify(_data))
		d = await http.request_completed
	http.queue_free()
	if result_mode == 0:
		return get_json(d[3])
	else:
		return d[3]

func get_json(_data):
	var j = JSON.new()
	if _data is PackedByteArray:
		if _data.size() == 0:
			return null
		return j.parse_string(_data.get_string_from_utf8())
	if _data is String:
		return j.parse_string(_data)

func save_server(data):
	for key in data:
		if data[key] is bool:
			data[key] = str("-", int(data[key]))
		if data[key] is Array:
			for x in range(data[key].size()):
				if data[key][x] is bool:
					data[key][x] = str("-", int(data[key][x]))
		if data[key] is Dictionary:
			for x in range(data[key].keys().size()):
				var key2 = data[key].keys()[x]
				if data[key][key2] is bool:
					data[key][key2] = str("-", int(data[key][key2]))
	var http = HTTPRequest.new()
	add_child(http)
	var header = [
		"Content-Type: application/json",
		"Authorization: Bearer %s"%token
	]
	http.request(protocol+subdomin+"/auth/update", header, HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await http.request_completed
	http.timeout = 3
	while d[3].size() == 0:
		http.request(protocol+subdomin+"/auth/update", header, HTTPClient.METHOD_POST, JSON.stringify(data))
		d = await http.request_completed
	http.queue_free()
	return get_json(d[3])
func save(_name, num, server=true):
	var confige = ConfigFile.new()
	confige.load(save_path)
	confige.set_value("user", _name, num)
	confige.save(save_path)
	if server and _name != "image":
		save_server({_name:num})
func multy_save(_data:Dictionary):
	var confige = ConfigFile.new()
	confige.load(save_path)
	for key in _data.keys():
		confige.set_value("user", key, _data[key])
	confige.save(save_path)
	save_server(_data)
func load_game(_name, defaulte=null):
	var confige = ConfigFile.new()
	confige.load(save_path)
	if confige.has_section_key("user", _name):
		return confige.get_value("user", _name, defaulte)
	else:
		save(_name, defaulte)
		return defaulte
func get_data(_name, default=0):
	var u ="/auth/get?name="+_name
	var count = await request(u)
	if count and count.has("num") and count.num:
		return count.num
	else:
		return default
func get_image(img:String, node=null):
	var http:HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request(img)
	var d = await http.request_completed
	http.queue_free()
	get_image_finished.emit(d[3], node, img)
	return d[3]
func load_from_server():
	var data = await request("/auth/whoami")
	if data is Dictionary and data.has("user_details"):
		save("user_name", data.user_details.username, false)
		for key in data.data.keys():
			var data2 = data.data
			if data2[key] is String and data2[key].begins_with("-") and data2[key].length() == 2:
				data2[key] = bool(int(data2[key]))
			if key != "user_name":
				if key == "num1":
					save("score", data2[key], false)
				elif key == "num2":
					save("league_score", data2[key], false)
				else:
					save(key, data2[key], false)
		messages = []
		if not load_game("support", false):
			for x in range(3):
				var m = await Updatedate.request("/users/support_message?part="+str(x))
				messages.append(m.messages if m.has("messages") else [])
		else:
			list_users = load_list_user([])
			var r = HTTPRequest.new()
			add_child(r)
			r.request(protocol+subdomin+"/users/users_message", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"users":load_list_user()}))
			r.request_completed.connect(func(result, respons, header, body):
				var new_data = get_json(body)
				save_list_user(new_data)
				r.queue_free())
	else:
		
		return false
	return data
func get_files():
	var images = await request("/ListFiles?path=icons")
	if !DirAccess.dir_exists_absolute("user://icons"):
		DirAccess.make_dir_absolute("user://icons")
	var savesd_images = DirAccess.get_files_at("user://icons")
	for image in images.files_name:
		if !savesd_images.has(image):
			var new_image = Image.new()
			
			var buffer = await get_image(image)
			new_image.load_jpg_from_buffer(buffer)
			new_image.load_png_from_buffer(buffer)
			new_image.save_png("user://icons/"+image)
	for image in savesd_images:
		if !images.files_name.has(image):
			DirAccess.remove_absolute("user://icons"+image)
func add_wait(node:Control):
	var wait = preload("res://scenes/wait.tscn").instantiate()
	wait.target = node
	node.add_child(wait)
	return wait
func get_icon_group(icon, group, node):
	if !DirAccess.dir_exists_absolute("user://group_icon"):
		DirAccess.make_dir_absolute("user://group_icon")
	if icon != "":
		icon = protocol + icon if not icon.begins_with("http") else icon
		var w = add_wait(node)
		var files = DirAccess.get_files_at("user://group_icon")
		var has_group_img = null
		for file in files:
			if group in file:
				has_group_img = file
		var group_name_file = icon.get_file().uri_decode()
		if has_group_img:
			if FileAccess.file_exists("user://group_icon/"+group_name_file):
				var img = Image.new()
				img.load("user://group_icon/"+group_name_file)
				node.texture = ImageTexture.create_from_image(img)
			else:
				DirAccess.remove_absolute("user://group_icon/"+has_group_img)
				var r = HTTPRequest.new()
				add_child(r)
				r.request(icon)
				var i = await r.request_completed
				r.timeout = 3
				while (i[3]).size() == 0:
					r.request(icon)
					i = await r.request_completed
				r.queue_free()
				var img = Image.new()
				img.load_webp_from_buffer(i[3])
				img.save_webp("user://group_icon/"+group_name_file)
				node.texture = ImageTexture.create_from_image(img)
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(icon)
			var i = await r.request_completed
			r.timeout = 3
			while (i[3]).size() == 0:
				r.request(icon)
				i = await r.request_completed
			r.queue_free()
			var img = Image.new()
			img.load_webp_from_buffer(i[3])
			img.save_webp("user://group_icon/"+group_name_file)
			node.texture = ImageTexture.create_from_image(img)
		w.queue_free()
func get_icon_user(icon:String, user_name, node):
	if !DirAccess.dir_exists_absolute("user://users_icon"):
		DirAccess.make_dir_absolute("user://users_icon")
	var files = DirAccess.get_files_at("user://users_icon")
	var has_user_img = null
	for file in files:
		if user_name in file:
			has_user_img = file
	if icon != "":
		var w = add_wait(node)
		icon = protocol + icon if not icon.begins_with("http") else icon
		var user_name_file = icon.get_file().uri_decode()
		
		if has_user_img:
			
			if FileAccess.file_exists("user://users_icon/"+user_name_file):
				var img = Image.new()
				img.load("user://users_icon/"+user_name_file)
				if node is TextureRect:
					node.texture = ImageTexture.create_from_image(img)
				if node is TextureButton:
					node.texture_normal = ImageTexture.create_from_image(img)
			else:
				DirAccess.remove_absolute("user://users_icon/"+has_user_img)
				var r = HTTPRequest.new()
				add_child(r)
				r.request(icon)
				var i = await r.request_completed
				r.timeout = 3
				while (i[3]).size() == 0:
					r.request(icon)
					i = await r.request_completed
				r.queue_free()
				var img = Image.new()
				img.load_webp_from_buffer(i[3])
				img.save_webp("user://users_icon/"+user_name_file)
				if node is TextureRect:
					node.texture = ImageTexture.create_from_image(img)
				if node is TextureButton:
					node.texture_normal = ImageTexture.create_from_image(img)
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(icon)
			var i = await r.request_completed
			r.timeout = 3
			while (i[3]).size() == 0:
				r.request(icon)
				i = await r.request_completed
			r.queue_free()
			var img = Image.new()
			img.load_webp_from_buffer(i[3])
			img.save_webp("user://users_icon/"+user_name_file)
			if node is TextureRect:
				node.texture = ImageTexture.create_from_image(img)
			if node is TextureButton:
				node.texture_normal = ImageTexture.create_from_image(img)
		w.queue_free()
	else:
		if has_user_img and FileAccess.file_exists("user://users_icon/"+has_user_img):
			var img = Image.new()
			img.load("user://users_icon/"+has_user_img)
			if node is TextureRect:
				node.texture = ImageTexture.create_from_image(img)
			if node is TextureButton:
				node.texture_normal = ImageTexture.create_from_image(img)
func get_gallery_image(icon, node):
	
	if !DirAccess.dir_exists_absolute("user://"+gallary_part):
		DirAccess.make_dir_absolute("user://"+gallary_part)
	if icon != "":
		var w = add_wait(node)
		icon = protocol + icon if not icon.begins_with("http") else icon
		var files = DirAccess.get_files_at("user://"+gallary_part)
		var file_name = icon.uri_decode().get_file()
		if FileAccess.file_exists("user://"+gallary_part+"/"+file_name):
			var img = Image.new()
			img.load("user://"+gallary_part+"/"+file_name)
			node.texture = ImageTexture.create_from_image(img)
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(icon)
			var i = await r.request_completed
			r.timeout = 3
			while (i[3]).size() == 0:
				r.request(icon)
				i = await r.request_completed
			r.queue_free()
			var img = Image.new()
			img.load_webp_from_buffer(i[3])
			img.save_webp("user://"+gallary_part+"/"+file_name)
			node.texture = ImageTexture.create_from_image(img)
		w.queue_free()
func get_message_image(icon, node):
	if !DirAccess.dir_exists_absolute("user://messages"):
		DirAccess.make_dir_absolute("user://messages")
	if icon != "":
		var w = add_wait(node)
		icon = protocol + icon if not icon.begins_with("http") else icon
		var files = DirAccess.get_files_at("user://messages")
		var file_name = icon.uri_decode().get_file()
		if FileAccess.file_exists("user://messages/"+file_name):
			var img = Image.new()
			img.load("user://messages/"+file_name)
			node.texture = ImageTexture.create_from_image(img)
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(icon)
			var i = await r.request_completed
			r.timeout = 3
			while (i[3]).size() == 0:
				r.request(icon)
				i = await r.request_completed
			r.queue_free()
			var img = Image.new()
			img.load_webp_from_buffer(i[3])
			img.save_webp("user://messages/"+file_name)
			node.texture = ImageTexture.create_from_image(img)
		w.queue_free()
func get_message_sound(audio, node):
	if !DirAccess.dir_exists_absolute("user://messages"):
		DirAccess.make_dir_absolute("user://messages")
	if audio != "":
		var w = add_wait(node.get_node("MarginContainer/HBoxContainer/Button"))
		audio = protocol + audio if not audio.begins_with("http") else audio
		var files = DirAccess.get_files_at("user://messages")
		var file_name = audio.uri_decode().get_file()
		if FileAccess.file_exists("user://messages/"+file_name):
			var file = FileAccess.open("user://messages/"+file_name, FileAccess.READ)
			var stream = AudioStreamMP3.new()
			stream.data = file.get_file_as_bytes("user://messages/"+file_name)
			node.set_audio(stream)
			file.close()
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(audio)
			var i = await r.request_completed
			r.timeout = 3
			while (i[3]).size() == 0:
				r.request(audio)
				i = await r.request_completed
			r.queue_free()
			var stream = AudioStreamMP3.new()
			stream.data = i[3]
			var file = FileAccess.open("user://messages/"+file_name, FileAccess.WRITE)
			file.store_buffer(i[3])
			file.close()
			node.set_audio(stream)
		w.queue_free()
func show_picture(tex):
	if tex != null:
		texture.texture = tex
		var tween = get_tree().create_tween()
		tween.tween_property(texture, "scale", Vector2.ONE, 0.5)
		tween.play()
func hide_picture():
	var tween = get_tree().create_tween()
	tween.tween_property(texture, "scale", Vector2.ZERO, 0.5)
	tween.play()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if texture.scale == Vector2.ONE:
				hide_picture()
func save_user_messages(_id, messages):
	var config = ConfigFile.new()
	if FileAccess.file_exists("user://messages.cfg"):
		config.load("user://messages.cfg")
	var last_message = config.get_value(_id, "messages", {"messages":[], "receiverId":[]})
	for m in messages.add:
		last_message["messages"].append(m)
	for m in messages.delete:
		for message in last_message["messages"]:
			if message.id == m:
				last_message["messages"].erase(message)
	last_message.receiverId = messages.receiverId
	config.set_value(_id, "messages", last_message)
	config.save("user://messages.cfg")
func load_messages(_id, default={"messages":[], "receiverId":[]}):
	var config = ConfigFile.new()
	if not FileAccess.file_exists("user://messages.cfg"):
		config.save("user://messages.cfg")
	config.load("user://messages.cfg")
	return config.get_value(_id, "messages", default)
func save_list_user(list):
	var config = ConfigFile.new()
	if FileAccess.file_exists("user://list_user.cfg"):
		config.load("user://list_user.cfg")
	var last_users = config.get_value("users", "list", [])
	if list:
		for m in list.add:
			last_users.append(m)
		for m in list.delete:
			for u in last_users:
				if u.conversationId == m.conversationId and u.new == m.new:
					last_users.erase(u)
	config.set_value("users", "list", last_users)
	last_users.sort_custom(func(x, y):return x.last_message_time > y.last_message_time)
	list_users = last_users
	config.save("user://list_user.cfg")
func load_list_user(default=[]):
	var config = ConfigFile.new()
	if not FileAccess.file_exists("user://list_user.cfg"):
		config.save("user://list_user.cfg")
	config.load("user://list_user.cfg")
	return config.get_value("users", "list", default)
func change_user(_id, num={}, addtion=0):
	var has_user = false
	for user in list_users:
		if user.conversationId == _id:
			for n in num.keys():
				user[n] = num[n]
				has_user = true
			if addtion:
				user.new += 1
	if has_user:
		list_users.sort_custom(func(x, y):return x.last_message_time > y.last_message_time)
		var config = ConfigFile.new()
		if FileAccess.file_exists("user://list_user.cfg"):
			config.load("user://list_user.cfg")
		config.set_value("users", "list", list_users)
		config.save("user://list_user.cfg")
		return true
	else:
		return false
func load_scene(new_scene) -> Object:
	var s
	if DirAccess.dir_exists_absolute("user://resource"):
		if FileAccess.file_exists("user://resource/"+new_scene):
			ResourceLoader.load_threaded_request("user://resource/"+new_scene)
			var progress = [0]
			while progress[0] != 1:
				ResourceLoader.load_threaded_get_status("user://resource/"+new_scene, progress)
			s = ResourceLoader.load_threaded_get("user://resource/"+new_scene).instantiate()
		else:
			ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
			var progress = [0]
			while progress[0] != 1:
				ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene, progress)
			s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
			
	else:
		DirAccess.make_dir_absolute("user://resource")
		ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
		var progress = [0]
		while progress[0] != 1:
			ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene, progress)
		s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
	return s
