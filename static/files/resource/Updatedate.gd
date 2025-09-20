extends Control
signal get_image_finished
signal download_progress
signal start_download
signal end_download
signal request_completed
signal recive_message
signal delete_message
signal seen_message
signal change_status
signal edit_message(message:Dictionary)
signal update_list
var globals = ["accounts", "current_version", "hash_list", "source_dic", "hash_list2", "current_user", "last_user", "planes", "num_users", "num_groups", "last_update"]
var plan = ""
var internet = true
var subplan = ""
var group_plan = false
var save_path = "user://data.cfg"
var token = ""
var year = "1404"
var id = ""
var waiting_message = {}
var waiting_editing = {}
var data_net = [{"protocol":"http://", "domin":"127.0.0.1:5000", "socket":"ws://127.0.0.1:3000"}, {"protocol":"https://", "domin":"messbah403.ir", "socket":"ws://shirinasalgame.ir"}]
var mode_net = 1
var protocol = data_net[mode_net].protocol
var subdomin = data_net[mode_net].domin
var checked_status = []
var conversation = {}
var part = 0
var gallary_part = ""
var current_user = 0
var last_user = 0
var online_supporter = [0, 0, 0]
var texture = TextureRect.new()
var bg = ColorRect.new()
var p_scene
var socket = WebSocketPeer.new()
var set_user = false
var plugin
var seen = 0
var microphone :AudioStreamPlayer2D
var speaker :AudioStreamPlayer2D
var messages = []
var list_users = []
var failed_request = []
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
	if subdomin != "127.0.0.1:5000" and internet:
		var http = HTTPRequest.new()
		add_child(http)
		var last_update = "1758131982304"
		http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":load_game("last_update", last_update), "file":"hash_list.json"}))
		var d = await http.request_completed
		http.timeout = 10
		while d[3].size() == 0:
			http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":load_game("last_update", last_update), "file":"hash_list.json"}))
			d = await http.request_completed
		http.queue_free()
		var data = get_json(d[3])
		if data and not data.has("error"):
			if not DirAccess.dir_exists_absolute("user://resource"):
				DirAccess.make_dir_absolute("user://resource")
			if data.add.size() > 0:
				get_tree().get_root().add_child(await load_scene("download.tscn"))
			var index = 1
			start_download.emit(data.add.size(), "بروزرسانی فایل‌ها")
			var source_dic = load_game("source_dic", {})
			var hash_list:Dictionary = load_game("hash_list", {})
			
			for file in data.add:
				var f = await request("/static/files/resource/"+file[0], HTTPClient.METHOD_GET, {}, 1)
	
				download_progress.emit(index)
				var new_file = FileAccess.open("user://resource/"+file[0], FileAccess.WRITE)
				new_file.store_buffer(f)
				new_file.close()
				
				if file[0].get_extension() == "tscn":
					var s = await load_scene(file[0])
					var nodes = s.get_tree_string().split("\n")
					var list = []
					for n in nodes:
						if n!= "":
							for p in s.get_node(n).get_property_list():
								if p.type == TYPE_OBJECT:
									var path = ([s.get_node(n).get(p.name).resource_path, n, p.name] if s.get_node(n).get(p.name) is Resource else null)
									if path != null:
										list.append(path)
					var dic = {}
					for x in list:
						
						if x[1] not in dic.keys():
							if file[0].get_file() not in x[0] and "tscn" not in x[0].get_file().get_extension() and x[0] != "" and x[0].get_file().get_extension() != "gd" and not FileAccess.file_exists(x[0]) and not FileAccess.file_exists("user://resource/"+x[0].get_file()):
								dic[x[1]] = [{x[2]:x[0]}]
						else:
							if file[0].get_file() not in x[0] and x[0] != "" and "tscn" not in x[0].get_file().get_extension() and x[0].get_file().get_extension() != "gd" and not FileAccess.file_exists(x[0]) and not FileAccess.file_exists("user://resource/"+x[0].get_file()):
								dic[x[1]].append({x[2]:x[0]})
					for node in dic.keys():
						for p in dic[node]:
							var h = await request("/get_hash?name="+p.values()[0].get_file().uri_encode())
							var i = await request("/static/files/source/"+p.values()[0].get_file().uri_encode(), HTTPClient.METHOD_GET, {}, 1)
							var f2 = FileAccess.open("user://resource/"+p.values()[0].get_file(), FileAccess.WRITE)
							f2.store_buffer(i)
							f2.close()
							hash_list[p.values()[0].get_file()] = h.result if h else ""
							save("hash_list", hash_list, false)
							if file[0] not in source_dic.keys():
								source_dic[file[0]] = {}
								source_dic[file[0]][node] = [{p.keys()[0]:"user://resource/"+p.values()[0].get_file()}]
							else:
								if node not in source_dic[file[0]]:
									source_dic[file[0]][node] = [{p.keys()[0]:"user://resource/"+p.values()[0].get_file()}]
								else:
									source_dic[file[0]][node].append([{p.keys()[0]:"user://resource/"+p.values()[0].get_file()}])
				index += 1
			for file in data.delete:
				DirAccess.remove_absolute("user://resource/"+file[0])
			save("last_update", str(data.time), false)
			await get_tree().create_timer(0.5).timeout
			end_download.emit()
			await update_source()
