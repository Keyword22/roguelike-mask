extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

const MAX_SFX_PLAYERS: int = 8

func _ready() -> void:
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

func play_music(stream: AudioStream, volume_db: float = -10.0) -> void:
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_player.stop()
