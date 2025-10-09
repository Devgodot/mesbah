# Item.gd  (attach to root Control of Item.tscn)
extends Control

@export var index: int = -1

func populate(index: int, data) -> void:
	self.index = index
	$Label.text = str(index) + ": " + str(data)  # یا هرچیزی که میخوای نمایش بدی

func _on_pressed() -> void:
	# اگر آیتم دکمه دارد یا سیگنال نیاز است
	emit_signal("item_pressed", index)
