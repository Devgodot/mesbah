extends Control

var supporters = []
var part = 0
var messages = []
@onready var vbox = $VBoxContainer
@onready var text_edit: TextEdit = $VBoxContainer/Panel/VBoxContainer/HBoxContainer/TextEdit
var scroll = [0, 0, 0]
var change = false
var seen_message = [[], [], []]
var check = false
var senderId = "0"
var action_box
var fram = 0
var responses = []
var box_ref
var max_line = 5
var times = []
var edited_box:PanelContainer
var not_seen
var plugin
var base_height = 0
var offset = 0
var screen_size
func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1
func uuid(len:int, step:int=4):
	var w = ["z", "x", "w", "v", "u", "t", "s", "r", "q", "p", "o", "n", "m", "l", "k", "j", "i", "h", "g", "f", "e", "d", "c", "b", "a", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	var id = ""
	for x in len:
		id += w.pick_random()
	var y = 0
	for x in (len / step - 1) if len % step == 0 else len / step:
		id = id.insert(((x + 1) * step) + y, "_")
		y += 1
	return id
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	# گرفتن لیست صداها
	#var voices = DisplayServer.tts_get_voices()
	#print("Available voices:", voices)
	#
	# گفتن متن
	#DisplayServer.tts_speak("salam man mohammad hosein hastam", "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Speech\\Voices\\Tokens\\TTS_MS_EN-US_ZIRA_11.0", 100, 1.0, 1.5)
	
	#DisplayServer.dialog_input_text("نام خود را بنویسید", "", "mhh", func(text):
		#print(text))
	#DisplayServer.dialog_show("test", "", ["1", "2", "3"], func(btn):
		#print(btn))
	
	focus_mode = FOCUS_ALL
	Updatedate.load_user()
	var c = Updatedate.conversation
	senderId = Updatedate.load_game("user_name", "")
	if c.has("id"):
		Updatedate.seen_message.connect(func(message:Dictionary):
			if message:
				if message.conversationId + message.part == c.id:
					messages[messages.find_custom(func(x):return x["id"] == message["id"])] = message
					var y = get_tree().get_nodes_in_group("message").find_custom(func (x): return x.get_meta("id", "") == message["id"])
					var box = get_tree().get_nodes_in_group("message")[y]
					box.seen = message.seen
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D").default_color = Color("32ff06")
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").default_color = Color("32ff06")
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").show()
				)
		Updatedate.edit_message.connect(func (message:Dictionary):
			if message:
				if message.conversationId + message.part == c.id:
					messages[messages.find_custom(func(x):return x["id"] == message["id"])] = message
					var y = get_tree().get_nodes_in_group("message").find_custom(func (x): return x.get_meta("id", "") == message["id"])
					get_tree().get_nodes_in_group("message")[y].get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  message.messages.text
				) 
		Updatedate.recive_message.connect(func(message, id):
			if message.conversationId + message.part == c.id:
				messages.append(message)
				if message.time.split(" ")[0] not in times.map(func(x):return x[2]):
					times.append([message.id, message.time, message.time.split(" ")[0]])
				var pos = -1
				for m in get_tree().get_nodes_in_group("message"):
					if m.get_meta("id", '') == id:
						pos = m.get_index()
						m.queue_free()
				add_message(message, pos)
				)
		Updatedate.delete_message.connect(func (id, message):
			if id == c.id:
				
				var m = get_tree().get_nodes_in_group("message").filter(func (x):return x.get_meta("id") == message)
				if m.size() > 0:
					var box = m[0]
					box.self_modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emitting = true
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emission_rect_extents = box.size / 2
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").position = box.size / 2
					if box_ref == box:
						_on_null_ref_pressed()
					await box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").finished
					box.queue_free()
					var t = messages[(messages.find_custom(func(x): return x.id == message))].time.split(" ")[0]
					messages.remove_at(messages.find_custom(func(x): return x.id == message))
					var t2 = messages.filter(func(x): return x.time.split(" ")[0] == t)
					if t2.size() == 0:
						times.remove_at(times.find_custom(func(x):return x[2] == t))
						for node in get_tree().get_nodes_in_group("times"):
							if node.get_meta("time", "") == t:
								node.queue_free()
					)
	if c.has("state"):
		if c.state == "online":
			$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "وضعیت: آنلاین"
		else:
			if c.last_seen.has("time"):
				$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "آخرین بازدید: " + c.last_seen.time
	if c.has("icon"):
		Updatedate.get_icon_user(c.icon, c.username, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect)
	$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name/texture/Label.text = c.custom_name if c.has("custom_name") and c.custom_name != "" else c.name if c.has("name") else ""
	if c.has("name"):
		if not c.has("icon"):
			get_text_name(c.name, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect/Label)
		if c.has("icon") and c.icon == "" and $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect.texture == null:
			get_text_name(c.name, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect/Label)
		$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name.dir = get_direction(c.name)
	if c.has("id"):
		messages = Updatedate.load_messages(Updatedate.conversation.id)
		for m in messages:
			if m.time.split(" ")[0] not in times.map(func(x):return x[2]):
				times.append([m.id, m.time, m.time.split(" ")[0]])
	var l = get_last_message()
	var index = 0
	for m in messages:
		if index <= l[0]:
			add_message(m)
		index += 1
	await get_tree().create_timer(0.1).timeout
	if l[1]:
		$VBoxContainer/ScrollContainer.get_item_pos(l[1].id)
	if Updatedate.conversation.has("id"):
		if Updatedate.waiting_message.has(Updatedate.conversation.id):
			for m in Updatedate.waiting_message[Updatedate.conversation.id]:
				add_message(m)
	show()
	
	check = true
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.gui_input.connect(func(event:InputEvent):
		if event is InputEventScreenTouch:
			if event.is_released() and box_ref:
				var ref_box = await $VBoxContainer/ScrollContainer.get_item_pos(box_ref.get_meta("id", ""))
				if ref_box:
					$ColorRect2.size.y = ref_box.size.y
					$ColorRect2.global_position.y = ref_box.global_position.y
					$AnimationPlayer2.play("fade"))
	$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name.show()
func get_last_message():
	for m in messages:
		if m.sender != senderId and (not m.has("seen") or m.seen == null):
			not_seen = m
			break
	if not_seen:
		var x = messages.find(not_seen)
		var delta = messages.size() - x
		if delta > 20:
			return [x, not_seen]
		else:
			return [x - (20 - delta), not_seen] if x - (20 - delta) > 0 else [0, not_seen]
	return [messages.size() - 20 if messages.size() - 20 > 0 else messages.size(), messages.back()]
func add_message(m, pos=-1):
	var obj:Node
	if m.sender == senderId:
		obj=$VBoxContainer/ScrollContainer/VBoxContainer/instance
	else:
		obj = $VBoxContainer/ScrollContainer/VBoxContainer/instance3
	if not_seen and m == not_seen:
		var _label = $VBoxContainer/ScrollContainer/VBoxContainer/instance2.duplicate()
		_label.show()
		_label.text = "پیام‌های خوانده نشده"
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(_label)
	if m.id in times.map(func(x):return x[0]):
		var label = $VBoxContainer/ScrollContainer/VBoxContainer/instance2.duplicate()
		var t = times.filter(func(x): return x[0] == m.id)[0][1]
		label.add_to_group("times")
		label.set_meta("time", times.filter(func(x): return x[0] == m.id)[0][2])
		var _t = t.split(" ")[0]
		var dic_time = {year=_t.split("/")[0], mounth=_t.split("/")[1], day=_t.split("/")[2]}
		var day = ""
		var mounthes = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]
		if t.split("$").size() == 2:
			day = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه'][int(t.split("$")[1])]
		if dic_time.year == Updatedate.year:
			label.text = str(day, " ", dic_time.day, " ", mounthes[int(dic_time.mounth) -1])
		else:
			label.text = str(dic_time.day, " ", mounthes[int(dic_time.mounth) -1], " ", dic_time.year)
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(label)
		if pos != -1:
			$VBoxContainer/ScrollContainer/VBoxContainer.move_child(label, pos)
			pos += 1
	var box :PanelContainer= obj.duplicate()
	box.add_theme_stylebox_override("panel", box.get_theme_stylebox("panel").duplicate())
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").add_theme_stylebox_override("normal", box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").get_theme_stylebox("normal").duplicate())
	box.show()
	if m.has("createdAt"):
		if not m.has("seen") or (m.has("seen") and m.seen == null):
			if Updatedate.conversation.last_seen != {}:
				if Updatedate.conversation.last_seen.timestamp > m.createdAt or Updatedate.conversation.state == "online":
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D").default_color = Color.GRAY
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").default_color = Color.GRAY
				else:
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D").default_color = Color.GRAY
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").hide()
			else:
				box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D").default_color = Color.GRAY
				box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").hide()
	else:
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D").hide()
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Line2D2").hide()
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/Node2D/Node2D").show()
	var time = m.time if m.has("time") else ""
	var weekday = (time.split("$")) if time != "" else [""]
	if m.has("sender_name"):
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Label").text = m.sender_name
	box.edit.connect(func (pos):
		if action_box != box:
			if action_box:
				action_box.get_node("AnimationPlayer").play("RESET")
			box.get_node("AnimationPlayer").play("action")
			action_box = box
			var x = box.global_position.x
			if m.sender != senderId:
				x += box.size.x
				$Node2D/AnimationPlayer2.play("flip_r")
			else:
				$Node2D/AnimationPlayer2.play("flip_l")
			$Node2D.global_position = Vector2(x, pos)
			$Node2D.global_position.y = clamp(pos, 186, $VBoxContainer/ScrollContainer.global_position.y + $VBoxContainer/ScrollContainer.size.y - 186)
			$Node2D.show()
			$Node2D/AnimationPlayer.play("action")
		)
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = weekday[0]
	box.add_to_group("message")
	box.set_meta("id", m.id)
	box.response.connect(func():
		if edited_box == null:
			box_ref = box
		)
	if m.response and m.response != "":
		var ref =  messages.filter(func(x):return x.id == m.response)
		if ref.size() == 1:
			var index = messages.find(ref[0])
			var index2 = messages.find(m)
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").text = ref[0].messages.text
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").gui_input.connect(func(event:InputEvent):
				if event is InputEventScreenTouch:
					if event.is_released():
						if !responses.has(box):  
							responses.append(box)
						
						var ref_box = await $VBoxContainer/ScrollContainer.get_item_pos(m.response)
						$ColorRect2.size.y = ref_box.size.y
						$ColorRect2.global_position.y = ref_box.global_position.y
						$AnimationPlayer2.play("fade"))
						
		else:
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").hide()
	else:
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").hide()
	if box.has_signal("screen_entered"):
		box.screen_entered.connect(func(seen):
			if seen == null:
				if senderId != m.sender and senderId in Updatedate.conversation.id:
					Updatedate.message_seen(m.id)
			check_has_node(box))
	$VBoxContainer/ScrollContainer/VBoxContainer.add_child(box)
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  m.messages.text
	var size_y = - vbox.get_theme_constant("separation")
	var vbox : VBoxContainer = box.get_node("HBoxContainer/MarginContainer/VBoxContainer")
	if pos != -1:
		$VBoxContainer/ScrollContainer/VBoxContainer.move_child(box, pos)
	return box
