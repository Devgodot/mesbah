extends Control

var groups = []
var users = {}
var tag = 0
var gender = 0
var username = ""
var change = false
var edit_mode = 0
var select_user = 0
var event_user = []
var sended_message = []
var request_group = []
var group_user = []
var birthday
var first_name = ""
var last_name = ""
var father_name = ""
var plugin
var plugin_name = "GodotGetImage"
var mode = 0
var groupmate = []
var camera
var refrence_t
var refrence_a
func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	set_process(false)
	Updatedate.load_user()
	if Engine.has_singleton("GodotGetImage"):
		camera = Engine.get_singleton("GodotGetImage")
		camera.setOptions({"use_front_camera":true})
	if Updatedate.load_game("accept_account", false):
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4.hide()
	if camera:
		camera.image_request_completed.connect(_on_texture_rect_face_detected)
	var wait = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer)
	var wait2 = Updatedate.add_wait($ScrollContainer/VBoxContainer/VBoxContainer2)
	var _user = await Updatedate.load_from_server()
	if not _user:
		Notification.add_notif("حساب شما حذف یا مسدود شده", Notification.ERROR)
		DirAccess.remove_absolute("user://session.dat")
		DirAccess.remove_absolute("user://data.cfg")
		Updatedate.current_user = 0
		await get_tree().create_timer(0.5).timeout
		Transation.change(self, "register.tscn")
	if Updatedate.load_game("accept_account", false):
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4.hide()
	Transation.check_trans()
	if Updatedate.load_game("pro", true):
		refrence_t = $ReferenceRect2.duplicate()
		refrence_t.target = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10/GridContainer.get_child(Transation.trans)
		refrence_t.show()
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10/GridContainer.get_child(Transation.trans).add_child(refrence_t)
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10.show()
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer9.show()
		for x in range($ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10/GridContainer.get_children().size()):
			var child:TextureButton = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10/GridContainer.get_child(x)
			child.pressed.connect(func ():
				Updatedate.save("transation", x)
				Transation.check_trans()
				refrence_t.queue_free()
				refrence_t = $ReferenceRect2.duplicate()
				refrence_t.target = child
				refrence_t.show()
				child.add_child(refrence_t))
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer9/RichTextLabel.text = Updatedate.load_game("custom_name", "[right]" + Updatedate.load_game("first_name", "")+ " "+ Updatedate.load_game("last_name", ""))
	else:
		Transation.trans = 0
		if refrence_t:
			refrence_t.queue_free()
		$ReferenceRect2.hide()
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer10.hide()
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer9.hide()
	Updatedate.socket.close()
	first_name = Updatedate.load_game("first_name", "")
	last_name = Updatedate.load_game("last_name", "")
	father_name = Updatedate.load_game("father_name", "")
	for box in get_tree().get_nodes_in_group("users"):
		box.get_node("LineEdit").text_changed.connect(func(new_text:String):
			box.get_node("Label2").text = ""
			if new_text.length() == 10 and !event_user.has(new_text) and !sended_message.has(new_text):
				
				var d = await Updatedate.request("/users/check?username="+new_text)
				if d and d.has("result"):
					box.get_node("Label2").text = "وجود دارد"
					box.get_node("Label2").label_settings.font_color = Color.DARK_GREEN
					if !event_user.has(new_text):
						event_user.append(new_text)
				else:
					box.get_node("Label2").text = d.message if d and d.has("message") else ""
					box.get_node("Label2").label_settings.font_color = Color.BLACK
			else:
				if new_text.length() == 9:
					for user in event_user:
						if new_text in user:
							event_user.erase(user)
				if event_user.has(new_text) or sended_message.has(new_text):
					box.get_node("Label2").label_settings.font_color = Color.BLACK
					box.get_node("Label2").text = "قبلاً انتخاب شده"
				)
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer/LineEdit.text = first_name
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/LineEdit.text = last_name
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer3/LineEdit.text = father_name
	
	birthday = Updatedate.load_game("birthday", "1380/1/1").split("/")
	
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox2.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox3.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer5/SpinBox.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox.value = int(birthday[2])
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox2.value = int(birthday[1])
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox3.value = int(birthday[0])
	var a = Updatedate.load_game("accounts", [])
	
	for x in range(a.size()):
		var btn:TextureButton = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer8/OptionButton/TextureButton.duplicate()
		Updatedate.get_icon_user("", a[x], btn)
		btn.gui_input.connect(func(event:InputEvent):
			if event is InputEventMouseButton :
				if event.button_index == 1 and event.is_released() and x != Updatedate.current_user:
					Updatedate.save("current_user", x, false)
					Updatedate.save("last_user", x, false)
					Updatedate.current_user = x
					Transation.change(self, "setting.tscn")
				if event.is_pressed() and event.button_index == 2:
					select_user = x
					$Node2D.show()
					$Node2D.position = btn.global_position + btn.size / 2
					$Node2D/AnimationPlayer.play("action")
			)
		if x == Updatedate.current_user:
			refrence_a = $ReferenceRect.duplicate()
			refrence_a.target = btn
			refrence_a.show()
			btn.add_child(refrence_a)
		btn.get_node("Label").text = a[x]
		btn.show()
		%OptionButton.add_child(btn)
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer8/OptionButton/TextureButton.queue_free()
	if %OptionButton.get_children().size() < 11:
		var add = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer8/OptionButton/add.duplicate()
		add.pressed.connect(func():
			Updatedate.save("current_user", %OptionButton.get_children().size() - 1, false)
			Updatedate.last_user = Updatedate.current_user
			Updatedate.current_user = %OptionButton.get_children().size() - 1
			Transation.change(self, "register.tscn")
			)
		add.show()
		%OptionButton.add_child(add)
	$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer8/OptionButton/add.queue_free()
	wait2.queue_free()
	tag = Updatedate.load_game("tag", 0)
	gender = Updatedate.load_game("gender", 0)
	username = Updatedate.load_game("user_name", "")
	Updatedate.get_icon_user(Updatedate.load_game("icon", ""), username, $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer7/Button/TextureRect)
	var d = await Updatedate.request("/auth/get?name=group_nameANDusers_sended_message")
	if d and d.has("nums") and d.nums[0] != null and d.nums[0] != "":
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button.group_name = d.nums[0]
		var group = await Updatedate.request("/groups/get?name="+d.nums[0].uri_encode())
		sended_message = d.nums[1] if d.nums[1] != null else []
		if group != null and group.has("users"):
			var u = []
			for user in group.users:
				u.append(custom_hash.hashing(custom_hash.GET_HASH, user))
			group_user = u
			group_user.erase(custom_hash.hashing(custom_hash.GET_HASH,group.leader))
		if username == custom_hash.hashing(custom_hash.GET_HASH,group.leader):
			if group.icon:
				Updatedate.get_icon_group(custom_hash.hashing(custom_hash.GET_HASH,group.icon), d.nums[0], $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button/TextureRect)
			if sended_message.size() + group_user.size() == 4:
				$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Label2.hide()
				$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button2.hide()
			if d.nums[0] != "":
				$ScrollContainer/VBoxContainer/TabContainer.current_tab = 2
				$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer/LineEdit.text = d.nums[0]
				var index = 0
				for x in range(group_user.size()):
					var user = group_user[x]
					var num = ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم", "دهم"][index]
					var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer2.duplicate()
					box.get_node("Label").text = "عضو " + num + " : "
					box.get_node("name/texture/Label").text = group.users_info[x + 1].custom_name if group.users_info[x + 1].has("custom_name") else "[center]"+ group.users_info[x + 1].name
					box.show()
					groupmate.append(box)
					$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3.add_child(box)
					await get_tree().create_timer(0.1).timeout
					box.get_node("name/texture").size = box.get_node("name").size
					box.get_node("name").texture = box.get_node("name/texture").get_texture()
					if box.get_node("name/texture/Label").size.x > box.get_node("name").size.x:
						box.get_node("name/texture").size.x = box.get_node("name/texture/Label").size.x * 1.5
						box.get_node("name/texture").size.y = box.get_node("name/texture/Label").size.y
						var shader =$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer2/name.material.shader
						var _material = ShaderMaterial.new()
						_material.shader = shader
						_material.set_shader_parameter("dir", get_direction(group.users_info[x + 1].name))
						box.get_node("name").material = _material
					index += 1
				for x in range(d.nums[1].size()):
					var user = d.nums[1][x]
					var num = ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم", "دهم"][index]
					var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer2.duplicate()
					box.get_node("Label2").text = "در انتظار تایید"
					box.get_node("Label").text = "عضو " + num
					box.get_node("Label2").show()
					box.show()
					groupmate.append(box)
					$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3.add_child(box)
					index += 1
					box.get_node("name/texture/Label").text = "[center]"+user
					box.get_node("name/texture").size = box.get_node("name").size
					box.get_node("name").texture = box.get_node("name/texture").get_texture()
					
		else:
			if d.nums[0] != "":
				if group.icon:
					Updatedate.get_icon_group(custom_hash.hashing(custom_hash.GET_HASH,group.icon), d.nums[0], $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer7/TextureRect)
					$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer7/TextureRect.gui_input.connect(func (event:InputEvent):
						if event is InputEventScreenTouch and event.is_pressed():
							Updatedate.show_picture($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer7/TextureRect.texture)
						)
					
				$ScrollContainer/VBoxContainer/TabContainer.current_tab = 3
				$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer/LineEdit.text = d.nums[0]
				var b = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer2.duplicate()
				b.get_node("Label").text = "سر گروه :"
				b.show()
				b.get_node("name/texture/Label").text = group.users_info[0].custom_name if group.users_info[0].has("custom_name") else "[center]"+ group.users_info[0].name
				$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4.add_child(b)
				await get_tree().create_timer(0.1).timeout
				b.get_node("name/texture").size = b.get_node("name").size
				b.get_node("name").texture = b.get_node("name/texture").get_texture()
				if b.get_node("name/texture/Label").size.x > b.get_node("name").size.x:
					b.get_node("name/texture").size.x = b.get_node("name/texture/Label").size.x * 2
					b.get_node("name/texture").size.y = b.get_node("name/texture/Label").size.y
					var shader =$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer2/name.material.shader
					var _material = ShaderMaterial.new()
					_material.shader = shader
					_material.set_shader_parameter("dir", get_direction(group.users_info[0].name))
					b.get_node("name").material = _material
				
				for x in range(group_user.size()):
					var user = group_user[x]
					var num = ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم", "دهم"][x]
					var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer2.duplicate()
					box.get_node("Label").text = "عضو " + num + " : "
					box.get_node("name/texture/Label").text = group.users_info[x + 1].custom_name if group.users_info[x + 1].has("custom_name") else "[center]"+ group.users_info[x + 1].name
					box.show()
					groupmate.append(box)
					$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4.add_child(box)
					await get_tree().create_timer(0.1).timeout
					box.get_node("name/texture").size = box.get_node("name").size
					box.get_node("name").texture = box.get_node("name/texture").get_texture()
					if box.get_node("name/texture/Label").size.x > box.get_node("name").size.x:
						box.get_node("name/texture").size.x = box.get_node("name/texture/Label").size.x * 2
						box.get_node("name/texture").size.y = box.get_node("name/texture/Label").size.y
						var shader =$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer2/name.material.shader
						var _material = ShaderMaterial.new()
						_material.shader = shader
						_material.set_shader_parameter("dir", get_direction(d.users_info[x + 1].name))
						box.get_node("name").material = _material
	wait.queue_free()
	set_process(true)
	for x in range(a.size()):
		var btn = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer8/OptionButton.get_child(x)
		var d2 = await Updatedate.request("/users/icon?username="+a[x])
		Updatedate.get_icon_user(d2.icon if d2.has("icon") else "", a[x], btn)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	%OptionButton.get_child(Updatedate.current_user).texture_normal = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer7/Button/TextureRect.texture
	if $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer/LineEdit.text != first_name or $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/LineEdit.text != last_name or $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer3/LineEdit.text != father_name \
	or $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox.value != int(birthday[2]) or $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox2.value != int(birthday[1]) or $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox3.value != int(birthday[0]):
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer6/Button.disabled = false
	else:
		$ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer6/Button.disabled = true
	var correct_group_name = true
	if groups.has(%group_name.text):
		correct_group_name = false
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer/Label2.text = "گروه وجود دارد"
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer/Label2.label_settings.font_color = Color.RED
	else:
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer/Label2.text = "گروه وجود ندارد"
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer/Label2.label_settings.font_color = Color.DARK_GREEN
	
	
	var s:PackedStringArray = %group_name.text.split(" ")
	var s2:PackedStringArray = %group_name.text.split("‌‌")
	var not_Space = false
	var not_Space2 = false
	for g in s:
		g = g.replace("‌", "")
		if g != "" and g != "‌" and g != "‌ ":
			not_Space = true
	for g in s2:
		g = g.replace(" ", "")
		if g != "" and g != "‌" and g != "‌ ":
			not_Space2 = true
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button.disabled = event_user.size() <= 0
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer6/Button.disabled = not (correct_group_name and %group_name.text != "" and %group_name.text != "‌" and not_Space and not_Space2)
	
