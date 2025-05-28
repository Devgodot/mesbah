extends Control

var seen = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$SystemBarColorChanger.set_navigation_bar_color(Color("33385e"))
	RenderingServer.set_default_clear_color(Color("33385e"))
	if Updatedate.load_game("management"):
		$Button3.show()
	if Updatedate.load_game("editor", false) or Updatedate.load_game("support"):
		$Button2.show()
	if Updatedate.load_game("support", false):
		var d = Updatedate.list_users
		if d :
			for user2 in d:
				seen += user2.new
		Updatedate.seen = seen
	
	
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
