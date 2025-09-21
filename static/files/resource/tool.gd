extends SceneTree


func _init() -> void:
	var args = OS.get_cmdline_args()
	if args.has("--s"):
		var fn = args[args.find("--s") + 1]
		check(fn)
	quit()
func check(_path):
	var s = ResourceLoader.load(_path).instantiate()
	var nodes = s.get_tree_string().split("\n")
	var list = []
	for n in nodes:
		if n!= "":
			for p in s.get_node(n).get_property_list():
				if p.type == TYPE_OBJECT:
					var path = ([s.get_node(n).get(p.name).resource_path, n, p.name] if s.get_node(n).get(p.name) is Resource else null)
					if path != null:
						list.append(path)
	print(list)
