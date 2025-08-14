extends Control

var plugin 
var plugin_name = "GodotGetImage"
var dialog
var search_type = 0
var search_type2 = 0
var groups = []
var upload_request = HTTPRequest.new()
var selected_users = []
var subplan
var saved_users = []
var subplanes = []
var subplanes2 = []
var plan_name = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	
	$"TabContainer/1/TabContainer".set_tab_title(0, "تغییر برنامه")
	$"TabContainer/1/TabContainer".set_tab_title(1, "تعریف برنامه")
	$"TabContainer/1/TabContainer".set_tab_title(2, "رتبه بندی")

	$SystemBarColorChanger.set_navigation_bar_color(Color("e9c93a"))
	RenderingServer.set_default_clear_color(Color("e9c93a"))
	add_child(upload_request)
	Updatedate.load_user()
	get_plan_by_year($"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/HBoxContainer/HBoxContainer/SpinBox".value)
	add_message()
	saved_users = Updatedate.load_game("saved_users", [])
	add_saved_users()
	
	for spin in get_tree().get_nodes_in_group("spin"):
		if spin is SpinBox:
			spin.get_line_edit().virtual_keyboard_type = LineEdit.VirtualKeyboardType.KEYBOARD_TYPE_NUMBER
	if Engine.has_singleton("GodotGetFile"):
		dialog = Engine.get_singleton("GodotGetFile")
	if dialog:
		dialog.requestFilePermissions()
		dialog.permission_not_granted_by_user.connect(func (e):
			dialog.resendPermission()
			)
		dialog.error.connect(func (e):
			Notification.add_notif(e, Notification.ERROR)
			$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".hide()
			$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".stream = null
			$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".set_audio(AudioStream.new())
			$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".ext = "")
		dialog.permission_granted.connect(func ():print(1))
		dialog.file_selected.connect(_on_file_dialog_file_selected)
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
	if plugin:
		plugin.error.connect(func(e):
			$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture = null
			Notification.add_notif("تصویری انتخاب نشد", Notification.ERROR))
		plugin.permission_not_granted_by_user.connect(func (permission):
			plugin.resendPermission())
	if plugin:
		var options = {
		"image_height" : 600,
		"image_width" : 600,
		"keep_aspect" : false,
		"image_format" : "jpg"
		}
		plugin.setOptions(options)
		plugin.image_request_completed.connect(func (dic):
			for Buffer in dic.values():
				var img = Image.new()
				img.load_jpg_from_buffer(Buffer)
				$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture = ImageTexture.create_from_image(img)
		)
	
	$AudioStreamRecord.state = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Label3"
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button2".pressed.connect(func():
		dialog.openFileDialog()
			)
	add_ticket()
	if Updatedate.load_game("user_name","") == "5100276150":
		%type.add_item("مدیرها")
	await get_tree().create_timer(0.1).timeout
	show()
func _on_button_4_pressed() -> void:
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Label3".hide()
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button3".hide()
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button4".hide()
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".set_audio($AudioStreamRecord.effect.get_recording())
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".show()
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button2".show()
	$AudioStreamRecord.effect.set_recording_active(false)
	$Timer.stop()


func _on_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var stream
	if path.get_file().get_extension() == "mp3":
		stream = AudioStreamMP3.new()
	if path.get_file().get_extension() == "wav":
		stream = AudioStreamWAV.new()
	if stream:
		stream.data = file.get_file_as_bytes(path)
		$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".ext = path.get_file().get_extension()
		$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".show()
		$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".set_audio(stream)
		file.close()
	else:
		Notification.add_notif("فقط فرمت mp3 و wav قابل پذیرش است", Notification.ERROR, load("res://sound/mixkit-wrong-answer-fail-notification-946.wav"))


func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
	

func _on_type_item_selected(index: int) -> void:
	add_editor(index, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2/OptionButton".selected)
	if index == 0:
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4".hide()
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2".hide()
	if index == 1:
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4".show()
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2".show()
	if index == 2:
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3".hide()
	else:
		$"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3".show()

func _on_add_editor_pressed() -> void:
	var w = Updatedate.add_wait($"TabContainer/2/VBoxContainer/BoxContainer/add_editor")
	var r = HTTPRequest.new()
	add_child(r)
	var type = %type.selected
	var part = $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3/OptionButton".selected
	var gender = $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4/OptionButton".selected
	var tag = $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2/OptionButton".selected
	if type == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_editor", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text, "part":part}))
	if type == 1:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_supporter", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text, "part":part, "gender":gender, "tag":tag}))
	if type == 2:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_management", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text}))
	var body = await r.request_completed
	r.timeout = 10
	while body[3].size() == 0:
		if type == 0:
			r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_editor", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text, "part":part}))
		if type == 1:
			r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_supporter", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text, "part":part, "gender":gender, "tag":tag}))
		if type == 2:
			r.request(Updatedate.protocol+Updatedate.subdomin+"/control/add_management", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":$"TabContainer/2/VBoxContainer/BoxContainer/HBoxContainer/LineEdit".text}))
	
		body = await r.request_completed
	r.queue_free()
	w.queue_free()
	var d2 = Updatedate.get_json(body[3])
	if d2.has("error"):
		Notification.add_notif(d2.error, Notification.ERROR)
		return
	if d2.has("data"):
		add_editor(type, part, gender, tag, d2.data)
	if d2.has("message"):
		Notification.add_notif(d2.message, Notification.SUCCESS)
	


func _on_tab_container_tab_selected(tab: int) -> void:
	if tab == 2:
		var d = await Updatedate.request("/groups/names")
		var g = d.data if d and d.has("data") else []
		groups = []
		for n in g:
			groups.append(n[0])
	if tab == 3:
		add_editor(%type.selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2/OptionButton".selected)
func add_editor(type, part, gender=0, tag=0, _data=[]):
	var d = {}
	var w = Updatedate.add_wait($"TabContainer/2/VBoxContainer/ScrollContainer")
	for child in $"TabContainer/2/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
		if "instance" not in child.name:
			child.queue_free()
	
	if _data.size() == 0:
		if type == 0:
			d = await Updatedate.request("/control/get_editors?part="+str(part))
		if type == 1:
			d = await Updatedate.request("/control/get_supporters?part={0}&gender={1}&tag={2}".format([part, gender, tag]))
		if type == 2:
			d = await Updatedate.request("/control/get_management")
	
	var data = d.data if d.has("data") else _data
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)
		return
	
	for user in data:
		var box = $"TabContainer/2/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
		box.show()
		Updatedate.get_icon_user(user.icon if user.has("icon") else "", user.username, box.get_node("MarginContainer/BoxContainer/VBoxContainer2/TextureRect"))
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer/RichTextLabel").text = "[right]" + user.first_name + " " + user.last_name
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer3/RichTextLabel").text = "[right]" + user.father_name
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label").text = "شماره تلفن : " + user.phone
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label2").text = "کد ملی : " + user.username
		if user.has("management"):
			box.get_node("MarginContainer/BoxContainer/VBoxContainer2/Button").hide()
		box.get_node("MarginContainer/BoxContainer/VBoxContainer2/Button").pressed.connect(func():
			var w2 = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer2/Button"))
			var r = HTTPRequest.new()
			add_child(r)
			if type == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_editor", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "part":part}))
			if type == 1:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_supporter", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "part":part, "gender":gender, "tag":tag}))
			if type == 2:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_management", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username}))
			
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				if type == 0:
					r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_editor", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "part":part}))
				if type == 1:
					r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_supporter", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "part":part, "gender":gender, "tag":tag}))
				if type == 2:
					r.request(Updatedate.protocol+Updatedate.subdomin+"/control/remove_management", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username}))
			
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w2.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
				return
			if d2.has("data"):
				add_editor(type, part, gender, tag, d2.data)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				
			)
		$"TabContainer/2/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
	w.queue_free()

