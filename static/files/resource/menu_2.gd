extends Control

var part = 0
var change = false
var texts = [["تدبر در قرآن (مسطورا) و نهج البلاغه", "چالش و کارکاه تئوری و عملی احکام", "چالش و گفتمان اعتقادی", "[center][b]مناجات خانگی
جلسه هفتگی هیأت
جلسات خانوادگی و ..."], ["شخصیت شناسی و مشاوره", "تغذیه و طب اسلامی", "آمادگی جسمانی", "    [b]تیر اندازی حرفه‌ای دیجیتال[/b]
برنامه‌های تفریحی ورزشی از جمله تنیس روی میز، فوتبال دستی، دارت، تنیس روی میز، بازی های کامپیوتری و ..."], ["کتاب و کتابخوانی", "بازی ها و کارسوق های فکری", "مهارت های ساختن، تفکر خلاق", "[center][font_size=60]اتاق فرار
[/font_size]جهت رایگان بودن اتاق فرار بایستی 2 الماس طلایی کسب نمونده باشید"]]
var textures = [[["res://sprite/wp-1544032956945.jpg","res://sprite/wp-1544032956945.jpg"], ["res://sprite/Layer 9.jpg", "res://sprite/12.jpg"]], [["res://sprite/Layer 7.jpg", "res://sprite/Layer 7.jpg"], ["res://sprite/14011114_1851874.jpg", "res://sprite/5.jpg"]], [["res://sprite/13950923_0535224.jpg", "res://sprite/13950923_0535224.jpg"], ["res://sprite/Layer 9.jpg", "res://sprite/6.jpg"]]]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	part = Updatedate.part
	var gender = Updatedate.load_game("gender", 0)
	var tag = Updatedate.load_game("tag", 0)
	$Control/Button9.text = texts[part][0]
	$Control/Button8.text = texts[part][1]
	$Control/Button7.text = texts[part][2]
	$Control/Button10/RichTextLabel.text = texts[part][3]
	if part == 2:
		if tag < 3:
			$Control/Button10.hide()
	
	$Control/TextureRect.texture = load(textures[part][gender][0 if tag < 3 else 1])
	for btn in get_tree().get_nodes_in_group("gallary"):
		btn.pressed.connect(func():
			Updatedate.gallary_part = str(part, "_", int(gender), "_", int(tag),"_", (btn.get_meta("id")))
			Updatedate.p_scene = scene_file_path.get_file().get_basename()
			Transation.change(self, "gallary.tscn")
			)
	
	for btn in get_tree().get_nodes_in_group("pos"):
		if btn is Button:
			btn.pressed.connect(func():
				Updatedate.plan = "رمضان 1403-1404"
				Updatedate.subplan = ["سلامت معنوی", "سلامت جسمانی", "سلامت فکری"][part]
				Updatedate.group_plan = btn.get_meta("group", false)
				Updatedate.p_scene = scene_file_path.get_file().get_basename()
				Transation.change(self, "positions.tscn")
				)
	await get_tree().create_timer(0.1).timeout
	show()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transation.change(self, "start.tscn", -1)
		
func _on_back_button_pressed() -> void:
	Transation.change(self, "start.tscn", -1)
