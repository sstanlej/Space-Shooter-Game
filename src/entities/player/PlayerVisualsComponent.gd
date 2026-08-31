class_name PlayerVisualsComponent extends Node

@export_group("Target Nodes")
@export var target_sprite: Sprite2D
@export var shield_sprite: Sprite2D

@export_group("Shield Textures")
@export var shield_texture_full: Texture2D
@export var shield_texture_cracked: Texture2D

var player: Player
var health_component: PlayerHealthComponent

var flash_tween: Tween
var blink_tween: Tween
var shield_tween: Tween

func _ready() -> void:
	player = get_parent() as Player
	if not player:
		return

	# Szukamy sprite'ów jeśli nie zostały przypisane w Inspektorze
	if not target_sprite:
		target_sprite = player.get_node_or_null("Sprite2D")
	if not shield_sprite:
		shield_sprite = player.get_node_or_null("ShieldSprite")

	# Podpinamy się pod sygnały zdrowia
	health_component = player.get_node_or_null("HealthComponent") as PlayerHealthComponent
	if health_component:
		health_component.damage_taken.connect(_on_damage_taken)
		health_component.invincibility_started.connect(_on_invincibility_started)
		health_component.invincibility_ended.connect(_on_invincibility_ended)
		health_component.shield_hit.connect(_on_shield_hit)
		health_component.shield_broken.connect(_on_shield_broken)
		health_component.died.connect(cleanup_all_tweens)
		
		# Wstępna synchronizacja tarczy
		update_shield_display(health_component.shield_charges)

func _exit_tree() -> void:
	cleanup_all_tweens()

# --- HIT FLASH (BŁYSK PO TRAFIENIU) ---

func _on_damage_taken(_amount: int) -> void:
	if not target_sprite or (player and player.is_spectator):
		return

	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	if target_sprite.material and target_sprite.material is ShaderMaterial:
		target_sprite.material.set_shader_parameter("active", true)
		flash_tween = create_tween()
		flash_tween.tween_interval(0.08)
		flash_tween.tween_callback(func():
			if target_sprite and target_sprite.material:
				target_sprite.material.set_shader_parameter("active", false)
		)
	else:
		var original_alpha = target_sprite.modulate.a
		target_sprite.modulate = Color(4.0, 4.0, 4.0, original_alpha)
		flash_tween = create_tween()
		flash_tween.tween_property(target_sprite, "modulate:r", 1.0, 0.08)
		flash_tween.parallel().tween_property(target_sprite, "modulate:g", 1.0, 0.08)
		flash_tween.parallel().tween_property(target_sprite, "modulate:b", 1.0, 0.08)

# --- I-FRAMES BLINK (MIGANIE PRZEZROCZYSTOŚCIĄ) ---

func _on_invincibility_started(_duration: float = 0.0) -> void:
	if not target_sprite or (player and player.is_spectator):
		return

	if blink_tween and blink_tween.is_running():
		blink_tween.kill()

	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(target_sprite, "modulate:a", 0.2, 0.08)
	blink_tween.tween_property(target_sprite, "modulate:a", 1.0, 0.08)

func _on_invincibility_ended() -> void:
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if target_sprite and player and not player.is_spectator:
		target_sprite.modulate.a = 1.0

# --- TARCZA: PREZENTACJA I ANIMACJE ---

func update_shield_display(charges: int) -> void:
	if not shield_sprite:
		return

	if charges <= 0:
		shield_sprite.hide()
		return

	shield_sprite.show()
	if charges == 1 and shield_texture_cracked:
		shield_sprite.texture = shield_texture_cracked
	elif shield_texture_full:
		shield_sprite.texture = shield_texture_full

func _on_shield_hit(remaining_charges: int) -> void:
	update_shield_display(remaining_charges)
	trigger_shield_impact_effect()

func _on_shield_broken() -> void:
	update_shield_display(0)
	trigger_shield_broken_effect()

func trigger_shield_impact_effect() -> void:
	if not shield_sprite or not shield_sprite.visible:
		return

	if shield_tween and shield_tween.is_running():
		shield_tween.kill()

	shield_tween = create_tween()
	shield_sprite.scale = Vector2(1.3, 1.3)
	shield_sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)

	shield_tween.set_parallel(true)
	shield_tween.tween_property(shield_sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shield_tween.tween_property(shield_sprite, "modulate", Color.WHITE, 0.2)

func trigger_shield_broken_effect() -> void:
	if not shield_sprite:
		return

	shield_sprite.show()
	var break_tween = create_tween().set_parallel(true)
	break_tween.tween_property(shield_sprite, "scale", Vector2(1.5, 1.5), 0.15)
	break_tween.tween_property(shield_sprite, "modulate:a", 0.0, 0.15)
	break_tween.chain().tween_callback(func():
		shield_sprite.hide()
		shield_sprite.scale = Vector2.ONE
		shield_sprite.modulate = Color.WHITE
	)

func cleanup_all_tweens() -> void:
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if shield_tween and shield_tween.is_running():
		shield_tween.kill()