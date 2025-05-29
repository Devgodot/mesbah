extends Control
signal select
var items = ["شنبه", "یک‌شنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنج‌شنبه", "جمعه"]
var current = 0
var change_pos = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var index = current
	for i in items:
		var label = Label.new()
		label.text = i
		label.size.x = $VBoxContainer.size.x
		label.size.y = 150
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		#label.gui_input.connect(func (event:InputEvent):
			#
			#if event is InputEventScreenTouch:
				#if label.modulate.a > 0:
					#current = index
					#print(index))
		label.position.y = (size.y / 2) - 75 + (150 * index)
		$VBoxContainer.add_child(label)
		index += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if change_pos > 150 and current < 0:
		change_pos = 0
		current += 1
		current = clamp(current, -items.size() + 1, 0)
		select.emit(items[abs(current)])
	if change_pos < -150 and current > -items.size() + 1:
		change_pos = 0
		current -= 1
		current = clamp(current, -items.size() + 1, 0)
		select.emit(items[abs(current)])
	if current == 0 and change_pos > 0:
		change_pos = 0
	if current == -items.size() + 1 and change_pos < 0:
		change_pos = 0
	current = clamp(current, -items.size() + 1, 0)
	
	var index = current
	for i in $VBoxContainer.get_children():
		i.add_theme_color_override("font_color", Color.WHITE)
		i.position.y = (size.y / 2) - 75 + (150 * index) + change_pos
		i.modulate.a = 1.0 -  (abs(i.position.y - ((size.y / 2) - 75)) / 150) * 0.35
		index += 1
	$VBoxContainer.get_child(abs(current)).add_theme_color_override("font_color", Color.AQUA)
func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if abs(event.relative.y) > 3:
			change_pos += event.relative.y
		
	if event is InputEventMouseButton:
		if !event.is_pressed():
			change_pos = 0
		if event.double_click:
			queue_free()
		