func update_source():
	var http = HTTPRequest.new()
	add_child(http)
	var hash_list:Dictionary = load_game("hash_list2", {})
	http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":hash_list, "file":"hash_list2.json"}))
	var d = await http.request_completed
	http.timeout = 10
	while d[3].size() == 0:
		http.request(protocol+subdomin+"/check_resource", get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":hash_list, "file":"hash_list2.json"}))
		d = await http.request_completed
	var data = get_json(d[3])
	if data:
		var index = 1
		if data.add.size() > 0:
			get_tree().get_root().add_child(await load_scene("download.tscn"))
		start_download.emit(data.add.size(), "بروزرسانی منابع فایل‌ها")
		for file in data.add:
			var f = await request("/static/files/source/"+file[0].get_file().uri_encode(), HTTPClient.METHOD_GET, {}, 1)
			download_progress.emit(index)
			var new_file = FileAccess.open("user://resource/"+file[0].get_file(), FileAccess.WRITE)
			new_file.store_buffer(f)
			new_file.close()
			hash_list[file[0]] = file[1]
			save("hash_list2", hash_list, false)
			index += 1
		for file in data.delete:
			DirAccess.remove_absolute("user://resource/"+file[0])
			hash_list.erase(file[0])
			save("hash_list2", hash_list, false)
		await get_tree().create_timer(0.5).timeout
		end_download.emit()
func get_cost(_id):
	var u =protocol+subdomin+"/purchase/cost?id="+str(_id)
	var d = await request(u)
	if d.has("num"):
		return d.num
	else:
		return 0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.get_name() != "Windows":
		mode_net = 1
		protocol = data_net[mode_net].protocol
		subdomin = data_net[mode_net].domin
	#get_tree().get_root().window_input.connect(func(event):
		#if event is InputEventScreenTouch:
			#if get_global_mouse_position().x < 0 or get_global_mouse_position().y < 0:
				#DisplayServer.virtual_keyboard_hide())
	recive_message.connect(func(message, id):
		for c in waiting_message:
			if waiting_message[c].size() > 0:
				var m = waiting_message[c][0]
				send_message(m.messages.text, m.id, m.response)
				break)
	if load_game("user_name") != "":
		socket.connect_to_url(data_net[mode_net].socket)
	current_user = load_game("current_user", 0)
	last_user = load_game("last_user", 0)
	
	setup_icon()
func setup_icon():
	texture.z_index = 5
	texture.add_to_group("image_show")
	bg.add_to_group("image_show")
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.size = Vector2(400, 400)
	texture.pivot_offset = Vector2(200, 200)
	texture.set_anchors_and_offsets_preset(Control.PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE)
	texture.scale = Vector2.ZERO
	texture.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.size = size
	bg.pivot_offset = bg.size/2
	bg.hide()
	bg.z_index = 4
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/floor.gdshader")
	m.set_shader_parameter("lod", 0)
	m.set_shader_parameter("mix_percentage", 0.0)
	bg.material = m
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	load_user()
	request("/messages/get?time=%s"%load_game("last_seen", "0"))
	request_completed.connect(func(data, url):
		if data and not data.has("error"):
			if url.begins_with("/messages/state_user?user="):
				checked_status.append(data.user.username)
				save_user_messages("", {"username":data.user.username, "custom_name":data.user.custom_name, "name":data.user.name, "state":data.state, "last_seen":data.last_seen, "icon":data.user.icon, "blocked":data.blocked})
		if url.begins_with("/messages/get?time") and data and data.has("conversations"):
			for conversationId in data.conversations:
				save_user_messages(conversationId, data.conversations[conversationId])
			save("last_seen", str(data.time))
			update_list.emit(list_messages()))
			
	bg.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton:
			if event.is_pressed():
				if texture.scale == Vector2.ONE:
					set_anchors_preset(Control.PRESET_FULL_RECT)
					hide_picture()
				if texture.scale > Vector2.ONE:
					set_anchors_preset(Control.PRESET_FULL_RECT)
					var tween = get_tree().create_tween()
					tween.tween_property(texture, "scale", Vector2.ONE, 0.2)
					tween.play()
					var tween2 = get_tree().create_tween()
					tween2.tween_property(texture, "position", (size / 2) - (texture.size / 2), 0.2)
					tween2.play()
					)
	zoom(texture)
	get_tree().root.size_changed.connect(func():
		if bg:
			bg.hide()
			bg.size = size
			bg.pivot_offset = bg.size/2)
