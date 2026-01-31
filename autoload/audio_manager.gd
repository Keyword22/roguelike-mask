extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

const MAX_SFX_PLAYERS: int = 8

var sfx_cache: Dictionary = {}

const SFX_PATHS = {
	"hit": "res://audio/sfx/hit.wav",
	"miss": "res://audio/sfx/miss.wav",
	"death_goblin": "res://audio/sfx/goblin-death.wav",
	"death_slime": "res://audio/sfx/slime-death.wav",
	"death_skeleton": "res://audio/sfx/skeleton-death.wav",
	"death_ghost": "res://audio/sfx/ghost-death.wav",
	"death_fairy": "res://audio/sfx/fairy-death.wav",
	"death_demon": "res://audio/sfx/demon-death.wav",
}

const DEATH_SFX_MAP = {
	"Goblin": "death_goblin",
	"Slime": "death_slime",
	"Esqueleto": "death_skeleton",
	"Fantasma": "death_ghost",
	"Hada": "death_fairy",
	"Demonio": "death_demon",
}

func _ready() -> void:
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	_preload_sfx()
	_connect_signals()

func _preload_sfx() -> void:
	for key in SFX_PATHS:
		var path = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			sfx_cache[key] = load(path)

func _connect_signals() -> void:
	EventBus.entity_attacked.connect(_on_entity_attacked)
	EventBus.entity_died.connect(_on_entity_died)

func _on_entity_attacked(_attacker: Entity, _target: Entity, damage: int) -> void:
	if damage > 0:
		play_sfx_by_name("hit")
	else:
		play_sfx_by_name("miss")

func _on_entity_died(entity: Entity) -> void:
	if DEATH_SFX_MAP.has(entity.entity_name):
		play_sfx_by_name(DEATH_SFX_MAP[entity.entity_name])

func play_sfx_by_name(sfx_name: String, volume_db: float = 0.0) -> void:
	if sfx_cache.has(sfx_name):
		play_sfx(sfx_cache[sfx_name], volume_db)

const PITCH_VARIATION: float = 0.15

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = randf_range(1.0 - PITCH_VARIATION, 1.0 + PITCH_VARIATION)
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
