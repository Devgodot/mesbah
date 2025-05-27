@tool
extends Resource
class_name Options
@export var id : int
@export var menu_button:bool=false:
	set(x):
		menu_button = x
		notify_property_list_changed()
		if main_button:
			main_button.add_button()
@export var text:String
@export var height = 20
@export var separation = 10
@export var active:bool=false
@export var base_button:MainButton
@export var panel_style:StyleBox
@export var subpanel_style:StyleBox
@export var options :Array[Options] = []:
	set(x):
		options = x
		var index = 0
		for option in options:
			if option:
				option.id = index
				option.main_button = main_button
				index += 1
		if main_button:
			main_button.add_button()
@export var font:Font
@export_group("سبک ها")
@export var normal_style : StyleBox
@export var focus_style : StyleBox
@export var hover_style : StyleBox
@export var pressed_style : StyleBox
@export var disabled_style : StyleBox
@export_group("رنگ ها")
@export var font_color:Color
@export var outline_color:Color
@export var font_hover_color:Color
@export var font_pressed_color:Color
@export var font_disabled_color:Color
@export var font_focus_color:Color
@export_group("اندازه ها")
@export var outline_size:float=0
@export var font_size:float=24
var main_button :MenuButtonBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _validate_property(property: Dictionary) -> void:
	
	if property.name == "id":
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if menu_button:
		if property.name in ["text", "font", "normal_style", "focus_style", "disabled_style", "pressed_style", "hover_style", "font_color", "outline_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_size", "outline_size"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		if property.name in ["active", "base_button", "options", "panel_style", "subpanel_style"]:
			property.usage |= PROPERTY_USAGE_EDITOR
		
	else:
		if property.name in ["text", "font", "normal_style", "focus_style", "disabled_style", "pressed_style", "hover_style", "font_color", "outline_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_size", "outline_size"]:
			property.usage |= PROPERTY_USAGE_EDITOR
		if property.name in ["active", "base_button", "options", "panel_style", "subpanel_style"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
