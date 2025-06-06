extends Control

var current_time = 0
var end_time = 100
var date = ""
var calendar
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SystemBarColorChanger.set_navigation_bar_color(Color("1f7a2f"))
	if Engine.has_singleton("GodotGetFile"):
		calendar = Engine.get_singleton("GodotGetFile")
		calendar.permission_granted.connect(func():
			var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
			for e in event:
				if e.has("title"):
					if e.title == "یادآور حرکت قطار":
						$Button2.disabled = true
						$Button2.text = "ثبت شده در تقویم")
		calendar.calendar_event_activity_closed.connect(func():
			var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
			for e in event:
				if e.has("title"):
					if e.title == "یادآور حرکت قطار":
						$Button2.disabled = true
						$Button2.text = "ثبت شده در تقویم")
	var w = Updatedate.add_wait(self)
	Updatedate.load_user()
	$Label.text = "نام: "+ Updatedate.load_game("first_name", "") + " " +Updatedate.load_game("last_name", "")
	$Label2.text = "نام پدر: "+ Updatedate.load_game("father_name", "")
	Updatedate.get_icon_user(Updatedate.load_game("icon", ""), Updatedate.load_game("user_name", ""), $NinePatchRect/TextureRect2)
	var data = await  Updatedate.request("/ticket/get_user_ticket")
	if data.has("ticket"):
		current_time = int(data.ticket.current_time) - int(int(Updatedate.load_game("start_ticket", "0")))
		end_time = int(data.ticket.unixtime)- int(int(Updatedate.load_game("start_ticket", "0")))
		date = data.ticket.unixtime
		create_qur_code()
		if calendar:
			
			var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
			
			for e in event:
				if e.has("title"):
					if e.title == "یادآور حرکت قطار":
						$Button2.disabled = true
						$Button2.text = "ثبت شده در تقویم"
		$Label4.text = data.ticket.time
		$Label4.show()
		$Timer.start()
		$TextureRect2.show()
		$TextureProgressBar.show()
		$Button.hide()
		$Button2.show()
	w.queue_free()
	$Node2D/CPUParticles2D2.emitting = true
	$AnimationPlayer.play("train")
	$CPUParticles2D.emitting = true
	show()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TextureRect2.position.x = $TextureProgressBar.position.x + ($TextureProgressBar.value * $TextureProgressBar.size.x / 100) - $TextureRect2.size.x / 2 
	if current_time > end_time:
		$Timer.stop()
	
	$TextureProgressBar.value = current_time * 100 / end_time
	if randi_range(0, 100) == 1:
		$Node2D/AnimatedSprite2D.frame = not $Node2D/AnimatedSprite2D.frame
func _on_timer_timeout() -> void:
	current_time += 1

