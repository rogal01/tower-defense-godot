# PowerUp.gd — Collectible power-up pickup
extends Area2D

signal collected(power_type: int)

var power_type: int = GameData.PowerType.FIREBALL

func _ready() -> void:
	$Sprite2D.texture = preload("res://icon.svg") # Placeholder, replace with power-up icon
	$Sprite2D.modulate = Color(0.9, 0.7, 0.2, 0.85)
	$AnimationPlayer.play("glow")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		emit_signal("collected", power_type)
		queue_free()
