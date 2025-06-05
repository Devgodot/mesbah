extends Control
var gender = 0
var tag = 0
var parts = ["سلامت معنوی", "سلامت جسمانی", "سلامت فکری"]
var diamonds = []
var groups = []
var scores = []
var name_group = ""
var user_name = ""
var current_c = ""
var current_r = []
var scroll = 0
var seen = 0
var seen2 = 0
var filter = {}
var camera
@onready var vbox = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer"

func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.has_singleton("GodotGetImage"):
		camera = Engine.get_singleton("GodotGetImage")
	if camera:
		camera.image_request_completed.connect(_on_texture_rect_face_detected)
		camera.setOptions({"use_front_camera":true, "image_height":500, "image_width": 500, "keep_aspect":true})
	seen = Updatedate.seen
	focus_mode = FOCUS_ALL
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer6/SpinBox".get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer6/SpinBox".get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	show()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TabContainer.set_tab_disabled(2, not Updatedate.load_game("support", false))
	if Updatedate.load_game("support", false):
		vbox.get_node("HBoxContainer/TextEdit/TextEdit").text = vbox.get_node("HBoxContainer/TextEdit").text
		vbox.get_node("HBoxContainer/TextEdit").scroll_fit_content_height = not (vbox.get_node("HBoxContainer/TextEdit/TextEdit").size.y > vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 5)
		if vbox.get_node("HBoxContainer/TextEdit").scroll_fit_content_height:
			vbox.get_node("HBoxContainer/TextEdit").custom_minimum_size.y =  vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 1
		else:
			vbox.get_node("HBoxContainer/TextEdit").custom_minimum_size.y =  vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 5
		if $TabContainer.current_tab == 2:
			$Label.hide()
			if seen > 0:
				$Label2.show()
				if seen < 100:
					$Label2.text = str(int(seen))
				else:
					$Label2.text = "+99"
			else:
				$Label2.hide()
			if seen2 > 0:
				$Label3.show()
				if seen2 < 100:
					$Label3.text = str(int(seen2))
				else:
					$Label3.text = "+99"
			else:
				$Label3.hide()
		else:
			if seen + seen2 > 0:
				$Label.show()
				if seen + seen2 < 100:
					$Label.text = str(int(seen + seen2))
				else:
					$Label.text = "+99"
			else:
				$Label.hide()
		
		match Updatedate.socket.get_ready_state():
			1:
				while Updatedate.socket.get_available_packet_count():
					var d = (Updatedate.get_json(Updatedate.socket.get_packet()))
					if d.has("message") and d.has("id"):
						Updatedate.save_user_messages(d.id, {"add":[d.message], "receiverId":d.receiverId, "delete":[]})
						if not Updatedate.change_user(d.id, {"last_message_time":d.message.timestamp}, 1):
							var r = HTTPRequest.new()
							add_child(r)
							r.request(Updatedate.protocol+Updatedate.subdomin+"/users/users_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"users":Updatedate.load_list_user()}))
							r.request_completed.connect(func(result, respons, header, body):
								var new_data = Updatedate.get_json(body)
								Updatedate.save_list_user(new_data)
								r.queue_free()
								add_list(filter)
								)
					if d.has("type") and d.type == "delete":
						Updatedate.change_user(d.conversationId, {"last_message_time":d.last_time_messages})
						add_list(filter)
						for m in get_tree().get_nodes_in_group("message"):
							if m.get_meta("id") == d.message:
								Updatedate.save_user_messages(current_c, {"add":[], "receiverId":current_r, "delete":[d.message]})
								remove(m)
						
					elif d.has("message") and d.id == current_c:
						if $"TabContainer/پیام ها/TabContainer".current_tab == 0:
							seen2 += 1
							Notification.add_notif("کاربر پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
						var message = d.message
						if message.sender == Updatedate.load_game("user_name"):
							var box = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
							box.add_to_group("message")
							box.set_meta("id", message.id)
							if box.get_node_or_null("HBoxContainer/MarginContainer/VBoxContainer/Label/Button"):
								box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").pressed.connect(func():
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").hide()
									remove(box)
									if !current_r.has(current_c.left(10)):
										current_r.append(current_c.left(10))
									Updatedate.socket.send(JSON.stringify({"type":"delete", "id":message.id, "conversationId":current_c, "receiverId":current_r, "senderId":Updatedate.load_game("user_name")}).to_utf8_buffer())
									)
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
							box.show()
							$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
						elif message.sender in d.receiverId and message.sender not in current_c:
							var box = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
							box.add_to_group("message")
							box.set_meta("id", message.id)
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "پشتیبان"
							box.show()
							$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
						else:
							var box = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
							box.add_to_group("message")
							box.set_meta("id", message.id)
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "کاربر"
							box.show()
							$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
						Updatedate.change_user(current_c, {"last_message_time":message.timestamp, "new":0})
						var r = HTTPRequest.new()
						add_child(r)
						r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/seen_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":[message.id], "conversationId":current_c}))
						r.request_completed.connect(func (x, y, z, b):
							r.queue_free())

					elif d.has("message") and d.has("id") and (d.id != current_c or $TabContainer.current_tab != 2) and (not d.has("type") or d.type !="onlineUsers"):
						if d.has("id") and d.id != current_c:
							if $"TabContainer/پیام ها/TabContainer".current_tab == 1:
								seen += 1
								Notification.add_notif("کاربری پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
							else:
								if $TabContainer.current_tab == 2:
									add_list()
								else:
									seen += 1
									Notification.add_notif("کاربری پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
						else:
							if d.has("id") and d.id == current_c:
								seen2 += 1
								Notification.add_notif("کاربر پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
							else :
								seen += 1
								Notification.add_notif("کاربری پیامی ارسال کرد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
					await get_tree().create_timer(0.2).timeout
					$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".get_v_scroll_bar().max_value
					scroll = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical
func _on_button_pressed() -> void:
	user_name = ""
	for child in $"TabContainer/فردی/MarginContainer/VBoxContainer/VBoxContainer".get_children():
		child.queue_free()
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".text = ""
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".size
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".material = ShaderMaterial.new()
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture = Image.new()
	$"TabContainer/فردی/MarginContainer/VBoxContainer".hide()
	var w = Updatedate.add_wait($"TabContainer/فردی/Button")
	var d = (await Updatedate.request("/users/get?username="+%id.text))
	diamonds = []
	scores = []
	if d.has("message"):
		Notification.add_notif(d.message, Notification.ERROR)
	if d and d.has("name"):
		user_name = %id.text
		gender = d.gender
		tag = d.tag
		$"TabContainer/فردی/MarginContainer/VBoxContainer".show()
		var edit_part:Array = Updatedate.load_game("part_edit", [])
		for di in d.diamonds:
			diamonds.append(di)
		for s in d.scores:
			scores.append(s)
		var str_edit_part = []
		for x in edit_part:
			str_edit_part.append(str(int(x)))
		
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/Label".text = "نام و نام خانوادگی : "
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".text = d.custom_name if d.has("custom_name") else "[right] " + d.name
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer2/Label2".text = "نام پدر : " + d.father_name
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer2/Label3".text = "شماره تلفن : " + d.phone
		Updatedate.get_icon_user(d.icon, %id.text ,$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect")
		var diamonds2 = []
		var scores2 = []
		for x in range(d.diamonds.size()):
			if str(x) in str_edit_part:
				var box = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer6".duplicate()
				box.get_node("Label").text = parts[x] + " : "
				box.get_node("SpinBox").value = d.scores[x]
				box.add_to_group("update_user")
				box.set_meta("id", str(x))
				box.get_node("CheckBox").button_pressed = bool(d.diamonds[x])
				box.show()
				$"TabContainer/فردی/MarginContainer/VBoxContainer/VBoxContainer".add_child(box)
			else:
				diamonds2.append(diamonds[x])
				scores2.append(scores[x])
				var box = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer3".duplicate()
				box.get_node("Label").text = parts[x] + " : " + str(d.scores[x], " امتیاز و ", ["الماس ندارد", "دارای الماس"][d.diamonds[x]])
				box.show()
				$"TabContainer/فردی/MarginContainer/VBoxContainer/VBoxContainer".add_child(box)
		diamonds = diamonds2
		scores = scores2
		await get_tree().create_timer(0.1).timeout
		if $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.x > 733:
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size.x = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.x * 2
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size.y = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.y
			var shader = $"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer/instance/MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer".material.shader
			var _material = ShaderMaterial.new()
			_material.shader = shader
			_material.set_shader_parameter("dir", get_direction(d.name))
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".material = _material
	w.queue_free()

func _on_update_user_pressed() -> void:
	var data = {}
	var score = 0
	var diamond = 0
	for child in get_tree().get_nodes_in_group("update_user"):
		data["diamonds"+str(child.get_meta("id", ""))] = int(child.get_node("CheckBox").button_pressed)
		data["score_"+str(gender, "_", tag, "_", child.get_meta("id", ""))] = int(child.get_node("SpinBox").value)
		score += int(child.get_node("SpinBox").value)
		diamond += int(child.get_node("CheckBox").button_pressed)
	for s in scores:
		score += s
	for d in diamonds:
		diamond += d
	data["score_"+str(gender, "_", tag)] = score
	data["diamonds"] = diamond
	var r = HTTPRequest.new()
	var w = Updatedate.add_wait($"TabContainer/فردی/MarginContainer/VBoxContainer/Button")
	add_child(r)
	r.timeout = 3
	r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":data, "username":user_name}))
	var d = await r.request_completed
	while d[3].size() == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":data, "username":user_name}))
		d = await r.request_completed
	r.queue_free()
	w.queue_free()
	d = Updatedate.get_json(d[3])
	if d.has("message"):
		Notification.add_notif(d.message)
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)


func _on_button2_pressed() -> void:
	$ScrollContainer.hide()
	name_group = ""
	for child in $"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer".get_children():
		child.queue_free()
	for child in $"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer2".get_children():
		child.queue_free()
	$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture = Image.new()
	$"TabContainer/گروهی/MarginContainer/VBoxContainer".hide()
	var w = Updatedate.add_wait($"TabContainer/گروهی/Button")
	var d = (await Updatedate.request("/groups/get?name="+%name.text.uri_encode()))
	if d.has("message"):
		Notification.add_notif(d.message, Notification.ERROR)
	if d and d.has("users_info"):
		name_group = %name.text
		diamonds = []
		scores = []
		Updatedate.get_icon_group(custom_hash.hashing(custom_hash.GET_HASH,d.icon), %name.text ,$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect")
		for di in d.diamonds.keys():
			diamonds.append({di:d.diamonds[di]})
		for s in d.scores.keys():
			scores.append({s:d.scores[s]})
		var edit_part:Array = Updatedate.load_game("part_edit", [])
		var str_edit_part = []
		for x in edit_part:
			str_edit_part.append(str(x))
		$"TabContainer/گروهی/MarginContainer/VBoxContainer".show()
		for x in range(d.users.size()):
			var box = $"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer5".duplicate()
			if d.users[x] == d.leader:
				box.get_node("Label").text = "نام سرگروه : "  
				box.get_node("Label2").text = "کد ملی : " + custom_hash.hashing(custom_hash.GET_HASH,d.users[x])
				box.get_node("name/texture/Label").text = "[font_size=45]"+d.users_info[x].custom_name if d.users_info[x].has("custom_name") else "[center]" + d.users_info[x].name
			else:
				box.get_node("Label").text = "نام عضو : "  
				box.get_node("Label2").text = "کد ملی : " + custom_hash.hashing(custom_hash.GET_HASH,d.users[x])
				box.get_node("name/texture/Label").text = d.users_info[x].custom_name if d.users_info[x].has("custom_name") else "[center]" + d.users_info[x].name
			box.show()
			$"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer2".add_child(box)
			box.get_node("name").texture = box.get_node("name/texture").get_texture()
			if box.get_node("name/texture/Label").size.x > 408:
				box.get_node("name/texture").size.x = box.get_node("name/texture/Label").size.x * 2
				box.get_node("name/texture").size.y = box.get_node("name/texture/Label").size.y
				var shader = $"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer/instance/MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer".material.shader
				var _material = ShaderMaterial.new()
				_material.shader = shader
				_material.set_shader_parameter("dir", get_direction(d.users_info[x].name))
				box.get_node("name").material = _material
		var diamonds2 = []
		var scores2 = []
		for x in range(d.diamonds.size()):
			if str(x) in str_edit_part:
				var box = $"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer6".duplicate()
				box.get_node("Label").text = parts[x] + " : "
				box.get_node("SpinBox").value = d.scores[str("score",x)]
				box.add_to_group("update_group")
				box.set_meta("id", str(x))
				box.get_node("CheckBox").button_pressed = bool(d.diamonds[str("diamond",x)])
				box.show()
				$"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer".add_child(box)
			else:
				diamonds2.append(diamonds[x])
				scores2.append(scores[x])
				var box = $"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer3".duplicate()
				box.get_node("Label").text = parts[x] + " : " + str(d.scores[str("score",x)], " امتیاز و ", ["الماس ندارد", "دارای الماس"][d.diamonds[str("diamond",x)]])
				box.show()
				$"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer".add_child(box)
		diamonds = diamonds2
		scores = scores2
	w.queue_free()
	

func _on_update_group_pressed() -> void:
	var data = {"diamonds":{}, "name":name_group, "scores":{}}
	for child in get_tree().get_nodes_in_group("update_group"):
		data["diamonds"][str("diamond", child.get_meta("id", ""))] = int(child.get_node("CheckBox").button_pressed)
		data["scores"][str("score", child.get_meta("id", ""))] = int(child.get_node("SpinBox").value)
	for s in scores:
		data["scores"][s.keys()[0]] = s.values()[0]
	for d in diamonds:
		data["diamonds"][d.keys()[0]] = d.values()[0]
	var r = HTTPRequest.new()
	var w = Updatedate.add_wait($"TabContainer/گروهی/MarginContainer/VBoxContainer/Button")
	add_child(r)
	r.timeout = 3
	r.request(Updatedate.protocol+Updatedate.subdomin+"/groups/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await r.request_completed
	while d[3].size() == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/groups/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
		d = await r.request_completed
	r.queue_free()
	w.queue_free()
	d = Updatedate.get_json(d[3])
	if d.has("message"):
		Notification.add_notif(d.message)
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)

func _on_back_button_pressed() -> void:
	if $TabContainer.current_tab == 2:
		if $"TabContainer/پیام ها/TabContainer".current_tab == 1:
			$"TabContainer/پیام ها/TabContainer".current_tab = 0
		else :
			$TabContainer.current_tab = 0
	elif $TabContainer.current_tab != 0:
		$TabContainer.current_tab = 0
	else:
		Transation.change(self, "start.tscn", -1)
		

func _on_tab_container_tab_selected(tab: int, args=0) -> void:
	$ScrollContainer.hide()
	$HBoxContainer.hide()
	if tab == 1:
		var d = await Updatedate.request("/groups/names")
		var g = d.data if d and d.has("data") else []
		groups = []
		for n in g:
			groups.append(n[0])
	if tab == 2 or (tab == 0 and args == 1 and $TabContainer.current_tab == 2):
		if $"TabContainer/پیام ها/TabContainer".current_tab != 1:
			$HBoxContainer.show()
		seen = 0
		Updatedate.seen = 0
		
		var w = Updatedate.add_wait($"TabContainer/پیام ها/TabContainer/لیست")
		await add_list()
		w.queue_free()
	if tab == 1 and args == 1:
		seen2 = 0
	
func add_list(_filter={}):
	
	var d = Updatedate.list_users
	
	for child in $"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer".get_children():
		if "instance" not in child.name:
			child.queue_free()
	if d:
		var users = []
		for user in d:
			if _filter.has("name"):
				if _filter.name in user.name:
					users.append(user)
			if _filter.has("username"):
				if _filter.username in user.username:
					users.append(user)
			if _filter.has("phone"):
				if _filter.phone in user.phone:
					users.append(user)
			if _filter.has("unseen"):
				if user.new > 0:
					users.append(user)
		if _filter == {} or (_filter.values()[0] == "" and not _filter.has("unseen")):
			users = d
		for user in users:
			var box = $"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer/instance".duplicate()
			
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Label").text = "نام و نام خانودگی : "
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/Label").text = user.custom_name if user.has("custom_name") else "[center]"+user.name
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Label2").text = "پیام جدید : "+str(int(user.new))
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Label").text = "کد ملی : "+str(user.username)
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Label3").text =  ["معنوی", "جسمانی", "فکری"][int(user.conversationId.right(1))]
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Label2").text = "شماره : "+str(user.phone)
			box.show()
			$"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer".add_child(box)
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer").texture = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport").get_texture()
			if box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/Label").size.x > 350:
				box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport").size.x = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/Label").size.x * 1.5
				var shader = $"TabContainer/پیام ها/TabContainer/لیست/VBoxContainer/instance/MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer".material.shader
				var _material = ShaderMaterial.new()
				_material.shader = shader
				_material.set_shader_parameter("dir", get_direction(user.name))
				box.get_node("MarginContainer/VBoxContainer/HBoxContainer/SubViewportContainer").material = _material
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect").gui_input.connect(func (event:InputEvent):
				if event is InputEventScreenTouch and event.is_pressed():
					Updatedate.show_picture(box.get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect").texture)
					)
			Updatedate.get_icon_user(user.icon, user.username, box.get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect"))
			box.gui_input.connect(func (event:InputEvent):
				if event is InputEventMouseButton and event.double_click and event.is_pressed():
					$"TabContainer/پیام ها/TabContainer".current_tab = 1
					for child in $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
						if "instance" not in child.name:
							child.queue_free()
					var r = HTTPRequest.new()
					add_child(r)
					r.request(Updatedate.protocol+Updatedate.subdomin+"/users/user_message?id="+user.conversationId, Updatedate.get_header(),HTTPClient.METHOD_POST, JSON.stringify({"messages":Updatedate.load_messages(user.conversationId).messages}))
					$Label4.show()
					r.request_completed.connect(func(result, re, h, b):
						var new_data = Updatedate.get_json(b)
						$Label4.hide()
						Updatedate.save_user_messages(user.conversationId, new_data)
						if new_data and new_data.has("add"):
							current_r = new_data.receiverId
							for message in new_data.delete:
								for m in get_tree().get_nodes_in_group("message"):
									if m.get_meta("id") == message:
										remove(m)
							var new_message = []
							for message in new_data.add:
								new_message.append(message.id)
								if message.sender == Updatedate.load_game("user_name"):
									var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
									box2.add_to_group("message")
									box2.set_meta("id", message.id)
									if box2.get_node_or_null("HBoxContainer/MarginContainer/VBoxContainer/Label/Button"):
										box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").pressed.connect(func():
											box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").hide()
											remove(box2)
											if !current_r.has(current_c.left(10)):
												current_r.append(current_c.left(10))
											Updatedate.socket.send(JSON.stringify({"type":"delete", "id":message.id, "conversationId":current_c, "receiverId":current_r, "senderId":Updatedate.load_game("user_name")}).to_utf8_buffer())
											)
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
									box2.show()
									$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
								elif message.sender in new_data.receiverId:
									var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
									box2.add_to_group("message")
									box2.set_meta("id", message.id)
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "پشتیبان"
									box2.show()
									$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
								else:
									var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
									box2.add_to_group("message")
									box2.set_meta("id", message.id)
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "کاربر"
									box2.show()
									$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
							await get_tree().create_timer(0.1).timeout
							$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".get_v_scroll_bar().max_value
							scroll = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical
							r.queue_free()
							)
					var d2 = Updatedate.load_messages(user.conversationId)
					current_c = user.conversationId
					Updatedate.change_user(current_c, {"new":0})
					add_list(filter)
					if d2 and d2.has("messages"):
						box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Label2").text = "پیام جدید : 0"
						current_r = d2.receiverId
						for message in d2.messages:
							if message.sender == Updatedate.load_game("user_name"):
								var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
								box2.add_to_group("message")
								box2.set_meta("id", message.id)
								if box2.get_node_or_null("HBoxContainer/MarginContainer/VBoxContainer/Label/Button"):
									box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").pressed.connect(func():
										box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").hide()
										remove(box2)
										if !current_r.has(current_c.left(10)):
											current_r.append(current_c.left(10))
										Updatedate.socket.send(JSON.stringify({"type":"delete", "id":message.id, "conversationId":current_c, "receiverId":current_r, "senderId":Updatedate.load_game("user_name")}).to_utf8_buffer())
										)
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
								box2.show()
								$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
							elif message.sender in d2.receiverId:
								var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
								box2.add_to_group("message")
								box2.set_meta("id", message.id)
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "پشتیبان"
								box2.show()
								$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
							else:
								var box2 = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
								box2.add_to_group("message")
								box2.set_meta("id", message.id)
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.timestamp
								box2.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "کاربر"
								box2.show()
								$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box2)
						await get_tree().create_timer(0.1).timeout
						$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".get_v_scroll_bar().max_value
						scroll = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical
					)
	await get_tree().create_timer(0.2).timeout
	$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".get_v_scroll_bar().max_value
	scroll = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical
func remove(m):
	m.self_modulate.a = 0.0
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").modulate.a = 0.0
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").modulate.a = 0.0
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").modulate.a = 0.0
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emitting = true
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emission_rect_extents = m.size / 2
	m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").position = m.size / 2
	await m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").finished
	m.queue_free() 
func _on_name_text_changed(new_text: String) -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		if child is Button and child.name != "instance":
			child.queue_free()
	if new_text == "":
		for n in groups:
			var btn = $ScrollContainer/VBoxContainer/instance.duplicate()
			var press = false
			var drag = false
			btn.gui_input.connect(func (event:InputEvent):
				if event is InputEventScreenDrag:
					drag = true
					press = false
				elif event is InputEventScreenTouch and event.is_released():
					press = true
					drag = false
				if press and not drag:
					%name.text = btn.text
					DisplayServer.virtual_keyboard_hide()
				)
			btn.text = n
			btn.show()
			$ScrollContainer/VBoxContainer.add_child(btn)
	for n in groups:
		if new_text in n:
			$ScrollContainer.show()
			var btn = $ScrollContainer/VBoxContainer/instance.duplicate()
			var press = false
			var drag = false
			btn.gui_input.connect(func (event:InputEvent):
				if event is InputEventScreenDrag:
					drag = true
					press = false
				elif event is InputEventScreenTouch and event.is_released():
					press = true
					drag = false
				if press and not drag:
					%name.text = btn.text
					DisplayServer.virtual_keyboard_hide()
				
				)
			btn.text = n
			btn.show()
			$ScrollContainer/VBoxContainer.add_child(btn)


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Updatedate.show_picture($"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture)


func _on_texture_rect_gui_input2(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Updatedate.show_picture($"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture)


func _on_sendbutton_pressed() -> void:
	if current_c:
		if !current_r.has(current_c.left(10)):
			current_r.append(current_c.left(10))
		var message = {
			"type":"message",
			"conversationId":current_c,
			"senderId": Updatedate.load_game("user_name"),
			"receiverId": current_r,
			"content": $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/HBoxContainer/TextEdit".text
		}
		Updatedate.socket.send(JSON.stringify(message).to_utf8_buffer())
		$"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/HBoxContainer/TextEdit".text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and $TabContainer.current_tab == 2 and $"TabContainer/پیام ها/TabContainer".current_tab == 1:
		vbox.get_node("ScrollContainer").scroll_vertical = scroll + vbox.get_node("HBoxContainer/TextEdit").size.y - 80

func _on_scroll_container_scroll_ended() -> void:
	scroll = $"TabContainer/پیام ها/TabContainer/گفتگو/VBoxContainer/ScrollContainer".scroll_vertical


func _on_filter_item_selected(index: int) -> void:
	$HBoxContainer/LineEdit.text = ""
	if index == 1:
		$HBoxContainer/LineEdit.max_length = 10
		$HBoxContainer/LineEdit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if index == 2:
		$HBoxContainer/LineEdit.max_length = 11
		$HBoxContainer/LineEdit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if index == 0:
		$HBoxContainer/LineEdit.max_length = 0
		$HBoxContainer/LineEdit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	$HBoxContainer/LineEdit.virtual_keyboard_type = [LineEdit.KEYBOARD_TYPE_DEFAULT, LineEdit.KEYBOARD_TYPE_NUMBER, LineEdit.KEYBOARD_TYPE_PHONE, LineEdit.KEYBOARD_TYPE_DEFAULT][index]


func _on_apply_button_pressed() -> void:
	var w = Updatedate.add_wait($HBoxContainer/Button)
	filter = {["name", "username", "phone", "unseen"][$HBoxContainer/filter.selected]:$HBoxContainer/LineEdit.text}
	await add_list(filter)
	w.queue_free()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		$ScrollContainer.hide()


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	if meta.begins_with("http"):
		OS.shell_open(meta)
	else:
		OS.shell_open("https://"+meta)


func _on_facebutton_pressed() -> void:
	if camera:
		camera.getCameraImage()

func _on_texture_rect_face_detected(imageBuffer: Dictionary) -> void:
	
	var w = Updatedate.add_wait($"TabContainer/فردی/Button2")
	var b = Image.new()
	b.load_jpg_from_buffer(imageBuffer["0"])
	print(b.get_size())
	var http = HTTPRequest.new()
	add_child(http)
	http.request(Updatedate.protocol+Updatedate.subdomin+"/recognize", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":imageBuffer["0"]}))
	var d = await http.request_completed
	while d[3].size() == 0:
		http.request(Updatedate.protocol+Updatedate.subdomin+"/recognize", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"data":imageBuffer["0"]}))
		d = await http.request_completed
	http.queue_free()
	w.queue_free()
	
	var result = Updatedate.get_json(d[3])
	print(d[3].get_string_from_utf8())
	if result:
		if result.has("name"):
			Notification.add_notif("با موفقیت پیدا شد!")
			%id.text = result.name.get_basename()
		else:
			Notification.add_notif(result.result, Notification.ERROR)
