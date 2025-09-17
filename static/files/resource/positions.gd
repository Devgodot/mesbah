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

func get_user_text(f, l, node:Label):
	node.text += f[0] if f != "" else ""
	node.text += "‌"+ l[0] if l != "" else ""
func get_text_name(text, node:Label):
	var split = text.split(" ")
	var words = []
	for g in split:
		if g != "":
			words.append(g)
	node.text = words[0][0] if words.size() > 0 else ""
	node.text += "‌" + words.back()[0] if words.size() > 1 else ""
# Called when the node enters the scene tree for the first time.
func _sort(data):
	print(data)
	for box in get_tree().get_nodes_in_group("boxes"):
		box.queue_free()
	var users = data.users
	for user in users:
		$Panel/Label5.hide()
		var _name = "[center]"+user.first_name + " " + user.last_name
		_name = user.custom_name if user.has("custom_name") and user.custom_name != "" else _name
		var diamonds = user.diamond_sum
		var score = user.score_sum
		var pos = user.position if user.has("position") else 0
		var icon = custom_hash.hashing(custom_hash.GET_HASH, user.icon) if user.has("icon") else ""
		var box: HBoxContainer = $ScrollContainer/VBoxContainer/HBoxContainer.duplicate()
		box.add_to_group("boxes")
		box.show()
		box.get_node("Label").text = str(int(pos))
		box.get_node("Label3").text = str(int(score))
		Updatedate.get_icon_user(icon, custom_hash.hashing(custom_hash.GET_HASH, user.name), box.get_node("Label2").get_child(1).get_child(0))
		var label = box.get_node("Label2").get_child(1).get_child(0).get_node("Label")
		get_user_text(user.first_name,  user.last_name, label)
		if user.icon != "" or box.get_node("Label2").get_child(1).get_child(0).texture != null:
			label.hide()
		for x in range(max_diamonds - 1):
			var di = box.get_node("Panel").get_child(0).get_child(0).duplicate()
			box.get_node("Panel").get_child(0).add_child(di)
		for x in range(diamonds):
			if x < box.get_node("Panel").get_child(0).get_children().size():
				box.get_node("Panel").get_child(0).get_child(x).modulate = Color.WHITE
		box.get_node("Label2/name/texture/Label").text = _name
		box.get_node("Label2/name").dir = get_direction(user.first_name)
		$ScrollContainer/VBoxContainer.add_child(box)
	$HBoxContainer2/Label.text = str(int(data.your_info.position)) if data.your_info.position else "-"
	$HBoxContainer2/Label3.text = str(int(data.your_info.score_sum))
	var label = $HBoxContainer2/Label2/TextureRect/TextureRect/Label
	var first_name = Updatedate.load_game("first_name", "")
	var last_name = Updatedate.load_game("last_name", "")
	get_user_text(first_name, last_name, label)
	if Updatedate.load_game("icon", '') != "" or $HBoxContainer2/Label2/TextureRect/TextureRect.texture != null:
		label.hide()
	for x in range(data.your_info.diamond_sum):
		if x < $HBoxContainer2/Panel/HBoxContainer.get_children().size():
			$HBoxContainer2/Panel/HBoxContainer.get_child(x).modulate = Color.WHITE
