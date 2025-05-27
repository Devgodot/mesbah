extends Control

var file = 0.0
var max_files = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Updatedate.start_download.connect(func(_size):
		max_files = _size)
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
		p.queue_free())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if max_files != 0:
		$TextureProgressBar.value = 34 + (float(file) / float(max_files)) * 27
	if file == max_files and file != 0:
		await get_tree().create_timer(0.5).timeout
		queue_free()