func _on_button_pressed() -> void:
	var w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer/Button)
	$ScrollContainer/VBoxContainer/TabContainer.current_tab = 1
	var d = await Updatedate.request("/groups/names")
	var g = d.data if d and d.has("data") else []
	groups = []
	for n in g:
		groups.append(n[0])
	w.queue_free()


func _on_button_2_pressed() -> void:
	$ScrollContainer/VBoxContainer/TabContainer.current_tab = 0
func _on_error(e):
	var dialog = get_node("AcceptDialog")
	dialog.window_title = "Error!"
	dialog.dialog_text = e
	dialog.show()


func _on_okey_pressed() -> void:
	var icon_group = ""
	var z = str(randi_range(0, 100000))
	var w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer6/Button)
	if $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer7/Button/TextureRect.texture != null:
		var r2 = HTTPRequest.new()
		get_tree().get_root().add_child(r2)
		var img :Image= $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer7/Button/TextureRect.texture.get_image()
		if !DirAccess.dir_exists_absolute("user://group_icon"):
			DirAccess.make_dir_absolute("user://group_icon")
		img.save_webp("user://group_icon/"+%group_name.text+z+".webp")
		r2.request(Updatedate.protocol+Updatedate.subdomin+"/upload", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"name":%group_name.text+z+".webp", "data":img.save_webp_to_buffer()}))
		var e = await r2.request_completed
		var err = Updatedate.get_json(e[3])
		if err and err.has("error"):
			$AcceptDialog.title = "خطا"
			$AcceptDialog.dialog_text = err.error
			$AcceptDialog.popup()
		r2.queue_free()
		icon_group = Updatedate.protocol+Updatedate.subdomin+"/static/files/users/"+Updatedate.load_game("phone", "")+"/"+(%group_name.text+z).uri_encode()+".webp"
	var r = HTTPRequest.new()
	add_child(r)
	r.request(Updatedate.protocol+Updatedate.subdomin+"/groups/create", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"group_name":%group_name.text, "event_user":event_user, "icon":icon_group}))
	var d = await r.request_completed
	var data = Updatedate.get_json(d[3])
	while d[3].size() == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/groups/create", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"group_name":%group_name.text, "event_user":event_user, "icon":icon_group}))
		d = await r.request_completed
		data = Updatedate.get_json(d[3])
	
	r.queue_free()
	if data and data.message == "successe":
		$ScrollContainer/VBoxContainer/TabContainer.current_tab = 2
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer/LineEdit.text = %group_name.text
		for x in range(event_user.size()):
			var user = event_user[x]
			var num = ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم", "دهم"][x]
			var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer2.duplicate()
			box.get_node("name/texture/Label").text = "[center]"+user
			box.get_node("Label2").text = "در انتظار تایید"
			box.get_node("Label").text = "عضو " + num
			box.get_node("Label2").show()
			box.show()
			groupmate.append(box)
			$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3.add_child(box)
			await get_tree().create_timer(0.1).timeout
			box.get_node("name/texture").size = box.get_node("name").size
			box.get_node("name").texture = box.get_node("name/texture").get_texture()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button.group_name = %group_name.text
	event_user = []
	w.queue_free()

