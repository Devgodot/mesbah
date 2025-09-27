extends Control

var supporters = []
var part = 0
var messages = {}
@onready var vbox = $VBoxContainer
@onready var text_edit: TextEdit = $VBoxContainer/Panel/VBoxContainer/HBoxContainer/TextEdit
var scroll = [0, 0, 0]
var change = false
var seen_message = [[], [], []]
var check = false
var last_index = 0
var last_index2 = 0
var last_vbox_size = 0
var senderId = "0"
var action_box
var fram = 0
var responses = []
var box_ref
var max_line = 5
var times = {}
var edited_box:PanelContainer
var not_seen
var plugin
var base_height = 0
var offset = 0
var screen_size
var unseen_len = 0
var ids = []
var unseen_ids = [1]
var last_id = ""
var r_id = ""
var last_height = 0
var has_keyboard = false
var action_box_offset = Vector2.ZERO
var mobile_box
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
	var btn = $VBoxContainer/Panel/VBoxContainer/HBoxContainer/Control/Button
	if Engine.has_singleton("GodotGetFile"):
		mobile_box = Engine.get_singleton("GodotGetFile")
		mobile_box.text_changed.connect(func (text):
			var s:PackedStringArray = text.split(" ")
			var s2:PackedStringArray = text.split("‌‌")
			var s3:PackedStringArray = text.split("‌\n")
			var not_Space = false
			var not_Space2 = false
			var not_line = false
			for g in s:
				g = g.replace("‌", "")
				g = g.replace(" ", "")
				g = g.replace("\n", "")
				if g != "" and g != "‌" and g != "‌ "and g!="\n":
					not_Space = true
					break
			for g in s2:
				g = g.replace(" ", "")
				g = g.replace("‌", "")
				g = g.replace("\n", "")
				if g != "" and g != "‌" and g != "‌ "and g!="\n":
					not_Space2 = true
					break
			for g in s3:
				g = g.replace(" ", "")
				g = g.replace("\n", "")
				g = g.replace("‌", "")
				if g != "" and g != "‌" and g != "‌ " and g!="\n":
					not_line = true
					break
			
			if not_line and not_Space and not_Space2:
				
				if btn.scale < Vector2.ONE:
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2.ONE, 0.3)
					tween.play()
			else:
				if btn.scale > Vector2.ZERO:
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2.ZERO, 0.3)
					tween.play()
				)
			
		mobile_box.showTextBox(text_edit.global_position.x, text_edit.global_position.y, text_edit.size.x, text_edit.size.y, max_line)
		text_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_ALL
	Updatedate.load_user()
	var c = Updatedate.conversation
	senderId = Updatedate.load_game("user_name", "")
	if c.has("id"):
		Updatedate.change_status.connect(func(data):
			if data.username in c.id and data.username != senderId:
				c.state = data.state
				
				if data.state == "online":
					$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "وضعیت: آنلاین"
					for box in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
						if box.name != "instance":
							if box.get_meta("id", "") != "":
								var m = messages[box.get_meta("id", "")]
								if not m.has("seen") or (m.has("seen") and m.seen == null):
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").show()
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").default_color = Color.GRAY
				else:
					if data.has("last_seen") and data.last_seen.has("time"):
						c.last_seen = data.last_seen
						$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "آخرین بازدید: " + data.last_seen.time)
		Updatedate.seen_message.connect(func(message:Dictionary):
			if message:
				if message.conversationId + message.part == c.id:
					messages[message["id"]] = message
					unseen_ids.erase(message.id)
					if get_tree().has_group(message.id):
						var box = get_tree().get_nodes_in_group(message.id)[0]
						box.seen = message.seen
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color("32ff06")
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").default_color = Color("32ff06")
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").show()
				)
		Updatedate.edit_message.connect(func (message:Dictionary):
			if message:
				if message.conversationId + message.part == c.id:
					messages[message["id"]] = message
					var box = get_tree().get_nodes_in_group(message.id)[0]
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").show()
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").show()
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Node2D").hide()
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  message.messages.text
					if message.has("createdAt"):
						if not message.has("seen") or (message.has("seen") and message.seen == null):
							if Updatedate.conversation.last_seen != {}:
								if float(Updatedate.conversation.last_seen.timestamp) > float(message.createdAt) or Updatedate.conversation.state == "online":
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").default_color = Color.GRAY
								else:
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
							else:
								box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
								box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
				) 
		Updatedate.recive_message.connect(func(message, id):
			if message.conversationId + message.part == c.id:
				messages[message.id] = message
				var p = ids.size() - 1
				var own = false
				if messages.has(id):
					for x in ids.size():
						var y = ids.size() - x - 1
						if id == ids[y]:
							p = y
							break
					ids.insert(p, message.id)
					messages.erase(id)
					ids.erase(id)
					own = true
				else:
					ids.append(message.id)
				if message.time.split(" ")[0] not in times.values():
					times[message.id] = message.time.split(" ")[0]
				$VBoxContainer/ScrollContainer.begin_id = ids[0]
				if ids.size() > 1:
					$VBoxContainer/ScrollContainer.last_id = ids.back()
				
				for m in get_tree().get_nodes_in_group(id):
					if m.pre_node:
						m.pre_node.next_node = null if m.next_node == null else m.next_node
					if m.next_node:
						m.next_node.pre_node = null if m.pre_node == null else m.pre_node
						m.next_node.index = m.index
					add_message(message, m.get_index())
					m.queue_free()
					await get_tree().create_timer(0.1).timeout
				last_id = ids.back()
				if message.sender != senderId:
					unseen_ids.append(message.id)
					_on_scroll_container_start_scroll(-1)
				if own:
					await focus_on_message(message.id)
				else:
					if ids.size() < 2:
						add_message(message)
					else:
						if get_tree().has_group(ids[-2]):
							add_message(message)
							await get_tree().create_timer(0.1).timeout
							await focus_on_message(message.id)
				if messages.size() == 1:
					get_tree().get_first_node_in_group(last_id).checked = true
				)
		Updatedate.delete_message.connect(func (id, message, pre_message):
			if id == c.id:
				var m = get_tree().get_nodes_in_group(message)
				if m.size() > 0:
					var box = m[0]
					box.self_modulate.a = 0.0
					for child in box.get_node("HBoxContainer/MarginContainer/VBoxContainer").get_children():
						if child is not CPUParticles2D:
							child.modulate.a = 0.0
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emitting = true
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emission_rect_extents = box.size / 2
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").position = box.size / 2
					if box_ref == box:
						_on_null_ref_pressed()
					await box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").finished
					var index = box.index
					if box.pre_node:
						box.pre_node.next_node = null if box.next_node == null else box.next_node
					if box.next_node:
						box.next_node.pre_node = null if box.pre_node == null else box.pre_node
					unseen_ids.erase(message)
					box.queue_free()
					var t = messages[message].time.split(" ")[0]
					messages.erase(message)
					ids.erase(message)
					
					
					if index >= ids.size():
						index -= 1
					if ids.size() > 0:
						$VBoxContainer/ScrollContainer.last_id = ids.back()
						$VBoxContainer/ScrollContainer.begin_id = ids[0]
						
						last_id = ids.back()
						var t2 = messages[ids[index]].time.split(" ")[0]
						if times.has(message):
							times.erase(message)
							for node in get_tree().get_nodes_in_group("times"):
								if node.get_meta("time", "") == t:
									node.queue_free()
							if t2 not in times.values():
								times[ids[index]] = t2
							if get_tree().has_group(ids[index]) and times.has(ids[index]):
								get_tree().get_first_node_in_group(ids[index]).queue_free()
					else:
						$VBoxContainer/ScrollContainer.last_id = ""
						$VBoxContainer/ScrollContainer.begin_id = ""
						last_id = ""
					)
	if c.has("state"):
		if c.state == "online":
			$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "وضعیت: آنلاین"
		else:
			if c.last_seen.has("time"):
				$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/Label.text = "آخرین بازدید: " + c.last_seen.time
	if c.has("icon"):
		Updatedate.get_icon_user(c.icon, c.username, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect)
	$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name.set_deferred("text", c.custom_name if c.has("custom_name") and c.custom_name != "" else c.name if c.has("name") else "")
	if c.has("name"):
		if not c.has("icon"):
			get_text_name(c.name, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect/Label)
		if c.has("icon") and c.icon == "" and $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect.texture == null:
			get_text_name(c.name, $ColorRect/MarginContainer/HBoxContainer/TextureRect2/TextureRect/Label)
		$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name.dir = get_direction(c.name)
	if c.has("id"):
		messages = Updatedate.load_messages(Updatedate.conversation.id)
		ids = messages.keys()
		ids.sort_custom(func (a, b): return float(messages[a].createdAt) < float(messages[b].createdAt))
		unseen_ids = ids.filter(func(x): return (not messages[x].has("seen") or (messages[x].has("seen") and messages[x].seen == null) and messages[x].sender != senderId))
		$VBoxContainer/ScrollContainer.begin_id = ids[0] if ids.size() > 0 else ""
		$VBoxContainer/ScrollContainer.last_id = ids[-1] if ids.size() > 0 else ""
		last_id = ids[-1] if ids.size() > 0 else ""
		for k in ids:
			var m = messages[k]
			if m.time.split(" ")[0] not in times.values():
				times[m.id] = m.time.split(" ")[0]
	if Updatedate.conversation.has("id"):
		if Updatedate.waiting_message.has(Updatedate.conversation.id):
			for m in Updatedate.waiting_message[Updatedate.conversation.id]:
				messages[m.id] = m
				ids.append(m.id)
				$VBoxContainer/ScrollContainer.last_id = ids[-1] if ids.size() > 0 else ""
	var l = get_last_message()
	var index = 0
	last_index = l[2]
	await create_by_pos(last_index)
	check = true
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.gui_input.connect(func(event:InputEvent):
		if event is InputEventScreenTouch:
			if event.is_released() and box_ref:
				await focus_on_message(box_ref)
				r_id = box_ref
				$AnimationPlayer2.play("fade")
				)
	$ColorRect/MarginContainer/HBoxContainer/VBoxContainer/name.show()
