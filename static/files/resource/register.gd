extends Control
var account = []
var press = false
var current_box = 0
var boxes = []
var edit_code = false
var enter_phones = []
var timers = {}
var current_phone
func _ready() -> void:
	$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox2.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox3.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	var user = false
	account = Updatedate.load_game("accounts", [])
	if Updatedate.current_user != Updatedate.load_game("last_user", 0):
		$MarginContainer4/VBoxContainer/Button2.show()
	else:
		user = Updatedate.load_user()
	if user:
		$MarginContainer/VBoxContainer/HBoxContainer/LineEdit.text = Updatedate.load_game("first_name", "")
		$MarginContainer/VBoxContainer/HBoxContainer2/LineEdit.text = Updatedate.load_game("last_name", "")
		$MarginContainer/VBoxContainer/HBoxContainer4/LineEdit.text = Updatedate.load_game("father_name", "")
		var birthday = Updatedate.load_game("birthday", "1380/1/1").split("/")
		$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox.value = int(birthday[2])
		$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox2.value = int(birthday[1])
		$MarginContainer/VBoxContainer/HBoxContainer3/SpinBox3.value = int(birthday[0])
		$MarginContainer/VBoxContainer/HBoxContainer5/OptionButton.select(Updatedate.load_game("tag", 0))
		$MarginContainer/VBoxContainer/HBoxContainer6/OptionButton.select(Updatedate.load_game("gender", 0))
		$MarginContainer3.hide()
		$MarginContainer4.hide()
		$MarginContainer2.hide()
		$AnimationPlayer.play_backwards("change")
	for x in range(get_tree().get_nodes_in_group("code").size()):
		var spin = get_tree().get_nodes_in_group("code")[x]
		if spin is Label:
			boxes.append(spin)
			spin.gui_input.connect(func (event:InputEvent):
				if event is InputEventMouseButton:
					if event.is_pressed():
						DisplayServer.virtual_keyboard_hide()
						DisplayServer.virtual_keyboard_show("exit", Rect2(0, 0, 0, 0), DisplayServer.KEYBOARD_TYPE_NUMBER)
						edit_code = true
						boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
						current_box = x
			)
	await get_tree().create_timer(0.1).timeout
	show()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timers.has(current_phone):
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.text = str(int(timers[current_phone].time_left))
	else :
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.text = "ارسال مجدد کد"
	if edit_code:
		boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/focus.tres"))
	
	var text :String = %phone.text
	if text.length() == 11 and text.begins_with("09"):
		$MarginContainer3/VBoxContainer/Button.disabled = false
	else :
		$MarginContainer3/VBoxContainer/Button.disabled = true
	var e = false
	for spin in get_tree().get_nodes_in_group("code"):
		if spin.text == "":
			e = true
	$MarginContainer/VBoxContainer/Button.disabled = not ($MarginContainer/VBoxContainer/HBoxContainer4/LineEdit.text != "" and $MarginContainer/VBoxContainer/HBoxContainer2/LineEdit.text != "" and $MarginContainer/VBoxContainer/HBoxContainer/LineEdit.text != "") or press
	$MarginContainer2/VBoxContainer/Button.disabled = e or press
	if %id.text.length() == 10 and %id.text not in account:
		$MarginContainer4/VBoxContainer/Button.disabled = false
	else:
		$MarginContainer4/VBoxContainer/Button.disabled = true


func _on_button_pressed() -> void:
	DisplayServer.virtual_keyboard_hide()
	boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
	edit_code = false
	var w = Updatedate.add_wait($MarginContainer2/VBoxContainer/Button)
	var r = HTTPRequest.new()
	add_child(r)
	var code = $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox2.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox3.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox4.text
	r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/register", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": current_phone, "code":code, "id":%id.text}))
	r.request_completed.connect(_on_code_sended.bind(w))
