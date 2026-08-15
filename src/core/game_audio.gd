class_name GameAudio extends Node2D

@onready var crash_sound : AudioStreamPlayer2D = $CrashSound
@onready var laser_sound : AudioStreamPlayer2D = $LaserSound
@onready var upgrade_sound : AudioStreamPlayer2D = $UpgradeSound
@onready var error_sound : AudioStreamPlayer2D = $ErrorSound
@onready var enemy_hit_sound : AudioStreamPlayer2D = $EnemyHitSound

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