func get_last_message():
	var n = 0
	for x in ids.size():
		var m = ids[x]
		if messages[m].sender != senderId and (not messages[m].has("seen") or messages[m].seen == null):
			not_seen = messages[m]
			n = x
			break
	if not_seen:
		var x = ids.find(not_seen.id)
		var delta = messages.size() - x
		if delta > 20:
			return [x, not_seen, n]
		else:
			return [x - (20 - delta), not_seen, n] if x - (20 - delta) > 0 else [0, not_seen, n]
	return [20 if messages.size() - 20 > 0 else messages.size(), messages[ids.back()] if ids.size() > 0 else {}, messages.size()]
	


func create_by_pos(x):
	if x >= messages.size():
		x = messages.size() - 1
	last_index = x
	for child in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if "instance" not in child.name:
			child.queue_free()
	get_tree().call_group("times", "queue_free")
	await get_tree().create_timer(0.1).timeout
	if messages.size() - x > 0 and x >= 0:
		var box = await add_message(messages[ids[x]])
		box.checked = true
		return box
func add_message(m, pos=-1):
	var obj:Node
	if m.sender == senderId:
		obj=$VBoxContainer/ScrollContainer/VBoxContainer/instance
	else:
		obj = $VBoxContainer/ScrollContainer/VBoxContainer/instance3
	var box :PanelContainer= obj.duplicate()
	if m.has("id"):
		box.add_to_group(m.id)
		box.set_meta("id", m.id)
	box.resized.connect(func():
		if edited_box == box:
			if last_height != 0 and last_height > $VBoxContainer/ScrollContainer.size.y - 83:
				var delta = box.size.y - last_height
				$VBoxContainer/ScrollContainer/VBoxContainer.position.y -= delta
			last_height = box.size.y
			)
	#var _label
	#if not_seen and m == not_seen:
		#_label = $VBoxContainer/ScrollContainer/VBoxContainer/instance2.duplicate()
		#_label.show()
		#_label.text = "پیام‌های خوانده نشده"
		#_label.ref = box
		#$VBoxContainer/ScrollContainer/VBoxContainer.add_child(_label)
		#if pos != -1:
			#$VBoxContainer/ScrollContainer/VBoxContainer.move_child(_label, pos)
			#pos += 1
		#if $VBoxContainer/ScrollContainer/VBoxContainer.get_child_count() == 4:
			#_label.index = last_index
			#_label.global_position.y = $VBoxContainer/ScrollContainer.global_position.y
		#if _label.get_index() > 3:
			#_label.pre_node =  $VBoxContainer/ScrollContainer/VBoxContainer.get_child(_label.get_index() - 1)
			#_label.pre_node.next_node = _label
		#if _label.get_index() - 3 < $VBoxContainer/ScrollContainer/VBoxContainer.get_child_count() - 4:
			#_label.next_node = $VBoxContainer/ScrollContainer/VBoxContainer.get_child(_label.get_index() + 1)
			#_label.next_node.pre_node = box
		#if _label.pre_node == null and _label.next_node:
			#_label.global_position.y = _label.next_node.global_position.y - _label.size.y - 10
			#_label.index = _label.next_node.index - 1 if _label.next_node.index != null else null
			#
	var extra_size = 0
	if times.has(m.id):
		var label = $VBoxContainer/ScrollContainer/VBoxContainer/instance2.duplicate()
		var t = times[m.id]
		label.add_to_group("times")
		label.set_meta("time", t)
		label.show()
		box.label = label
		label.modulate.a = 0
		extra_size += 73
		var dic_time = {year=t.split("/")[0], mounth=t.split("/")[1], day=t.split("/")[2]}
		var day = ""
		var mounthes = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]
		if t.split("$").size() == 2:
			day = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه'][int(t.split("$")[1])]
		if dic_time.year == Updatedate.year:
			label._text = str(day, " ", dic_time.day, " ", mounthes[int(dic_time.mounth) -1])
		else:
			label._text = str(dic_time.day, " ", mounthes[int(dic_time.mounth) -1], " ", dic_time.year)
		$VBoxContainer/ScrollContainer/Control.add_child(label)
		
	box.add_theme_stylebox_override("panel", box.get_theme_stylebox("panel").duplicate())
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").add_theme_stylebox_override("normal", box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").get_theme_stylebox("normal").duplicate())
	box.show()
	box.modulate.a = 0
	if m.has("createdAt"):
		if not m.has("seen") or (m.has("seen") and m.seen == null):
			if Updatedate.conversation.last_seen != {}:
				if float(Updatedate.conversation.last_seen.timestamp) > float(m.createdAt) or Updatedate.conversation.state == "online":
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").default_color = Color.GRAY
				else:
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
			else:
				box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
				box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
	else:
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").hide()
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Node2D").show()
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
			$VBoxContainer/ScrollContainer.scroll = Vector2.ZERO
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
			box_ref = m.id
			if has_keyboard == false:
				if mobile_box:
					mobile_box.getFocus()
				else:
					text_edit.grab_focus()
		)
	if m.response and m.response != "":
		var ref =  messages[m.response]
		if ref:
			var index = box.index
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").text = ref.messages.text
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label3").gui_input.connect(func(event:InputEvent):
				if event is InputEventScreenTouch:
					if event.is_released():
						await focus_on_message(m.response)
						r_id = m.response
						$AnimationPlayer2.play("fade")
						if !responses.has(m.id) and m.id != last_id:  
							responses.append(m.id))
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
	if Updatedate.waiting_editing.has(Updatedate.conversation.id):
		var new_m = Updatedate.waiting_editing[Updatedate.conversation.id].filter(func(x):return x[0] == m.id)
		if new_m.size() > 0:
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").hide()
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Node2D").show()
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = new_m[0][1]
	var size_y = - vbox.get_theme_constant("separation")
	var vbox : VBoxContainer = box.get_node("HBoxContainer/MarginContainer/VBoxContainer")
	if pos != -1:
		$VBoxContainer/ScrollContainer/VBoxContainer.move_child(box, pos)
	if $VBoxContainer/ScrollContainer/VBoxContainer.get_child_count() == 4:
		box.index = last_index
		last_index2 = last_index
		box.global_position.y = $VBoxContainer/ScrollContainer.global_position.y + extra_size
	if box.get_index() > 3:
		box.pre_node =  $VBoxContainer/ScrollContainer/VBoxContainer.get_child(box.get_index() - 1)
		box.pre_node.next_node = box
		box.global_position.y = box.pre_node.global_position.y + box.pre_node.size.y + 10 + extra_size
	if box.get_index() - 3 < $VBoxContainer/ScrollContainer/VBoxContainer.get_child_count() - 4:
		box.next_node = $VBoxContainer/ScrollContainer/VBoxContainer.get_child(box.get_index() + 1)
	if box.pre_node == null and box.next_node:
		box.index = box.next_node.index - 1 if box.next_node.index != null else null
		
	return box
