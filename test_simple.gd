# 简化版测试脚本 - 只测试核心功能
extends Node

func _ready():
	print("=== 简化测试开始 ===")
	
	# 获取TaskManager引用
	var task_manager = get_node_or_null("/root/TaskManager")
	
	if task_manager:
		print("✓ TaskManager 找到")
		
		# 测试面具完整度系统
		var initial_integrity = task_manager.get_mask_integrity()
		print("初始面具完整度: ", initial_integrity)
		
		# 测试修改面具完整度
		task_manager.modify_mask_integrity(-10)
		var new_integrity = task_manager.get_mask_integrity()
		print("修改后面具完整度: ", new_integrity)
		
		# 测试百分比计算
		var percentage = task_manager.get_mask_integrity_percentage()
		print("面具完整度百分比: ", percentage, "%")
		
		# 测试等级系统
		var level = task_manager.get_mask_integrity_level()
		print("面具完整度等级: ", level)
		
		# 测试信号连接
		if task_manager.has_signal("mask_integrity_changed"):
			print("✓ mask_integrity_changed 信号存在")
		else:
			print("✗ mask_integrity_changed 信号不存在")
			
	else:
		print("✗ TaskManager 未找到")
		print("可用的自动加载节点:")
		for node in get_tree().get_root().get_children():
			print("  - ", node.name)
	
	print("=== 简化测试完成 ===")

func _input(event):
	if event.is_action_pressed("space"):
		print("空格键按下 - 减少面具完整度")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			task_manager.modify_mask_integrity(-5)
			print("当前完整度: ", task_manager.get_mask_integrity())
			print("当前百分比: ", task_manager.get_mask_integrity_percentage(), "%")
	
	if event.is_action_pressed("r"):
		print("R键按下 - 重置面具完整度")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			task_manager.reset_mask_integrity()
			print("面具完整度已重置为: ", task_manager.get_mask_integrity())