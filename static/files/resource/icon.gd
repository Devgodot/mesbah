@tool
extends Resource
class_name Icon
@export var tab_animation:TabAnimation:
	set(x):
		tab_animation = x
		tab_animation.tab_container = tab_container
@export var icon_selected:Texture2D
@export var icon_unselected:Texture2D
@export var label_settings:TabSettings
@export var expand_icon : bool = false:
	set(x):
		expand_icon = x
		notify_property_list_changed()
@export var max_icon_width:int=0:
	set(x):
		max_icon_width = x
		if max_icon_width < 0:
			max_icon_width = 0
		
@export var flat : bool = false
@export var icon_v_aligment:VerticalAlignment=VERTICAL_ALIGNMENT_TOP
@export var icon_h_aligment:HorizontalAlignment=HORIZONTAL_ALIGNMENT_CENTER
@export var text:String=""
var tab_container
func _validate_property(property: Dictionary) -> void:
	if property.name == "max_icon_width":
		if expand_icon:
			property.usage = PROPERTY_USAGE_EDITOR
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		
	
