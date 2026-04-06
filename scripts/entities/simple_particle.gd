# SimpleParticle.gd — Spawns a burst of particles for effects
extends Node2D

@export var color: Color = Color(1,1,1)
@export var amount: int = 16
@export var lifetime: float = 0.5
@export var speed: float = 120.0

var _particles: Array = []
var _time: float = 0.0

func _ready() -> void:
	for i in range(amount):
		var angle = randf() * TAU
		var vel = Vector2(cos(angle), sin(angle)) * (speed * randf_range(0.7, 1.2))
		_particles.append({"pos": Vector2.ZERO, "vel": vel})
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.92
	queue_redraw()
	if _time > lifetime:
		queue_free()

func _draw() -> void:
	for p in _particles:
		draw_circle(p["pos"], 2.5, color.lightened(0.2))
