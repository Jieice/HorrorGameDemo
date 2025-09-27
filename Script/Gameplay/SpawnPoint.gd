extends Node3D

@export var player_scene: PackedScene

func _ready() -> void:
	if not Engine.is_editor_hint():
		# 运行时删除编辑器里的辅助Mesh
		if has_node("SpawnMarker"):
			$SpawnMarker.queue_free()
	# 生成玩家
	spawn_player()

func spawn_player() -> void:
	if player_scene == null:
		push_error("SpawnPoint: 没有设置玩家预制体！")
		return

	var player = player_scene.instantiate()
	# 使用延迟添加避免父节点忙碌错误
	get_tree().root.call_deferred("add_child", player)
	# 延迟设置位置和旋转，确保节点已添加到树中
	await get_tree().process_frame
	player.global_position = global_position
	player.global_rotation = global_rotation