func zoom(texture:TextureRect):
	texture.gui_input.connect(func(event:InputEvent):
		texture.scale = clamp(texture.scale, Vector2.ONE, Vector2.ONE * 10)
		var delta = size - (texture.scale * texture.size)
		var s = ((texture.size * texture.scale) - texture.size) / 2.0
		if delta.x > 0:
			texture.position.x = clamp(texture.position.x, s.x, delta.x + s.x)
		else:
			texture.position.x = clamp(texture.position.x, delta.x + s.x, s.x)
		if delta.y > 0:
			texture.position.y = clamp(texture.position.y, s.y, delta.y + s.y)
		else:
			texture.position.y = clamp(texture.position.y, delta.y + s.y, s.y)
		if event is InputEventMagnifyGesture:
			texture.scale *= event.factor
			texture.scale = clamp(texture.scale, Vector2.ONE, Vector2.ONE * 10)
		if event is InputEventMouseButton:
			if event.ctrl_pressed and event.is_pressed():
				if event.button_index == 5:
					if texture.scale.x > 1.0:
						texture.scale -= Vector2.ONE * event.factor / 2
				if event.button_index == 4:
					if texture.scale.x < 10.0:
						texture.scale += Vector2.ONE * event.factor / 2
		if event is InputEventScreenDrag:
			texture.position += event.relative * texture.scale
			
		)
func _process(delta: float) -> void:
	if texture == null:
		texture = TextureRect.new()
		bg = ColorRect.new()
	if not get_tree().root.get_children().has(texture):
		get_tree().root.add_child(bg)
		get_tree().root.add_child(texture)
		print(10)
		setup_icon()
	if bg.material == null:
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/floor.gdshader")
		m.set_shader_parameter("lod", 0)
		m.set_shader_parameter("mix_percentage", 0.0)
		bg.material = m
	socket.poll()
	if socket.get_ready_state() == 3 and load_game("user_name") != "":
		socket.connect_to_url(data_net[mode_net].socket)
		set_user = false
		internet = false
	if socket.get_ready_state() == 1:
		if not set_user:
			socket.send(JSON.stringify({ "type": 'register', "username":load_game("user_name", "") }).to_utf8_buffer())
			set_user = true
		if not internet:
			internet = true
			for r in failed_request:
				request(r)
			request("/messages/get?time=%s"%load_game("last_seen", "0"))
			for c in waiting_message:
				if waiting_message[c].size() > 0:
					var m = waiting_message[c][0]
					send_message(m.messages.text, m.id, m.response)
					break
			for c in waiting_editing:
				for x in waiting_editing[c]:
					send_edit_message(x[0], x[1])
		get_message()