func check_has_node(node):
	if check:
		var n = node.index
		if n != null:
			var above_node
			var below_node
			if messages.size() > n + 1:
				below_node = messages[ids[n + 1]]
			if n > 0:
				above_node = messages[ids[n - 1]]
			if above_node and not get_tree().has_group(above_node["id"]):
				last_index2 = n - 1
				add_message(above_node,  node.get_index())
			if below_node and not get_tree().has_group(below_node["id"]):
				last_index2 = n + 1
				add_message(below_node,  node.get_index()+1)
			
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
	$VBoxContainer/Control/Button/Label.visible = unseen_ids.size() > 0
	$VBoxContainer/Control/Button/Label.text = str(unseen_ids.size())
	offset = get_keyboard_offset()
	var _delta = Vector2(DisplayServer.window_get_size())/get_viewport().get_visible_rect().size
	if edited_box:
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").set_deferred("text", text_edit.text if mobile_box == null else mobile_box.getText())
	if fram <= 6:
		fram += 1
	for id in responses:
		if get_tree().has_group(id):
			responses.erase(id)
	if r_id != "":
		if get_tree().has_group(r_id):
			var box = get_tree().get_first_node_in_group(r_id)
			if box:
				$ColorRect2.size.y = box.size.y
				$ColorRect2.global_position.y = box.global_position.y
	else:
		$ColorRect2.hide()
	if box_ref:
		$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = messages[box_ref].messages.text if messages.has(box_ref) else ""
		$VBoxContainer/Panel/VBoxContainer/MarginContainer.show()
	$ColorRect2.size.x = size.x
	if offset > 100:
		has_keyboard = true
		last_vbox_size = size.y - 95 - vbox.position.y - offset
		vbox.size.y = last_vbox_size
	else:
		if has_keyboard:
			has_keyboard = false
			if mobile_box:
				mobile_box.exitFocus()
		if last_vbox_size != size.y - 10 - vbox.position.y:
			last_vbox_size = size.y - 10 - vbox.position.y
			var tween = get_tree().create_tween()
			tween.tween_property(vbox, "size:y", size.y - 10 - vbox.position.y, 0.3)
			tween.play()

		
	if mobile_box:
		mobile_box.updatePosition(text_edit.global_position.x * _delta.x, (text_edit.global_position.y + 100) * _delta.y, text_edit.size.x * _delta.x, text_edit.size.y*_delta.y)
	var index = 0
	for x in text_edit.get_line_count():
		for y in text_edit.get_line_wrap_count(x) + 1:
			index += 1
	if mobile_box:
		text_edit.custom_minimum_size.y = mobile_box.getHeight()/_delta.y
	else:
		if index <= max_line:
			text_edit.custom_minimum_size.y = index * text_edit.get_line_height() + 10
		if index > max_line:
			text_edit.custom_minimum_size.y = max_line * text_edit.get_line_height() + 10
	
	if $VBoxContainer/ScrollContainer/VBoxContainer.get_child_count() == 3 and check:
		if ids.size() > last_index2:
			last_index = last_index2
			var box = add_message(messages[ids[last_index2]])
			await get_tree().physics_frame
			box.checked = true
