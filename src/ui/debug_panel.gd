class_name DebugPanel extends TextureRect

var tween: Tween
var pos_hidden = [0, 135]
var pos_open = [0, 0]
var is_open: bool = false
var options: Array = ["trigger_pause", "level_up"]
@export var trigger_pause_label: RichTextLabel
@export var add_level_label: RichTextLabel

var labels: Array
var selected: int = 0

func _ready() -> void:
	labels = [trigger_pause_label, add_level_label]
	labels[selected].add_theme_color_override("default_color", Color.LIME)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		if is_open:
			move_close()
			print("Closed debug panel")
		else:
			move_open()
			print("Opened debug panel")
	if not is_open:
		return
	if event.is_action_pressed("down"):
		if options.size() > selected + 1:
			selected += 1
			labels[selected-1].add_theme_color_override("default_color", Color.WHITE)
			labels[selected].add_theme_color_override("default_color", Color.LIME)
	if event.is_action_pressed("up"):
		if selected - 1 >= 0:
			selected -= 1
			labels[selected+1].add_theme_color_override("default_color", Color.WHITE)
			labels[selected].add_theme_color_override("default_color", Color.LIME)
	if event.is_action_pressed("attack"):
		execute_option(options[selected])

func execute_option(option: String) -> void:
	if option == "trigger_pause":
		print("Triggering pause")
	elif option == "level_up":
		print("Adding level")

func move_open() -> void:
	is_open = true
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", pos_open[1], 0.8)
	tween.tween_property(self, "position:y", pos_open[1]-10, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", pos_open[1], 0.2).set_ease(Tween.EASE_IN)

func move_close() -> void:
	is_open = false
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", pos_hidden[1], 1)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
