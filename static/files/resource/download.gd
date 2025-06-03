extends Control

var file = 0.0
var max_files = 0.0
var main_text = ""
var dots = ""
var add_dots = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.start_download.connect(func(_size, _text):
		max_files = _size
		main_text =_text)
	Updatedate.download_progress.connect(func(i):
		file = i
		var p:Polygon2D =$Polygon2D.duplicate()
		p.show()
		p.look_at($CPUParticles2D.position)
		p.position.x = randi_range($CPUParticles2D.position.x - 400, $CPUParticles2D.position.x + 400)
		p.position.y = randi_range($CPUParticles2D.position.y - 400, $CPUParticles2D.position.y + 400)
		add_child(p)
		var tween = get_tree().create_tween()
		tween.tween_property(p, "position", $CPUParticles2D.position, 0.5)
		tween.play()
		await tween.finished
		
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
	if max_files != 0:
		$TextureProgressBar.value = 34 + (float(file) / float(max_files)) * 27
	if add_dots:
		add_dots = false
		dots += "." 
		if dots.length() > 3:
			dots = ""
		await get_tree().create_timer(0.8).timeout
		add_dots = true
	$Label.text = "[light color=white freq=30 num=2]" + main_text + dots
