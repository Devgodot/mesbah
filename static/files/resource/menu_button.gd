@tool
extends VBoxContainer
class_name MenuButtonBar
signal item_pressed(id:String)
var control = Control.new()
var drag = false
@export var active :bool= false:
	set(x):
		if control and action == false:
			action = true
			if control.get_child_count() > 0:
				var btn:Button = control.get_child(0)
				if btn :
					if btn.get_child_count() > 0:
						var tex:TextureRect = btn.get_child(0)
						if base_button:
							var tween = get_tree().create_tween()
							tween.tween_property(tex, "rotation_degrees", base_button.end_rotation if x else base_button.start_rotation, 0.3)
							tween.play()
							var tween2 = get_tree().create_tween()
							tween2.tween_property(control, "custom_minimum_size:y", btn.size.y + sum if x else btn.size.y, 0.3)
							tween2.play()
							await tween.finished
		action = false
		active = x
@export var base_button :MainButton
@export var subpanel_style:StyleBox
@export var panel_style:StyleBox:
	set(x):
		panel_style = x
		if get_children().size() > 0:
			var panel2 : Panel=get_node("back_panel").get_child(0)
			if panel2 and panel_style:
				panel2.add_theme_stylebox_override("panel", panel_style)
@export var height:float=30
@export var options :Array[Options]:
	set(x):
		options = x
		var index = 0
		for option in options:
			if option:
				option.id = index
				option.main_button = self
				index += 1
		add_button()
