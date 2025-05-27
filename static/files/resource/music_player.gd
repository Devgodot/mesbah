extends PanelContainer

var pos = 0
var length = 0
var stream
var ext = ""
func set_audio(audio:AudioStream):
	stream = audio
	_on_audio_stream_player_finished()
	$AudioStreamPlayer.stream = audio
	length = $AudioStreamPlayer.stream.get_length()
	$MarginContainer/HBoxContainer/HSlider.max_value = length
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $AudioStreamPlayer.playing:
		pos = $AudioStreamPlayer.get_playback_position()
	$MarginContainer/HBoxContainer/HSlider.value = pos
	var s = "" if int(length) % 60 >= 10 else "0"
	var s2 = "" if int(pos) % 60 >= 10 else "0"
	var m = "" if int(length) / 60 >= 10 else "0"
	var m2 = "" if int(pos) / 60 >= 10 else "0"
	$MarginContainer/Label.text = str(m, int(length) / 60, " : ", s, int(length) % 60, " / ", m2, int(pos) / 60, " : ", s2,int(pos) % 60)
	
func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		for music in get_tree().get_nodes_in_group("music"):
			if music != self:
				music.get_node("MarginContainer/HBoxContainer/Button").button_pressed = false
	if $AudioStreamPlayer.stream:
		$MarginContainer/HBoxContainer/HSlider/CPUParticles2D.emitting = toggled_on
		$MarginContainer/HBoxContainer/Button/Sprite2D/CPUParticles2D.emitting = toggled_on
		$AudioStreamPlayer.playing = toggled_on
		$AudioStreamPlayer.seek(pos)

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		pos = $MarginContainer/HBoxContainer/HSlider.value


func _on_audio_stream_player_finished() -> void:
	pos = 0
	$MarginContainer/HBoxContainer/Button.button_pressed = false
	$MarginContainer/HBoxContainer/HSlider.value = 0
	$MarginContainer/HBoxContainer/HSlider/CPUParticles2D.emitting = false
	$MarginContainer/HBoxContainer/Button/Sprite2D/CPUParticles2D.emitting =  false


func _on_h_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		pos = clamp((float(event.position.x) / float($MarginContainer/HBoxContainer/HSlider.size.x)) * $MarginContainer/HBoxContainer/HSlider.max_value, 0, length)
		if $AudioStreamPlayer.playing :
			$AudioStreamPlayer.seek(pos)
