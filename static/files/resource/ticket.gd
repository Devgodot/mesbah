extends Control

var current_time = 0
var end_time = 100
var date = ""
var calendar
var active = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.has_singleton("GodotGetFile"):
		calendar = Engine.get_singleton("GodotGetFile")
		calendar.permission_granted.connect(func():
			var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
			for e in event:
				if e.has("title"):
					if e.title == "یادآور حرکت قطار":
						$TextureRect4/Button2.disabled = true
						$TextureRect4/Button2.text = "ثبت شده در تقویم")
		calendar.calendar_event_activity_closed.connect(func():
			var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
			for e in event:
				if e.has("title"):
					if e.title == "یادآور حرکت قطار":
						$TextureRect4/Button2.disabled = true
						$TextureRect4/Button2.text = "ثبت شده در تقویم")
	Updatedate.load_user()
	var first_name = Updatedate.load_game("first_name", "")
	var last_name = Updatedate.load_game("last_name", "")
	$TextureRect4/Label.text = "نام: "+ first_name + " " + last_name
	$TextureRect4/Label2.text = "نام پدر: "+ Updatedate.load_game("father_name", "")
	Updatedate.get_icon_user(Updatedate.load_game("icon", ""), Updatedate.load_game("user_name", ""), $TextureRect4/NinePatchRect/TextureRect2)
	if Updatedate.load_game("icon", "") == "" and $TextureRect4/NinePatchRect/TextureRect2.texture is GradientTexture2D:
		$TextureRect4/NinePatchRect/Label.text = first_name[0] if first_name != "" else ""
		if last_name != "":
			$TextureRect4/NinePatchRect/Label.text += "‌" + last_name[0]
	var data = Updatedate.load_game("ticket_user", {})
	Updatedate.request("/ticket/get_user_ticket")
	Updatedate.request_completed.connect(func(data, url):
		if url == "/ticket/get_user_ticket":
			if data:
				Updatedate.save("ticket_user", data, false)
			if data and data.has("ticket"):
				check_ticket(data)
			elif data and not data.has("ticket"):
				$Label4.hide()
				$Timer.stop()
				$TextureRect2.hide()
				$TextureProgressBar.hide()
				$TextureRect4/Button.show()
				$TextureRect4/Button2.hide())
	
	if data and data.has("ticket"):
		data.ticket.current_time = int(Time.get_unix_time_from_system()) * 1000
		check_ticket(data)
	else:
		$Label4.hide()
		$Timer.stop()
		$TextureRect2.hide()
		$TextureProgressBar.hide()
		$TextureRect4/Button.show()
		$TextureRect4/Button2.hide()
	create_qur_code()
	$TextureRect/Path2D/PathFollow2D/Node2D/CPUParticles2D2.emitting = true
	$CPUParticles2D.emitting = true
	var pos = size.x / 2
	$TextureRect4.position.x = pos - ($TextureRect4.size.x / 2)
	$TextureProgressBar.position.x = pos - ($TextureProgressBar.size.x / 2)
	$Label4.position.x = pos - ($Label4.size.x / 2)
	$Panel.position.x = pos - ($Panel.size.x / 2)
	$TextureRect2.position.y = $TextureProgressBar.position.y - 10
	$ColorRect2.size.y = size.y
	$ColorRect2.position.y = 1000
	await get_tree().create_timer(0.1).timeout
	show()
func check_ticket(data):
	current_time = int(data.ticket.current_time) - int(int(Updatedate.load_game("start_ticket", "0")))
	end_time = int(data.ticket.unixtime)- int(int(Updatedate.load_game("start_ticket", "0")))
	date = data.ticket.unixtime
	if calendar:
		var event = calendar.getCalendarEvents(int(Updatedate.load_game("start_ticket", "0")) - 100000000, int(date) + 100000000)
		for e in event:
			if e.has("title"):
				if e.title == "یادآور حرکت قطار":
					$TextureRect4/Button2.disabled = true
					$TextureRect4/Button2.text = "ثبت شده در تقویم"
	$Label4.text = data.ticket.time
	$Label4.show()
	$Timer.start()
	$TextureRect2.show()
	$TextureProgressBar.show()
	$TextureRect4/Button.hide()
	$TextureRect4/Button2.show()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TextureRect2.position.x = $TextureProgressBar.position.x + ($TextureProgressBar.value * $TextureProgressBar.size.x / 100) - $TextureRect2.size.x / 2 
	if current_time > end_time:
		$Timer.stop()
	$TextureRect/Path2D/PathFollow2D.progress -= 200 * delta
	$TextureProgressBar.value = current_time * 100 / end_time
	if randi_range(0, 100) == 1:
		$TextureRect/Path2D/PathFollow2D/Node2D/AnimatedSprite2D.frame = not $TextureRect/Path2D/PathFollow2D/Node2D/AnimatedSprite2D.frame
func _on_timer_timeout() -> void:
	current_time += 1

