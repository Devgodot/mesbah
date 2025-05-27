extends Control

var max_notif
enum State {SUCCESS, ERROR}
const SUCCESS= State.SUCCESS
const ERROR = State.ERROR
func _ready() -> void:
	max_notif = Updatedate.load_game("max_notif", 5)
# Called when the node enters the scene tree for the first time.
func add_notif(text="پیام شما پاسخ داده شد", state:=SUCCESS, sound:AudioStream=load("res://sound/mixkit-positive-notification-951.wav")):
	if Updatedate.load_game("show_notif", true):
		if $VBoxContainer.get_children().size() < max_notif:
			var n:Label= $VBoxContainer/Label.duplicate()
			var a = AudioStreamPlayer.new()
			n.text = text
			if state == SUCCESS:
				a.stream = sound
				n.add_theme_stylebox_override("normal", load("res://styles/notification.tres"))
			else:
				a.stream = load("res://sound/mixkit-wrong-answer-fail-notification-946.wav")
			n.show()
			$VBoxContainer.add_child(n)
			add_child(a)
			a.playing = true
			await a.finished
			a.queue_free()
		else :
			$VBoxContainer.get_child(max_notif-1).queue_free()
			var n= $VBoxContainer/Label.duplicate()
			n.text = text
			var a = AudioStreamPlayer.new()
			if state == SUCCESS:
				a.stream = sound
				n.add_theme_stylebox_override("normal", load("res://styles/notification.tres"))
			else:
				a.stream = load("res://sound/mixkit-wrong-answer-fail-notification-946.wav")
			n.show()
			$VBoxContainer.add_child(n)
			add_child(a)
			a.playing = true
			await a.finished
			a.queue_free()
			
			
