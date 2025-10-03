extends Node

# 测试脚本：验证PlayerController自动加载修复

func _ready():
	print("=== 测试PlayerController自动加载修复 ===")
	
	# 测试1: 检查自动加载的PlayerController是否存在
	var player_controller = get_node_or_null("/root/PlayerController")
	if player_controller:
		print("✓ 自动加载的PlayerController存在: ", player_controller)
	else:
		print("✗ 错误: 自动加载的PlayerController不存在")
		return
	
	# 测试2: 检查是否只有一个PlayerController实例
	var all_players = get_tree().get_nodes_in_group("PlayerController")
	if all_players.size() == 1:
		print("✓ 只有一个PlayerController实例: ", all_players.size())
	else:
		print("✗ 错误: 发现多个PlayerController实例: ", all_players.size())
		for i in all_players.size():
			print("  实例", i, ": ", all_players[i])
	
	# 测试3: 检查world.gd是否正确使用自动加载的实例
	var world = get_node_or_null("/root/World")
	if world and world.has_method("_initialize_player_controller"):
		print("✓ World节点存在并包含初始化方法")
	else:
		print("✗ 错误: World节点或初始化方法不存在")
	
	print("=== 测试完成 ===")
	
	# 5秒后退出
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()