var action = false
var sum = 0
func add_button():
	if control.get_children().size() > 0:
		for child in control.get_child(0).get_children():
			if child is Button or child is MenuButtonBar:
				child.queue_free(
				)
		var height_options = 0
		for option in options:
			if option:
				height_options += option.separation
				var btn
				if option.menu_button:
					btn = MenuButtonBar.new()
					btn.options = option.options
				else:
					btn = Button.new()
					btn.mouse_filter = Control.MOUSE_FILTER_PASS
					btn.mouse_force_pass_scroll_events = false
				btn.size.x = size.x
				if btn is Button:
					btn.text = option.text
				btn.size.y = option.height
				btn.set_meta("id", option.id)
				if btn is Button:
					btn.pressed.connect(func():
						item_pressed.emit(str(option.id)))
				else:
					btn.item_pressed.connect(func(id):
						item_pressed.emit(str(option.id,"_",id)))
				btn.position.y = control.get_child(0).size.y + height_options
				height_options += option.height + option.separation
				control.get_child(0).add_child(btn)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child.name == "base_counter":
			child.queue_free()
	
	var btn = Button.new()
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size = Vector2.ONE * (btn.size.y * 3 / 5)
	tex.position = Vector2.ONE * (btn.size.y * 2 / 5)
	tex.pivot_offset = tex.size / 2
	btn.add_child(tex)
	var panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(panel)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.mouse_force_pass_scroll_events = false
	btn.toggle_mode = true
	btn.gui_input.connect(func (event:InputEvent):
		
		if event is InputEventScreenTouch and event.is_released() and not drag:
			if Geometry2D.is_point_in_polygon(event.position, [Vector2(0, 0), Vector2(btn.size.x, 0), btn.size, Vector2(0,btn.size.y)]): 
				active= not active
		)
	control.queue_free()
	control = Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.name = "base_counter"
	control.add_child(btn)
	var panel2 = Panel.new()
	panel2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel_style:
		panel2.add_theme_stylebox_override("panel", panel_style)
		
	
	var c = Control.new()
	c.show_behind_parent = true
	c.name = "back_panel"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(panel2)
	add_child(c)
	add_child(control)
	add_button()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	if control:
		control.size.x = size.x
		control.clip_contents = true
		if control.get_child_count() > 0:
			var btn:Button = control.get_child(0)
			var panel2 : Panel=get_node("back_panel").get_child(0)
			if panel2:
				panel2.mouse_filter = Control.MOUSE_FILTER_IGNORE
				panel2.size = control.size
				
				panel2.show_behind_parent = true
				
			if btn :
				btn.toggle_mode = true
				btn.button_pressed = active
				var buttons = []
				var panel : Panel
				for child in btn.get_children():
					if child is Button or child is MenuButtonBar:
						buttons.append(child)
					if child is Panel:
						panel = child
						
				if options.size() > 0 and buttons.size() > 0:
					sum = options[buttons[0].get_meta("id", 0)].separation
					for button in buttons:
						var option :Options = options[button.get_meta("id", 0)]
						button.size.x = size.x
						button.size.y = option.height
						button.position.y = btn.size.y + sum
						if button is Button:
							button.text = option.text
							if option.normal_style:
								button.add_theme_stylebox_override("normal", option.normal_style)
							if option.hover_style:
								button.add_theme_stylebox_override("hover", option.hover_style)
							if option.pressed_style:
								button.add_theme_stylebox_override("pressed", option.pressed_style)
							if option.disabled_style:
								button.add_theme_stylebox_override("disabled", option.disabled_style)
							if option.focus_style:
								button.add_theme_stylebox_override("focus", option.focus_style)
							if option.font:
								button.add_theme_font_override("font", option.font)
							if option.outline_size:
								button.add_theme_constant_override("outline_size", option.outline_size)
							if option.font_size:
								button.add_theme_font_size_override("font_size", option.font_size)
							if option.font_color:
								button.add_theme_color_override("font_color", option.font_color)
							if option.outline_color:
								button.add_theme_color_override("font_outline_color", option.outline_color)
							if option.font_hover_color:
								button.add_theme_color_override("font_hover_color", option.font_hover_color)
							if option.font_pressed_color:
								button.add_theme_color_override("font_pressed_color", option.font_pressed_color)
							if option.font_disabled_color:
								button.add_theme_color_override("font_disabled_color", option.font_disabled_color)
							if option.font_focus_color:
								button.add_theme_color_override("font_focus_color", option.font_focus_color)
						else:
							if Engine.is_editor_hint():
								button.active = option.active
							button.height = option.height
							button.base_button = option.base_button
							button.subpanel_style = option.subpanel_style
							button.panel_style = option.panel_style
						sum += button.size.y + option.separation
					if action == false:
						control.custom_minimum_size.y = btn.size.y if active == false else btn.size.y + sum
					if panel:
						if subpanel_style:
							panel.add_theme_stylebox_override("panel", subpanel_style)
						panel.position.y = btn.size.y + 2
						panel.size.x = size.x
						panel.size.y = sum
						panel.visible = active
				if base_button:
					if btn.get_child_count() > 0:
						var tex:TextureRect = btn.get_child(0)
						if base_button.arrow_icon:
							tex.texture = base_button.arrow_icon
							if action == false:
								tex.rotation_degrees = base_button.start_rotation if active == false else base_button.end_rotation
						tex.size = clamp(Vector2.ONE * (btn.size.y * 3 / 5), Vector2(1, 1), base_button.max_arrow_width * Vector2.ONE if base_button.max_arrow_width != 0 else (btn.size.y * 3 / 5) * Vector2.ONE)
						tex.position = (Vector2.ONE * (btn.size.y / 5)) + base_button.offset_arrow
						tex.pivot_offset = tex.size / 2
					btn.flat = base_button.flat
					btn.disabled = base_button.disabled
					btn.icon = base_button.icon_selected if btn.button_pressed else base_button.icon_unselected
					btn.expand_icon = base_button.expand_icon
					btn.icon_alignment = base_button.icon_h_aligment
					btn.vertical_icon_alignment = base_button.icon_v_aligment
					btn.alignment = base_button.aligment
					btn.text = base_button.text
					btn.add_theme_constant_override("icon_max_width", base_button.max_icon_width)
					if base_button.label_settings:
						btn.add_theme_color_override("font_color", base_button.label_settings.unselected_color)
						btn.add_theme_color_override("font_hover_color", base_button.label_settings.unselected_color)
						btn.add_theme_color_override("font_pressed_color", base_button.label_settings.selected_color)
						btn.add_theme_color_override("font_focus_color", base_button.label_settings.selected_color if btn.button_pressed else base_button.label_settings.unselected_color)
						btn.add_theme_color_override("font_hover_pressed_color", base_button.label_settings.selected_color)
						btn.add_theme_color_override("font_outline_color", base_button.label_settings.ouline_selected_color if btn.button_pressed else base_button.label_settings.outline_unselected_color)
						btn.add_theme_constant_override("outline_size", base_button.label_settings.outline_size)
						if base_button.label_settings.font:
							btn.add_theme_font_override("font", base_button.label_settings.font)
						btn.add_theme_font_size_override("font_size", base_button.label_settings.font_size)
					if base_button.normal_style:
						btn.add_theme_stylebox_override("normal", base_button.normal_style)
					if base_button.hover_style:
						btn.add_theme_stylebox_override("hover", base_button.hover_style)
					if base_button.pressed_style:
						btn.add_theme_stylebox_override("pressed", base_button.pressed_style)
					if base_button.hover_pressed_style:
						btn.add_theme_stylebox_override("hover_pressed", base_button.hover_pressed_style)
					if base_button.disabled_style:
						btn.add_theme_stylebox_override("disabled", base_button.disabled_style)
					btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
				btn.size.x = size.x
				btn.size.y = height
				btn.global_position = global_position
func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		
		drag = true
	
	if event is InputEventMouseButton:
		if event.is_released():
			await get_tree().create_timer(0.1).timeout
			drag = false
