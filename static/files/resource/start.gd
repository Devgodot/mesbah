extends Control

var seen = 0
var user_label:Label
var supporter_label:Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.current_user = Updatedate.load_game("current_user", 0)
	Updatedate.load_user()
	$SystemBarColorChanger.set_navigation_bar_color(Color("e8ad31"))
	if not Updatedate.load_game("management"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(3), 3)
	if not Updatedate.load_game("editor", false) and not Updatedate.load_game("support"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(4), 4 if Updatedate.load_game("management") else 3)
	if Updatedate.load_game("support", false):
		var d = Updatedate.list_users
		if d :
			for user2 in d:
				seen += user2.new
		Updatedate.seen = seen
		
	var m = await Updatedate.request("/auth/unseen_message")
	if m and m.has("num"):
		if m.num != 0:
			$Button5/Label.show()
			$Button5/Label.text = str(int(m.num))
	if not Updatedate.load_game("support"):
		var m2 = await Updatedate.request("/auth/unseen_message?p=1")
		if m2 and m2.has("num"):
			if m2.num != 0:
				Updatedate.seen = m2.num
	get_tree().create_timer(0.10).timeout.connect(func ():
		show()
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


func _on_custom_tab_container_tab_selected(tab: int) -> void:
	if tab == 0 or tab == 1:
		Updatedate.save("tab", tab, false)
	else :
		Updatedate.save("tab", 1, false)
	match tab:
		2:
			if not Updatedate.load_game("management") and not Updatedate.load_game("support"):
				Transation.change(self, "control.tscn")
			else:
				$CustomTabContainer.current_tab = 1
				$CustomTabContainer.set_style()
				Notification.add_notif("پشتیبانان به این بخش دسترسی ندارند.", Notification.ERROR)
		3:
			if Updatedate.load_game("management", false):
				Transation.change(self, "managment.tscn")
			else:
				Transation.change(self, "main2.tscn")
		4:
			Transation.change(self, "main2.tscn")


func _on_control_item_pressed2(id: String) -> void:
	Updatedate.p_scene = scene_file_path.get_file().get_basename()
	Updatedate.part = 3 +int(id)
	Transation.change(self, "positions.tscn")
