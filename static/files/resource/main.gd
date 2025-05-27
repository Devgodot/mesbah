extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Updatedate.load_game("support"):
		var m2 = await Updatedate.request("/auth/unseen_message?p=1")
		if m2 and m2.has("num"):
			if m2.num != 0:
				Updatedate.seen = m2.num
				$Button3/Label.show()
				$Button3/Label.text = str(m2.num)
	else:
		$Button3.hide()
	var m = await Updatedate.request("/auth/unseen_message")
	if m and m.has("num"):
		if m.num != 0:
			$Button2/Label.show()
			$Button2/Label.text = str(m.num)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Updatedate.seen > 0:
		$Button3/Label.show()
		$Button3/Label.text = str(Updatedate.seen)

func _on_button_7_pressed() -> void:
	Transation.change(self, "menu1.tscn")
	

func _on_button_pressed() -> void:
	Transation.change(self, "setting.tscn")


func _on_button_2_pressed() -> void:
	Transation.change(self, "messages.tscn")


func _on_button_8_pressed() -> void:
	Updatedate.p_scene = scene_file_path.get_file().get_basename()
	Updatedate.part = 3
	Transation.change(self, "positions.tscn")
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if Updatedate.load_game("editor", false):
			print(0)
			Transation.change(self, "start.tscn", -1)
		else:
			get_tree().quit()
func _on_button_5_pressed() -> void:
	Updatedate.p_scene = scene_file_path.get_file().get_basename()
	Updatedate.part = 4
	Transation.change(self, "positions.tscn")
	

func _on_button_3_pressed() -> void:
	Transation.change(self, "control.tscn")
	