func add_ticket():
	var w = Updatedate.add_wait($TextureRect4/Button)
	for ticket in $Panel/MarginContainer/ScrollContainer/GridContainer.get_children():
		if ticket.name != "Button":
			ticket.queue_free()
	var d = await Updatedate.request("/ticket/get_ticket")
	if d and d.has("error"):
		Notification.add_notif(d.error, Notification.ERROR)
		w.queue_free()
		return
	if d and d.has("data"):
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
						active = false
						current_time = 0
						Updatedate.save("start_ticket",str(message.current_time))
						create_qur_code()
						end_time = int(message.unixtime)- int(message.current_time)
						date = message.unixtime
						$TextureRect4/Label4.text = message.time
						$TextureRect4/Label4.show()
						$Timer.start()
						$TextureRect2.show()
						$TextureProgressBar.show()
						$TextureRect4/Button.hide()
						$TextureRect4Button2.show()
				w2.queue_free())
			index += 1
			$Panel/MarginContainer/ScrollContainer/GridContainer.add_child(btn)
	
	w.queue_free()
func _on_button_pressed() -> void:
	if Updatedate.load_game("accept_account", false):
		await add_ticket()
		if $Panel.position.y > size.y:
			active = true
			var tween = get_tree().create_tween()
			tween.tween_property($Panel, "position:y", (size.y / 2) - ($Panel.size.y), 0.5)
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.play()
		else:
			var tween = get_tree().create_tween()
			tween.tween_property($Panel, "position:y", size.y + 50, 0.5)
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.play()
			active = false
		
	else:
		Notification.add_notif("حساب شما تأیید نشده! به مسجد جامع مراجعه کنید.", Notification.ERROR)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if $Panel.position.y < size.y:
			var tween = get_tree().create_tween()
			tween.tween_property($Panel, "position:y", size.y + 50, 0.5)
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.play()
			active = false


func _on_button2_pressed() -> void:
	
	if calendar:
		calendar.addCalendarEvent("یادآور حرکت قطار", "قطار شادی داره حرکت می کنه، زود آماده شو جا نمونی.",int(Updatedate.load_game("start_ticket", "0")), date, 60)
	

func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)
	if what == NOTIFICATION_RESIZED:
		$TextureRect.position.x = size.x / 2
		var pos = size.x / 2
		$ColorRect2.size.y = size.y
		$ColorRect2.position.y = 1000
		$TextureRect4.position.x = pos - ($TextureRect4.size.x / 2)
		$TextureProgressBar.position.x = pos - ($TextureProgressBar.size.x / 2)
		$Label4.position.x = pos - ($Label4.size.x / 2)
		$Panel.position.x = pos - ($Panel.size.x / 2)
		$TextureRect2.position.y = $TextureProgressBar.position.y - 10
		if active:
			$Panel.position.y = (size.y / 2) - ($Panel.position.y / 2)
		else:
			$Panel.position.y = size.y + 10
		var num_point = 20
		var curve = Curve2D.new()
		curve.add_point(Vector2(0, 150))
		curve.add_point(Vector2(size.x / 2, 250), Vector2(-150, 0), Vector2(150, 0))
		curve.add_point(Vector2(size.x, 150))
		var length = curve.get_baked_length()
		var points = []
		for i in num_point:
			var t = (float(i) / (num_point - 1)) * length
			points.append(curve.sample_baked(t))
		$Line2D.points = points
		$Line2D2.points = points
		$Line2D3.points = points
func _on_savebutton_pressed() -> void:
	
	OS.shell_open("https://qr-code.ir/api/qr-code?s=5&e=M&t=P&d="+Updatedate.protocol+Updatedate.subdomin+"/ticket/check?user="+Updatedate.load_game("user_name"))
func create_qur_code():
	$TextureRect4/TextureRect3.show()
	if FileAccess.file_exists("user://resource/"+Updatedate.load_game("user_name")+".png"):
		var image = Image.new()
		image.load("user://resource/"+Updatedate.load_game("user_name")+".png")
		$TextureRect4/TextureRect3.texture = ImageTexture.create_from_image(image)
	else:
		var w = Updatedate.add_wait($TextureRect4/TextureRect3)
		var http = HTTPRequest.new()
		add_child(http)
		http.request("https://qr-code.ir/api/qr-code?s=5&e=M&t=P&d="+Updatedate.protocol+Updatedate.subdomin+"/ticket/check?user="+Updatedate.load_game("user_name"))
		http.request_completed.connect(func(result, response, header, data):
			w.queue_free()
			http.queue_free()
			if data.size() > 0:
				var image = Image.new()
				image.load_png_from_buffer(data)
				image.save_png("user://resource/"+Updatedate.load_game("user_name")+".png")
				$TextureRect4/TextureRect3.texture = ImageTexture.create_from_image(image)
			)


func _on_file_dialog_file_selected(path: String) -> void:
	pass


func _on_texture_rect_2_gui_input(event: InputEvent) -> void:
	print(0)
