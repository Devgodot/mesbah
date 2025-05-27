extends Control


var change = false

func _on_button_pressed(part) -> void:
	Updatedate.part = part
	Transation.change(self,  "menu2.tscn")
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "main.tscn", -1)



func _on_back_button_pressed() -> void:
	Transation.change(self, "main.tscn", -1)
	
