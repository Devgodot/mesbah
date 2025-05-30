extends Control

var seen = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$SystemBarColorChanger.set_navigation_bar_color(Color("33385e"))
	RenderingServer.set_default_clear_color(Color("33385e"))
	if not Updatedate.load_game("management"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(3), 3)
	if not Updatedate.load_game("editor", false) or not Updatedate.load_game("support"):
		$CustomTabContainer.add_tabs(null, $CustomTabContainer.get_child(4), 3)
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
			$Button5/Label.text = str(m.num)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Updatedate.load_game("support", false) and Updatedate.seen  > 0:
		$Button2/Label.show()
		$Button2/Label.text = str(Updatedate.seen)

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
	match id:
		"0":
			Transation.change(self, "ticket.tscn")


func _on_button_5_pressed() -> void:
	Transation.change(self, "messages.tscn")


func _on_custom_tab_container_tab_selected(tab: int) -> void:
	match tab:
		2:
			Transation.change(self, "control.tscn")
		3:
			Transation.change(self, "managment.tscn")
		4:
			Transation.change(self, "main2.tscn")


func _on_control_item_pressed2(id: String) -> void:
	Updatedate.p_scene = scene_file_path.get_file().get_basename()
	Updatedate.part = 3 +int(id)
	Transation.change(self, "positions.tscn")
