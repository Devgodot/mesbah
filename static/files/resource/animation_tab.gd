@tool
extends Resource
class_name TabAnimation


@export var texture_progress:Texture2D:
	set(x):
		texture_progress = x
		if tab_container:tab_container.add_tabs()
@export var texture_over:Texture2D:
	set(x):
		texture_over = x
		if tab_container:tab_container.add_tabs()
@export var texture_under:Texture2D:
	set(x):
		texture_under = x
		if tab_container:tab_container.add_tabs()
@export var fill_mode:TextureProgressBar.FillMode=0:
	set(x):
		fill_mode = x
		if tab_container:tab_container.add_tabs()
@export var nine_patch_stretch:bool:
	set(x):
		nine_patch_stretch = x
		if tab_container:tab_container.add_tabs()
@export var texture_progress_offset:Vector2:
	set(x):
		texture_progress_offset = x
		if tab_container:tab_container.add_tabs()
@export var tint_progress:Color:
	set(x):
		tint_progress = x
		if tab_container:tab_container.add_tabs()
@export var tint_over:Color:
	set(x):
		tint_over = x
		if tab_container:tab_container.add_tabs()
@export var tint_under:Color:
	set(x):
		tint_under = x
		if tab_container:tab_container.add_tabs()
var tab_container:CustomTabContainer
func handle_animation():
	var progress = TextureProgressBar.new()
	progress.texture_progress = texture_progress
	progress.texture_over=texture_over
	progress.texture_under = texture_under
	progress.fill_mode = fill_mode
	progress.nine_patch_stretch = nine_patch_stretch
	progress.texture_progress_offset =texture_progress_offset 
	progress.tint_progress = tint_progress
	progress.tint_over = tint_over
	progress.tint_under = tint_under
	return progress
