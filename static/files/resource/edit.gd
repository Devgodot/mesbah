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
var planes = []
var subplanes = []
var _plan = ""
var _plan2 = ""
var _subplan = ""
var _subplan2 = ""
func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel2.set_tab_title(0, "ذخیره شده")
	$Panel2.set_tab_title(1, "جستجو")
	Updatedate.load_user()
	var d = await Updatedate.request("/planes/my_planes")
	saved_users = Updatedate.load_game("saved_users", [])
	add_saved_users()
	if d and d.has("planes"):
		for plan in d.planes:
			if planes.has(plan.name) == false:
				planes.append(plan.name)
				$"TabContainer/فردی/HBoxContainer/OptionButton".add_item(plan.name)
				$"TabContainer/گروهی/HBoxContainer2/OptionButton".add_item(plan.name)
		subplanes = d.planes
		for sub in subplanes:
			if sub.name == planes[0]:
				$"TabContainer/فردی/HBoxContainer/OptionButton2".add_item(sub.subplan)
				$"TabContainer/گروهی/HBoxContainer2/OptionButton2".add_item(sub.subplan)
	_plan = $"TabContainer/فردی/HBoxContainer/OptionButton".get_item_text(0).uri_encode()
	_subplan = $"TabContainer/فردی/HBoxContainer/OptionButton2".get_item_text(0).uri_encode()
	_plan2 = $"TabContainer/گروهی/HBoxContainer2/OptionButton".get_item_text(0).uri_encode()
	_subplan2 = $"TabContainer/گروهی/HBoxContainer2/OptionButton2".get_item_text(0).uri_encode()
	seen = Updatedate.seen
	focus_mode = FOCUS_ALL
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer3/SpinBox".get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer6/SpinBox".get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	get_tree().create_timer(0.10).timeout.connect(func ():
		show())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Panel.position = %name.global_position + Vector2(0, %name.size.y)
	$Panel.size.x = %name.size.x
	#$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".custom_minimum_size.y = size.x / 10
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size.x = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".size.x
	
func _on_button_pressed() -> void:
	user_name = ""
	for child in $"TabContainer/فردی/MarginContainer/VBoxContainer/VBoxContainer".get_children():
		child.queue_free()
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".text = ""
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".size
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".material = ShaderMaterial.new()
	$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect".texture = null
	$"TabContainer/فردی/MarginContainer/VBoxContainer".hide()
	var w = Updatedate.add_wait($"TabContainer/فردی/HBoxContainer2/Button2")
	var d = (await Updatedate.request("/score/get?user_id=%s&plan=%s&subplan=%s"%[%username.text, _plan, _subplan]))
	
	if d and d.has("message"):
		Notification.add_notif(d.message, Notification.ERROR)
	if d and d.has("user"):
		var user = d.user
		user_name = %username.text
		if user.icon == "":
			var split = user.name.split(" ")
			var words = []
			for g in split:
				if g != '':
					words.append(g)
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".text = words[0][0]
			if words.size() > 1:
				$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".text += " " + words.back()[0]
		$"TabContainer/فردی/MarginContainer/VBoxContainer".show()
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/Label".text = "نام و نام خانوادگی : "
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".text = user.custom_name if user.has("custom_name") else "[right] " + user.name
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer2/Label2".text = "نام پدر : " + user.father_name
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer2/Label3".text = "شماره تلفن : " + user.phone
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer3/SpinBox".value = int(d.score)
		
		Updatedate.get_icon_user(user.icon, %username.text ,$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect")
		$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".show()
		if $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect".texture:
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".hide()
		await get_tree().create_timer(
			0.1
		).timeout
		if $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.x > $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".size.x:
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size.x = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.x * 2
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture".size.y = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name/texture/Label".size.y
			var shader = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".material.shader
			var _material = ShaderMaterial.new()
			_material.shader = shader
			_material.set_shader_parameter("dir", get_direction(user.name))
			$"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer5/name".material = _material
	w.queue_free()

func _on_update_user_pressed() -> void:
	
	var r = HTTPRequest.new()
	var w = Updatedate.add_wait($"TabContainer/فردی/MarginContainer/VBoxContainer/Button")
	add_child(r)
	r.timeout = 3
	var score = $"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer3/SpinBox".value
	r.request(Updatedate.protocol+Updatedate.subdomin+"/score/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"name":user_name, "plan":_plan.uri_decode(), "subplan":_subplan.uri_decode(), "score":score, "group":false}))
	var d = await r.request_completed
	while d[3].size() == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/score/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"name":user_name, "plan":_plan.uri_decode(), "subplan":_subplan.uri_decode(), "score":score, "group":false}))
		d = await r.request_completed
	r.queue_free()
	w.queue_free()
	d = Updatedate.get_json(d[3])
	if d.has("message"):
		Notification.add_notif(d.message)
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)


