extends StaticBody2D

@onready var sprite_a = $Sprite2D_A
@onready var sprite_b = $Sprite2D_B

@export var scroll_speed: float = 200.0

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	# Geser kedua sprite ke kiri
	sprite_a.position.x -= scroll_speed * delta
	sprite_b.position.x -= scroll_speed * delta

	# Jika sprite_a keluar dari layar kiri, pindah ke kanan sprite_b
	var texture_width = sprite_a.texture.get_width()
	if sprite_a.position.x < -texture_width:
		sprite_a.position.x = sprite_b.position.x + texture_width
	
	if sprite_b.position.x < -texture_width:
		sprite_b.position.x = sprite_a.position.x + texture_width