func add_ticket():
	var w = Updatedate.add_wait($Button)
	for ticket in $Panel/MarginContainer/ScrollContainer/GridContainer.get_children():
		if ticket.name != "Button":
			ticket.queue_free()
	var d = await Updatedate.request("/ticket/get_ticket")
	if d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)
		w.queue_free()
		return
	if d.has("data"):
		var month = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]
		var index = 0
		for ticket in d.data:
			var btn = $Panel/MarginContainer/ScrollContainer/GridContainer/Button.duplicate()
			btn.show()
			var t = ticket.time.split(" ")
			btn.get_node("Label").text = str(ticket.day, " ", t[0].split("/")[2], " ",month[int(t[0].split("/")[1]) - 1], "\n", "ساعت ", t[1] if int(t[1].split(":")[0]) <= 12 else str(int(t[1].split(":")[0]) - 12, ":"  if int(t[1].split(":")[1]) != 0 else "", t[1].split(":")[1] if int(t[1].split(":")[1]) != 0 else "") , " صبح" if int(t[1].split(":")[0]) < 12 else " عصر")
			btn.get_node("ProgressBar").value = int(ticket.users) * 100 / int(ticket.max_users)
			btn.get_node("ProgressBar/Label").text = str(int(ticket.users)," / " ,int(ticket.max_users))
			btn.get_node("Label3").text = str("سانس ", ["اول", "دوم", "سوم", "چهارم", "پنجم", "ششم", "هفتم", "هشتم", "نهم"][index])
			if ticket.users == ticket.max_users:
				btn.get_node("Label2").text = "ظرفیت تکمیل است"
				btn.get_node("Label2").horizontal_aligment = HORIZONTAL_ALIGNMENT_CENTER
			btn.pressed.connect(func():
				var w2 = Updatedate.add_wait($Panel/MarginContainer/ScrollContainer)
				var http = HTTPRequest.new()
				add_child(http)
				http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/add_user_to_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":ticket.time}))
				var d2 = await http.request_completed
				http.timeout = 10
				while d2[3].size() == 0:
					http.request(Updatedate.protocol+Updatedate.subdomin+"/ticket/add_user_to_ticket", Updatedate.get_header(), HTTPClient.METHOD_POST, JSON.stringify({"time":ticket.time}))
					d2 = await http.request_completed
				http.queue_free()
				var message = Updatedate.get_json(d2[3])
				if message:
					if message.has("error"):
						Notification.add_notif(message.error, Notification.ERROR)
					if message.has("message"):
						Notification.add_notif(message.message)
						$Panel.hide()
						current_time = 0
						Updatedate.save("start_ticket",str(message.current_time))
						prints(Updatedate.load_game("start_ticket"), (message.current_time))
						end_time = int(message.unixtime)- int(message.current_time)
						date = message.unixtime
						$Label4.text = message.time
						$Label4.show()
						$Timer.start()
						$TextureRect2.show()
						$TextureProgressBar.show()
						$Button.hide()
						$Button2.show()
				w2.queue_free())
			index += 1
			$Panel/MarginContainer/ScrollContainer/GridContainer.add_child(btn)
	
	w.queue_free()
func _on_button_pressed() -> void:
	if Updatedate.load_game("accept_account", false):
		await add_ticket()
		if $AnimationPlayer3.current_animation_position == 0.0:
			$AnimationPlayer3.play("panel")
	else:
		Notification.add_notif("حساب شما تأیید نشده! به مسجد جامع مراجعه کنید.", Notification.ERROR)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if $AnimationPlayer3.current_animation_position != 0.0:
			$AnimationPlayer3.play_backwards("panel")


func _on_button2_pressed() -> void:
	
	if calendar:
		calendar.addCalendarEvent("یادآور حرکت قطار", "قطار شادی داره حرکت می کنه، زود آماده شو جا نمونی.",int(Updatedate.load_game("start_ticket", "0")), date, 60)
	

func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)


func _on_savebutton_pressed() -> void:
	
	OS.shell_open("https://qr-code.ir/api/qr-code?s=5&e=M&t=P&d="+Updatedate.protocol+Updatedate.subdomin+"/ticket/check?user="+Updatedate.load_game("user_name"))
func create_qur_code():
	$TextureRect3.show()
	if FileAccess.file_exists("user://resource/"+Updatedate.load_game("user_name")+".png"):
		var image = Image.new()
		image.load("user://resource/"+Updatedate.load_game("user_name")+".png")
		$TextureRect3.texture = ImageTexture.create_from_image(image)
	else:
		var w = Updatedate.add_wait($TextureRect3)
		var http = HTTPRequest.new()
		add_child(http)
		http.request("https://qr-code.ir/api/qr-code?s=5&e=M&t=P&d="+Updatedate.protocol+Updatedate.subdomin+"/ticket/check?user="+Updatedate.load_game("user_name"))
		var d = await http.request_completed
		while d[3].size() == 0:
			http.request("https://qr-code.ir/api/qr-code?s=5&e=M&t=P&d="+Updatedate.protocol+Updatedate.subdomin+"/ticket/check?user="+Updatedate.load_game("user_name"))
			d = await http.request_completed
		var image = Image.new()
		image.load_png_from_buffer(d[3])
		image.save_png("user://resource/"+Updatedate.load_game("user_name")+".png")
		$TextureRect3.texture = ImageTexture.create_from_image(image)
		w.queue_free()


func _on_file_dialog_file_selected(path: String) -> void:
	pass