func load_user():
	var d = null
	if FileAccess.file_exists("user://session.dat"):
		if load_game("accounts", []).size() == 0:
			DirAccess.remove_absolute("user://session.dat")
			return false
		if current_user > load_game("accounts", []).size() -1:
			current_user = 0
			save("current_user", 0)
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
func delete_user(user_name:String):
	if FileAccess.file_exists("user://session.dat"):
		var file = FileAccess.open("user://session.dat", FileAccess.READ)
		var d = file.get_var()
		for u in d:
			if u.id == user_name:
				d.erase(u)
		file.close()
		FileAccess.open("user://session.dat", FileAccess.WRITE).store_var(d)
		var accounts = load_game("accounts", [])
		accounts.erase(user_name)
		save("accounts", accounts)
func random_level(pa, _data={}):
	var q = "part=%s"%pa.uri_encode()
	var u =protocol+subdomin+"/levels/random?"+q
	var d = await request(u)
	if d and d.has("data"):
		_data = d.data
	return _data
func cancel_request():
	for r in get_tree().get_nodes_in_group("request"):
		r.cancel_request()
		r.queue_free()
func request(url, method=HTTPClient.METHOD_GET,_data={}, result_mode=0):
	var http = HTTPRequest.new()
	http.add_to_group("request")
	add_child(http)

	var header = [
		"Content-Type: application/json",
		"Authorization: Bearer %s"%token
	]
	if _data.keys().size() > 0:
		http.request(protocol+subdomin+url if not url.begins_with("http") else url, header, method)
	else:
		http.request(protocol+subdomin+url if not url.begins_with("http") else url, header, method, JSON.stringify(_data))
	var d = await http.request_completed
	
	if d[3].size() == 0:
		if not failed_request.has(url):
			failed_request.append(url)
	http.queue_free()
	if result_mode == 0:
		if get_json(d[3]):
			request_completed.emit(get_json(d[3]), url)
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
func save(_name, num, server=true, _section=""):
	var confige = ConfigFile.new()
	confige.load(save_path)
	var accounts = confige.get_value("global", "accounts", [])
	var user = _section if _section != "" else accounts[confige.get_value("global", "current_user", 0)] if accounts.size() > confige.get_value("global", "current_user", 0) else ""
	if _name in globals:
		confige.set_value("global", _name, num)
	else:
		if user != "":
			confige.set_value(user, _name, num)
	confige.save(save_path)
	if server and _name != "image":
		save_server({_name:num})
func multy_save(_data:Dictionary, _section=""):
	var confige = ConfigFile.new()
	confige.load(save_path)
	var accounts = confige.get_value("global", "accounts", [])
	var user = _section if _section != "" else accounts[confige.get_value("global", "current_user", 0)] if accounts.size() > confige.get_value("global", "current_user", 0) else ""
	for key in _data.keys():
		if key in globals:
			confige.set_value("global", key, _data[key])
		else:
			if user != "":
				confige.set_value(user, key, _data[key])
	confige.save(save_path)
	save_server(_data)
func load_game(_name, defaulte=null, _section=""):
	var confige = ConfigFile.new()
	confige.load(save_path)
	
	var accounts = confige.get_value("global", "accounts", [])
	var user = accounts[confige.get_value("global", "current_user", 0)] if accounts.size() > confige.get_value("global", "current_user", 0) else ""
	var section = "global" if _name in globals else user if _section == "" else _section
	if confige.has_section_key(section, _name):
		return confige.get_value(section, _name, defaulte)
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
			pass
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
		if data == null:
			return true
		else:
			if data.has("error"):
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
func get_icon_group(icon, group, node:TextureRect):
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
				if node:
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
				if node:
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
			if node:
				node.texture = ImageTexture.create_from_image(img)
		w.queue_free()
		if node:
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			node.gui_input.connect(func(event:InputEvent):
				if event is InputEventScreenTouch  and event.is_pressed():
					if texture.scale.x > 0.2:
						hide_picture()
					else:
						show_picture(node.texture))
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
				if node and node is TextureRect:
					node.texture = ImageTexture.create_from_image(img)
				if node and node is TextureButton:
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
			if node and node is TextureRect:
				node.texture = ImageTexture.create_from_image(img)
			if node and node is TextureButton:
				node.texture_normal = ImageTexture.create_from_image(img)
		if w:
			w.queue_free()
	else:
		if has_user_img and FileAccess.file_exists("user://users_icon/"+has_user_img):
			var img = Image.new()
			img.load("user://users_icon/"+has_user_img)
			if node and node is TextureRect:
				node.texture = ImageTexture.create_from_image(img)
			if node and node is TextureButton:
				node.texture_normal = ImageTexture.create_from_image(img)
	if node and node is TextureRect:
		
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.gui_input.connect(func(event:InputEvent):
			if event is InputEventScreenTouch and event.is_pressed():
				
				if texture.scale.x > 0.2:
					hide_picture()
				else:
					show_picture(node.texture))
