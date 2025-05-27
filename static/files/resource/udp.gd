# Godot 4 GDScript UDP Server Example

extends Control

var udp_socket:UDPServer
var udp_client:PacketPeerUDP
var port = 41234
var clients = []
var audio_stream_player: AudioStreamPlayer
var audio_effect_capture:AudioStreamPlayer
var recording: bool = false

func start_recording():
	audio_effect_capture.bus = "Record"
	audio_effect_capture.playing = true
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Record"), 0, true)
	recording = true
	print("Recording started")

func stop_recording():
	audio_effect_capture.playing = false
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Record"), 0, false)
	recording = false
	print("Recording stopped")
func _ready():
	udp_socket = UDPServer.new()
	udp_client = PacketPeerUDP.new()
	udp_client.set_dest_address("127.0.0.1", port)
	var err = udp_socket.listen(port)
	if err != OK:
		print("Error binding to port: ", err)
	else:
		print("UDP Server listening on port: ", port)

	# Get the AudioStreamPlayer and AudioEffectCapture nodes
	audio_stream_player = $AudioStreamPlayer # Replace with your actual node path
	audio_effect_capture = $AudioEffectCapture # Replace with your actual node path
func _process(delta):
	
	audio_stream_player.playing = true
	var pack = (udp_client.get_packet())
	if pack.size() != 0:
		
		audio_stream_player.stream.data = pack
	if recording:
		# Get captured audio data
		var captured_audio:AudioEffectCapture = AudioServer.get_bus_effect(1, 0)
		var buffer = captured_audio.get_buffer(captured_audio.get_frames_available())
		if buffer.size() > 0:
			# Convert audio data to ByteArray
			var audio_data: PackedByteArray = buffer.to_byte_array()
			# Send audio data to server
			udp_client.put_packet(audio_data)
			captured_audio.clear_buffer()
	if Input.is_action_just_pressed("ui_accept"):
		start_recording()
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if udp_client != null:
			udp_client.close()
			print("UDP Server closed")
		get_tree().quit()