func _on_button_pressed() -> void:
	if edited_box:
		
		if not Updatedate.waiting_editing.has(Updatedate.conversation.id):
			Updatedate.waiting_editing[Updatedate.conversation.id] = []
		if Updatedate.waiting_message.has(Updatedate.conversation.id):
			var d = Updatedate.waiting_message[Updatedate.conversation.id].filter(func(x):return x.id == edited_box.get_meta("id", ""))
			if d.size() > 0:
				Updatedate.waiting_message[Updatedate.conversation.id].erase(d[0])
				d[0].messages.text = text_edit.text if mobile_box == null else mobile_box.getText()
				Updatedate.waiting_message[Updatedate.conversation.id].append(d[0])
				edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  text_edit.text
				_on_null_ref_pressed()
				return
		var d =  Updatedate.waiting_editing[Updatedate.conversation.id].filter(func(x):return x[0] == edited_box.get_meta("id", ""))
		if d.size() > 0:
			Updatedate.waiting_editing[Updatedate.conversation.id].erase(d[0])
		Updatedate.waiting_editing[Updatedate.conversation.id].append([edited_box.get_meta("id", ""), text_edit.text])
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").hide()
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Node2D").show()
		edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  text_edit.text
		Updatedate.send_edit_message(edited_box.get_meta("id", ""), text_edit.text if mobile_box == null else mobile_box.getText())
		_on_null_ref_pressed()
	else:
		if not Updatedate.waiting_message.has(Updatedate.conversation.id):
			Updatedate.waiting_message[Updatedate.conversation.id] = []
		var id = uuid(20, 5)
		var m = {"messages":{"text":text_edit.text if mobile_box == null else mobile_box.getText()}, "id":id, "part":Updatedate.conversation.part, "sender":Updatedate.load_game("user_name", ""), "sender_name":"شما", "response":box_ref if box_ref else ""}
		Updatedate.waiting_message[Updatedate.conversation.id].append(m)
		messages[id] = m
		ids.append(id)
		$VBoxContainer/ScrollContainer.begin_id = ids[0]
		$VBoxContainer/ScrollContainer.last_id = id
		if get_tree().has_group(last_id):
			add_message(m)
			await get_tree().create_timer(0.1).timeout
			await  focus_on_message(id)
		else:
			await focus_on_message(id)
		last_id = id
		
		Updatedate.send_message(text_edit.text if mobile_box == null else mobile_box.getText(), id, box_ref if box_ref else "")
		text_edit.text = ""
		if mobile_box:
			mobile_box.setText("")
		_on_null_ref_pressed()
