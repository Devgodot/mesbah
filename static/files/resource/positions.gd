extends Control

enum Mode{spiritual, body, idea, all, group}
var mode = Mode.group
var max_diamonds = 1
var change = false
var title_text = ["سلامت معنوی", "سلامت جسمانی", "سلامت فکری", "طرح رمضان 1403-1404"]
func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.load_user()
	mode = Updatedate.part
	var sort
	var my_pos
	var w = Updatedate.add_wait($ScrollContainer)
	var w2 = Updatedate.add_wait($HBoxContainer2/Label)
	var w3 = Updatedate.add_wait($HBoxContainer2/Label3)
	var w4 = Updatedate.add_wait($HBoxContainer2/Panel)
	var gender = Updatedate.load_game("gender", 0)
	var tag = Updatedate.load_game("tag", 0)
	$HBoxContainer2/Label2/TextureRect/TextureRect.gui_input.connect(func (event:InputEvent):
		if event is InputEventScreenTouch:
			if event.is_pressed():
				Updatedate.show_picture($HBoxContainer2/Label2/TextureRect/TextureRect.texture) )
	for x in range(max_diamonds - 1):
		var di = $HBoxContainer2/Panel/HBoxContainer/TextureRect.duplicate()
		$HBoxContainer2/Panel/HBoxContainer.add_child(di)
	if mode < 3:
		sort = await Updatedate.request("/users/all?sort=diamonds%sAND%s&filter=custom_nameANDfirst_nameANDlast_nameANDiconAND%sANDdiamonds%s&pre_page=20"%[str(mode), str("score_", gender, "_", tag, "_", mode), str("score_", gender, "_", tag, "_", mode), str(mode)])
		my_pos = await Updatedate.request("/users/me?sort=diamonds%sAND%s"%[str(mode), str("score_", gender, "_", tag, "_", mode)])
	if mode == 3:
		max_diamonds = 3
		sort = await Updatedate.request("/users/all?sort=diamondsANDscore&filter=custom_nameANDfirst_nameANDlast_nameANDiconANDscoreANDdiamonds&pre_page=20")
		my_pos = await Updatedate.request("/users/me?sort=diamondsANDscore")
		var length = (await Updatedate.request("/users/length"))
		$Label12.text = "تعداد نفرات: "
		$Label12.text += str(int(length.length)) if length and length.has("length") else "0"
		$Label12.show()
	if mode == 4:
		$Label10.text = "تیم های برتر\n"+ title_text[3]
		$Label11.text = "جایگاه تیم شما در\n" +title_text[3]
		max_diamonds = 3
		sort = await Updatedate.request("/groups/all?pre_page=20")
		my_pos = await Updatedate.request("/groups/me")
		var length = (await Updatedate.request("/groups/length"))
		$Label12.text = "تعداد گروه ها: "
		$Label12.text += str(int(length.length)) if length and length.has("length") else "0"
		$Label12.show()
		if my_pos and my_pos.has("name"):
			$HBoxContainer2/Label2.text = my_pos.name
			Updatedate.get_icon_group(my_pos.icon, my_pos.name, $HBoxContainer2/Label2/TextureRect/TextureRect)
		else:
			
			$HBoxContainer2/Label2.text = "عضو گروه نیستید"
	else:
		$Label10.text += title_text[mode]
		$Label11.text += title_text[mode]
		Updatedate.get_icon_user(Updatedate.load_game("icon", ""), Updatedate.load_game("user_name", ""), $HBoxContainer2/Label2/TextureRect/TextureRect)
		var pro = Updatedate.load_game("pro", false)
		if pro:
			$HBoxContainer2/Label2/name/texture/Label.text = Updatedate.load_game("custom_name", "[right]" + Updatedate.load_game("first_name", "")+ " "+ Updatedate.load_game("last_name", ""))
			await get_tree().create_timer(0.1).timeout
			$HBoxContainer2/Label2/name.texture = $HBoxContainer2/Label2/name/texture.get_texture()
			if $HBoxContainer2/Label2/name/texture/Label.size.x > 437:
				$HBoxContainer2/Label2/name/texture.size.x = $HBoxContainer2/Label2/name/texture/Label.size.x * 1.5
				var shader = $HBoxContainer2/Label2/name.material.shader
				var _material = ShaderMaterial.new()
				_material.shader = shader
				_material.set_shader_parameter("dir", get_direction(Updatedate.load_game("first_name", "")+ " "+ Updatedate.load_game("last_name", "")))
				$HBoxContainer2/Label2/name.material = _material
		else:
			$HBoxContainer2/Label2.text = Updatedate.load_game("first_name", "") + " " + Updatedate.load_game("last_name", "")
		
	if sort and sort.has("message"):
		$Label5.show()
	if sort and sort.has("users"):
		var users = sort.users
		for user in users:
			var data= user.data
			var _name = "[center]"+data.first_name + " " + data.last_name if data.has("last_name") and data.has("first_name") else user.phone.left(4) + "***" + user.phone.right(4)
			_name = data.custom_name if data.has("custom_name") else _name
			var diamonds = 0
			var score = 0
			if mode < 3:
				score = data[str("score_", gender, "_", tag, "_", mode)] if data.has(str("score_", gender, "_", tag, "_", mode)) else 0
				diamonds = data["diamonds"+str(mode)] if data.has("diamonds"+str(mode)) else 0
			else:
				score = data["score"] if data.has("score") else 0
				diamonds = data["diamonds"] if data.has("diamonds") else 0
				
			var pos = data.position if data.has("position") else 0
			var icon = custom_hash.hashing(custom_hash.GET_HASH, data.icon) if data.has("icon") else ""
			var box: HBoxContainer = $ScrollContainer/VBoxContainer/HBoxContainer.duplicate()
			box.show()
			box.get_node("Label").text = str(int(pos))
			box.get_node("Label3").text = str(int(score))
			box.get_node("Label2").get_child(1).get_child(0).gui_input.connect(func (event:InputEvent):
				if event is InputEventScreenTouch:
					if event.is_pressed():
						Updatedate.show_picture(box.get_node("Label2").get_child(1).get_child(0).texture))
			Updatedate.get_icon_user(icon, custom_hash.hashing(custom_hash.GET_HASH, user.username), box.get_node("Label2").get_child(1).get_child(0))
			for x in range(max_diamonds - 1):
				var di = box.get_node("Panel").get_child(0).get_child(0).duplicate()
				box.get_node("Panel").get_child(0).add_child(di)
			for x in range(diamonds):
				if x < box.get_node("Panel").get_child(0).get_children().size():
					box.get_node("Panel").get_child(0).get_child(x).modulate = Color.WHITE
			box.get_node("Label2/name/texture/Label").text = _name
			$ScrollContainer/VBoxContainer.add_child(box)
			box.get_node("Label2/name").texture = box.get_node("Label2/name/texture").get_texture()
			if box.get_node("Label2/name/texture/Label").size.x > 437:
				box.get_node("Label2/name/texture").size.x = box.get_node("Label2/name/texture/Label").size.x * 1.5
				var shader = $ScrollContainer/VBoxContainer/HBoxContainer/Label2/name.material.shader
				var _material = ShaderMaterial.new()
				_material.shader = shader
				_material.set_shader_parameter("dir", get_direction(data.first_name + " " + data.last_name))
				box.get_node("Label2/name").material = _material
	elif sort and sort.has("result"):
		var result = sort.result
		for group in result:
			var _name = group.name if group.has("name") else ""
			var diamonds = group.diamonds if group.has("diamonds") else 0
			var score = group.score if group.has("score") else 0
			var pos = group.position if group.has("position") else 0
			var icon = custom_hash.hashing(custom_hash.GET_HASH, group.icon) if group.has("icon") else ""
			var box: HBoxContainer = $ScrollContainer/VBoxContainer/HBoxContainer.duplicate()
			box.show()
			box.get_node("Label").text = str(int(pos))
			box.get_node("Label2").text = _name
			box.get_node("Label3").text = str(int(score))
			box.get_node("Label2").get_child(1).get_child(0).gui_input.connect(func (event:InputEvent):
				
				if event is InputEventScreenTouch:
					
					if event.is_pressed():
						Updatedate.show_picture(box.get_node("Label2").get_child(1).get_child(0).texture))
			Updatedate.get_icon_group(icon, _name, box.get_node("Label2").get_child(1).get_child(0))
			for x in range(max_diamonds - 1):
				var di = box.get_node("Panel").get_child(0).get_child(0).duplicate()
				box.get_node("Panel").get_child(0).add_child(di)
			for x in range(diamonds):
				if x < box.get_node("Panel").get_child(0).get_children().size():
					box.get_node("Panel").get_child(0).get_child(x).modulate = Color.WHITE
			$ScrollContainer/VBoxContainer.add_child(box)
	for x in range(max_diamonds - 1):
		var di = $HBoxContainer2/Panel/HBoxContainer/TextureRect.duplicate()
		$HBoxContainer2/Panel/HBoxContainer.add_child(di)
	if my_pos and my_pos.has("pos") and my_pos.pos == 0:
		$HBoxContainer2/Label.text = "-"
		$HBoxContainer2/Label3.text = "-"
	if my_pos and my_pos.has("nums"):
		$HBoxContainer2/Label.text = str(int(my_pos.pos))
		$HBoxContainer2/Label3.text = str(int(my_pos.nums[1]))
		for x in range(my_pos.nums[0]):
			if x < $HBoxContainer2/Panel/HBoxContainer.get_children().size():
				$HBoxContainer2/Panel/HBoxContainer.get_child(x).modulate = Color.WHITE
	w.queue_free()
	w2.queue_free()
	w3.queue_free()
	w4.queue_free()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, Updatedate.p_scene+".tscn", -1)
func _on_back_button_pressed() -> void:
	Transation.change(self, Updatedate.p_scene+".tscn", -1)