func _on_add_user_pressed() -> void:
	event_user = []
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button2.show()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button.show()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer3.show()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button2.hide()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Label2.hide()


func _on_cancel_pressed() -> void:
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button2.hide()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button.hide()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer3.hide()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button2.show()
	$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Label2.show()

func _on_send_event_pressed() -> void:
	if event_user.size() == 1:
		var w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button)
		var r = HTTPRequest.new()
		add_child(r)
		r.timeout = 5
		r.request(Updatedate.protocol+Updatedate.subdomin+"/users/event", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"group_name":$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer/LineEdit.text, "user":event_user[0]}))
		var d = await r.request_completed
		var data = Updatedate.get_json(d[3])
		while d[3].size() == 0:
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/event", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"group_name":$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer/LineEdit.text, "user":event_user[0]}))
			d = await r.request_completed
			data = Updatedate.get_json(d[3])
		r.queue_free()
		if data and data.message == "successe":
			var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer2.duplicate()
			box.get_node("LineEdit").text = %LineEdit.text
			%LineEdit.text = ""
			sended_message.append(%LineEdit.text)
			var num = ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم", "دهم"][group_user.size() + sended_message.size() - 1]
			box.get_node("Label2").text = "در انتظار تایید"
			box.get_node("Label").text = "عضو " + num
			box.get_node("Label2").show()
			box.show()
			groupmate.append(box)
			$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3.add_child(box)
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button2.hide()
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/Button.hide()
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer3.hide()
		if group_user.size() + sended_message.size() < 4:
			$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button2.show()
			$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Label2.show()
		w.queue_free()