func focus_on_message(_id:String):
	if $VBoxContainer/Control/Button.visible:
		$AnimationPlayer.play_backwards("pop_button")
	if messages.has(_id) and edited_box == null and true in $VBoxContainer/ScrollContainer.can_drag:
		if get_tree().has_group(_id):
			var box = get_tree().get_first_node_in_group(_id)
			var bottom_pos = $VBoxContainer/ScrollContainer.global_position.y + $VBoxContainer/ScrollContainer.size.y - box.size.y
			var top_pos = $VBoxContainer/ScrollContainer.global_position.y
			if box.label:
				bottom_pos -= 73
				top_pos += 73
			if box.global_position.y > bottom_pos:
				var delta = box.global_position.y - bottom_pos
				var tween = get_tree().create_tween()
				tween.tween_property($VBoxContainer/ScrollContainer, "scroll_offset", $VBoxContainer/ScrollContainer.scroll_offset - delta, 0.2)
				tween.play()
				await tween.finished
			if box.global_position.y < top_pos:
				var delta = top_pos - box.global_position.y
				var tween = get_tree().create_tween()
				tween.tween_property($VBoxContainer/ScrollContainer, "scroll_offset", $VBoxContainer/ScrollContainer.scroll_offset + delta, 0.2)
				tween.play()
				await tween.finished
			return box
		else:
			var i = -1
			for x in ids.size():
				if ids[ids.size() - x - 1] == _id:
					i = ids.size() - x - 1
					break
			if i != -1:
				return await create_by_pos(i)
	return null
