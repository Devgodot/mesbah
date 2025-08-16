extends Control

var part = "sh"
var target
var change = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	part = Updatedate.gallary_part
	Updatedate.request_completed.connect(func(data, url):
		if url.begins_with("/ListFiles?path=app/"):
			if data:
				var i = Updatedate.load_game("gallery", {})
				i[part] = data.files
				Updatedate.save("gallery", i, false)
				check_images(data.files))
	if part != "":
		Updatedate.request("/ListFiles?path=app/"+part)
		if !DirAccess.dir_exists_absolute("user://"+part):
			DirAccess.make_dir_absolute("user://"+part)
		var images = Updatedate.load_game("gallery", {})
		if images.has(part):
			check_images(images[part])
	await get_tree().create_timer(0.1).timeout
	show()
func check_images(images):
	for child in $MarginContainer/ScrollContainer/GridContainer.get_children():
		if child.name != "instance":
			child.queue_free()
	var names = []
	for image in images:
		names.append(image.get_file())
		var btn = $MarginContainer/ScrollContainer/GridContainer/instance.duplicate()
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
		