func _on_editor_part_selected(index: int) -> void:
	add_editor(%type.selected, index, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2/OptionButton".selected)


func _on_gender_supporter_selected(index: int) -> void:
	add_editor(%type.selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3/OptionButton".selected, index, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer2/OptionButton".selected)



func _on_tag_supporter_selected(index: int) -> void:
	add_editor(%type.selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer3/OptionButton".selected, $"TabContainer/2/VBoxContainer/BoxContainer/BoxContainer4/OptionButton".selected, index)


func _on_option_button_item_selected(index: int) -> void:
	%search.text = ""
	search_type = index
	match index:
		0:
			%search.alignment = HORIZONTAL_ALIGNMENT_CENTER
			%search.max_length = 0
			%search.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
		1:
			%search.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			%search.max_length = 10
			%search.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		2:
			%search.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			%search.max_length = 11
			%search.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PHONE
		3:
			%search.alignment = HORIZONTAL_ALIGNMENT_CENTER
			%search.max_length = 20
			%search.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT


func _on_search_pressed() -> void:
	$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2".hide()
	if %search.text != "":
		var d 
		var w = Updatedate.add_wait($"TabContainer/4/VBoxContainer/ScrollContainer")
		var w3 = Updatedate.add_wait($"TabContainer/4/VBoxContainer/BoxContainer/Button")
		
		match search_type:
			0:
				d = await Updatedate.request("/control/get_users?name="+%search.text.uri_encode())
			1:
				d = await Updatedate.request("/control/get_users?username="+%search.text)
			2:
				d = await Updatedate.request("/control/get_users?phone="+%search.text)
			3:
				d = await Updatedate.request("/control/get_group?name="+%search.text.uri_encode())
		
		if d.has("data"):
			if search_type != 3:
				add_users(d.data)
			else:
				$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture = null
				$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2".show()
				var data = d.data
				$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer/RichTextLabel".text = %search.text
				$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer3/Label".text = "امتیاز : " + str(d.score)
				$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer3/Label2".text = "الماس : " + str(d.diamonds)
				Updatedate.get_icon_group(d.icon, %search.text, $"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/BoxContainer/TextureRect")
				for x in range(5):
					var box = $"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance2/MarginContainer/VBoxContainer/GridContainer".get_child(x)
					if x >= data.size():
						box.hide()
					else:
						box.get_node("BoxContainer/RichTextLabel").text = data[x].first_name + " " + data[x].last_name if data[x].has("first_name") else ""
						box.get_node("BoxContainer2/RichTextLabel").text = data[x].phone if data[x].has("phone") else ""
						box.get_node("BoxContainer3/RichTextLabel").text = data[x].username if data[x].has("username") else ""
						
						box.get_node("Button").pressed.connect(func():
							var w2 = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button"))
							var r = HTTPRequest.new()
							add_child(r)
							r.request(Updatedate.protocol+Updatedate.subdomin+"/control/left_group", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":data[x].username}))
							var body = await r.request_completed
							r.timeout = 10
							while body[3].size() == 0:
								r.request(Updatedate.protocol+Updatedate.subdomin+"/control/left_group", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":data[x].username}))
								body = await r.request_completed
							r.queue_free()
							var d2 = Updatedate.get_json(body[3])
							w2.queue_free()
							if d2.has("error"):
								Notification.add_notif(d2.error, Notification.ERROR)
							if d2.has("message"):
								Notification.add_notif(d2.message, Notification.SUCCESS)
								_on_search_pressed())
		if d.has("error"):
			Notification.add_notif(d.error, Notification.ERROR)
		w.queue_free()
		w3.queue_free()
func _process(delta: float) -> void:
	$Window.visible = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/Button2".button_pressed
	$ScrollContainer.visible = %search.has_focus() and search_type == 3
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/message/TextEdit".text = %message.text
	%message.scroll_fit_content_height = not ($"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/message/TextEdit".size.y > %message.get_line_height() * 5)
	$Window/MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel.text = "[right]"+%message.text
	if $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture != null:
		$Window/MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/TextureRect.show()
		$Window/MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/TextureRect.texture = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture
	else:
		$Window/MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/TextureRect.hide()
	if %message.scroll_fit_content_height:
		%message.custom_minimum_size.y =  %message.get_line_height() * 1
	else:
		%message.custom_minimum_size.y =  %message.get_line_height() * 5
func add_users(data):
	for child in $"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
		if "instance" not in child.name:
			child.queue_free()
	for user in data:
		var box = $"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
		Updatedate.get_icon_user(user.icon if user.has('icon') else "", user.username, box.get_node("MarginContainer/BoxContainer/TextureRect"))
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer/RichTextLabel").text = user.custom_name if user.has("custom_name") else "[right]" + user.first_name + " " + user.last_name if user.has("first_name") and user.has("last_name") else "[right]بدون نام"
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label").text = "شماره تلفن : " + user.phone if user.has("phone") else ""
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label2").text = "کد ملی : " + user.username 
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer3/Label").text = "امتیاز : " + str(int(user.score)) if user.has("score") else "امتیاز : 0"
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer3/Label2").text = "الماس : " + str(int(user.diamonds)) if user.has("diamonds") else "الماس : 0"
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/gender_edit").select(user.gender if user.has("gender") else 0)
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox").button_pressed = user.pro if user.has("pro") else false
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox2").button_pressed = user.block if user.has("block") else false
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox3").button_pressed = user.accept_account if user.has("accept_account") else false
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer8/CheckBox").button_pressed = bool(user.nationality) if user.has("nationality") else false
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Label").text = "بلیط قطار: "+ user.time if user.has("time") else "بلیط قطار: کاربر بلیطی ندارد."
		if not user.has("time"):
			box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Button").hide()
		box.show()
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Button").pressed.connect(func():
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Button"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/remove_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "time":user.time}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/remove_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "time":user.time}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Label").text = "بلیط قطار: کاربر بلیطی ندارد."
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer7/Button").hide()
			)
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/Button").pressed.connect(func():
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/Button"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/control/change_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "gender":box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/gender_edit").selected}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/control/change_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "gender":box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/gender_edit").selected}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS))
		var day = box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button3")
		var month = box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button4")
		var year = box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button5")
		var birthday = user.birthday.split("/")
		day.text = birthday[2]
		month.text = birthday[1]
		year.text = birthday[0]
		day.pressed.connect(func():
			var s = Updatedate.load_scene("scroll_button.tscn")
			var items = []
			var d = 30
			var m = month.text
			var y = year.text
			if int(m) < 7:
				d = 31
			if int(m) == 12:
				d = 29 if int(y) % 4 != 3 else 30
			for x in range(d):
				if x < 10:
					items.append(str("0", x+1))
				else:
					items.append(str(x+1))
			for x in range(items.size()):
				if day.text == items[x]:
					s.current = -x
			s.select.connect(func(item):
				day.text = item)
			s.items = items
			add_child(s))
		month.pressed.connect(func():
			var s = Updatedate.load_scene("scroll_button.tscn")
			var items = []
			for x in range(12):
				if x < 9:
					items.append(str("0", x+1))
				else:
					items.append(str(x+1))
			for x in range(items.size()):
				if month.text == items[x]:
					s.current = -x
			s.select.connect(func(item):
				month.text = item)
			s.items = items
			add_child(s))
		year.pressed.connect(func():
			var s = Updatedate.load_scene("scroll_button.tscn")
			var items = []
			for x in range(1300, 1450):
				if x < 10:
					items.append(str("0", x))
				else:
					items.append(str(x))
			for x in range(items.size()):
				if year.text == items[x]:
					s.current = -x
			s.select.connect(func(item):
				year.text = item)
			s.items = items
			add_child(s))
			
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button").pressed.connect(func():
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer6/Button"))
			var r = HTTPRequest.new()
			add_child(r)
			var new_birthday = str(year.text, "/", month.text, "/", day.text)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "birthday":new_birthday}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "birthday":new_birthday}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS))
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/Button").pressed.connect(func():
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/Button"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/control/change_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "gender":box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/gender_edit").selected}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/control/change_user", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "gender":box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer4/gender_edit").selected}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS))
		
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox").toggled.connect(func (toggled):
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"pro":toggled}}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"pro":toggled}}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				)
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer8/CheckBox").toggled.connect(func (toggled):
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer8/CheckBox"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"nationality":toggled}}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"nationality":toggled}}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				)
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox2").toggled.connect(func (toggled):
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox2"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"block":toggled}}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"block":toggled}}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				)
		box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox3").toggled.connect(func (toggled):
			var w = Updatedate.add_wait(box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer5/CheckBox3"))
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"accept_account":toggled}}))
			var body = await r.request_completed
			r.timeout = 10
			while body[3].size() == 0:
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/update", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"username":user.username, "data":{"accept_account":toggled}}))
				body = await r.request_completed
			r.queue_free()
			var d2 = Updatedate.get_json(body[3])
			w.queue_free()
			if d2.has("error"):
				Notification.add_notif(d2.error, Notification.ERROR)
			if d2.has("message"):
				Notification.add_notif(d2.message, Notification.SUCCESS)
				)
		$"TabContainer/4/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)