func _on_back_button_pressed() -> void:
	if mobile_box:
		mobile_box.hideTextBox()
		DisplayServer.virtual_keyboard_hide()
	Transation.change(self, "start.tscn", -1)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if mobile_box:
			mobile_box.hideTextBox()
		
		Transation.change(self, "start.tscn", -1)
	

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if meta.begins_with("http"):
		OS.shell_open(meta)
	else:
		OS.shell_open("https://"+meta)


func _on_timer_timeout() -> void:
	if $VBoxContainer/Control/Button.visible:
		$AnimationPlayer.play_backwards("pop_button")

func _on_scroll_container_start_scroll(dir) -> void:
	if $ColorRect2.visible:
		$ColorRect2.hide()
	if not get_tree().has_group(last_id) and dir == -1:
		if not $VBoxContainer/Control/Button.visible:
			$AnimationPlayer.play("pop_button")
		else:
			$Timer.start()
	else:
		if $VBoxContainer/Control/Button.visible:
			$AnimationPlayer.play_backwards("pop_button")


func _on_scroll_pressed() -> void:
	if $VBoxContainer/Control/Button.visible:
		$AnimationPlayer.play_backwards("pop_button")
	if responses.size() > 0:
		await focus_on_message(responses[0])
		r_id = responses[0]
		$AnimationPlayer2.play("fade")
		responses.remove_at(0)
	else:
		for id in unseen_ids:
			Updatedate.message_seen(id)
		focus_on_message(last_id)


