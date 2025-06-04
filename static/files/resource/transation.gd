extends Control
var active = false
var trans = 0
func change(scene, new_scene:String, dir=1):
	if not active:
		active = true
		var s = await Updatedate.load_scene(new_scene)
		Notification.add_notif("امتحانی هست")
		match trans:
			0:
				get_tree().get_root().add_child.call_deferred(s)
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
			
				
			1:
				get_tree().get_root().add_child(s)
				s.position.x = -1000 * dir
				var tween = get_tree().create_tween()
				tween.tween_property(scene, "position:x", 1000 * dir, 0.5)
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
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			6:
				$CPUParticles2D2.emitting = true
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			7:
				$CPUParticles2D3.position = Vector2(-100 if dir == 1 else 1100, 1000)
				$CPUParticles2D3.gravity.x = 1000 * dir
				$CPUParticles2D3.direction.x = dir
				$CPUParticles2D3.emitting = true
				await get_tree().create_timer(0.75).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			8:
				$CPUParticles2D4.emitting = true
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
			9:
				$CPUParticles2D5.emitting = true
				await get_tree().create_timer(0.5).timeout
				scene.queue_free()
				get_tree().get_root().add_child(s)
		await get_tree().create_timer(0.5).timeout
		active = false

func check_trans():
	if Updatedate.load_game("pro", false):
		trans = int(Updatedate.load_game("transation", 0))
	else:
		trans = 0