func _on_search_text_changed(new_text: String) -> void:
	if search_type == 3:
		for child in $ScrollContainer/VBoxContainer.get_children():
			if child.name != "instance" and child is Button:
				child.queue_free()
		for g in groups:
			if new_text in g:
				var btn = $ScrollContainer/VBoxContainer/instance.duplicate()
				btn.text = g
				btn.gui_input.connect(func(event:InputEvent):
					if event is InputEventMouseButton and event.double_click:
						%search.text = g)
				btn.show()
				$ScrollContainer/VBoxContainer.add_child(btn)


func _on_image_button_pressed() -> void:
	if plugin:
		plugin.getGalleryImage()


func _on_send_message_pressed() -> void:
	var data = {}
	data["text"] = %message.text
	data["users"] = "all"
	var tags = []
	var w = Updatedate.add_wait($"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/Button")
	for x in range($"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer2/GridContainer".get_children().size()):
		var child = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer2/GridContainer".get_child(x)
		if child.button_pressed:
			tags.append(x)
	var filter = {}
	if tags.size() > 0:
		filter["tag"] = tags
	if $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer/OptionButton".selected != 2:
		filter["gender"] = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer/OptionButton".selected
	data["filter"] = filter
	if $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture != null:
		data["imagedata"] = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/Button/TextureRect".texture.get_image().save_webp_to_buffer()
		data["imagename"] = "1.webp"
	if $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".stream != null:
		data["audiodata"] = $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".stream.data
		data["audioname"] = "1." + $"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer4/PanelContainer".ext
	
	upload_request.request(Updatedate.protocol+Updatedate.subdomin+"/control/send_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await upload_request.request_completed
	while d[3].size() == 0:
		upload_request.request(Updatedate.protocol+Updatedate.subdomin+"/control/send_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
		d = await upload_request.request_completed
	var result = Updatedate.get_json(d[3])
	w.queue_free()
	if result.has("error"):
		Notification.add_notif(result.error, Notification.ERROR)
	if result.has("message"):
		Notification.add_notif(result.message, Notification.SUCCESS)
		add_message()
func add_message():
	var m = await Updatedate.request("/control/get_messages")
	for child in $"TabContainer/3/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
		if child.name != "instance":
			child.queue_free()
	
	if m.has("data"):
		var data = m.data
		for message in data:
			var box = $"TabContainer/3/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
			box.get_node("MarginContainer/VBoxContainer/BoxContainer/RichTextLabel").text = "[right]" + message.text
			var receiver = ""
			if message.receiver.users is String and message.receiver.users == "all":
				receiver += "همه‌ی "
				if message.receiver.filter.has("gender"):
					receiver += ["آقایون", "خانم‌های"][message.receiver.filter.gender] + " "
				else:
					receiver += "افراد "
				if message.receiver.filter.has("tag") and message.receiver.filter.tag.size() > 0:
					receiver += "در رده‌های "
					var tags = ["مهدکودک ", "اول تا سوم ", "چهارم تا ششم ", "هفتم تا نهم ", "دهم تا دوازدهم ", "سطوح تحصیلی بالاتر ", "کادر اجرایی "]
					for x in message.receiver.filter.tag:
						receiver += tags[x]
				else:
					receiver += "در همه‌ی رده‌ها"
			else:
				for user in message.receiver.users:
					receiver += user + " "
			box.get_node("MarginContainer/VBoxContainer/BoxContainer2/Label2").text = receiver
			box.get_node("MarginContainer/VBoxContainer/BoxContainer4/Label2").text = message.time
			box.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button").pressed.connect(func():
				var w = Updatedate.add_wait(box.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button"))
				var r = HTTPRequest.new()
				add_child(r)
				r.request(Updatedate.protocol+Updatedate.subdomin+"/users/delete_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":message.id}))
				var body = await r.request_completed
				r.timeout = 10
				while body[3].size() == 0:
					r.request(Updatedate.protocol+Updatedate.subdomin+"/users/delete_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":message.id}))
					body = await r.request_completed
				r.queue_free()
				var d2 = Updatedate.get_json(body[3])
				w.queue_free()
				if d2.has("error"):
					Notification.add_notif(d2.error, Notification.ERROR)
				if d2.has("message"):
					Notification.add_notif(d2.message, Notification.SUCCESS)
					add_message())
			box.show()
			$"TabContainer/3/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
			
			