func _on_edit_pressed() -> void:
	birthday = str(int($ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox3.value), "/", int($ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox2.value), "/", int($ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer4/SpinBox.value))
	first_name = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer/LineEdit.text
	last_name = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/LineEdit.text
	father_name = $ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer3/LineEdit.text
	Updatedate.multy_save({"first_name":first_name, "last_name":last_name, "father_name":father_name, "birthday":birthday})
	Notification.add_notif("با موفقیت بروز شد")
	birthday = birthday.split("/")
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if $ColorRect2.visible:
			$ColorRect2.hide()
		else:
			Transation.change(self, "start.tscn", -1)
func _on_change_icon_pressed() -> void:
	if plugin:
		plugin.getGalleryImage()
		mode = 0
func _on_permission_not_granted_by_user(permission):
	plugin.resendPermission()
func fillter_group(_name):
	var g = []
	var l = []
	for leader in group_user:
		l.append(leader[0])
	for n in groups:
		if _name in n[0] and n[1] < 5 and n[2] == tag and n[3] == gender and !l.has(n[5]):
			g.append(n)
	for child in $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/MarginContainer/ScrollContainer/VBoxContainer.get_children():
		if child.name != "instanse":
			child.queue_free()
	if g.size() == 0:
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/MarginContainer/Control/Label.show()
	else:
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/MarginContainer/Control/Label.hide()
	for m in g:
		var box = $ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/MarginContainer/ScrollContainer/VBoxContainer/instanse.duplicate()
		box.show()
		box.get_node("Label").text = "نام گروه : " + m[0]
		box.get_node("Label2").text = "اعضا: " + str(m[1] , " / ", 5)
		box.get_node("TextureRect/TextureRect")
		box.get_node("TextureRect/TextureRect").gui_input.connect(func (event:InputEvent):
			if event is InputEventScreenTouch:
				if event.is_pressed():
					Updatedate.show_picture(box.get_node("TextureRect/TextureRect").texture))
		Updatedate.get_icon_group(custom_hash.hashing(custom_hash.GET_HASH,m[4]), m[0], box.get_node("TextureRect/TextureRect"))
		box.get_node("Button").pressed.connect(func():
			Updatedate.request("/users/request?group_name="+m[0].uri_encode())
			box.queue_free()
			groups.erase(m)
			g.erase(m))
		$ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/MarginContainer/ScrollContainer/VBoxContainer.add_child(box)
