extends ScrollContainer

@export var item_scene: PackedScene
@export var item_height: float = 210
@export var buffer: int = 5   # تعداد آیتم اضافه بالای و پایین صفحه برای smooth scroll

var items_pool: Array = []
var visible_items: Array = []
var conversations = {}
var ids = []
var content_vbox: VBoxContainer
func _refresh_content_height():
	var total_height = conversations.size() * item_height
	content_vbox.custom_minimum_size = Vector2(0, total_height)

func uuid(len:int, step:int=4):
	var w = ["z", "x", "w", "v", "u", "t", "s", "r", "q", "p", "o", "n", "m", "l", "k", "j", "i", "h", "g", "f", "e", "d", "c", "b", "a", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	var id = ""
	for x in len:
		id += w.pick_random()
	var y = 0
	for x in (len / step - 1) if len % step == 0 else len / step:
		id = id.insert(((x + 1) * step) + y, "_")
		y += 1
	return id

func _ready():
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content_vbox)
	conversations = Updatedate.list_messages()
	
	for x in 100000:
		conversations[uuid(16)] = { "new": 0, "username": "5100276153", "icon": "https://messbah403.ir/static/files/users/09999876739/51002761533016.webp", "name": "محمدحسین حق‌شناس", "custom_name": "", "part": "رمضان 1403-1404 - سلامت فکری", "last_seen": { "time": "1404/06/20  17:12", "timestamp": "1757598141330.0" }, "message":{"messages": { "text": str(x) }, "part": "رمضان 1403-1404 - سلامت فکری", "response": "", "seen": "1759416722682", "sender": "5100377003", "sender_name": "matin haghshenas", "time": "1404/07/10  18:21 $4", "updatedAt": "1759416695814", "createdAt": str(x), "id": "692c8b02-633c-42c8-9226-480f9e821515"}, "state":"online"}
	ids = conversations.keys()
	var not_message = ids.filter(func (m): return not conversations[m].has("message"))
	ids = ids.filter(func (m): return conversations[m].has("message"))
	ids.sort_custom(func(a, b): return float(conversations[a].message.createdAt) > float(conversations[b].message.createdAt))
	ids.append_array(not_message)
	# اتصال سیگنال scroll (Godot 4)
	self.connect("scroll_started", Callable(self, "_on_scroll"))
	_refresh_visible_items()
	_refresh_content_height()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
# ایجاد یا recycle آیتم‌ها
func _get_item() -> Node:
	if items_pool.size() > 0:
		return items_pool.pop_back()
	else:
		var item = item_scene.instantiate()
		item.hide()
		content_vbox.add_child(item)
		return item

# هنگام اسکرول، visible items را بروزرسانی کن
func _on_scroll():
	_refresh_visible_items()

func _refresh_visible_items():
	if conversations.size() == 0:
		return
	print(0)
	var scroll_top = get_v_scroll()
	var scroll_bottom = scroll_top + size.y

	var first_index = max(0, int(scroll_top / item_height) - buffer)
	var last_index = min(conversations.size() - 1, int(scroll_bottom / item_height) + buffer)

	# بازگرداندن آیتم‌های خارج از محدوده
	for item in visible_items.duplicate():
		if item.index < first_index or item.index > last_index:
			items_pool.append(item)
			visible_items.erase(item)
			item.hide()

	# اضافه کردن آیتم‌های جدید
	for i in range(first_index, last_index + 1):
		var exists = false
		for v in visible_items:
			if v.index == i:
				exists = true
				break
		if not exists:
			var item = _get_item()
			_populate_item(item, conversations[ids[i]], i)
			visible_items.append(item)

# پر کردن آیتم با داده
func _populate_item(item: Node, data, index: int):
	item.index = index
	item.global_position.y = index * item_height
	item.show()
	item.size.x = size.x
	# مثال ساده برای متن و نام کاربر
	if item.has_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label"):
		var label = item.get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer2/Label")
		label.text = data.message.messages.text if data.message and data.message.messages else ""
	
	# وضعیت آنلاین / offline
	if item.has_node("Panel/HBoxContainer/TextureRect/TextureRect2"):
		var icon_online = item.get_node("Panel/HBoxContainer/TextureRect/TextureRect2")
		if data.state == "online":
			icon_online.show()
		else:
			icon_online.hide()

	# نشانگر پیام جدید
	if item.has_node("Panel/HBoxContainer/VBoxContainer2/Label2"):
		var new_label = item.get_node("Panel/HBoxContainer/VBoxContainer2/Label2")
		if data.new > 0:
			new_label.text = str(int(data.new)) if data.new < 100 else "+99"
			new_label.show()
		else:
			new_label.hide()
