@tool
extends Resource
class_name MainButton
@export var arrow_icon:Texture2D:
	set(x):
		arrow_icon = x
		notify_property_list_changed()
@export var max_arrow_width = 0
@export var offset_arrow = Vector2.ZERO
@export_range(-360, 360, 0.1) var start_rotation = 0
@export_range(-360, 360, 0.1) var end_rotation = 0
@export var icon_selected:Texture2D
@export var icon_unselected:Texture2D
@export var label_settings:TabSettings
@export var expand_icon : bool = false:
	set(x):
		expand_icon = x
		notify_property_list_changed()
@export var max_icon_width:int=0
@export var flat : bool = false
@export var disabled : bool = false
@export var icon_v_aligment:VerticalAlignment=VERTICAL_ALIGNMENT_TOP
@export var icon_h_aligment:HorizontalAlignment=HORIZONTAL_ALIGNMENT_CENTER
@export var aligment:HorizontalAlignment=HORIZONTAL_ALIGNMENT_CENTER
@export_multiline var text:String=""
@export var normal_style:StyleBox
@export var hover_style:StyleBox
@export var pressed_style:StyleBox
@export var hover_pressed_style:StyleBox
@export var disabled_style:StyleBox