func _on_sort_button_pressed() -> void:
	var w = Updatedate.add_wait($"TabContainer/1/VBoxContainer/BoxContainer/BoxContainer4/Button")
	for child in $"TabContainer/1/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
		if "instance" not in child.name:
			child.queue_free()
	if %sort_part.selected != 4:
		var d = await Updatedate.request("/control/sort_users?sort={1}AND{0}&filter={0}AND{1}ANDfirst_nameANDlast_nameANDicon&per_page={2}".format(["score_"+str(%sort_gender.selected, "_", %sort_tag.selected) + (str("_", %sort_part.selected)  if %sort_part.selected < 3 else ""), "diamonds"+str(%sort_part.selected if %sort_part.selected < 3 else ""), int(%per_page.value)]))
		if d.has("error"):
			Notification.add_notif(d.error, Notification.ERROR)
			w.queue_free()
			return
		if d.has("users"):
			var users = d.users
			for user in users:
				var box = $"TabContainer/1/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
				Updatedate.get_icon_user(user.data.icon if user.data.has("icon") else "", user.username, box.get_node("MarginContainer/BoxContainer/TextureRect"))
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/Label").text = str("رتبه : ", int(user.data.position))
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer/RichTextLabel").text = user.data.first_name + " " + user.data.last_name
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label2").text = "کدملی : "+user.username
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer2/Label").text = "شماره تلفن : "+user.phone
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer3/Label").text = "امتیاز : "+str(int(user.data["score_"+str(%sort_gender.selected, "_", %sort_tag.selected) + (str("_", %sort_part.selected) if %sort_part.selected < 3 else "")]))
				box.get_node("MarginContainer/BoxContainer/VBoxContainer/BoxContainer3/Label2").text = "الماس : "+str(int(user.data["diamonds"+str(%sort_part.selected if %sort_part.selected < 3 else "")]))
				box.show()
				$"TabContainer/1/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
	else:
		var d = await Updatedate.request("/control/sort_group?gender={0}&tag={1}&sort_group?&filter=first_nameANDlast_name&per_page={2}".format([%sort_gender.selected, %sort_tag.selected, int(%per_page.value)]))
		if d.has("error"):
			w.queue_free()
			Notification.add_notif(d.error, Notification.ERROR)
			return
		if d.has("groups"):
			var groups = d.groups
			for group in groups:
				var box = $"TabContainer/1/VBoxContainer/ScrollContainer/VBoxContainer/instance2".duplicate()
				Updatedate.get_icon_group(group.icon if group.has("icon") else "", group.name, box.get_node("MarginContainer/VBoxContainer/BoxContainer/TextureRect"))
				box.get_node("MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/Label").text = str("رتبه : ", int(group.position))
				box.get_node("MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer/RichTextLabel").text = group.name
				for x in range(5):
					if x < group.users.users.size():
						var user = group.users.users[x]
						var box2 = box.get_node("MarginContainer/VBoxContainer/GridContainer").get_child(x)
						box2.get_node("BoxContainer/RichTextLabel").text = user.first_name + " " + user.last_name
						box2.get_node("BoxContainer3/RichTextLabel").text = user.username
						box2.get_node("BoxContainer2/RichTextLabel").text = user.phone
					else:
						box.get_node("MarginContainer/VBoxContainer/GridContainer").get_child(x).hide()
				box.get_node("MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer3/Label").text = "امتیاز : "+str(int(group.score))
				box.get_node("MarginContainer/VBoxContainer/BoxContainer/VBoxContainer/BoxContainer3/Label2").text = "الماس : "+str(int(group.diamonds))
				box.show()
				$"TabContainer/1/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
	w.queue_free()



