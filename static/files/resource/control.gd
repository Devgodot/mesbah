extends Control

var supporters = []
var part = 0
var messages = []
@onready var vbox = $TabContainer.get_child(part)
var scroll = [0, 0, 0]
var change = false
var not_seen = [0, 0, 0]
var seen_message = [[], [], []]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_mode = FOCUS_ALL
	Updatedate.load_user()
	Updatedate.seen = 0
	var w = Updatedate.add_wait($TabContainer)
	for x in range(3):
		vbox = $TabContainer.get_child(x)
		var s = await Updatedate.request("/users/supporters?part="+str(x))
		var l = []
		if s and s.has("supporters"):
			for y in s.supporters:
				l.append(custom_hash.hashing(custom_hash.GET_HASH, y))
			supporters.append(l)
		for m in Updatedate.messages[x]:
			if m.sender == Updatedate.load_game("user_name"):
				add_message(m, Updatedate.load_game("user_name")+"_"+str(x))
			elif m.sender != Updatedate.load_game("user_name"):
				add_message(m, Updatedate.load_game("user_name")+"_"+str(x), $Container/PanelContainer)
		if seen_message[x].size() > 0:
			var r = HTTPRequest.new()
			add_child(r)
			r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/seen_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":seen_message[x], "conversationId":Updatedate.load_game("user_name", "")+"_"+str(x)}))
	
	$TabContainer.current_tab = 0
	vbox = $TabContainer.get_child(0)
	vbox.get_node("ScrollContainer").scroll_vertical = 0
	scroll[part] = vbox.get_node("ScrollContainer").scroll_vertical
	w.queue_free()