func join_pressed() -> void:
	$ScrollContainer/VBoxContainer/TabContainer.current_tab = 4
	var w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer/Button2)
	var d = await Updatedate.request("/groups/names")
	var d2 = await Updatedate.request("/auth/get?name=users_request")
	request_group = d2.nums[0] if d2 and d2.has("nums") else []
	groups = d.data if d and d.has("data") else []
	w.queue_free()
func _on_fillter_button_pressed() -> void:
	fillter_group($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer5/HBoxContainer/LineEdit.text)

func _on_left_pressed() -> void:
	sended_message = []
	event_user = []
	var w
	if $ScrollContainer/VBoxContainer/TabContainer.current_tab == 2:
		w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer3/HBoxContainer7/Button3)
	if $ScrollContainer/VBoxContainer/TabContainer.current_tab == 3:
		w = Updatedate.add_wait($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer7/Button3)
	
	await Updatedate.request("/auth/left_group")
	w.queue_free()
	for user in groupmate:
		user.queue_free()
	groupmate = []
	$ScrollContainer/VBoxContainer/TabContainer.current_tab = 0


func _on_back_pressed() -> void:
	$ScrollContainer/VBoxContainer/TabContainer.current_tab = 0


func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		DisplayServer.virtual_keyboard_hide()
		$ColorRect2.hide()
		if $Node2D.visible and not $Node2D/AnimationPlayer.is_playing():
			$Node2D/AnimationPlayer.play_backwards("action")
			await $Node2D/AnimationPlayer.animation_finished
			$Node2D.hide()


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	Updatedate.show_picture($ScrollContainer/VBoxContainer/TabContainer/VBoxContainer4/HBoxContainer7/TextureRect.texture)


