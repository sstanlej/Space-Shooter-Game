class_name GameAudio extends Node2D

@onready var crash_sound : AudioStreamPlayer2D = $CrashSound
@onready var laser_sound : AudioStreamPlayer2D = $LaserSound

# Called when the node enters the scene tree for the first time.
func play_crash() -> void:
	crash_sound.play()

func play_laser() -> void:
	laser_sound.play()