func _on_button2_pressed() -> void:
	$Panel.hide()
	name_group = ""
	for child in $"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer".get_children():
		child.queue_free()
	$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect".texture = Image.new()
	$"TabContainer/گروهی/MarginContainer/VBoxContainer".hide()
	$"TabContainer/گروهی/MarginContainer".hide()
	var w = Updatedate.add_wait($"TabContainer/گروهی/HBoxContainer/Button")
	var d = (await Updatedate.request("/score/group?name=%s&plan=%s&subplan=%s"%[%name.text.uri_encode(), _plan2, _subplan2]))
	if d and d.has("message"):
		Notification.add_notif(d.message, Notification.ERROR)
	if d and d.has("users_info"):
		$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer6/SpinBox".value = d.score
		name_group = %name.text
		Updatedate.get_icon_group(custom_hash.hashing(custom_hash.GET_HASH,d.icon), %name.text ,$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect")
		
		if d.icon == "":
			var split_name = name_group.split(" ")
			var words = []
			for g in split_name:
				if g != "":
					words.append(g)
			$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".text = words[0][0]
			if words.size() > 1:
				$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".text += " "+words[-1][0]
		else:
			$"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect/TextureRect/Label".text = ""
		$"TabContainer/گروهی/MarginContainer/VBoxContainer".show()
		for x in range(d.users.size()):
			var box = $"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer5".duplicate()
			if d.users[x] == d.leader:
				box.get_node("Label").text = "نام سرگروه : "  
				box.get_node("Label2").text = "کد ملی : " + custom_hash.hashing(custom_hash.GET_HASH,d.users[x])
				box.get_node("name/texture/Label").text = "[font_size=45]"+d.users_info[x].custom_name if d.users_info[x].has("custom_name") else d.users_info[x].name
			else:
				box.get_node("Label").text = "نام عضو : "  
				box.get_node("Label2").text = "کد ملی : " + custom_hash.hashing(custom_hash.GET_HASH,d.users[x])
				box.get_node("name/texture/Label").text = d.users_info[x].custom_name if d.users_info[x].has("custom_name") else d.users_info[x].name
			box.show()
			box.get_node("name").dir = get_direction(d.users_info[x].name)
			$"TabContainer/گروهی/MarginContainer/VBoxContainer/VBoxContainer".add_child(box)
		$"TabContainer/گروهی/MarginContainer".show()
	w.queue_free()
	

func _on_update_group_pressed() -> void:
	var data = {"group":true, "plan":_plan2.uri_decode(), "subplan":_subplan2.uri_decode(), "score": $"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer6/SpinBox".value, "name": name_group}
	var r = HTTPRequest.new()
	var w = Updatedate.add_wait($"TabContainer/گروهی/MarginContainer/VBoxContainer/Button")
	add_child(r)
	r.timeout = 3
	r.request(Updatedate.protocol+Updatedate.subdomin+"/score/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
	var d = await r.request_completed
	while d[3].size() == 0:
		r.request(Updatedate.protocol+Updatedate.subdomin+"/score/add", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify(data))
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
	if $TabContainer.current_tab != 0:
		$TabContainer.current_tab = 0
	else:
		Transation.change(self, "start.tscn", -1)
		

func _on_tab_container_tab_selected(tab: int, args=0) -> void:
	Updatedate.load_user()
	$Panel.hide()
	$HBoxContainer.hide()
	if tab == 1:
		var d = await Updatedate.request("/groups/names")
		var g = d.data if d and d.has("data") else []
		groups = []
		for n in g:
			groups.append(n[0])
	
func _on_name_text_changed(new_text: String) -> void:
	for child in $Panel/ScrollContainer/VBoxContainer.get_children():
		if child is Button and child.name != "instance":
			child.queue_free()
	if new_text == "":
		for n in groups:
			var btn = $Panel/ScrollContainer/VBoxContainer/instance.duplicate()
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
			$Panel/ScrollContainer/VBoxContainer.add_child(btn)
	for n in groups:
		if new_text in n:
			$Panel.show()
			var btn = $Panel/ScrollContainer/VBoxContainer/instance.duplicate()
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
			$Panel/ScrollContainer/VBoxContainer.add_child(btn)


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Updatedate.show_picture($"TabContainer/گروهی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture)


func _on_texture_rect_gui_input2(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Updatedate.show_picture($"TabContainer/فردی/MarginContainer/VBoxContainer/BoxContainer/TextureRect".texture)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		$Panel.hide()
		$Panel2.hide()
		$TextureRect2.hide()


func _on_option_button_item_selected(index: int) -> void:
	var plan:String = $"TabContainer/فردی/HBoxContainer/OptionButton".get_item_text(index)
	_plan = plan.uri_encode()
	$"TabContainer/فردی/HBoxContainer/OptionButton2".clear()
	for sub in subplanes:
		if sub.name == plan:
			$"TabContainer/فردی/HBoxContainer/OptionButton2".add_item(sub.subplan)
var search_type = 0
func _on_searchButton_pressed() -> void:
	if %search2.text != "":
		var d 
		var w = Updatedate.add_wait($Panel2/MarginContainer2/VBoxContainer/ScrollContainer)
		var w2 = Updatedate.add_wait($Panel2/MarginContainer2/VBoxContainer/BoxContainer/Button)
		match search_type:
			0:
				d = await Updatedate.request("/control/get_users?name="+%search2.text.uri_encode())
			1:
				d = await Updatedate.request("/control/get_users?username="+%search2.text)
			2:
				d = await Updatedate.request("/control/get_users?phone="+%search2.text)
			
		if d and d.has("data"):
			_remove_child($Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer)
			for user in d.data:
				var instance: PanelContainer = $Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/instance.duplicate()
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer/RichTextLabel").text = "[center]"+ user["first_name"] + " " + user["last_name"]
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer2/Label").text =  "شماره تلفن: " + user["phone"]
				instance.get_node("MarginContainer/VBoxContainer/BoxContainer2/Label2").text =  "کدملی: " + user["username"]
				var btn = instance.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button")
				var btn2:Button = instance.get_node("MarginContainer/VBoxContainer/BoxContainer3/Button2")
				
				var user_data = {"name": user["first_name"] + " " + user["last_name"] + " " +user["father_name"], "username": user["username"]}
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
					$Panel2.hide()
					$TextureRect2.hide()
					%username.text = user["username"])
				instance.show()
				$Panel2/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer.add_child(instance)
		w.queue_free()
		w2.queue_free()

func _remove_child(child, filter_name=["instance", "add"]):
	for n in child.get_children():
		if n.name not in filter_name:
			n.queue_free()
var saved_users = []
func add_saved_users():
	_remove_child($Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2)
	_remove_child($Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer)
	for user in saved_users:
		var btn : Button= $Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/instance.duplicate()
		btn.text = "نام: "+ user.name +"\n کدملی: "+ user.username
		btn.show()
		btn.name = "user"
		btn.pressed.connect(func ():
			$Panel2.hide()
			$TextureRect2.hide()
			%username.text = user["username"])
		$Panel2/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.add_child(btn)
		
	


func _on_search_type_selected(index: int) -> void:
	search_type = index


func _on_select_user_pressed() -> void:
	$Panel2.show()
	$TextureRect2.show()
	


func _on_option_button_2_item_selected(index: int) -> void:
	_subplan = $"TabContainer/فردی/HBoxContainer/OptionButton2".get_item_text(index).uri_encode()


func _on_name_focus_entered() -> void:
	$Panel.show()
	_on_name_text_changed(%name.text)
	


func _on_option_button_item_selected2(index: int) -> void:
	var plan:String = $"TabContainer/گروهی/HBoxContainer2/OptionButton".get_item_text(index)
	_plan2 = plan.uri_encode()
	$"TabContainer/گروهی/HBoxContainer2/OptionButton2".clear()
	for sub in subplanes:
		if sub.name == plan:
			$"TabContainer/گروهی/HBoxContainer2/OptionButton2".add_item(sub.subplan)


func _on_option_button_2_item_selected2(index: int) -> void:
	_subplan = $"TabContainer/گروهی/HBoxContainer2/OptionButton2".get_item_text(index).uri_encode()
