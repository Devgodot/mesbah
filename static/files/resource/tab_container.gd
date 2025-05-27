@tool
@icon("res://sprite/menu.png")
extends Control
class_name CustomTabContainer
var numbers :Array[Icon]
signal tab_selected(tab:int)
func _get_property_list():
	
	var properties = []
	var control_num = 0
	for child in get_children():
		if child != panel and child is Control:
			control_num += 1
	for i in range(control_num):
		
		properties.append({
			"name": "element_%d" % (i + 1),
			"type": TYPE_OBJECT,
			"hint":PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string":"Icon"
		})
	return properties
func _get(property):
	if property.begins_with("element_"):
		var index = property.get_slice("_", 1).to_int()
		if numbers.size() >= index:
			return numbers[index-1]
		return null
func _set(property, value):
	if property.begins_with("element_"):
		var index = property.get_slice("_", 1).to_int()
		if numbers.size() >= index:
			numbers[index-1] = value
			return true
		else:
			numbers.append(value)
			return true
	return false

@export var current_tab:int=-1:
	set(x):
		var p_tab = current_tab
		if !Engine.is_editor_hint():
			current_tab = x
		if !Engine.is_editor_hint():
			await tree_entered
		var buttons = []
		if panel.get_children().size() > 0.0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					buttons.append(child)
		if animation == false:
			current_tab = clamp(x, -1, buttons.size()-1)
			change_tab(p_tab, current_tab)
		ready_tab = x
@export var transation:bool=true
@export_group("separation")
@export var separation:float=70:
	set(x):
		separation = x
		add_tabs()
@export var separation_style:StyleBox=StyleBoxLine.new():
	set(x):
		separation_style = x
		add_tabs()

@export_group("panel")
@export var panel_style:StyleBox:
	set(x):
		panel_style = x
		panel.add_theme_stylebox_override("panel", panel_style)

@export_enum("چپ", "وسط", "راست") var horzonital_pos = 0:
	set(x):
		horzonital_pos = x
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			panel.get_child(0).alignment = x 
@export_enum("بالا", "پایین") var vertical_pos = 0:
	set(x):
		vertical_pos = x
		panel.position.y = [0, size.y - panel.size.y][vertical_pos if vertical_pos != null else 0]
@export var height_panel = 100:
	set(x):
		height_panel = x
		panel.size = Vector2(size.x , height_panel)
		panel.position.y = [0, size.y - panel.size.y][vertical_pos if vertical_pos != null else 0]
@export_group("tabs")
@export var element_min_size = Vector2(50, 50):
	set(x):
		element_min_size = x
		if element_min_size.y > height_panel:
			element_min_size.y = height_panel
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					child.custom_minimum_size = element_min_size
@export_subgroup("animation")
@export var tab_animation :TabAnimation:
	set(x):
		tab_animation = x
		tab_animation.tab_container = self
@export var animation_length:float=0.3
@export_subgroup("styles")

@export var tab_normal:StyleBox:
	set(x):
		tab_normal = x
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					child.add_theme_stylebox_override("normal", tab_normal)

@export var tab_hover:StyleBox:
	set(x):
		tab_hover = x
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					child.add_theme_stylebox_override("hover", tab_hover)

@export var tab_pressed:StyleBox:
	set(x):
		tab_pressed = x
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					child.add_theme_stylebox_override("pressed", tab_pressed)

@export var tab_focus:StyleBox:
	set(x):
		tab_focus = x
		if !Engine.is_editor_hint():
			await tree_entered
		if panel.get_children().size() > 0:
			for child in panel.get_child(0).get_children():
				if child is Button:
					child.add_theme_stylebox_override("focus", tab_focus)
@export_subgroup("tab icon")
var panel = PanelContainer.new()
var animation = false
var ready_tab = 0
func child_entered(node):
	if node is Control:
		if node != panel:
			var element = Button.new()
			element.text = node.name
			element.name = node.name
			element.custom_minimum_size = element_min_size
			panel.get_child(0).add_child(element)
			node.renamed.connect(func():
				element.name = node.name
				element.text = node.name)
			add_tabs()
			notify_property_list_changed()

func child_remove(node):
	var controls= []
	for child in get_children():
		if child is Control and child != panel:
			controls.append(child)
	for child in panel.get_child(0).get_children():
		if child is Button:
			if child.get_meta("refrence", child) == node:
				child.queue_free()
			notify_property_list_changed()
	add_tabs(node)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.alignment = horzonital_pos
	panel.add_child(hbox)
	panel.name = "panel_element"
	panel.size = Vector2(size.x , height_panel)
	panel.position.y = [0, size.y - panel.size.y][vertical_pos if vertical_pos != null else 0]
	add_child(panel)
	add_tabs()
	child_entered_tree.connect(child_entered)
	child_exiting_tree.connect(child_remove)
	current_tab = ready_tab
