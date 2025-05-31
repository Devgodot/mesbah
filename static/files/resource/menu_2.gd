extends Control

var part = 0
var change = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	part = Updatedate.part
	var gender = Updatedate.load_game("gender", 0)
	var tag = Updatedate.load_game("tag", 0)
	
	$TabContainer.current_tab = part
	
	$TabContainer.get_child(part).current_tab = gender
	$TabContainer.get_child(part).get_child(gender).current_tab = 0 if tag < 3 else 1
	for btn in get_tree().get_nodes_in_group("gallary"):
		btn.pressed.connect(func():
			Updatedate.gallary_part = str(part, "_", int(gender), "_", int(tag),"_", (btn.get_meta("id")))
			Updatedate.p_scene = scene_file_path.get_file().get_basename()
			Transation.change(self, "gallary.tscn")
			)
	
	for btn in get_tree().get_nodes_in_group("pos"):
		if btn is Button:
			btn.pressed.connect(func():
				Updatedate.p_scene = scene_file_path.get_file().get_basename()
				Transation.change(self, "positions.tscn")
				)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)
		
func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
