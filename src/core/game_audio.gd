class_name GameAudio extends Node2D

@onready var crash_sound : AudioStreamPlayer2D = $CrashSound
@onready var laser_sound : AudioStreamPlayer2D = $LaserSound
@onready var upgrade_sound : AudioStreamPlayer2D = $UpgradeSound
@onready var error_sound : AudioStreamPlayer2D = $ErrorSound
@onready var enemy_hit_sound : AudioStreamPlayer2D = $EnemyHitSound
@onready var select_sound : AudioStreamPlayer2D = $SelectSound
@onready var levelup_sound : AudioStreamPlayer2D = $LevelUpSound

@export var background_music: AudioStream
var music_player: AudioStreamPlayer

func _ready() -> void:
	setup_music_player()

func setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusicPlayer"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(music_player)

	if background_music:
		play_music(background_music)

func play_music(stream: AudioStream, volume_db: float = -15.0) -> void:
	if not stream or not music_player:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_crash() -> void:
	crash_sound.play()

func play_laser() -> void:
	laser_sound.play()

func play_upgrade() -> void:
	upgrade_sound.play()

func play_error() -> void:	
	error_sound.play()

func play_enemy_hit() -> void:
	enemy_hit_sound.play()

func play_select() -> void:
	select_sound.play()

func play_levelup() -> void:
	levelup_sound.play()