func _on_window_close_requested() -> void:
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/Button2".button_pressed = false


func _on_window_go_back_requested() -> void:
	$"TabContainer/3/VBoxContainer/BoxContainer/BoxContainer5/Button2".button_pressed = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)


func _on_button_pressed(mode) -> void:
	var s = Updatedate.load_scene("scroll_button.tscn")
	var items = []
	match mode:
		0:
			for x in range(60):
				if x < 10:
					items.append(str("0", x))
				else:
					items.append(str(x))
			s.select.connect(func(item):
				$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button".text = item)
			for x in range(items.size()):
				if $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button".text == items[x]:
					s.current = -x
		1:
			for x in range(24):
				if x < 10:
					items.append(str("0", x))
				else:
					items.append(str(x))
			s.select.connect(func(item):
				$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button2".text = item)
			for x in range(items.size()):
				if $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button2".text == items[x]:
					s.current = -x
		2:
			var day = 30
			var m = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button4".text
			var y = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button5".text
			if int(m) < 7:
				day = 31
			if int(m) == 12:
				day = 29 if int(y) % 4 != 3 else 30
			for x in range(day):
				if x < 10:
					items.append(str("0", x+1))
				else:
					items.append(str(x+1))
			s.select.connect(func(item):
				$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button3".text = item)
			for x in range(items.size()):
				if $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button3".text == items[x]:
					s.current = -x
		3:
			for x in range(12):
				if x < 10:
					items.append(str("0", x+1))
				else:
					items.append(str(x+1))
			s.select.connect(func(item):
				$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button4".text = item)
			for x in range(items.size()):
				if $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button4".text == items[x]:
					s.current = -x
		4:
			for x in range(1404, 1450):
				items.append(str(x))
			s.select.connect(func(item):
				$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button5".text = item)
			for x in range(items.size()):
				if $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button5".text == items[x]:
					s.current = -x
	s.items = items
	
	add_child(s)


func _on_add_ticket_pressed() -> void:
	var w = Updatedate.add_wait($"TabContainer/5/VBoxContainer/BoxContainer/add_editor")
	var http = HTTPRequest.new()
	add_child(http)
	var min = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button".text
	var h = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button2".text
	var day = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button3".text
	var m = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button4".text
	var year = $"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer3/Button5".text
	var time = str(year,"/",m,"/",day, " ", h,":", min)
	var tag = []
	for x in range($"TabContainer/5/VBoxContainer/BoxContainer/HBoxContainer/GridContainer".get_children().size()):
		var child : CheckBox = $"TabContainer/5/VBoxContainer/BoxContainer/HBoxContainer/GridContainer".get_child(x)
		if child is CheckBox:
			if child.text != "اتباع":
				if child.button_pressed:
					tag.append(x)
	var nationality = int(%nationality.button_pressed)
	http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/add_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":time, "max_users":$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer/SpinBox".value, "tag":tag, "nationality":nationality, "gender":%sort_gender2.selected}))
	var d = await http.request_completed
	http.timeout = 10
	while d[3].size() == 0:
		http.request(Updatedate.protocol+Updatedate.subdomin+"/check_resource", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":time, "max_users":$"TabContainer/5/VBoxContainer/BoxContainer/BoxContainer/SpinBox".value, "tag":tag, "nationality":nationality, "gender":%sort_gender2.selected}))
		d = await http.request_completed
	http.queue_free()
	var data = Updatedate.get_json(d[3])
	if data:
		if data.has("error"):
			Notification.add_notif(data.error, Notification.ERROR)
		if data.has("message"):
			Notification.add_notif(data.message)
			add_ticket()
	w.queue_free()
func add_ticket():
	var w = Updatedate.add_wait($"TabContainer/5/VBoxContainer/ScrollContainer")
	for child in $"TabContainer/5/VBoxContainer/ScrollContainer/VBoxContainer".get_children():
		if "instance" not in child.name:
			child.queue_free()
	
	var d = await Updatedate.request("/ticket/get_ticket?all=true")
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)
		w.queue_free()
		return
	if d.has("data"):
		var data = d.data
		for ticket in data:
			var box = $"TabContainer/5/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
			box.get_node("MarginContainer/VBoxContainer/BoxContainer/SpinBox").value = ticket.max_users
			box.get_node("MarginContainer/VBoxContainer/BoxContainer/Label2").text = str("مسافران: ", int(ticket.users))
			var btn = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Button")
			var btn2 = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Button2")
			var btn3 = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Button3")
			var btn4 = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Button4")
			var btn5 = box.get_node("MarginContainer/VBoxContainer/HBoxContainer/Button5")
			var l = box.get_node("MarginContainer/VBoxContainer/HBoxContainer3/Label")
			
			l.text = "مشخصات : این قطار برای "+["پسر های", "دختر های", "افراد"][ticket.gender]+" با رده‌های سنی "
			var tags = ["زیر شش سال", "اول تا سوم", "چهارم تا ششم", "هفتم تا نهم"]
			for t in ticket.tag:
				l.text += str(tags[t], "، ")
			l.text += "با تابعیت ایران است." if ticket.nationality == 0 else "با تابعیت کشورهای دیگر است."
			var _time:PackedStringArray = ticket.time.split(" ")
			btn.text = _time[1].split(":")[1]
			
			btn2.text = _time[1].split(":")[0]
			btn5.text = _time[0].split("/")[0]
			btn4.text = _time[0].split("/")[1]
			btn3.text = _time[0].split("/")[2]
			box.show()
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button").pressed.connect(func():
				var http = HTTPRequest.new()
				add_child(http)
				var time = str(btn5.text,"/",btn4.text,"/",btn3.text, " ", btn2.text,":", btn.text)
				http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/change_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"new_time":time, "time":ticket.time, "max_users":box.get_node("MarginContainer/VBoxContainer/BoxContainer/SpinBox").value}))
				var d2 = await http.request_completed
				http.timeout = 10
				while d2[3].size() == 0:
					http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/change_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"new_time":time, "time":ticket.time, "max_users":box.get_node("MarginContainer/VBoxContainer/BoxContainer/SpinBox").value}))
					d2 = await http.request_completed
				http.queue_free()
				var message = Updatedate.get_json(d2[3])
				if message:
					
					if message.has("error"):
						Notification.add_notif(message.error, Notification.ERROR)
					if message.has("message"):
						Notification.add_notif(message.message)
						add_ticket()
				)
			box.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button2").pressed.connect(func():
				var http = HTTPRequest.new()
				add_child(http)
				http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/delete_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":ticket.miladi_time}))
				var d2 = await http.request_completed
				http.timeout = 10
				while d2[3].size() == 0:
					http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/delete_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":ticket.miladi_time}))
					d2 = await http.request_completed
				http.queue_free()
				var message = Updatedate.get_json(d2[3])
				if message:
					if message.has("error"):
						Notification.add_notif(message.error, Notification.ERROR)
					if message.has("message"):
						Notification.add_notif(message.message)
						add_ticket()
				)
			btn.pressed.connect(func():
				var s = Updatedate.load_scene("scroll_button.tscn")
				var items = []
				for x in range(60):
					if x < 10:
						items.append(str("0", x))
					else:
						items.append(str(x))
				for x in range(items.size()):
					if btn.text == items[x]:
						s.current = -x
				s.select.connect(func(item):
					btn.text = item)
				s.items = items
				add_child(s)
				)
			btn2.pressed.connect(func():
				var s = Updatedate.load_scene("scroll_button.tscn")
				var items = []
				for x in range(24):
					if x < 10:
						items.append(str("0", x))
					else:
						items.append(str(x))
				for x in range(items.size()):
					if btn2.text == items[x]:
						s.current = -x
				s.select.connect(func(item):
					btn2.text = item)
				s.items = items
				add_child(s)
				)
			btn3.pressed.connect(func():
				var s = Updatedate.load_scene("scroll_button.tscn")
				var items = []
				var day = 30
				var m = btn4.text
				var y = btn5.text
				if int(m) < 7:
					day = 31
				if int(m) == 12:
					day = 29 if int(y) % 4 != 3 else 30
				for x in range(day):
					if x < 10:
						items.append(str("0", x+1))
					else:
						items.append(str(x+1))
				for x in range(items.size()):
					if btn.text == items[x]:
						s.current = -x
				s.select.connect(func(item):
					btn3.text = item)
				s.items = items
				add_child(s)
				)
			btn4.pressed.connect(func():
				var s = Updatedate.load_scene("scroll_button.tscn")
				var items = []
				for x in range(12):
					if x < 10:
						items.append(str("0", x))
					else:
						items.append(str(x))
				for x in range(items.size()):
					if btn4.text == items[x]:
						s.current = -x
				s.select.connect(func(item):
					btn4.text = item)
				s.items = items
				add_child(s)
				)
			btn5.pressed.connect(func():
				var s = Updatedate.load_scene("scroll_button.tscn")
				var items = []
				for x in range(1404, 1450):
					if x < 10:
						items.append(str("0", x))
					else:
						items.append(str(x))
				for x in range(items.size()):
					if btn2.text == items[x]:
						s.current = -x
				s.select.connect(func(item):
					btn5.text = item)
				s.items = items
				add_child(s)
				)
			$"TabContainer/5/VBoxContainer/ScrollContainer/VBoxContainer".add_child(box)
	w.queue_free()


