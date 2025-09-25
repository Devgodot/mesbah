extends Control

var file = 0.0
var max_files = 0.0
var main_text = ""
var dots = ""
var add_dots = true
var http:HTTPRequest
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.start_download.connect(func(_size, _text):
		max_files = _size
		main_text =_text)
	Updatedate.download_progress.connect(func(i, _http=null):
		if _http:
			http = _http
		file += 1
		var p:Polygon2D =$Polygon2D.duplicate()
		p.show()
		p.look_at($TextureProgressBar/CPUParticles2D.global_position)
		p.position.x = randi_range($TextureProgressBar/CPUParticles2D.global_position.x - 400, $TextureProgressBar/CPUParticles2D.global_position.x + 400)
		p.position.y = randi_range($TextureProgressBar/CPUParticles2D.global_position.y - 400, $TextureProgressBar/CPUParticles2D.global_position.y + 400)
		add_child(p)
		var tween = get_tree().create_tween()
		tween.tween_property(p, "position", $TextureProgressBar/CPUParticles2D.global_position, 0.5)
		tween.play()
		await tween.finished
		var tween2 = get_tree().create_tween()
		tween2.tween_property($TextureProgressBar, "value", 34 + (float(file) / float(max_files)) * 27, 27.0 / float(max_files) * 0.05)
		tween2.play()
		var c: CPUParticles2D =$CPUParticles2D2.duplicate()
		c.position = p.position+Vector2(17, 25)
		c.emitting = true
		add_child(c)
		p.queue_free()
		await c.finished
		c.queue_free()
		)
	Updatedate.end_download.connect(func():
		queue_free())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if http:
		if http.get_body_size() != -1:
			$ProgressBar.show()
			$ProgressBar.value = http.get_downloaded_bytes() / http.get_body_size() * 100
			var num = http.get_downloaded_bytes()
			var max = http.get_body_size()
			var prefix1 = "ب"
			var prefix2 = "ب"
			if num > 1000000:
				num = int(num / 10000)
				num /= 100.0
				prefix1 = "م.ب"
			elif num > 1000:
				num = int(num / 100)
				num /= 100.0
				prefix1 = "ک.ب"
			if max > 1000000:
				max = int(max / 10000)
				max /= 100.0
				prefix2 = "م.ب"
			elif max > 1000:
				max = int(max / 100)
				max /= 100.0
				prefix2 = "ک.ب"
			$ProgressBar/Label.text = str(num , " ", prefix1, " / ", max, " ", prefix2)
	if add_dots:
		add_dots = false
		dots += "." 
		if dots.length() > 3:
			dots = ""
		await get_tree().create_timer(0.8).timeout
		add_dots = true
	$Label.text = "[light color=white freq=30 num=2]" + main_text + dots
