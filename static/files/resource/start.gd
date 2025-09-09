extends Control

var seen = 0
var user_label:Label
var supporter_label:Label
var planes = []
var boxes = {}
var conversations = {}
var ids = []
var created_c = 0
var max_c = 0
var check = false
var last_scroll = 0
var last_c = 0
var max_scroll = 0
var first_supporter = ""
var status_users = []
var supporters = {}
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
func get_new_message(message, _id):
	var id = message.conversationId + message.part
	
	if ids.has(id):
		var c = conversations[id]
		c["message"] = message
		if message.sender != Updatedate.load_game("user_name", ""):
			c.new += 1
		ids.erase(id)
		ids.push_front(id)
		if get_tree().has_group(id):
			var btn = get_tree().get_nodes_in_group(id)[0]
			if btn._index != 0:
				if btn.next_node:
					btn.next_node._index = btn._index
					btn.next_node.pre_node = btn.pre_node
				if btn.pre_node:
					btn.pre_node.next_node = btn.next_node
				btn.queue_free()
			else:
				change_conversation(btn, c)
	else:
		conversations[id] = Updatedate.get_conversation(message.conversationId + message.part)
		ids.push_front(id)
	$CustomTabContainer/MarginContainer3/ScrollContainer.begin_id = ids[0]
	if int($CustomTabContainer/MarginContainer3/ScrollContainer.size.y / 210) < conversations.size():
		$CustomTabContainer/MarginContainer3/ScrollContainer.last_id = ids.back()
	max_c = conversations.size()
func edit_message(message):
	var id = message.conversationId + message.part
	if ids.has(id):
		var c = conversations[id]
		conversations[id].message = message
		if get_tree().has_group(c.message.id):
			var btn = get_tree().get_nodes_in_group(id)[0]
			btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label").text = message.messages.text if message and message.has("messages") and message.messages else ""

