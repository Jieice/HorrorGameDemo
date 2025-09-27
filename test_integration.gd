# 简单的集成测试脚本
# 将此脚本附加到一个节点上进行测试

extends Node

func _ready():
	print("=== 集成测试开始 ===")
	
	# 测试TaskManager
	var task_manager = get_node_or_null("/root/TaskManager")
	if task_manager:
		print("✓ TaskManager 找到")
		print("  当前面具完整度: ", task_manager.get_mask_integrity())
		print("  当前等级: ", task_manager.get_mask_integrity_level())
	else:
		print("✗ TaskManager 未找到")
	
	# 测试UIManager
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		print("✓ UIManager 找到")
	else:
		print("✗ UIManager 未找到")
	
	print("=== 集成测试完成 ===")

func _input(event):
	if event.is_action_pressed("space"):
		print("空格键按下 - 测试面具完整度变化")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			task_manager.modify_mask_integrity(-5)
			print("面具完整度减少5点")
	
	if event.is_action_pressed("ctrl") and event.is_action_pressed("t"):
		print("Ctrl+T 按下 - 添加测试任务")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			task_manager.add_task("manual_test", "手动测试任务", "这是一个手动添加的测试任务", "按空格键减少面具完整度", -3, [], "你感觉这个任务会让你更加脆弱...")
			print("测试任务已添加")