func check_has_node(node):
	if check:
		var index = node.get_index()
		var above_node
		var below_node 
		var n = messages.find_custom(func(x): return node.get_meta("id", "") == x["id"])
		if messages.size() > n + 1:
			below_node = messages[n + 1]
		if n > 0:
			above_node = messages[n - 1]
		
		var nodes = get_tree().get_nodes_in_group("message").filter(func(x):return (above_node and x.get_meta("id", "") == above_node["id"]) or (below_node and x.get_meta("id", "") == below_node["id"])).map(func(x):return x.get_meta("id", ""))
		if above_node and not nodes.has(above_node["id"]):
			add_message(above_node, index)
		if below_node and not nodes.has(below_node["id"]):
			add_message(below_node, index+1)
			
func get_keyboard_offset():
	var screen_size = DisplayServer.get_display_safe_area()
	var _scale = size.y / get_tree().root.size.y
	return (DisplayServer.screen_get_size().y - (screen_size.size.y + screen_size.position.y)) * _scale
func get_user_text(f, l, node:Label):
	node.text += f[0] if f != "" else ""
	node.text += " "+ l[0] if l != "" else ""
func get_text_name(text, node:Label):
	var split = text.split(" ")
	var words = []
	for g in split:
		if g != "":
			words.append(g)
	node.text = words[0][0] if words.size() > 0 else ""
	node.text += " " + words.back()[0] if words.size() > 1 else ""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	offset = get_keyboard_offset()
	if edited_box:
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = text_edit.text
	if fram <= 6:
		fram += 1
	for box in responses:
		if box.global_position.y < ($VBoxContainer/ScrollContainer.size.y / 2) + $VBoxContainer/ScrollContainer.global_position.y:
			responses.erase(box)
	if box_ref:
		$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = box_ref.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text
		$VBoxContainer/Panel/VBoxContainer/MarginContainer.show()
	$ColorRect2.size.x = size.x
	
	if offset > 100:
		vbox.size.y = size.y - 95 - vbox.position.y - offset
	else:
		vbox.size.y = size.y - 10 - vbox.position.y
	var index = 0
	for x in text_edit.get_line_count():
		for y in text_edit.get_line_wrap_count(x) + 1:
			index += 1
	if index <= max_line:
		text_edit.custom_minimum_size.y = index * text_edit.get_line_height() + 10
	if index > max_line:
		text_edit.custom_minimum_size.y = max_line * text_edit.get_line_height() + 10
	var s:PackedStringArray = text_edit.text.split(" ")
	var s2:PackedStringArray = text_edit.text.split("‌‌")
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
func _on_button_pressed() -> void:
	if edited_box:
		Updatedate.send_edit_message(edited_box.get_meta("id", ""),text_edit.text)
		_on_null_ref_pressed()
	else:
		if not Updatedate.waiting_message.has(Updatedate.conversation.id):
			Updatedate.waiting_message[Updatedate.conversation.id] = []
		var id = uuid(20, 5)
		var m = {"messages":{"text":text_edit.text}, "id":id, "part":Updatedate.conversation.part, "sender":Updatedate.load_game("user_name", ""), "sender_name":"شما", "response":box_ref.get_meta("id", "") if box_ref else ""}
		Updatedate.waiting_message[Updatedate.conversation.id].append(m)
		add_message(m)
		Updatedate.send_message(text_edit.text, id, box_ref.get_meta("id", "") if box_ref else "")
		text_edit.text = ""
		_on_null_ref_pressed()
