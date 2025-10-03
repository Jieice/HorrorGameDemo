extends Node3D

@export var player_scene: PackedScene = preload("res://Scene/Player/player.tscn")

func _ready():
	print("SpawnPoint ready!")
	var player = player_scene.instantiate()
	print("Player spawned at: ", self.global_transform.origin)
	player.global_transform = self.global_transform
	get_parent().add_child.call_deferred(player)
