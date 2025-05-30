extends Control

var change = false
var media = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.load_user()
	var w = Updatedate.add_wait($ScrollContainer)
	var m = await Updatedate.request("/auth/get?name=message")
	if m and m.has("nums"):
		if m.nums[0]:
			for message in m.nums[0]:
				if message.has("type"):
					var box = $ScrollContainer/VBoxContainer/PanelContainer.duplicate()
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = message.sender
					if message.type == "update":
						if Updatedate.load_game("current_version", "") == Updatedate.load_game("update_version", ""):
							continue
					if message.type == "guid" or message.type == "update":
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer").hide()
					else:
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Button2").pressed.connect(func ():
							Updatedate.request("/auth/remove_message?id=%s&user=%s"%[message.id, message.data.user])
							box.queue_free()
							Notification.add_notif("با موفقیت لغو شد"))
						if message.type == "join":
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Button").pressed.connect(func ():
								var d = await Updatedate.request("/auth/join_group?group="+ message.data.group_name.uri_encode())
								box.queue_free()
								if d.has("message"):
									Notification.add_notif(d.message)
								if d.has("error"):
									Notification.add_notif(d.error, Notification.ERROR))
								
						if message.type == "request":
							box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Button").pressed.connect(func ():
								box.queue_free()
								var d = await Updatedate.request("/auth/accept_group?user="+ message.data.user)
								if d.has("message"):
									Notification.add_notif(d.message)
								if d.has("error"):
									Notification.add_notif(d.error, Notification.ERROR)
								)
					if message.has("image"):
						media.append(message.image.uri_decode().get_file())
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/TextureRect").show()
						Updatedate.get_message_image(message.image, box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/TextureRect"))
					if message.has("sound"):
						media.append(message.sound.uri_decode().get_file())
						var sound = preload("res://scenes/music_player.tscn").instantiate()
						Updatedate.get_message_sound(message.sound, sound)
						box.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2").add_child(sound)
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label2").text = message.data.time.split(".")[0]
					box.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "[right]"+message.text
					box.show()
					$ScrollContainer/VBoxContainer.add_child(box)
	
	w.queue_free()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)
		

func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
	

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if meta.begins_with("http"):
		OS.shell_open(meta)
	else:
		OS.shell_open("https://"+meta)