func get_gallery_image(icon, node):
	
	if !DirAccess.dir_exists_absolute("user://"+gallary_part):
		DirAccess.make_dir_absolute("user://"+gallary_part)
	if icon != "":
		var w = add_wait(node)
		icon = protocol + icon if not icon.begins_with("http") else icon
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
			var stream = AudioStreamMP3.new()
			stream.data = FileAccess.get_file_as_bytes("user://messages/"+file_name)
			node.set_audio(stream)
		else:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(audio)
			var i = await r.request_completed
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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if tex != null:
		bg.show()
		texture.texture = tex
		var tween2 = get_tree().create_tween()
		tween2.tween_property(bg, "material:shader_parameter/lod", 2.5, 0.2)
		tween2.play()
		var tween3 = get_tree().create_tween()
		tween3.tween_property(bg, "material:shader_parameter/mix_percentage", 0.5, 0.2)
		tween3.play()
		await tween2.finished
		var tween = get_tree().create_tween()
		tween.tween_property(texture, "scale", Vector2.ONE, 0.2)
		tween.play()
		
func hide_picture():
	var tween4 = get_tree().create_tween()
	tween4.tween_property(texture, "position", (size / 2) - (texture.size / 2), 0.2)
	tween4.play()
	await tween4.finished
	var tween = get_tree().create_tween()
	tween.tween_property(texture, "scale", Vector2.ZERO, 0.2)
	tween.play()
	await tween.finished
	var tween2 = get_tree().create_tween()
	tween2.tween_property(bg, "material:shader_parameter/lod", 0, 0.2)
	tween2.play()
	var tween3 = get_tree().create_tween()
	tween3.tween_property(bg, "material:shader_parameter/mix_percentage", 0.0, 0.2)
	tween3.play()
	await tween2.finished
	bg.hide()

## پیام های شما را بروزرسانی می‌کند. در ابتدا آیدی مکالمه را دریافت می‌کند و سپس دیکشنری پیام ها را می‌گیرد، که خود آن شامل دو مولفه‌ی [code] add [/code] و [code] delete [/code] هست که هر دو لیستی از پیام هایی هستند که می‌خواهید اضافه یا حذف شوند.
##[codeblock] save_user_messages(conversationId, {"add":[data.message], "delete":[]})
func save_user_messages(_id:String, _messages:Dictionary):
	var config = ConfigFile.new()
	if FileAccess.file_exists("user://messages_"+load_game("user_name", "")+".cfg"):
		config.load("user://messages_"+load_game("user_name", "")+".cfg")
	if _id != "":
		if _messages.has("remove"):
			if config.has_section(_id):
				config.erase_section(_id)
				config.save("user://messages_"+load_game("user_name", "")+".cfg")
			return
		if _id.length() > 20:
			var last_message:Dictionary = config.get_value(_id, "messages", {})
			if _messages.has("part"):
				config.set_value(_id, "part", _messages.part)
			if _messages.has("icon"):
				config.set_value(_id, "icon", _messages.icon)
			if _messages.has("name"):
				config.set_value(_id, "name", _messages.name)
			if _messages.has("custom_name"):
				config.set_value(_id, "custom_name", _messages.custom_name)
			if _messages.has("username") and _id != "":
				config.set_value(_id, "username", _messages.username)
			if _messages.has("seen"):
				last_message[_messages.seen.id].seen = _messages.seen.seen
			if _messages.has("blocked"):
				config.set_value(_id, "blocked", _messages.blocked)
			if _messages.has("add"):
				for m in _messages.add:
					last_message[m.id] = m
					if config.get_value(_id, "last_message", "") == "":
						config.set_value(_id, "last_message", m.id)
					else:
						if float(last_message[config.get_value(_id, "last_message", "")].createdAt) < float(m.createdAt):
							config.set_value(_id, "last_message", m.id)
			if _messages.has("delete"):
				for id in _messages.delete:
					last_message.erase(id[0])
					if config.get_value(_id, "last_message", "") == id[0]:
						config.set_value(_id, "last_message", id[1])
			config.set_value(_id, "messages", last_message)
	else:
		var list = Array(config.get_sections()).filter(func(s): return _messages.username in s and _messages.username != Updatedate.load_game("user_name", ""))
		for c in list:
			if _messages.has("blocked"):
				config.set_value(c, "blocked", _messages.blocked)
			if _messages.has("name"):
				config.set_value(c, "name", _messages.name)
			if  _messages.has("custom_name"):
				config.set_value(c, "custom_name", _messages.custom_name)
			if _messages.has("icon"):
				config.set_value(c, "icon", _messages.icon)
			if _messages.has("state"):
				config.set_value(c, "state", _messages.state)
				_messages.last_seen["timestamp"] = str(_messages.last_seen["timestamp"])
				config.set_value(c, "last_seen", _messages.last_seen)
	config.save("user://messages_"+load_game("user_name", "")+".cfg")

