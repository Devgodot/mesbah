extends Control

var plugin
var plugin_name = "GodotGetImage"
var version = "1.3"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var user = Updatedate.load_user()
	if user:
		var data = await Updatedate.load_from_server()
		Transation.check_trans()
		Updatedate.save("current_version", version, false)
		if data is Dictionary:
			var required_info = ["father_name", "first_name", "last_name", "birthday", "gender", "tag"]
			var not_data= false
			for r in required_info:
				if !data.data.has(r):
					not_data = true
			if not_data:
				Transation.change(self, "register.tscn")
			else:
				if FileAccess.file_exists("user://resource/Updatedate.gd"):
					get_tree().call_group("image_show", "queue_free")
					Updatedate.set_script(ResourceLoader.load("user://resource/Updatedate.gd"))
					
				await Updatedate.update_resource()
				if FileAccess.file_exists("user://resource/Updatedate.gd"):
					get_tree().call_group("image_show", "queue_free")
					Updatedate.set_script(ResourceLoader.load("user://resource/Updatedate.gd"))
					await Updatedate.get_tree().create_timer(0.1).timeout
				Transation.change(self, "start.tscn")
				
		else:
			Transation.change(self, "start.tscn")
	else:
		Transation.change(self, "register.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
