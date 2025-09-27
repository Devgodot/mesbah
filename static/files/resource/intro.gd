extends Control

var plugin
var plugin_name = "GodotGetImage"
var version = "1.3"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var user = Updatedate.load_user()
	await update_resource()
	if user:
		var data = await Updatedate.load_from_server()
		Transation.check_trans()
		Updatedate.save("current_version", version, false)
		if data is Dictionary:
			var required_info = ["father_name", "first_name", "last_name", "birthday", "gender", "tag"]
			var not_data= false
			for r in required_info:
				if !data.data.has(r):
					not_data = true
			if not_data:
				Transation.change(self, "register.tscn")
			else:
				if FileAccess.file_exists("user://resource/Updatedate.gd"):
					get_tree().call_group("image_show", "queue_free")
					Updatedate.texture = null
					Updatedate.set_script(ResourceLoader.load("user://resource/Updatedate.gd"))
					await Updatedate.get_tree().create_timer(0.1).timeout
				Transation.change(self, "start.tscn")
		else:
			await Updatedate.get_tree().create_timer(0.1).timeout
			Transation.change(self, "start.tscn")
	else:
		await Updatedate.get_tree().create_timer(0.1).timeout
		Transation.change(self, "register.tscn")
func update_resource():
	var subdomin = Updatedate.subdomin
	var internet = Updatedate.internet
	var protocol = Updatedate.protocol
	if subdomin != "127.0.0.1:5000" and internet:
		var http = HTTPRequest.new()
		add_child(http)
		var last_update = "1758988600207"
		if float(Updatedate.load_game("last_update", "0")) > float(last_update):
			last_update = Updatedate.load_game("last_update", "0")
		else:
			DirAccess.remove_absolute("user://resource")
			DirAccess.remove_absolute("user://update")
		if not DirAccess.dir_exists_absolute("user://update"):
			DirAccess.make_dir_absolute("user://update")
		http.request(protocol+subdomin+"/check_resource", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"time":last_update, "file":"hash_list.json"}))
		var d = await http.request_completed
		http.timeout = 10
		while d[3].size() == 0:
			http.request(protocol+subdomin+"/check_resource", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"time":last_update, "file":"hash_list.json"}))
			d = await http.request_completed
		http.queue_free()
		var data = Updatedate.get_json(d[3])
		print(data)
		if data and not data.has("error"):
			if not DirAccess.dir_exists_absolute("user://resource"):
				DirAccess.make_dir_absolute("user://resource")
			if data.add.size() > 0 or data.pack.size() > 0:
				get_tree().get_root().add_child(preload("res://scenes/download.tscn").instantiate())
			var index = 1
			if data.pack.size() > 0:
				Updatedate.start_download.emit(data.add.size(), "بروزرسانی ‌دارایی‌ها")
			for file in data.pack:
				var http2 = HTTPRequest.new()
				add_child(http2)
				http2.download_file = "user://update/"+file
				http2.request(protocol+subdomin+"/static/files/update/"+file, ["Content-Type: application/json"])
				Updatedate.download_progress.emit(index, http2)
				await http2.request_completed
				http2.queue_free()
				print(FileAccess.get_file_as_bytes("user://update/"+file).size())
				ProjectSettings.load_resource_pack("user://update/"+file)
				index += 1
				http2.queue_free()
			if data.add.size() > 0:
				index = 1
				Updatedate.start_download.emit(data.add.size(), "بروزرسانی فایل‌ها")
			for file in data.add:
				var http2 = HTTPRequest.new()
				add_child(http2)
				Updatedate.download_progress.emit(index)
				http2.download_file = "user://resource/"+file
				http2.request(protocol+subdomin+"/static/files/resource/"+file, ["Content-Type: application/json"])
				await http2.request_completed
				http2.queue_free()
				index += 1
				http2.queue_free()
			Updatedate.save("last_update", str(data.time), false)
			await get_tree().create_timer(1.5).timeout
			Updatedate.end_download.emit()