func add_message(m, _id="",obj=vbox.get_node("ScrollContainer/VBoxContainer/PanelContainer")):
	var box = obj.duplicate()
	box.show()
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = '[right]' + m.text
	box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = m.timestamp
	box.add_to_group("message")
	box.set_meta("id", m.id)
	
	if box.get_node_or_null("HBoxContainer/MarginContainer/VBoxContainer/Label/Button"):
		box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").pressed.connect(func():
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label/Button").hide()
			box.self_modulate.a = 0.0
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").modulate.a = 0.0
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").modulate.a = 0.0
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").modulate.a = 0.0
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emitting = true
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emission_rect_extents = box.size / 2
			box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").position = box.size / 2
			await box.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").finished
			box.queue_free()
			Updatedate.messages[int(_id.right(1))].erase(m)
			Updatedate.socket.send(JSON.stringify({"type":"delete","senderId":Updatedate.load_game("user_name"), "id":m.id, "conversationId":_id, "receiverId":supporters[part]}).to_utf8_buffer())
			)
	vbox.get_node("ScrollContainer/VBoxContainer/PanelContainer").add_sibling(box)
	seen_message[int(_id.right(1))].append(m.id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label4.text = "پشتیبان های برخط: " + str(Updatedate.online_supporter[part])
	
	if not_seen[0] == 0:
		$Label3.hide()
	else:
		$Label3.show()
		$Label3.text = str(not_seen[0])
	if not_seen[1] == 0:
		$Label2.hide()
	else:
		$Label2.show()
		$Label2.text = str(not_seen[1])
	if not_seen[2] == 0:
		$Label.hide()
	else:
		$Label.show()
		$Label.text = str(not_seen[2])
	
	vbox.get_node("HBoxContainer/TextEdit/TextEdit").text = vbox.get_node("HBoxContainer/TextEdit").text
	vbox.get_node("HBoxContainer/TextEdit").scroll_fit_content_height = not (vbox.get_node("HBoxContainer/TextEdit/TextEdit").size.y > vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 5)
	if vbox.get_node("HBoxContainer/TextEdit").scroll_fit_content_height:
		vbox.get_node("HBoxContainer/TextEdit").custom_minimum_size.y =  vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 1
	else:
		vbox.get_node("HBoxContainer/TextEdit").custom_minimum_size.y =  vbox.get_node("HBoxContainer/TextEdit").get_line_height() * 5
	match Updatedate.socket.get_ready_state():
		1:
			while Updatedate.socket.get_available_packet_count():
				var d = (Updatedate.get_json(Updatedate.socket.get_packet()))
				if d.has("type") and d.type == "onlineUsers":
					Updatedate.online_supporter = d.count
				if d.has("type") and d.type == "delete":
					for z in range(3):
							var delete = []
							for n in Updatedate.messages[z]:
								if n.id == d.message:
									delete.append(n)
							if delete.size() > 0:
								Updatedate.messages[z].erase(delete[0])
					for m in get_tree().get_nodes_in_group("message"):
						if m.get_meta("id") == d.message:
							m.self_modulate.a = 0.0
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").modulate.a = 0.0
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").modulate.a = 0.0
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").modulate.a = 0.0
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emitting = true
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").emission_rect_extents = m.size / 2
							m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").position = m.size / 2
							await m.get_node("HBoxContainer/MarginContainer/VBoxContainer/CPUParticles2D").finished
							m.queue_free()
				elif d.has("message") :
					vbox = $TabContainer.get_child(int(d.id.right(1)))
					Updatedate.messages[int(d.id.right(1))].append(d.message)
					if part != int(d.id.right(1)):
						not_seen[int(d.id.right(1))] += 1
						Notification.add_notif("پیام شما پاسخ داده شد", Notification.SUCCESS, load("res://sound/mixkit-confirmation-tone-2867.wav"))
					if d.message.sender == Updatedate.load_game("user_name"):
						add_message(d.message, d.id)
					elif d.message.sender != Updatedate.load_game("user_name") and Updatedate.load_game("user_name") in d.receiverId:
						add_message(d.message, d.id ,$Container/PanelContainer)
					if not seen_message.has(d.message.id):
						var r = HTTPRequest.new()
						add_child(r)
						r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/seen_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":[d.message.id],"conversationId":Updatedate.load_game("user_name", "")+"_"+str(part)}))
						await r.request_completed
						r.queue_free()
				vbox = $TabContainer.get_child(part)
				vbox.get_node("ScrollContainer").scroll_vertical = 0
				scroll[part] = 0
	var s:PackedStringArray = vbox.get_node("HBoxContainer/TextEdit/TextEdit").text.split(" ")
	var s2:PackedStringArray = vbox.get_node("HBoxContainer/TextEdit/TextEdit").text.split("‌‌")
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
	vbox.get_node("HBoxContainer/Button").disabled = not (not_Space and not_Space2)
func _on_button_pressed() -> void:
	var message = {
		"type":"message",
		"conversationId":Updatedate.load_game("user_name")+"_"+str(part),
		"senderId": Updatedate.load_game("user_name"),
		"receiverId": supporters[part],
		"content": vbox.get_node("HBoxContainer/TextEdit").text
	}
	Updatedate.socket.send(JSON.stringify(message).to_utf8_buffer())
	vbox.get_node("HBoxContainer/TextEdit").text = ""
func _on_tab_container_tab_selected(tab: int) -> void:
	part = tab
	vbox = $TabContainer.get_child(part)
	not_seen[part] = 0
	var ids = []
	for box in vbox.get_node("ScrollContainer/VBoxContainer").get_children():
		if box.get_meta("id", "") != "" and not seen_message.has(box.get_meta("id", "")):
			ids.append(box.get_meta("id", ""))
			seen_message.append(box.get_meta("id", ""))
	if ids.size() > 0:
		var r = HTTPRequest.new()
		add_child(r)
		r.request(Updatedate.protocol+Updatedate.subdomin+"/auth/seen_message", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"id":ids}))
		await r.request_completed
		r.queue_free()

func _on_scroll_container_scroll_ended() -> void:
	scroll[part] = vbox.get_node("ScrollContainer").scroll_vertical


func _on_scroll_container_scroll_started() -> void:
	scroll[part] = vbox.get_node("ScrollContainer").scroll_vertical


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
