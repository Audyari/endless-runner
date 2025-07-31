extends Area2D

@export var move_speed := 150.0  # Kecepatan geser ke kiri (bisa diatur dari editor)
@export var reset_position_x := 800.0  # Posisi muncul ulang dari kanan
@export var min_position_x := -50.0  # Batas kiri untuk reset

func _process(delta: float) -> void:
	# Geser batu ke kiri
	position.x -= move_speed * delta
	
	# Kalau sudah keluar layar kiri, reset ke kanan
	if position.x < min_position_x:
		position.x = reset_position_x

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("PLAYER KENA BATU! Nama body:", body.name)
		# Di sini kamu bisa tambahkan logika mati / ulangi game