func _on_null_ref_pressed() -> void:
	if box_ref:
		box_ref = null
	if edited_box:
		text_edit.text = ""
		if mobile_box:
			mobile_box.setText("")
		_on_text_edit_text_changed()
		edited_box.z_index = 0
		edited_box = null
		$AnimationPlayer2.play("fade2")
		$VBoxContainer/ScrollContainer.last_id = ids.back()
		$VBoxContainer/ScrollContainer.begin_id = ids[0]
		last_id = ids.back()
		$AnimationPlayer2.play_backwards("fade2")
	$VBoxContainer/Panel/VBoxContainer/MarginContainer.hide()
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = ""


func _on_text_edit_text_changed() -> void:
	var text = text_edit.text
	var s:PackedStringArray = text.split(" ")
	var s2:PackedStringArray = text.split("‌‌")
	var s3:PackedStringArray = text.split("‌\n")
	var not_Space = false
	var not_Space2 = false
	var not_line = false
	for g in s:
		g = g.replace("‌", "")
		g = g.replace(" ", "")
		g = g.replace("\n", "")
		if g != "" and g != "‌" and g != "‌ "and g!="\n":
			not_Space = true
			break
	for g in s2:
		g = g.replace(" ", "")
		g = g.replace("‌", "")
		g = g.replace("\n", "")
		if g != "" and g != "‌" and g != "‌ "and g!="\n":
			not_Space2 = true
			break
	for g in s3:
		g = g.replace(" ", "")
		g = g.replace("\n", "")
		g = g.replace("‌", "")
		if g != "" and g != "‌" and g != "‌ " and g!="\n":
			not_line = true
			break
	var btn = $VBoxContainer/Panel/VBoxContainer/HBoxContainer/Control/Button
	if not_line and not_Space and not_Space2:
		if btn.scale < Vector2.ONE:
			var tween = get_tree().create_tween()
			tween.tween_property(btn, "scale", Vector2.ONE, 0.3)
			tween.play()
	else:
		if btn.scale > Vector2.ZERO:
			var tween = get_tree().create_tween()
			tween.tween_property(btn, "scale", Vector2.ZERO, 0.3)
			tween.play()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		r_id = ""
		if event.is_pressed() and event.button_index != MOUSE_BUTTON_RIGHT:
			if action_box:
				off_action()