func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)
	

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if meta.begins_with("http"):
		OS.shell_open(meta)
	else:
		OS.shell_open("https://"+meta)


func _on_timer_timeout() -> void:
	if $VBoxContainer/Control/Button.visible:
		$AnimationPlayer.play_backwards("pop_button")

func _on_scroll_container_start_scroll() -> void:
	if $ColorRect2.visible:
		$ColorRect2.hide()
	if not $VBoxContainer/Control/Button.visible:
		$AnimationPlayer.play("pop_button")
	else:
		$Timer.start()


func _on_scroll_pressed() -> void:
	$AnimationPlayer.play_backwards("pop_button")
	if responses.size() > 0:
		var ref_box = await $VBoxContainer/ScrollContainer.get_item_pos(responses[0].get_meta("id", ""), -1)
		$ColorRect2.size.y = ref_box.size.y
		$ColorRect2.global_position.y = ref_box.global_position.y
		$AnimationPlayer2.play("fade")
		responses.erase(ref_box)
	else:
		$VBoxContainer/ScrollContainer.get_item_pos(messages.back().id, -10)
	


func _on_null_ref_pressed() -> void:
	if box_ref:
		box_ref = null
	if edited_box:
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = $VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text
		text_edit.text = ""
		edited_box.z_index = 0
		edited_box = null
		$AnimationPlayer2.play_backwards("fade2")
	$VBoxContainer/Panel/VBoxContainer/MarginContainer.hide()
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = ""