func _on_save_plan_pressed() -> void:
	var data = {"subplanes":[]}
	var w = Updatedate.add_wait($"TabContainer/1/TabContainer/MarginContainer2")
	for plan in subplanes:
		var editors = []
		for user in plan.get_meta("selected_users", []):
			editors.append(user.username)
		data.subplanes.append({"name": plan.get_node("MarginContainer/VBoxContainer/HBoxContainer3/LineEdit").text, "diamond_range":plan.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value, "editors":editors})
	data["name"] = %plan.text
	var http = HTTPRequest.new()
	add_child(http)
	http.request(Updatedate.protocol+Updatedate.subdomin+"/planes/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await http.request_completed
	while d[3].size() == 0:
		http.request(Updatedate.protocol+Updatedate.subdomin+"/planes/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
		d = await http.request_completed
	var result = Updatedate.get_json(d[3])
	if result.has("error"):
		Notification.add_notif(result.error, Notification.ERROR)
	if result.has("message"):
		Notification.add_notif(result.message)
	w.queue_free()

func _on_clear_button_pressed() -> void:
	for plan in subplanes:
		plan.queue_free()
	subplanes = []
	subplan = null
	$Panel2.hide()
	$TextureRect2.hide()
	%plan.text = ""

func _remove_child(child, filter_name=["instance", "add"]):
	for n in child.get_children():
		if n.name not in filter_name:
			n.queue_free()


func _on_add_subplan_pressed() -> void:
	var instance = $"TabContainer/1/TabContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
	instance.show()
	instance.name = "sub"
	instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button").pressed.connect(func (): 
		subplanes.erase(instance)
		instance.queue_free())
	instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button2").pressed.connect(func (): 
		$Panel2.show()
		$TextureRect2.show()
		if subplan:
			subplan.set_meta("selected_users", selected_users)
			if subplan is PanelContainer:
				var label = subplan.get_node("MarginContainer/VBoxContainer/Label2")
				label.text = "[right][b][color=41ff00]مربیان:[/color][/b]"
				var index = 0
				for user in selected_users:
					label.text += " " + user.name
					if index < selected_users.size() - 1:
						label.text += " و"
					index += 1
		subplan = instance
		_remove_child($Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer)
		selected_users = instance.get_meta("selected_users", [])
		add_saved_users())
	subplanes.append(instance)
	$"TabContainer/1/TabContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer".add_child(instance, true, Node.INTERNAL_MODE_FRONT)