func _on_delete_pressed() -> void:
	if Updatedate.waiting_message.has(Updatedate.conversation.id):
		var d = Updatedate.waiting_message[Updatedate.conversation.id].filter(func(x):return x.id == ids[(action_box.index)])
		if d.size() > 0:
			DisplayServer.dialog_show("لغو ارسال", "این پیام بعد از اتصال به اینترنت دیگر ارسال نخواهد شد، آیا اطمینان دارید؟", ["بله", "خیر"], 
			func(btn):
				if btn == 0:
					if action_box and action_box.index:
						messages.erase(d[0].id)
						ids.erase(d[0].id)
						get_tree().call_group(d[0].id, "queue_free")
						if ids.size() > 0:
							$VBoxContainer/ScrollContainer.begin_id = ids[0]
							$VBoxContainer/ScrollContainer.last_id = ids.back()
							last_id = ids.back()
						Updatedate.waiting_message[Updatedate.conversation.id].erase(d[0])
						off_action())
			return
	if Updatedate.waiting_editing.has(Updatedate.conversation.id):
		var d = Updatedate.waiting_editing[Updatedate.conversation.id].filter(func(x):return x[0] == ids[(action_box.index)])
		if d.size() > 0:
			DisplayServer.dialog_show("لغو ارسال", "این پیام بعد از اتصال به اینترنت دیگر ارسال نخواهد شد، آیا اطمینان دارید؟", ["بله", "خیر"], 
			func(btn):
				if btn == 0:
					if action_box and action_box.index:
						var box = action_box
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").show()
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").show()
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Node2D").hide()
						var message = messages[d[0][0]]
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text =  message.messages.text
						if message.has("createdAt"):
							if not message.has("seen") or (message.has("seen") and message.seen == null):
								if Updatedate.conversation.last_seen != {}:
									if float(Updatedate.conversation.last_seen.timestamp) > float(message.createdAt) or Updatedate.conversation.state == "online":
										box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
										box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").default_color = Color.GRAY
									else:
										box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
										box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
								else:
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D").default_color = Color.GRAY
									box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2/Node2D/Line2D2").hide()
						Updatedate.waiting_editing[Updatedate.conversation.id].erase(d[0])
						off_action())
			return
	DisplayServer.dialog_show("حذف پیام", "آیا از حذف این پیام، اطمینان دارید؟ این پیام برای هر دو نفر پاک خواهد شد.", ["بله", "خیر"], func(btn):
		if btn == 0:
			if action_box and action_box.index:
				Updatedate.delete(ids[(action_box.index)], ids[action_box.index - 1] if action_box.index > 0 else "")
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
	last_height = edited_box.size.y
	$AnimationPlayer2.play("fade2")
	$VBoxContainer/ScrollContainer.last_id = edited_box.get_meta("id", "")
	$VBoxContainer/ScrollContainer.begin_id = edited_box.get_meta("id", "")
	last_id = edited_box.get_meta("id", "")
	edited_box.z_index = 1
	if mobile_box:
		mobile_box.setText(edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text)
	else:
		text_edit.text = edited_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text
	$VBoxContainer/Panel/VBoxContainer/MarginContainer.show()
	$VBoxContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = text_edit.text if mobile_box == null else mobile_box.getText()
	off_action()


func _on_copy_pressed() -> void:
	if action_box:
		DisplayServer.clipboard_set(action_box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text)
		Notification.add_notif("متن کپی شد.")
		off_action()


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if mobile_box:
				if has_keyboard == false:
					mobile_box.getFocus()