func load_messages(_id, default={}):
	var config = ConfigFile.new()
	if not FileAccess.file_exists("user://messages_"+load_game("user_name", "")+".cfg"):
		config.save("user://messages_"+load_game("user_name", "")+".cfg")
	config.load("user://messages_"+load_game("user_name", "")+".cfg")
	var m = config.get_value(_id, "messages", default)
	return m
func list_messages():
	var config = ConfigFile.new()
	if not FileAccess.file_exists("user://messages_"+load_game("user_name", "")+".cfg"):
		config.save("user://messages_"+load_game("user_name", "")+".cfg")
	config.load("user://messages_"+load_game("user_name", "")+".cfg")
	var data = {}
	for c in config.get_sections():
		var user = ""
		var m = config.get_value(c, "messages", {})
		var new_messages = m.values().filter(func (x): return (not x.has("seen") or x["seen"] == null) and x["sender"] != load_game("user_name", ""))
		data[c] = {new=len(new_messages), username=config.get_value(c, "username", ""), icon=config.get_value(c, "icon", ""), "name"=config.get_value(c, "name", ""), custom_name=config.get_value(c, "custom_name", ""), part=config.get_value(c, "part", ""), "last_seen"=config.get_value(c, "last_seen", {}), state=config.get_value(c, "state", "")}
		if m.has(config.get_value(c, "last_message", "")):
			data[c]["message"] = m[config.get_value(c, "last_message", "")]
	return data
func get_conversation(_id):
	var config = ConfigFile.new()
	if not FileAccess.file_exists("user://messages_"+load_game("user_name", "")+".cfg"):
		config.save("user://messages_"+load_game("user_name", "")+".cfg")
	config.load("user://messages_"+load_game("user_name", "")+".cfg")
	var m = config.get_value(_id, "messages", {})
	var new_messages = m.values().filter(func (x): return (not x.has("seen") or x["seen"] == null) and x["sender"] != load_game("user_name", ""))
	var data= {new=len(new_messages), username=config.get_value(_id, "username", ""), icon=config.get_value(_id, "icon", ""), "name"=config.get_value(_id, "name", ""), custom_name=config.get_value(_id, "custom_name", ""), part=config.get_value(_id, "part", ""), "last_seen"=config.get_value(_id, "last_seen", {}), state=config.get_value(_id, "state", "")}
	if m.has(config.get_value(_id, "last_message", "")):
		data["message"] = m[config.get_value(_id, "last_message", "")]
	return data
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
	var s:Object
	if DirAccess.dir_exists_absolute("user://resource"):
		var script:Script
		if FileAccess.file_exists("user://resource/"+new_scene.get_basename()+".gd"):
			script = load("user://resource/"+new_scene.get_basename()+".gd")
		if FileAccess.file_exists("user://resource/"+new_scene):
			ResourceLoader.load_threaded_request("user://resource/"+new_scene)
			var progress = [0]
			while progress[0] != 1:
				ResourceLoader.load_threaded_get_status("user://resource/"+new_scene, progress)
			s = ResourceLoader.load_threaded_get("user://resource/"+new_scene).instantiate()
			if script:
				s.set_script(script)
			
		else:
			ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
			var progress = [0]
			while progress[0] != 1:
				ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene, progress)
			s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
			
			if script:
				s.set_script(script)
	else:
		DirAccess.make_dir_absolute("user://resource")
		ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
		var progress = [0]
		while progress[0] != 1:
			ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene, progress)
		s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
	var source_dic = load_game("source_dic", {})

	if new_scene in source_dic.keys():
		for node in source_dic[new_scene]:
			for p in source_dic[new_scene][node]:
				s.get_node(node).set(p.keys()[0], ResourceLoader.load(p.values()[0]))
				print( ResourceLoader.load(p.values()[0]))
	return s

