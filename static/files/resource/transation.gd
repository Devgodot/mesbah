extends Control
signal scene_loaded(scene:Node)
var active = false
var trans = 0

func change(scene, new_scene:String, dir=1):
	if Updatedate.bg.visible:
		Updatedate.hide_picture()
		
		return
	
	if not active:
		Updatedate.failed_request = []
		active = true
		load_scene_threaded(new_scene)
		var s = await scene_loaded
		
		match trans:
			0:
				get_tree().get_root().add_child.call_deferred(s)
				scene.queue_free()
			1:
				get_tree().get_root().add_child(s)
				s.position.x = -size.x * dir
				var tween = get_tree().create_tween()
				tween.tween_property(scene, "position:x", size.x * dir, 0.5)
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.play()
				var tween2 = get_tree().create_tween()
				tween2.tween_property(s, "position:x", 0, 0.5)
				tween2.play()
				tween2.set_ease(Tween.EASE_IN_OUT)
				await tween.finished
				scene.queue_free()
			2:
				get_tree().get_root().add_child(s)
				s.modulate.a = 0
				scene.modulate.a = 1
				var tween = get_tree().create_tween()
				tween.tween_property(scene, "modulate:a", 0, 0.5)
				tween.set_ease(Tween.EASE_IN)
				tween.play()
				var tween2 = get_tree().create_tween()
				tween2.tween_property(s, "modulate:a", 1, 0.5)
				tween2.play()
				tween2.set_ease(Tween.EASE_OUT)
				await tween.finished
				scene.queue_free()
			3:
				get_tree().get_root().add_child(s)
				s.pivot_offset = s.size / 2
				scene.pivot_offset = scene.size / 2
				s.scale = Vector2(0, 0) if dir == 1 else Vector2.ONE
				if dir == -1:
					scene.z_index = 11
				if dir == 1:
					s.z_index = 13
				var tween = get_tree().create_tween()
				tween.tween_property(s if dir==1 else scene, "scale", Vector2.ONE if dir == 1 else Vector2.ZERO, 0.5)
				tween.set_ease(Tween.EASE_IN)
				tween.play()
				await tween.finished
				scene.queue_free()
			4:
				scene.rotation = 0
				scene.pivot_offset = scene.size / 2
				var tween = get_tree().create_tween()
				tween.tween_property(scene, "rotation", PI * dir, 0.25)
				tween.set_ease(Tween.EASE_IN)
				tween.play()
				await tween.finished
				get_tree().get_root().add_child(s)
				s.pivot_offset = s.size / 2
				s.rotation = PI * dir
				scene.queue_free()
				var tween2 = get_tree().create_tween()
				tween2.tween_property(s, "rotation", PI * 2 * dir, 0.25)
				tween2.set_ease(Tween.EASE_IN)
				tween2.play()
			5:
				$CPUParticles2D.emitting = true
				$CPUParticles2D.emission_rect_extents = size / 2
				$CPUParticles2D.position = size / 2
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			6:
				$CPUParticles2D2.emitting = true
				$CPUParticles2D2.emission_rect_extents = size / 2
				$CPUParticles2D2.position = size / 2
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			7:
				$CPUParticles2D3.position = Vector2(-100 if dir == 1 else size.x + 100, size.y / 2)
				$CPUParticles2D3.gravity.x = size.x * dir
				$CPUParticles2D3.direction.x = dir
				$CPUParticles2D3.emitting = true
				$CPUParticles2D3.emission_rect_extents = size / 2
				await get_tree().create_timer(0.75).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			8:
				$CPUParticles2D4.emitting = true
				$CPUParticles2D4.emission_rect_extents = size / 2
				$CPUParticles2D4.position = size / 2
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			9:
				$CPUParticles2D5.emitting = true
				$CPUParticles2D5.emission_rect_extents = size / 2
				$CPUParticles2D5.position = size / 2
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
		await get_tree().create_timer(0.5).timeout
		get_tree().root.move_child(s, get_tree().root.get_child_count() - 3)
		active = false

func check_trans():
	if Updatedate.load_game("pro", false):
		trans = int(Updatedate.load_game("transation", 0))
	else:
		trans = 0
func load_scene(new_scene) -> Object:
	var s:Object
	if DirAccess.dir_exists_absolute("user://resource"):
		var script:Script
		if FileAccess.file_exists("user://resource/"+new_scene.get_basename()+".gd"):
			script = load("user://resource/"+new_scene.get_basename()+".gd")
		if FileAccess.file_exists("user://resource/"+new_scene):
			
			s = ResourceLoader.load("user://resource/"+new_scene).instantiate()
			if script:
				s.set_script(script)
			
		else:
			ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
			while ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
	
			if script:
				s.set_script(script)
	else:
		
		DirAccess.make_dir_absolute("user://resource")
		ResourceLoader.load_threaded_request("res://scenes/"+new_scene)
		while ResourceLoader.load_threaded_get_status("res://scenes/"+new_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		s = ResourceLoader.load_threaded_get("res://scenes/"+new_scene).instantiate()
	
	return s
var loader_path := ""
var loader_scene:PackedScene
var loader_script:Script
var loaded_node:Node

func load_scene_threaded(path:String):
	
	loader_script = null
	loaded_node = null
	# بررسی اسکریپت
	if FileAccess.file_exists("user://resource/" + path.get_basename() + ".gd"):
		loader_script = load("user://resource/" + path.get_basename() + ".gd")
	# درخواست لود Threaded
	if FileAccess.file_exists("user://resource/" + path):
		ResourceLoader.load_threaded_request("user://resource/" + path)
		loader_path = "user://resource/" + path
	else:
		ResourceLoader.load_threaded_request("res://scenes/" + path)
		loader_path = "res://scenes/" + path
	set_process(true)
func _process(delta):
	if loader_path == "":
		return
	var status = ResourceLoader.load_threaded_get_status(loader_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		loader_scene = ResourceLoader.load_threaded_get(loader_path)
		loaded_node = loader_scene.instantiate()
		if loader_script:
			loaded_node.set_script(loader_script)
		scene_loaded.emit(loaded_node)
		# ریست کردن
		loader_path = ""
		set_process(false)
