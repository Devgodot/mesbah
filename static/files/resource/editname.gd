extends Control

var aligment = "[right]"
var font_size = "[font_size=45]"
var font_color = "[color=white]"
var outline_color = ""
var outline_size = ""
var shake = ""
var wave = ""
var light = ""
var tornado = ""
var base_name = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for spin in get_tree().get_nodes_in_group("spin"):
		if spin is SpinBox:
			spin.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
			
	$TabContainer.set_tab_title(0, "کد نویسی")
	$TabContainer.set_tab_title(1, "آماده")
	base_name = Updatedate.load_game("first_name", "") + " " + Updatedate.load_game("last_name", "")
	$TabContainer/TextEdit.text = Updatedate.load_game("custom_name")
	aligment = Updatedate.load_game("aligment", aligment)
	font_color = Updatedate.load_game("font_color", font_color)
	font_size = Updatedate.load_game("font_size", font_size)
	outline_color = Updatedate.load_game("outline_color", outline_color)
	outline_size = Updatedate.load_game("outline_size", outline_size)
	shake = Updatedate.load_game("shake", shake)
	wave = Updatedate.load_game("wave", wave)
	tornado = Updatedate.load_game("tornado", tornado)
	light = Updatedate.load_game("light", light)
	$RichTextLabel.text = $TabContainer/TextEdit.text
	$TabContainer/ScrollContainer/VBoxContainer/BoxContainer/OptionButton.select({"[right]":0, "[center]":1, "[left]":2}[aligment])
	$TabContainer/ScrollContainer/VBoxContainer/BoxContainer2/SpinBox.value = font_size.to_int()
	$TabContainer/ScrollContainer/VBoxContainer/BoxContainer2/ColorPickerButton.color = Color.from_string(font_color.split("=")[1].erase(font_color.split("=")[1].length() - 1), Color.WHITE)
	$TabContainer/ScrollContainer/VBoxContainer/BoxContainer3/SpinBox.value = outline_size.to_int()
	if outline_color != "":
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer3/ColorPickerButton.color = Color.from_string(outline_color.split("=")[1].erase(outline_color.split("=")[1].length() - 1), Color.WHITE)
	$TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox.button_pressed = shake != ""
	$TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox2.button_pressed = light != ""
	$TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox3.button_pressed = tornado != ""
	$TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox4.button_pressed = wave != ""
	if light != "":
		var light_param = light.split(" ")
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer2/ColorPickerButton.color = Color.from_string(light_param[1].split("=")[1], Color.WHITE)
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer/SpinBox.value = light_param[4].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer3/SpinBox.value = light_param[2].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer4/SpinBox.value = light_param[3].to_int()
	if wave != "":
		var wave_param = wave.split(" ")
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer5/GridContainer/HBoxContainer/SpinBox.value = wave_param[1].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer5/GridContainer/HBoxContainer3/SpinBox.value = wave_param[2].to_int()
	if shake != "":
		var shake_param = shake.split(" ")
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer4/SpinBox.value = shake_param[1].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer/SpinBox.value = shake_param[2].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer3/SpinBox.value = shake_param[3].to_int()
	if tornado != "":
		var tornado_param = tornado.split(" ")
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer6/GridContainer/HBoxContainer/SpinBox.value = tornado_param[1].to_int()
		$TabContainer/ScrollContainer/VBoxContainer/BoxContainer6/GridContainer/HBoxContainer3/SpinBox.value = tornado_param[2].to_int()
	show()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $TabContainer.current_tab == 1:
		if not $TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox.button_pressed:
			shake = ""
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7.hide()
		else:
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7.show()
			shake = "[shake level={0} rate={1} freq={2}]".format([$TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer4/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer3/SpinBox.value])
		if not $TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox3.button_pressed:
			tornado = ""
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer6.hide()
		else:
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer6.show()
			tornado = "[tornado radius={0} freq={1}]".format([$TabContainer/ScrollContainer/VBoxContainer/BoxContainer6/GridContainer/HBoxContainer/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer7/GridContainer/HBoxContainer3/SpinBox.value])
		if not $TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox4.button_pressed:
			wave = ""
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer5.hide()
		else:
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer5.show()
			wave = "[wave amp={0} freq={1}]".format([$TabContainer/ScrollContainer/VBoxContainer/BoxContainer5/GridContainer/HBoxContainer/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer5/GridContainer/HBoxContainer3/SpinBox.value])
		if not $TabContainer/ScrollContainer/VBoxContainer/HBoxContainer/CheckBox2.button_pressed:
			light = ""
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4.hide()
		else:
			$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4.show()
			light = "[light color=#{0}".format([$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer2/ColorPickerButton.color.to_html(false)])+ " freq={1} len={2} num={0}]".format([$TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer3/SpinBox.value, $TabContainer/ScrollContainer/VBoxContainer/BoxContainer4/GridContainer/HBoxContainer4/SpinBox.value])
		aligment = ["[right]", "[center]", "[left]"][$TabContainer/ScrollContainer/VBoxContainer/BoxContainer/OptionButton.selected]
		font_size = "[font_size=%d]"%[$TabContainer/ScrollContainer/VBoxContainer/BoxContainer2/SpinBox.value]
		outline_size = "[outline_size=%d]"%[$TabContainer/ScrollContainer/VBoxContainer/BoxContainer3/SpinBox.value]
		font_color = "[color=%s]"%$TabContainer/ScrollContainer/VBoxContainer/BoxContainer2/ColorPickerButton.color.to_html(false)
		outline_color = "[outline_color=%s]"%$TabContainer/ScrollContainer/VBoxContainer/BoxContainer3/ColorPickerButton.color.to_html(false)
		$RichTextLabel.text = aligment + font_size + font_color + outline_size + outline_color + shake + light + tornado + wave + base_name
		$TabContainer/TextEdit.text = $RichTextLabel.text
func _on_text_edit_text_changed() -> void:
	$RichTextLabel.text = $TabContainer/TextEdit.text


func _on_button_pressed() -> void:
	Notification.add_notif("با موفقیت بروزرسانی شد")
	Updatedate.multy_save({
		"font_color": font_color,
		"font_size": font_size,
		"outline_color": outline_color,
		"custom_name": $TabContainer/TextEdit.text,
		"outline_size": outline_size,
		"shake": shake,
		"wave": wave,
		"tornado": tornado,
		"light": light,
		"aligment":aligment
		})
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "setting.tscn", -1)


func _on_button_2_pressed() -> void:
	Transation.change(self, "setting.tscn", -1)