func _on_text_edit_text_changed() -> void:
	var btn = $VBoxContainer/Panel/VBoxContainer/HBoxContainer/Control/Button
	if text_edit.text != "" and btn.scale < Vector2.ONE:
		var tween = get_tree().create_tween()
		tween.tween_property(btn, "scale", Vector2.ONE, 0.3)
		tween.play()
	if text_edit.text == "":
		var tween = get_tree().create_tween()
		tween.tween_property(btn, "scale", Vector2.ZERO, 0.3)
		tween.play()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index != MOUSE_BUTTON_RIGHT:
			if action_box:
				off_action()


func _on_delete_pressed() -> void:
	DisplayServer.dialog_show("حذف پیام", "آیا از حذف این پیام، اطمینان دارید؟ این پیام برای هر دو نفر پاک خواهد شد.", ["بله", "خیر"], func(btn):
		if btn == 0:
			if action_box:
				Updatedate.delete(action_box.get_meta('id', ""))
				off_action())

	
func off_action():
	action_box.get_node("AnimationPlayer").play("RESET")
	action_box = null
	$Node2D/AnimationPlayer.play_backwards("action")
	await $Node2D/AnimationPlayer.animation_finished
	if action_box == null:
		$Node2D.hide()

func _on_edit_pressed() -> void:
	_on_null_ref_pressed()
	edited_box = action_box
	$AnimationPlayer2.play("fade2")
	edited_box.z_index = 1
	text_edit.text = edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text
	$VBoxContainer/Panel/VBoxContainer/MarginContainer.show()
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = text_edit.text
	off_action()


func _on_copy_pressed() -> void:
	if action_box:
		DisplayServer.clipboard_set(action_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text)
		Notification.add_notif("متن کپی شد.")
		off_action()