func send_message(text:String, _id, responsed:String=""):
	if conversation["part"] != "":
		var data = {type="message", conversationId=conversation["id"].left(20), senderId=load_game("user_name", ""), content={text=text}, part=conversation["part"], response=responsed, id=_id}
		if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			socket.send_text(JSON.stringify(data))

func send_edit_message(_id:String, text:String):
	
	var data = {type="edited", conversationId=conversation["id"].left(20), senderId=load_game("user_name", ""), content={text=text}, id=_id}
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
func message_seen(_id:String):
	var data = {type="seen", conversationId=conversation["id"].left(20), senderId=load_game("user_name", ""), content={text=""}, id=_id}
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
func delete(id:String, pre_id:String):
	var data = {type="delete", conversationId=conversation["id"].left(20), senderId=load_game("user_name", ""), content={text=""}, id=id, part=conversation["part"], pre_id=pre_id}
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
func get_message():
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var data = get_json(socket.get_packet())
			if data and data.has("type"):
				match data.type:
					"message":
						data.message.createdAt = str(float(data.message.createdAt))
						data.message.updatedAt = str(float(data.message.updatedAt))
						save_user_messages(data.message.conversationId + data.message.part, {"add":[data.message], "delete":[]})
						save("last_seen", str(data.message.createdAt), false)
						
						if waiting_message.has(data.message.conversationId + data.message.part):
							for m in waiting_message[data.message.conversationId + data.message.part]:
								if m.id == data.id:
									waiting_message[data.message.conversationId + data.message.part].erase(m)
						recive_message.emit(data.message, data.id)
					"delete":
						save_user_messages(data.conversationId + data.part, {"add":[], "delete":[[data.message, data.pre_message]]})
						save("last_seen", str(data.time), false)
						delete_message.emit(data.conversationId + data.part, data.message, data.pre_message)
					"edited":
						data.message.createdAt = str(float(data.message.createdAt))
						data.message.updatedAt = str(float(data.message.updatedAt))
						save_user_messages(data.message.conversationId + data.message.part, {"add":[data.message], "delete":[]})
						save("last_seen", str(data.message.updatedAt), false)
						edit_message.emit(data.message)
						if waiting_editing.has(data.message.conversationId + data.message.part):
							for m in waiting_editing[data.message.conversationId + data.message.part]:
								if m[0] == data.message.id:
									waiting_editing[data.message.conversationId + data.message.part].erase(m)
					"seen":
						data.message.createdAt = str(float(data.message.createdAt))
						data.message.updatedAt = str(float(data.message.updatedAt))
						data.message.seen = str(float(data.message.seen))
						save_user_messages(data.message.conversationId + data.message.part, {"add":[], "delete":[], "seen":data.message})
						save("last_seen", str(data.message.seen), false)
						seen_message.emit(data.message)
					"new":
						save_user_messages(data.conversationId + data.part, {"add":[], "delete":[], "username":data.user.username, "icon":data.user.icon, "name":data.user.name, "custom_name":data.user.custom_name if data.user.has("custom_name") else "", "part":data.part})
					"status":
						data.timestamp = str(float(data.timestamp))
						save_user_messages("", {"add":[], "delete":[], "last_seen":{"time":data.time, "timestamp":data.timestamp}, "state":data.state, "username":data.username, "icon":data.user.icon, "custom_name":data.user.custom_name if data.user.has("custom_name") else "", "name":data.user.name})
						change_status.emit({"last_seen":{"time":data.time, "timestamp":data.timestamp}, "state":data.state, "username":data.username, "icon":data.user.icon, "custom_name":data.user.custom_name if data.user.has("custom_name") else "", "name":data.user.name})