func _ready() -> void:
	Updatedate.load_user()
	if Updatedate.plan != "":
		if Updatedate.subplan == "":
			if Updatedate.group_plan:
				Updatedate.request("/score/group_sort?plan=%s&max_members=%d"%[Updatedate.plan.uri_encode(), 20])
			else:
				Updatedate.request("/score/sort?plan=%s&max_members=%d"%[Updatedate.plan.uri_encode(), 20])
		else:
			if Updatedate.group_plan:
				Updatedate.request("/score/group_sort?plan=%s&max_members=%d&subplan=%s"%[Updatedate.plan.uri_encode(), 20, Updatedate.subplan.uri_encode()])
			else:
				Updatedate.request("/score/sort?plan=%s&max_members=%d&subplan=%s"%[Updatedate.plan.uri_encode(), 20, Updatedate.subplan.uri_encode()])
	Updatedate.request_completed.connect(func(data, url:String):
		if url.begins_with("/score/group_sort"):
			if data:
				Updatedate.save("group_sort_"+Updatedate.plan+Updatedate.subplan, data, false)
				group_sort(data)
		if url == "/users/length":
			if data:
				Updatedate.save("num_users", data.length)
				$Label12.text = "تعداد نفرات: "
				$Label12.text += str(int(data.length)) if data.has("length") else "0"
				$Label12.show()
		if url == "/groups/length":
			if data:
				Updatedate.save("num_groups", data.length)
				$Label12.text = "تعداد گروه ها: "
				$Label12.text += str(int(data.length)) if  data.has("length") else "0"
				$Label12.show()
		if data and data.has("users") and url.begins_with("/score/sort"):
			Updatedate.save("sort_"+Updatedate.plan+Updatedate.subplan, data, false)
			_sort(data)
			)
	if Updatedate.plan != "" and Updatedate.subplan == "" and Updatedate.group_plan == false:
		max_diamonds = 3
		Updatedate.request("/users/length")
		$Label12.text = "تعداد نفرات: "
		$Label12.text += str(int(Updatedate.load_game("num_users", 0)))
		$Label12.show()
	if Updatedate.plan != "" and Updatedate.subplan == "" and Updatedate.group_plan == true:
		max_diamonds = 3
		$Label12.text = "تعداد گروه ها: "
		$Label12.text += str(int(Updatedate.load_game("num_groups", 0)))
		$Label12.show()
		Updatedate.request("/groups/length")
	if Updatedate.group_plan == false:
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
		
	
	if Updatedate.group_plan:
		$Label10.text = "تیم های برتر\n" + Updatedate.plan + " "
		$Label10.text += ("("+ Updatedate.subplan+")") if Updatedate.subplan != "" else ""
		$Label11.text = "جایگاه تیم شما در\n" + Updatedate.plan + ' '
		$Label11.text += ("("+ Updatedate.subplan+")") if Updatedate.subplan != "" else ""
	else:
		$Label10.text += Updatedate.plan + " "
		$Label10.text += ("("+ Updatedate.subplan+")") if Updatedate.subplan != "" else ""
		$Label11.text += Updatedate.plan + " "
		$Label11.text += ("("+ Updatedate.subplan+")") if Updatedate.subplan != "" else ""
	for x in range(max_diamonds - 1):
		var di = $HBoxContainer2/Panel/HBoxContainer/TextureRect.duplicate()
		$HBoxContainer2/Panel/HBoxContainer.add_child(di)
	if not Updatedate.group_plan:
		if Updatedate.load_game("sort_"+Updatedate.plan+Updatedate.subplan, {}) != {}:
			_sort(Updatedate.load_game("sort_"+Updatedate.plan+Updatedate.subplan, {}))
	else:
		if Updatedate.load_game("group_sort_"+Updatedate.plan+Updatedate.subplan, {}) != {}:
			group_sort(Updatedate.load_game("group_sort_"+Updatedate.plan+Updatedate.subplan, {}))
	await get_tree().create_timer(0.1).timeout
	show()
func group_sort(data):
	for box in get_tree().get_nodes_in_group("boxes"):
		box.queue_free()
	for group in data.groups:
		$Panel/Label5.hide()
		var _name = group.name if group.has("name") else ""
		var diamonds = group.diamond_sum if group.has("diamond_sum") else 0
		var score = group.score_sum if group.has("score_sum") else 0
		var pos = group.position if group.has("position") else 0
		var icon = custom_hash.hashing(custom_hash.GET_HASH, group.icon) if group.has("icon") else ""
		var box: HBoxContainer = $ScrollContainer/VBoxContainer/HBoxContainer.duplicate()
		box.add_to_group("boxes")
		box.show()
		box.get_node("Label").text = str(int(pos))
		box.get_node("Label2").text = _name
		box.get_node("Label3").text = str(int(score))
		Updatedate.get_icon_group(icon, _name, box.get_node("Label2").get_child(1).get_child(0))
		var label = box.get_node("Label2").get_child(1).get_child(0).get_node("Label")
		get_text_name(_name, label)
		if group.icon != "" or box.get_node("Label2").get_child(1).get_child(0).texture != null:
			label.hide()
		for x in range(max_diamonds - 1):
			var di = box.get_node("Panel").get_child(0).get_child(0).duplicate()
			box.get_node("Panel").get_child(0).add_child(di)
		for x in range(diamonds):
			if x < box.get_node("Panel").get_child(0).get_children().size():
				box.get_node("Panel").get_child(0).get_child(x).modulate = Color.WHITE
		$ScrollContainer/VBoxContainer.add_child(box)
	if data.your_info:
		$HBoxContainer2/Label.text = str(int(data.your_info.position)) if data.your_info.position else "-"
		$HBoxContainer2/Label3.text = str(int(data.your_info.score_sum))
		$HBoxContainer2/Label2.text = data.your_info.name
		Updatedate.get_icon_group(data.your_info.icon, data.your_info.name, $HBoxContainer2/Label2/TextureRect/TextureRect)
		var label = $HBoxContainer2/Label2/TextureRect/TextureRect/Label
		get_text_name(data.your_info.name, label)
		if data.your_info.icon != "" or $HBoxContainer2/Label2/TextureRect/TextureRect.texture != null:
			label.hide()
		for x in range(data.your_info.diamond_sum):
			if x < $HBoxContainer2/Panel/HBoxContainer.get_children().size():
				$HBoxContainer2/Panel/HBoxContainer.get_child(x).modulate = Color.WHITE
	else:
		$HBoxContainer2/Label2.text = "عضو گروه نیستید"
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, Updatedate.p_scene+".tscn", -1)
func _on_back_button_pressed() -> void:
	Transation.change(self, Updatedate.p_scene+".tscn", -1)