func _on_code_sended(r, re, h, b, w):
	if b:
		var data = Updatedate.get_json(b)
		if data:
			if data is Array and data[0].has("error"):
				Notification.add_notif(data[0].error, Notification.ERROR)
			if data.has("message") :
				var accounts = []
				if FileAccess.file_exists("user://session.dat"):
					var file2 = FileAccess.open("user://session.dat", FileAccess.READ)
					accounts = file2.get_var()
					file2.close()
				accounts.append(data.tokens)
				var file = FileAccess.open("user://session.dat", FileAccess.WRITE)
				file.store_var(accounts)
				file.close()
				var a = Updatedate.load_game("accounts", [])
				a.append(data.tokens.id)
				Updatedate.save("accounts", a, false)
				Updatedate.save("last_user" , Updatedate.current_user,false)
				Updatedate.load_user()
				if data.message == "sign In":
					$AnimationPlayer.play_backwards("change")
				else :
					var data2 = await Updatedate.load_from_server()
					Transation.check_trans()
					Updatedate.socket.close()
					var required_info = ["father_name", "first_name", "last_name", "birthday", "gender", "tag"]
					var not_data= false
					for r2 in required_info:
						if data2 is Dictionary and !data2.data.has(r2):
							not_data = true
					if not_data:
						Transation.change(self, "register.tscn")
					else:
						await Updatedate.update_resource()
						await get_tree().create_timer(1).timeout
						Transation.change(self, "start.tscn")
						
	else:
		Notification.add_notif("اتصال اینترنت برقرار نیست", Notification.ERROR) 
		var r2 = HTTPRequest.new()
		r2.timeout = 10
		add_child(r2)
		var code2 = $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox4.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox3.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox2.text + $MarginContainer2/VBoxContainer/HBoxContainer3/SpinBox.text
		r2.request(Updatedate.protocol+Updatedate.subdomin+"/auth/register", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": %phone.text, "code":code2, "id":%id.text}))
		r2.request_completed.connect(_on_code_sended.bind(w))
	w.queue_free()

func _on_button2_pressed() -> void:
	$AnimationPlayer.play("change1")
	$MarginContainer2/VBoxContainer/HBoxContainer/Label.text = str("لطفاً کد ارسالی به شماره تلفن", %phone.text,"را وارد کنید.")
	if !enter_phones.has(%phone.text):
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.text = ""
		var r = HTTPRequest.new()
		add_child(r)
		r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/verify", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": %phone.text, "game":"مصباح"}))
		var i = await r.request_completed
		r.queue_free()
		if i[3].size() != 0:
			enter_phones.append(%phone.text)
			delete_phone(%phone.text)
			current_phone = %phone.text

func _on_button3_pressed() -> void:
	var first_name = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit.text 
	var last_name =  $MarginContainer/VBoxContainer/HBoxContainer2/LineEdit.text
	var father_name = $MarginContainer/VBoxContainer/HBoxContainer4/LineEdit.text
	var birthday = str(int($MarginContainer/VBoxContainer/HBoxContainer3/SpinBox3.value),"/", int($MarginContainer/VBoxContainer/HBoxContainer3/SpinBox2.value), "/",int($MarginContainer/VBoxContainer/HBoxContainer3/SpinBox.value))
	var tag = $MarginContainer/VBoxContainer/HBoxContainer5/OptionButton.selected
	var gender = $MarginContainer/VBoxContainer/HBoxContainer6/OptionButton.selected
	Updatedate.multy_save({"first_name":first_name, "last_name":last_name, "father_name": father_name, "birthday":birthday, "gender":gender, "tag":tag, "icon":""})
	await Updatedate.update_resource()
	await get_tree().create_timer(1).timeout
	Transation.change(self, "start.tscn")


