extends GPUParticles3D

# 空气中的尘埃粒子 - 跟随玩家移动

var player: CharacterBody3D = null

func _ready():
	# 查找玩家
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("[DustParticles] 尘埃粒子已启动，跟随玩家")
	
	# 粒子设置
	emitting = true

func _process(_delta):
	# 跟随玩家位置
	if player and is_instance_valid(player):
		global_position = player.global_position
