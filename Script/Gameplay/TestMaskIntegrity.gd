extends Node3D

# 测试面具完整度系统的脚本

func _ready():
	print("=== 面具完整度系统测试开始 ===")
	
	# 获取必要的管理器
	var task_manager = get_node_or_null("/root/TaskManager")
	var ui_manager = get_node_or_null("/root/UIManager")
	
	if not task_manager:
		print("错误: 无法找到TaskManager")
		return
	
	if not ui_manager:
		print("错误: 无法找到UIManager")
		return
	
	# 测试面具完整度系统
	_test_mask_integrity_system(task_manager, ui_manager)
	
	# 测试任务系统
	_test_task_system(task_manager)
	
	print("=== 面具完整度系统测试完成 ===")

func _test_mask_integrity_system(task_manager, ui_manager):
	print("\n--- 测试面具完整度系统 ---")
	
	# 测试初始值
	var initial_integrity = task_manager.get_mask_integrity()
	print("初始面具完整度: ", initial_integrity)
	
	# 测试修改面具完整度
	print("增加10点面具完整度...")
	task_manager.modify_mask_integrity(10)
	
	print("减少20点面具完整度...")
	task_manager.modify_mask_integrity(-20)
	
	# 测试获取百分比
	var percentage = task_manager.get_mask_integrity_percentage()
	print("当前面具完整度百分比: ", percentage, "%")
	
	# 测试获取等级
	var level = task_manager.get_mask_integrity_level()
	print("当前面具完整度等级: ", level)

func _test_task_system(task_manager):
	print("\n--- 测试任务系统 ---")
	
	# 添加测试任务
	print("添加测试任务...")
	task_manager.add_task("test_task_1", "测试任务", "这是一个测试任务", 0, [], "你感觉这个任务很重要...", {"location": "test_scene"})
	
	# 获取当前任务
	var active_tasks = task_manager.get_active_tasks()
	print("当前活跃任务数量: ", active_tasks.size())
	
	for task in active_tasks:
		print("任务ID: ", task.id, " 标题: ", task.title)
	
	# 测试完成任务
	print("完成测试任务...")
	task_manager.complete_task("test_task_1")
	
	# 检查任务状态
	var completed_tasks = task_manager.get_completed_tasks()
	print("已完成任务数量: ", completed_tasks.size())

func _input(event):
	# 测试键盘快捷键
	if event.is_action_pressed("ctrl") and event.is_action_pressed("t"):
		print("\n=== 手动测试触发 ===")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			print("减少5点面具完整度...")
			task_manager.modify_mask_integrity(-5)
			
	if event.is_action_pressed("ctrl") and event.is_action_pressed("r"):
		print("\n=== 重置面具完整度 ===")
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			print("重置面具完整度到50...")
			task_manager.mask_integrity.current_value = 50
			task_manager.emit_signal("mask_integrity_changed", task_manager.mask_integrity.current_value - 5, task_manager.mask_integrity.current_value)