func seen_message(message):
	var id = message.conversationId + message.part
	if ids.has(id):
		conversations[id].message = message
		var data = conversations[id]
		if get_tree().has_group(id):
			var btn = get_tree().get_nodes_in_group(id)[0]
			var m = message
			if not m.has("seen") or (m.has("seen") and m.seen == null):
				if data.last_seen != {}:
					if float(data.last_seen.timestamp) > float(m.createdAt) or data.state == "online":
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").default_color = Color.GRAY
					else:
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
				else:
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
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
	Updatedate.current_user = Updatedate.load_game("current_user", 0)
	Updatedate.load_user()
	conversations = Updatedate.list_messages()
	ids = conversations.keys()
	var not_message = ids.filter(func (m): return not conversations[m].has("message"))
	ids = ids.filter(func (m): return conversations[m].has("message"))
	ids.sort_custom(func(a, b): return float(conversations[a].message.createdAt) > float(conversations[b].message.createdAt))
	ids.append_array(not_message)
	max_c = conversations.size()
	var index2 = 0
	for c in ids:
		if index2 < 15:
			add_conversation(c, conversations[c], $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer)
			index2 += 1
		else:
			break
	created_c = index2
	Updatedate.change_status.connect(func(data):
		var list = ids.filter(func(s): return data.username in s and data.username != Updatedate.load_game("user_name", ""))
		for c in list:
			conversations[c]["state"] = data.state
			conversations[c]["last_seen"] = data.last_seen
			if get_tree().has_group(c):
				var btn = get_tree().get_first_node_in_group(c)
				if data.state == "online":
					btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").show()
				else:
					btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").hide()
				var m = conversations[c].message if conversations[c].has("message") else null
				if m != null:
					if not m.has("seen") or (m.has("seen") and m.seen == null):
						if data.last_seen != {}:
							if float(data.last_seen.timestamp) > float(m.createdAt) or data.state == "online":
								btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
								btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").default_color = Color.GRAY
							else:
								btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
								btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
						else:
							btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
							btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
		)
				
	Updatedate.request_completed.connect(func(data, url:String):
		if data:
			if url.begins_with("/messages/state_user?user="):
				status_users.erase(data.user.username)
				var list = ids.filter(func(s): return data.user.username in s)
				for c in list:
					conversations[c]["name"] = data.user.name
					conversations[c]["custom_name"] = data.user.custom_name
					conversations[c]["icon"] = data.user.icon
					conversations[c]["state"] = data.state
					conversations[c]["last_seen"] = data.last_seen
					conversations[c]["blocked"] = data.blocked
					if get_tree().has_group(c):
						var btn = get_tree().get_first_node_in_group(c)
						Updatedate.get_icon_user(data.user.icon, data.user.username, btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect"))
						if data.state == "online":
							btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").show()
						else:
							btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").hide()
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/name").set_deferred("text", data.user.custom_name if data.user.has("custom_name") and data.user.custom_name != "" else data.user.name)
						if data.user.name != "":
							if not data.user.has("icon"):
								get_text_name(data.user.name, btn.get_node("Panel/HBoxContainer/TextureRect/Label"))
							if data.user.has("icon") and data.user.icon == "" and btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect").texture == null:
								get_text_name(data.user.name, btn.get_node("Panel/HBoxContainer/TextureRect/Label"))
							btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/name").dir = get_direction(data.user.name)
						var m = conversations[c].message if conversations[c].has("message") else null
						if m != null:
							if not m.has("seen") or (m.has("seen") and m.seen == null):
								if data.last_seen != {}:
									if float(data.last_seen.timestamp) > float(m.createdAt) or data.state == "online":
										btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
										btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").default_color = Color.GRAY
									else:
										btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
										btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
						else:
							btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D").hide()
			if url == "/planes/all":
				Updatedate.save("planes", data, false)
				for plan in data:
					if plan not in planes:
						add_ranking(plan)
				for plan in planes:
					if plan not in data.keys():
						if boxes.has(plan):
							boxes[plan].queue_free()
							boxes.erase(plan)
			if url == "/auth/unseen_message":
				if data.num != 0:
					$Button5/Label.show()
					$Button5/Label.text = str(int(data.num))
			if url == "/messages/supporters":
				for s in data.supporters:
					conversations[s.username + Updatedate.load_game("user_name", "") + s.part] = s
					supporters[s.username + Updatedate.load_game("user_name", "") + s.part] = s
					if first_supporter == "":
						first_supporter = s.username + Updatedate.load_game("user_name", "") + s.part
					ids.append(s.username + Updatedate.load_game("user_name", "") + s.part)
					if conversations.size() == 1:
						add_conversation(ids[0], s)
				$CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer.get_child(-1).has_on_screen = false
				if ids.size() > 0:
					$CustomTabContainer/MarginContainer3/ScrollContainer.begin_id = ids[0]
					$CustomTabContainer/MarginContainer3/ScrollContainer.last_id = ids.back() if ids.size() * 210 > $CustomTabContainer/MarginContainer3/ScrollContainer.size.y else ""
					
				)
	Updatedate.update_list.connect(func (data):
		conversations = data
		first_supporter = ""
		for s in supporters:
			if first_supporter == "":
				first_supporter = s
			conversations[s] = supporters[s]
		max_c = conversations.size()
		ids = conversations.keys()
		not_message = ids.filter(func (m): return not conversations[m].has("message"))
		ids = ids.filter(func (m): return conversations[m].has("message"))
		ids.sort_custom(func(a, b): return float(conversations[a].message.createdAt) > float(conversations[b].message.createdAt))
		ids.append_array(not_message)
		if ids.size() > 0:
			$CustomTabContainer/MarginContainer3/ScrollContainer.begin_id = ids[0]
		if ids.size() > 1:
			$CustomTabContainer/MarginContainer3/ScrollContainer.last_id = ids[-1]
		if $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer.get_child_count() > 1:
			create_by_pos($CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer.get_child(1)._index if $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer.get_child(1)._index else 0)
		else:
			if ids.size() > 0:
				create_by_pos(0)
		
		)
	Updatedate.recive_message.connect(get_new_message)
	Updatedate.seen_message.connect(seen_message)
	Updatedate.edit_message.connect(edit_message)
	Updatedate.request("/messages/supporters")
	$CustomTabContainer/MarginContainer3/ScrollContainer.max_scroll = (conversations.size() * 210) + 100
	$CustomTabContainer/MarginContainer3/Control/VSlider.max_value = (conversations.size() * 210) + 100
	if not Updatedate.load_game("management"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(3), 3)
	if not Updatedate.load_game("editor", false) and not Updatedate.load_game("support"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(4), 4 if Updatedate.load_game("management") else 3)
	Updatedate.request("/auth/unseen_message")
	Updatedate.request("/planes/all")
	if ids.size() > 0:
		$CustomTabContainer/MarginContainer3/ScrollContainer.begin_id = ids[0]
	for plan in Updatedate.load_game("planes", {}):
		add_ranking(plan)
	
	get_tree().create_timer(0.10).timeout.connect(func ():
		show()
		check = true
		if $CustomTabContainer.has_method("set_style"):
			$CustomTabContainer.set_style())

func get_tab(indx)-> Button:
	var buttons = []
	for child in $CustomTabContainer.panel.get_child(0).get_children():
		if child is Button:
			buttons.append(child)
	if buttons.size() > indx:
		return buttons[indx]
	else :
		if buttons.size() > 0:
			return buttons[buttons.size() - 1]
		else:
			return Button.new()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $CustomTabContainer/MarginContainer3/ScrollContainer.size.y != 0:
		if int($CustomTabContainer/MarginContainer3/ScrollContainer.size.y / 210) < conversations.size():
			$CustomTabContainer/MarginContainer3/ScrollContainer.last_id = ids.back()
	if conversations.size() > 100:
		$CustomTabContainer/MarginContainer3/Control.show()
	if Updatedate.load_game("support", false) :
		if Updatedate.seen  > 0:
			if supporter_label:
				supporter_label.show()
				supporter_label.text = str(int(Updatedate.seen))
				supporter_label.position = Vector2(60, 38)
			else:
				var btn = get_tab(4)
				if btn.text == "مربیان":
					supporter_label = $Label.duplicate()
					btn.add_child(supporter_label)
	else:
		if Updatedate.seen > 0:
			if user_label:
				user_label.show()
				user_label.text = str(int(Updatedate.seen))
				user_label.position = Vector2(100, 38)
			else:
				user_label = $Label.duplicate()
				get_tab(2).add_child(user_label)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not Transation.active:
			get_tree().quit()
func _on_button_pressed() -> void:
	Transation.change(self, "main.tscn")
	

func _on_button2_pressed() -> void:
	Transation.change(self, "main2.tscn")
	

func _on_button_3_pressed() -> void:
	Transation.change(self, "managment.tscn")


func _on_control_item_pressed(id: String) -> void:
	
	Updatedate.part = int(id)
	Transation.change(self, "menu2.tscn")


func _on_button_4_pressed() -> void:
	Transation.change(self, "setting.tscn")


func _on_control_2_item_pressed(id: String) -> void:

	if id == "0":
		Transation.change(self, "ticket.tscn")
	else:
		Updatedate.gallary_part = "1_"+str(int(id)-1)
		Updatedate.p_scene = "start"
		Transation.change(self, "gallary.tscn")

func _on_button_5_pressed() -> void:
	Transation.change(self, "messages.tscn")

func create_by_pos(x):
	if x >= conversations.size():
		x = conversations.size() - 1
	last_c = x
	for child in $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer.get_children():
		if child.name != "instance":
			child.queue_free()
	await get_tree().create_timer(0.1).timeout
	var num = 12 if conversations.size() > 12 else conversations.size()
	if conversations.size() - x > 0:
		if conversations.size() - x < 12:
			num = int($CustomTabContainer/MarginContainer3/ScrollContainer.size.y / 210) + 1 if conversations.size() > 12 else conversations.size()
			x = conversations.size() - num - 1 if conversations.size() > 12 else 0
			last_c = x
		for n in num:
			add_conversation(ids[x+n], conversations[ids[x+n]])
func _on_custom_tab_container_tab_selected(tab: int) -> void:
	if tab == 0 or tab == 1 or tab == 2:
		Updatedate.save("tab", tab, false)
	else :
		Updatedate.save("tab", 1, false)
	match tab:
			#else:
				#$CustomTabContainer.current_tab = 1
				#$CustomTabContainer.set_style()
				#Notification.add_notif("پشتیبانان به این بخش دسترسی ندارند.", Notification.ERROR)
		3:
			if Updatedate.load_game("management", false):
				Transation.change(self, "managment.tscn")
			else:
				Transation.change(self, "main2.tscn")
		4:
			Transation.change(self, "main2.tscn")


func _on_control_item_pressed2(id: String, _name) -> void:
	Updatedate.p_scene = scene_file_path.get_file().get_basename()
	Updatedate.part = 3 +int(id)
	Updatedate.plan = _name
	Updatedate.group_plan = bool(int(id))
	Updatedate.subplan = ""
	Transation.change(self, "positions.tscn")
	
func add_ranking(_name):
	planes.append(_name)
	var plan = $CustomTabContainer/MarginContainer2/Panel/ScrollContainer/VBoxContainer/position.duplicate()
	plan.item_pressed.connect(_on_control_item_pressed2.bind(_name))
	plan.show()
	boxes[_name] = plan
	var baseButton:MainButton = $CustomTabContainer/MarginContainer2/Panel/ScrollContainer/VBoxContainer/position.base_button.duplicate()
	baseButton.text = "[light color=yellow len=25 num=4 freq=10]"+_name
	plan.base_button = baseButton
	$CustomTabContainer/MarginContainer2/Panel/ScrollContainer/VBoxContainer.add_child(plan, true)

func add_conversation(_id, data, node=$CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer, pos=-1):
	if data :
		var btn:Button = $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer/instance.duplicate()
		btn.show()
		btn.name = "button"
		get_tree().call_group(_id, "queue_free")
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label").text = "[b][color=0dca94][outline_color=001313][outline_size=3]"+data.message.sender_name+ ":\n"+"[/outline_size][/outline_color][/color][/b]"  if data and data.has("message") and data.message and data.message.has("sender_name") and data.message.sender_name else ""
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label").text += data.message.messages.text if data.has("message") and data.message and data.message.has("messages") and data.message.messages else ""
		if data.has("username"):
			if not status_users.has(data["username"]) and not Updatedate.checked_status.has(data["username"]):
				status_users.append(data["username"])
				Updatedate.request("/messages/state_user?user="+data["username"])
		if data.has("icon") and data.has("username"):
			Updatedate.get_icon_user(data.icon, data.username, btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect"))
		if data.has("new"):
			if data.new > 0:
				btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").text = str(int(data.new)) if data.new < 100 else "+99"
			else:
				btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").hide()
		else:
			btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").hide()
		if data.has("message"):
			var m = data.message
			if not m.has("seen") or (m.has("seen") and m.seen == null):
				if data.last_seen != {}:
					if data.state == "online":
						btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").show()
					else:
						btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect2").hide()
					if float(data.last_seen.timestamp) > float(m.createdAt) or data.state == "online":
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").default_color = Color.GRAY
					else:
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
						btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
				else:
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
			
			btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label").text = data.message.time.split(" ")[2]
		else:
			btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label").hide()
			btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label").hide()
		if data.has("part"):
			btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/RichTextLabel").text = "[light color=yellow freq=20 num=3 len=100][right] درباره‌ی طرح " + data.part
		else:
			btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/RichTextLabel").text = ''
		btn.gui_input.connect(btn_pressed.bind(_id, data))
		node.add_child(btn, true)
		btn.add_to_group(_id)
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/name").set_deferred("text", data.custom_name if data.has("custom_name") and data.custom_name != "" else data.name)
		if data.name != "":
			if not data.has("icon"):
				get_text_name(data.name, btn.get_node("Panel/HBoxContainer/TextureRect/Label"))
			if data.has("icon") and data.icon == "" and btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect").texture == null:
				get_text_name(data.name, btn.get_node("Panel/HBoxContainer/TextureRect/Label"))
			btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/name").dir = get_direction(data.name)
		btn.size.x = size.x
		if pos != -1:
			node.move_child(btn, pos)
		var x = btn.get_index()
		
		if node.get_child_count() == 2:
			btn.position.y = 0
			btn._index = last_c
		if x > 1:
			btn.pre_node = node.get_child(x-1)
			btn.position.y = btn.pre_node.position.y + 210
			btn.pre_node.next_node = btn
		if x <= node.get_child_count() - 2:
			btn.next_node = node.get_child(x + 1)
			btn.position.y = btn.next_node.position.y - 210
			btn.next_node.pre_node = btn
		if btn.pre_node == null and btn.next_node:
			btn._index = btn.next_node._index - 1 if btn.next_node._index != null else null
		btn.screen_entered.connect(check_has_node.bind(btn))
		if _id == first_supporter:
			var label = $CustomTabContainer/MarginContainer3/ScrollContainer/Label.duplicate()
			label.show()
			label.next_node = btn
			btn.label = label
			node.add_child(label, true)
			if pos != -1:
				node.move_child(label, pos)
func change_conversation(btn, data):
	if data.has("icon") and data.has("username"):
		Updatedate.get_icon_user(data.icon, data.username, btn.get_node("Panel/HBoxContainer/TextureRect/TextureRect"))
	if data.has("new"):
		if data.new > 0:
			btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").text = str(int(data.new)) if data.new < 100 else "+99"
		else:
			btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").hide()
	else:
		btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label2").hide()
	if data.has("message"):
		var m = data.message
		if not m.has("seen") or (m.has("seen") and m.seen == null):
			if data.last_seen != {}:
				if data.last_seen.timestamp > m.createdAt or data.state == "online":
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").default_color = Color.GRAY
				else:
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
					btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
			else:
				btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D").default_color = Color.GRAY
				btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D/Line2D2").hide()
		
		btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label").text = data.message.time.split(" ")[2]
	else:
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label/Node2D").hide()
		btn.get_node("Panel/HBoxContainer/VBoxContainer2/Label").hide()
	if data.has("part"):
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/RichTextLabel").text = "[light color=yellow freq=20 num=3 len=100][right] درباره‌ی طرح " + data.part
	else:
		btn.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/RichTextLabel").text = ''
func get_direction(text:String):
	if text[0] < "ی" and text[0] > "آ":
		return -1
	else :
		return 1

func btn_pressed(event:InputEvent, id, data):

	if event is InputEventScreenTouch:
		if event.is_pressed():
			$CustomTabContainer/MarginContainer3/ScrollContainer.drag = false
		if event.is_released():
			if $CustomTabContainer/MarginContainer3/ScrollContainer.drag:
				$CustomTabContainer/MarginContainer3/ScrollContainer.drag = false
			else:
				Updatedate.conversation = {"id": id, "part":data.part, "name":data.name if data.has("name") else "", "icon":data.icon if data.has("icon") else "", "custom_name":data.custom_name if data.has("custom_name") else "", "username":data.username if data.has("username") else "", "state":data.state if data.has("state") else "unknow", "last_seen":data.last_seen if data.has("last_seen") else {}}
				Transation.change(self, "control.tscn", 1)
func check_has_node(node):
	if check and node._index != null:
		var index = node.get_index()
		var above_node = []
		var below_node = []
		
		var n = node._index
		for x in 1:
			
			if conversations.size() > n + 1 + x:
				var id = ids[n + 1 + x]
				below_node.append([id, conversations[id]])
			if n > x and n < conversations.size():
				var id = ids[n - 1 - x]
				above_node.append([id, conversations[id]])
		for x in 1:
			if above_node.size() > x and not get_tree().has_group(above_node[x][0]):
				add_conversation(above_node[x][0], above_node[x][1],$CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer , 1)
			if below_node.size() > x and not get_tree().has_group(below_node[x][0]):
				add_conversation(below_node[x][0], below_node[x][1], $CustomTabContainer/MarginContainer3/ScrollContainer/VBoxContainer,index + 1 + x)


func _on_v_slider_value_changed(value: float) -> void:
	
	if abs(last_scroll - value) < 2000:
		$CustomTabContainer/MarginContainer3/ScrollContainer.scroll = Vector2(0, last_scroll - value)
	else:
		create_by_pos(int(value / 210))
	last_scroll = value
	
