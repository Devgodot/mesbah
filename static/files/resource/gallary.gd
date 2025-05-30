extends Control

var part = "sh"
var target
var change = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	part = Updatedate.gallary_part
	var w = Updatedate.add_wait($MarginContainer)
	var images = await Updatedate.request("/ListFiles?path=app/"+part)
	
	if part != "":
		if !DirAccess.dir_exists_absolute("user://"+part):
			DirAccess.make_dir_absolute("user://"+part)
		var names = []
		print(images)
		for image in images.files:
			
			names.append(image.get_file())
			var btn = $MarginContainer/ScrollContainer/GridContainer/Button.duplicate()
			btn.show()
			Updatedate.get_gallery_image(image, btn.get_child(0).get_child(0))
			btn.pressed.connect(func():
				$TextureRect.size = btn.get_child(0).get_child(0).size
				$TextureRect.position = btn.get_child(0).get_child(0).global_position
				$TextureRect.texture = btn.get_child(0).get_child(0).texture
				$TextureRect.show()
				target = btn.get_child(0).get_child(0)
				var tween= get_tree().create_tween()
				tween.tween_property($TextureRect, "size", size, 0.5)
				tween.play()
				var tween2= get_tree().create_tween()
				tween2.tween_property($TextureRect, "position", Vector2.ZERO, 0.5)
				tween2.play())
			$MarginContainer/ScrollContainer/GridContainer.add_child(btn)
		
		for file in DirAccess.get_files_at("user://"+part):
			if !names.has(file):
				DirAccess.remove_absolute("user://"+part+"/"+file)
		w.queue_free()
		$Label2.visible = names.size() == 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.double_click:
			if target and get_tree().get_processed_tweens().size() == 0:
				var tween= get_tree().create_tween()
				tween.tween_property($TextureRect, "size", target.size, 0.5)
				tween.play()
				var tween2= get_tree().create_tween()
				tween2.tween_property($TextureRect, "position", target.global_position, 0.5)
				tween2.play()
				await tween2.finished
				target = null
				$TextureRect.hide()
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if target and get_tree().get_processed_tweens().size() == 0:
			var tween= get_tree().create_tween()
			tween.tween_property($TextureRect, "size", target.size, 0.5)
			tween.play()
			var tween2= get_tree().create_tween()
			tween2.tween_property($TextureRect, "position", target.global_position, 0.5)
			tween2.play()
			await tween2.finished
			target = null
			$TextureRect.hide()
		else:
			Transation.change(self,  Updatedate.p_scene+".tscn", -1)
	
func _on_back_button_pressed() -> void:
	if target and get_tree().get_processed_tweens().size() == 0:
		var tween= get_tree().create_tween()
		tween.tween_property($TextureRect, "size", target.size, 0.5)
		tween.play()
		var tween2= get_tree().create_tween()
		tween2.tween_property($TextureRect, "position", target.global_position, 0.5)
		tween2.play()
		await tween2.finished
		target = null
		$TextureRect.hide()
	else:
		Transation.change(self,  Updatedate.p_scene+".tscn", -1)
		