func _on_button4_pressed() -> void:
	var w = Updatedate.add_wait($MarginContainer4/VBoxContainer/Button)
	var r = HTTPRequest.new()
	add_child(r)
	r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/check_user", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"id": %id.text}))
	var d = await r.request_completed
	var data = Updatedate.get_json(d[3])
	while d[3].size() == 0:
		Notification.add_notif("اتصال اینترنت برقرار نیست", Notification.ERROR) 
		r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/check_user", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"id": %id.text}))
		d = await r.request_completed
		data = Updatedate.get_json(d[3])
	r.queue_free()
	if data is Dictionary and data.has("phone"):
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.text = ""
		$MarginContainer2/VBoxContainer/Button/Button.hide()
		$MarginContainer2/VBoxContainer/Button/Button2.show()
		$MarginContainer2/VBoxContainer/HBoxContainer/Label.text = str("لطفاً کد ارسالی به شماره تلفن", data.phone,"را وارد کنید.")
		if !enter_phones.has(data.phone):
			var r2 = HTTPRequest.new()
			add_child(r2)
			r2.request(Updatedate.protocol+Updatedate.subdomin+"/auth/verify", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": data.phone, "game":"مصباح"}))
			var i = await r2.request_completed
			r2.queue_free()
			if i[3].size() != 0:
				enter_phones.append(data.phone)
				delete_phone(data.phone)
				current_phone = data.phone
		$AnimationPlayer.play("change3")
	else:
		$MarginContainer2/VBoxContainer/Button/Button2.hide()
		$MarginContainer2/VBoxContainer/Button/Button.show()
		$AnimationPlayer.play("change2")
	w.queue_free()
func delete_phone(phone):
	var timer = get_tree().create_timer(120)
	timers[phone] = timer
	await timer.timeout
	if enter_phones.has(phone):
		enter_phones.erase(phone)
	timers.erase(phone)

func _on_cancel_pressed() -> void:
	Updatedate.save("current_user", Updatedate.load_game("last_user", 0), false)
	Updatedate.current_user = Updatedate.last_user
	Transation.change(self, "setting.tscn", -1)
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and edit_code:
			if event.keycode == KEY_ENTER or  event.keycode == KEY_KP_ENTER:
				DisplayServer.virtual_keyboard_hide()
				_on_button_pressed()
			elif event.keycode != KEY_BACKSPACE:
				boxes[current_box].text = str(int(OS.get_keycode_string(event.key_label)))
				if current_box <  3:
					current_box += 1
					boxes[current_box - 1].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
			else:
				if boxes[current_box].text != "":
					boxes[current_box].text = ""
				else:
					if current_box > 0:
						current_box -= 1
						boxes[current_box].text = ""
						boxes[current_box + 1].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
		


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			DisplayServer.virtual_keyboard_hide()
			boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
			edit_code = false


func _on_back_pressed() -> void:
	DisplayServer.virtual_keyboard_hide()
	boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
	edit_code = false
	$AnimationPlayer.play_backwards("change2")


func _on_edit_phone_pressed() -> void:
	DisplayServer.virtual_keyboard_hide()
	boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
	edit_code = false
	$AnimationPlayer.play_backwards("change1")
	for x in range(get_tree().get_nodes_in_group("code").size()):
		var spin = get_tree().get_nodes_in_group("code")[x]
		spin.text = ""


func _on_edit_username_pressed() -> void:
	DisplayServer.virtual_keyboard_hide()
	boxes[current_box].add_theme_stylebox_override("normal", load("res://styles/normal.tres"))
	edit_code = false
	$AnimationPlayer.play_backwards("change3")
	for x in range(get_tree().get_nodes_in_group("code").size()):
		var spin = get_tree().get_nodes_in_group("code")[x]
		spin.text = ""


func _on_label_gui_input(event: InputEvent) -> void:
	if !timers.has(current_phone) and event is InputEventScreenTouch and event.is_pressed():
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.hide()
		var r = HTTPRequest.new()
		add_child(r)
		r.timeout = 10
		r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/verify", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": current_phone, "game":"مصباح"}))
		var i = await r.request_completed
		while i[3].size() == 0:
			Notification.add_notif("اتصال اینترنت برقرار نیست", Notification.ERROR) 
			r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/verify", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"phone": current_phone, "game":"مصباح"}))
			i = await r.request_completed
		enter_phones.append(current_phone)
		delete_phone(current_phone)
		for x in range(get_tree().get_nodes_in_group("code").size()):
			var spin = get_tree().get_nodes_in_group("code")[x]
			spin.text = ""
		$MarginContainer2/VBoxContainer/HBoxContainer/Label/Label.show()