func _on_spin_box_value_changed(value: float) -> void:
	Updatedate.save("max_notif", value)
	Updatedate.save("show_notif", bool(value))
	Notification.max_notif = value
	if value:
		Notification.add_notif("با موفقیت بروز شد")


func _on_edit_name_pressed() -> void:
	Transation.change(self, "editname.tscn")


func _on_texture_rect_face_detected(imageBuffer: Dictionary) -> void:
	print(mode)
	if mode == 4:
		var w = Updatedate.add_wait($ScrollContainer/VBoxContainer/VBoxContainer2/HBoxContainer7/Button2)
		var image = Image.new()
		image.load_jpg_from_buffer(imageBuffer["0"])
		var http = HTTPRequest.new()
		add_child(http)
		http.request(Updatedate.protocol+Updatedate.subdomin+"/upload", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"name":"", "data":imageBuffer["0"], "type":"face"}))
		var d = await http.request_completed
		while d[3].size() == 0:
			http.request(Updatedate.protocol+Updatedate.subdomin+"/upload", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"name":"", "data":imageBuffer["0"], "type":"face"}))
			d = await http.request_completed
		image.save_webp("user://"+Updatedate.load_game("user_name", "")+".webp")
		http.queue_free()
		w.queue_free()
		Notification.add_notif("با موفقیت ثبت شد!")


func _on_face_button_pressed() -> void:
	if camera:
		mode = 4
		camera.getCameraImage()


func _on_delete_account_pressed() -> void:
	if FileAccess.file_exists("user://session.dat"):
		var file = FileAccess.open("user://session.dat", FileAccess.READ_WRITE)
		var d = file.get_var()
		if d is Array:
			if select_user < d.size():
				d.remove_at(select_user)
				var a = Updatedate.load_game("accounts", [])
				a.remove_at(select_user)
				Updatedate.save("accounts", a, false)
				file.store_var(d)
				file.close()
			if d.size() > 0:
				Updatedate.current_user = 0
				Transation.change(self, "setting.tscn")
			else:
				Updatedate.current_user = 0
				Updatedate.save("last_user", 0, false)
				Transation.change(self, "register.tscn")


func _on_edit_phone_pressed() -> void:
	edit_mode = 1
	$ColorRect2.show()
	$ColorRect2/Panel/MarginContainer/VBoxContainer/Label.text = "شماره تلفن جدید خود را وارد کنید."
	$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.text = ""
	$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.max_length = 11

func _on_save_button_pressed() -> void:
	var w = Updatedate.add_wait($ColorRect2/Panel/MarginContainer/VBoxContainer/Button)
		
	if edit_mode == 0:
		if $ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.text.length() < 10:
			Notification.add_notif("کد ملی باید ده رقم باشد", Notification.ERROR)
			w.queue_free()
			return 
		var d = await Updatedate.request("/auth/change_username?new="+$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.text)
		if d and d.has("tokens"):
			var file = FileAccess.open("user://session.dat", FileAccess.READ_WRITE)
			var d2 = file.get_var()
			d2.remove_at(select_user)
			d2.append(d.tokens)
			var a = Updatedate.load_game("accounts", [])
			a.remove_at(select_user)
			a.append(d.username)
			Updatedate.save("accounts", a, false)
			file.store_var(d)
			file.close()
			for img in DirAccess.get_files_at("user://users_icon"):
				if username in img:
					DirAccess.rename_absolute("user://users_icon/"+img, "user://users_icon/"+d.img)
			
			Notification.add_notif(d.message)
			Transation.change(self, "setting.tscn")
		else:
			if d and d.has("error"):
				Notification.add_notif(d.error, Notification.ERROR)
	if edit_mode == 1:
		var d = await Updatedate.request("/auth/change_phonee?phone="+$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.text)
		if d and d.has("error"):
			Notification.add_notif(d.error, Notification.ERROR)
		if d and d.has("message"):
			Notification.add_notif(d.message)
	w.queue_free()
func _on_user_name_button_pressed() -> void:
	edit_mode = 0
	$ColorRect2.show()
	$ColorRect2/Panel/MarginContainer/VBoxContainer/Label.text = "کد ملی جدید خود را وارد کنید."
	$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.text = ""
	$ColorRect2/Panel/MarginContainer/VBoxContainer/LineEdit.max_length = 10
	
	