func  _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if $Panel2.visible:
			$Panel2.hide()
			if not $Panel.visible:
				$TextureRect2.hide()
			if subplan:
				subplan.set_meta("selected_users", selected_users)
				if subplan is PanelContainer:
					var label = subplan.get_node("MarginContainer/VBoxContainer/Label2")
					label.text = "[right][b][color=41ff00]مربیان:[/color][/b]"
					var index = 0
					for user in selected_users:
						label.text += " " + user.name
						if index < selected_users.size() - 1:
							label.text += " و"
						index += 1
		elif $Panel.visible:
			$Panel.hide()
			$TextureRect2.hide()


func _on_plan_text_submitted(new_text: String) -> void:
	grab_focus()


func _on_search_item_selected(index: int) -> void:
	%search2.text = ""
	search_type2 = index
	match index:
		0:
			%search2.alignment = HORIZONTAL_ALIGNMENT_CENTER
			%search2.max_length = 0
			%search2.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
		1:
			%search2.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			%search2.max_length = 10
			%search.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		2:
			%search2.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			%search2.max_length = 11
			%search2.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PHONE


func _on_searchButton_pressed() -> void:
	if %search2.text != "":
		var d 
		var w = Updatedate.add_wait($Panel2/MarginContainer2/VBoxContainer/ScrollContainer)
		var w2 = Updatedate.add_wait($Panel2/MarginContainer2/VBoxContainer/BoxContainer/Button)
		
		match search_type2:
			0:
				d = await Updatedate.request("/control/get_users?name="+%search2.text.uri_encode())
			1:
				d = await Updatedate.request("/control/get_users?username="+%search2.text)
			2:
				d = await Updatedate.request("/control/get_users?phone="+%search2.text)
			
		if d.has("data"):
			_remove_child($Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer)
			for user in d.data:
				var instance: PanelContainer = $Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/instance.duplicate()
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer/RichTextLabel").text = "[center]"+ user["first_name"] + " " + user["last_name"]
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer2/Label").text =  "شماره تلفن: " + user["phone"]
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer2/Label2").text =  "کدملی: " + user["username"]
				var btn = instance.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button")
				var btn2:Button = instance.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button2")
				
				var user_data = {"name": user["first_name"] + " " + user["last_name"] + " " +user["father_name"], "username": user["username"]}
				if selected_users.map(func(x): return x.username).has(user_data.username):
					btn.text = "لغو انتخاب"
					btn.button_pressed = true
				else:
					btn.text = "انتخاب"
					btn.button_pressed = false
				if not saved_users.map(func(x): return x.username).has(user_data.username):
					btn2.button_pressed = false
					btn2.text = "افزودن به مخاطبین"
				else :
					btn2.text = "حذف از مخاطبین"
					btn2.button_pressed = true
				btn2.pressed.connect(func():
					if saved_users.map(func(x): return x.username).has(user_data.username):
						saved_users = saved_users.filter(func(x): return x.username != user_data.username)
						btn2.text = "افزودن به مخاطبین"
					else :
						btn2.text = "حذف از مخاطبین"
						saved_users.append(user_data)
					add_saved_users()
					Updatedate.save("saved_users", saved_users))
					
				btn.pressed.connect(func():
					if selected_users.map(func(x): return x.username).has(user_data.username):
						selected_users = selected_users.filter(func(x): return x.username != user_data.username)
						btn.text = "انتخاب"
					else:
						selected_users.append(user_data)
						btn.text = "لغو انتخاب"
					add_saved_users())
				instance.show()
				$Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer.add_child(instance)
		w.queue_free()
		w2.queue_free()