func add_tabs(remove=null):
	if panel.get_children().size() > 0:
		for child in panel.get_child(0).get_children():
			child.queue_free()
		var s = VSeparator.new()
		if separation_style:
			s.add_theme_stylebox_override("separator", separation_style)
		s.add_theme_constant_override("separation", separation)
		panel.get_child(0).add_child(s)
		var index = 0
		for node in get_children():
			if node != panel and node != remove:
				if node is Control:
					var element = Button.new()
					var a = tab_animation.handle_animation() if tab_animation else null
					if numbers.size() <= index:
						numbers.resize(index+1)
					if numbers[index] != null:
						if numbers[index].tab_animation != null:
							a = numbers[index].tab_animation.handle_animation()
					if a:
						element.add_child(a)
					element.toggle_mode = true
					element.text = node.name
					element.name = node.name
					element.set_meta("refrence", node)
					element.pressed.connect(func():
						if animation == false:
							change_tab(current_tab, index)
							current_tab = index
							tab_selected.emit(index)
						)
					element.custom_minimum_size = element_min_size
					if tab_focus:
						element.add_theme_stylebox_override("focus", tab_focus)
					if tab_normal:
						element.add_theme_stylebox_override("normal", tab_normal)
					if tab_hover:
						element.add_theme_stylebox_override("hover", tab_hover)
					if tab_pressed:
						element.add_theme_stylebox_override("pressed", tab_pressed)
					panel.get_child(0).add_child(element)
					var s2 = VSeparator.new()
					if separation_style:
						s2.add_theme_stylebox_override("separator", separation_style)
					s2.add_theme_constant_override("separation", separation)
					panel.get_child(0).add_child(s2)
					index += 1
func change_tab(p, c):
	if animation == false and p != -1 and c != -1 and p != c:
		animation = true
		var controls = []
		for child in get_children():
			if child != panel and child is Control:
				controls.append(child)
		var p_child = controls[p]
		var c_child = controls[c]
		c_child.show()
		if transation:
			p_child.position.y = [panel.size.y, 0][vertical_pos]
			c_child.position.y = [panel.size.y, 0][vertical_pos]
			p_child.position.x = 0 
			c_child.position.x = size.x if p < c else -size.x
		var buttons = []
		for child in panel.get_child(0).get_children():
			if child is Button:
				buttons.append(child)
		var p_tab = buttons[p]
		var c_tab = buttons[c]
		
		if transation:
			var tween = get_tree().create_tween()
			tween.tween_property(p_child, "position:x", -size.x if p < c else size.x,animation_length)
			tween.play()
			var tween2 = get_tree().create_tween()
			tween2.tween_property(c_child, "position:x", 0, animation_length)
			tween2.play()
		else:
			p_child.hide()
		if p_tab.get_child(0) is TextureProgressBar:
			var progress:TextureProgressBar = p_tab.get_child(0)
			var tab_tween = get_tree().create_tween()
			tab_tween.tween_property(progress, "value", 0, animation_length)
			tab_tween.play()
			var progress2:TextureProgressBar = c_tab.get_child(0)
			var tab_tween2 = get_tree().create_tween()
			tab_tween2.tween_property(progress2, "value", 100, animation_length)
			tab_tween2.play()
			await tab_tween.finished
		if transation:
			p_child.hide()
		animation = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	panel.size = Vector2(size.x , height_panel)
	panel.position.y = [0, size.y - panel.size.y][vertical_pos if vertical_pos != null else 0]
	panel.size.x = size.x
	if animation == false:
		var controls = []
		for child in get_children():
			if child != panel and child is Control:
				controls.append(child)
				child.position.y = [panel.size.y, 0][vertical_pos]
				child.position.x = 0
				child.size = size - Vector2(0, panel.size.y)
		for x in range(controls.size()):
			if x != current_tab:
				controls[x].hide()
			else:
				controls[x].show()
	var buttons = []
	for child in panel.get_child(0).get_children():
		if child is Button:
			buttons.append(child)
	numbers.resize(buttons.size())
	for z in range(numbers.size()):
		if numbers[z] is Icon:
			numbers[z].tab_container = self
		var child:Button = buttons[z]
		if child.get_child_count() > 0 and  child.get_child(0) is TextureProgressBar:
			var progress:TextureProgressBar = child.get_child(0)
			progress.size = child.size
			progress.show_behind_parent = true
			if animation == false:
				if z == current_tab:
					progress.value = 100
				else:
					progress.value = 0
		if z == current_tab:
			child.button_pressed = true
		else:
			child.button_pressed = false
		if numbers[z] != null:
			var style = numbers[z]
			child.icon = style.icon_selected if current_tab == z else style.icon_unselected
			if style.label_settings != null:
				child.add_theme_constant_override("outline_size", style.label_settings.outline_size)
				child.add_theme_font_size_override("font_size", style.label_settings.font_size)
				if style.label_settings.font != null:
					child.add_theme_font_override("font", style.label_settings.font)
				child.add_theme_color_override("font_color", style.label_settings.unselected_color)
				child.add_theme_color_override("font_hover_color", style.label_settings.unselected_color)
				child.add_theme_color_override("font_focus_color", style.label_settings.selected_color)
				child.add_theme_color_override("font_outline_color", style.label_settings.ouline_selected_color if child.button_pressed else style.label_settings.outline_unselected_color)
				child.add_theme_color_override("font_pressed_color", style.label_settings.selected_color)
				child.add_theme_color_override("font_hover_pressed_color", style.label_settings.selected_color)
			child.expand_icon = style.expand_icon
			child.icon_alignment = style.icon_h_aligment
			child.vertical_icon_alignment = style.icon_v_aligment
			child.flat = style.flat
			child.add_theme_constant_override("icon_max_width", style.max_icon_width if style.expand_icon else 0)
			if style.text != "":
				child.text = style.text
			else:
				child.text = child.get_meta("refrence", self).name
		else:
			child.text = child.get_meta("refrence", self).name
			child.expand_icon = false
			child.flat = false
			child.icon = null
			