func add_saved_users():
	_remove_child($Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2)
	_remove_child($Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer)
	$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.hide()
	$Panel2/MarginContainer/ScrollContainer/VBoxContainer/Label2.hide()
	$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.hide()
	$Panel2/MarginContainer/ScrollContainer/VBoxContainer/Label.hide()
	
	for user in saved_users:
		var btn : Button= $Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/instance.duplicate()
		btn.text = "نام: "+ user.name +"\n کدملی: "+ user.username
		btn.show()
		btn.name = "user"
		btn.pressed.connect(func ():
			if selected_users.map(func(x): return x.username).has(user.username):
				selected_users = selected_users.filter(func(x): return x.username != user.username)
			else:
				selected_users.append(user)
			add_saved_users())
		if selected_users.map(func(x): return x.username).has(user.username):
			btn.button_pressed = true
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/Label2.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.add_child(btn)
		else:
			btn.button_pressed = false
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/Label.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.add_child(btn)
	for user in selected_users:
		if not saved_users.map(func(x): return x.username).has(user.username):
			var btn : Button= $Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/instance.duplicate()
			btn.text = "نام: "+ user.name +"\n کدملی: "+ user.username
			btn.show()
			btn.name = "user"
			btn.button_pressed = true
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/Label2.show()
			$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.add_child(btn)
			btn.pressed.connect(func ():
				selected_users = selected_users.filter(func(x): return x.username != user.username)
				add_saved_users())

func get_plan_by_year(year):
	var d = await Updatedate.request("/planes/get?year=%s"%int(year))
	var option:OptionButton = $"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/HBoxContainer/HBoxContainer2/OptionButton"
	if d.has("planes"):
		if d.planes.size() == 0:
			$"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/HBoxContainer/HBoxContainer2/Label2".show()
			option.hide()
		else:
			$"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/HBoxContainer/HBoxContainer2/Label2".hide()
			option.show()
			option.clear()
			for plan in d.planes:
				option.add_item(plan)


func _on_get_planes_pressed() -> void:
	var option:OptionButton = $"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/HBoxContainer/HBoxContainer2/OptionButton"
	plan_name = (option.get_item_text(option.selected)).uri_encode()
	var d = await Updatedate.request("/planes/get?name=%s"%plan_name)
	for plan in subplanes2:
		plan.queue_free()
	subplanes2 = []
	if d and d.has("subplanes"):
		for plan in d.subplanes:
			var instance = $"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/MarginContainer/BoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
			var label = instance.get_node("MarginContainer/VBoxContainer/Label2")
			label.text = "[right][b][color=41ff00]مربیان:[/color][/b]"
			var index = 0
			for user in plan.editors:
				label.text += " " + user.name
				if index < plan.editors.size() - 1:
					label.text += " و"
				index += 1
			instance.get_node("MarginContainer/VBoxContainer/HBoxContainer3/LineEdit").text = plan.name
			instance.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value = plan.diamond_range
			instance.set_meta("selected_users", plan.editors)
			instance.show()
			subplanes2.append(instance)
			instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button").pressed.connect(func (): 
				subplanes2.erase(instance)
				instance.queue_free()
				)
			instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button2").pressed.connect(func (): 
				$Panel2.show()
				$TextureRect2.show()
				if subplan:
					subplan.set_meta("selected_users", selected_users)
					if subplan is PanelContainer:
						var label2 = subplan.get_node("MarginContainer/VBoxContainer/Label2")
						label2.text = "[right][b][color=41ff00]مربیان:[/color][/b]"
						var index2 = 0
						for user in selected_users:
							label2.text += " " + user.name
							if index2 < selected_users.size() - 1:
								label2.text += " و"
							index2 += 1
				subplan = instance
				_remove_child($Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer)
				selected_users = instance.get_meta("selected_users", [])
				add_saved_users())
			$"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/MarginContainer/BoxContainer/ScrollContainer/VBoxContainer".add_child(instance, false, Node.INTERNAL_MODE_FRONT)
			
	print(d)


func _on_reload_changes_pressed() -> void:
	_on_get_planes_pressed()


func _on_save_changes_pressed() -> void:
	var data = {"subplanes":[]}
	var w = Updatedate.add_wait($"TabContainer/1/TabContainer/MarginContainer")
	for plan in subplanes2:
		var editors = []
		for user in plan.get_meta("selected_users", []):
			editors.append(user.username)
		data.subplanes.append({"name": plan.get_node("MarginContainer/VBoxContainer/HBoxContainer3/LineEdit").text, "diamond_range":plan.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value, "editors":editors})
	data["name"] = plan_name.uri_decode()
	var http = HTTPRequest.new()
	add_child(http)
	http.request(Updatedate.protocol+Updatedate.subdomin+"/planes/edit", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await http.request_completed
	while d[3].size() == 0:
		http.request(Updatedate.protocol+Updatedate.subdomin+"/planes/edit", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
		d = await http.request_completed
	var result = Updatedate.get_json(d[3])
	if result.has("error"):
		Notification.add_notif(result.error, Notification.ERROR)
	if result.has("message"):
		Notification.add_notif(result.message)
	w.queue_free()


func _on_add_pressed() -> void:
	if plan_name != "":
		var instance = $"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/MarginContainer/BoxContainer/ScrollContainer/VBoxContainer/instance".duplicate()
		instance.show()
		subplanes2.append(instance)
		instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button").pressed.connect(func (): 
			subplanes2.erase(instance)
			instance.queue_free()
		)
		instance.get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button2").pressed.connect(func (): 
			$Panel2.show()
			$TextureRect2.show()
			if subplan:
				subplan.set_meta("selected_users", selected_users)
				if subplan is PanelContainer:
					var label2 = subplan.get_node("MarginContainer/VBoxContainer/Label2")
					label2.text = "[right][b][color=41ff00]مربیان:[/color][/b]"
					var index2 = 0
					for user in selected_users:
						label2.text += " " + user.name
						if index2 < selected_users.size() - 1:
							label2.text += " و"
						index2 += 1
			subplan = instance
			_remove_child($Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer)
			selected_users = instance.get_meta("selected_users", [])
			add_saved_users())
		$"TabContainer/1/TabContainer/MarginContainer/VBoxContainer/MarginContainer/BoxContainer/ScrollContainer/VBoxContainer".add_child(instance, false, Node.INTERNAL_MODE_FRONT)
		
