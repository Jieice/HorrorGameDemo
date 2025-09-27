extends Node

# 测试清理后的系统功能
# 这个脚本用于验证所有组件是否能正常工作

func _ready():
	print("=== 开始系统功能测试 ===")
	
	# 测试自动加载节点
	test_autoload_nodes()
	
	# 测试PlayerController
	test_player_controller()
	
	# 测试对话系统
	test_dialogue_system()
	
	# 测试任务系统
	test_task_system()
	
	print("=== 系统功能测试完成 ===")

func test_autoload_nodes():
	print("\n--- 测试自动加载节点 ---")
	
	# 首先尝试从父节点获取PlayerController
	var player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		# 如果父节点中没有，尝试从根节点获取（向后兼容）
		player_controller = get_node_or_null("/root/PlayerController")
	print("PlayerController: ", player_controller != null)
	
	var dialogue_box = get_node_or_null("/root/DialogueBox")
	print("DialogueBox: ", dialogue_box != null)
	
	var pause_menu = get_node_or_null("/root/PauseMenu")
	print("PauseMenu: ", pause_menu != null)
	
	var task_manager = get_node_or_null("/root/TaskManager")
	print("TaskManager: ", task_manager != null)
	
	var ui_manager = get_node_or_null("/root/UIManager")
	print("UIManager: ", ui_manager != null)

func test_player_controller():
	print("\n--- 测试PlayerController ---")
	
	# 首先尝试从父节点获取PlayerController
	var player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		# 如果父节点中没有，尝试从根节点获取（向后兼容）
		player_controller = get_node_or_null("/root/PlayerController")
	if not player_controller:
		print("错误: PlayerController未找到")
		return
	
	print("PlayerController当前状态: ", player_controller.get_current_state())
	print("PlayerController状态名称: ", player_controller._get_state_name(player_controller.get_current_state()))
	
	# 测试状态变化信号
	if player_controller.has_signal("state_changed"):
		print("PlayerController具有state_changed信号")
	else:
		print("警告: PlayerController缺少state_changed信号")

func test_dialogue_system():
	print("\n--- 测试对话系统 ---")
	
	var dialogue_box = get_node_or_null("/root/DialogueBox")
	if not dialogue_box:
		print("错误: DialogueBox未找到")
		return
	
	print("DialogueBox可见性: ", dialogue_box.visible)
	
	# 检查对话框的关键方法
	var methods_to_check = ["start_dialogue", "close_dialogue", "show_choices"]
	for method in methods_to_check:
		if dialogue_box.has_method(method):
			print("DialogueBox具有方法: ", method)
		else:
			print("警告: DialogueBox缺少方法: ", method)

func test_task_system():
	print("\n--- 测试任务系统 ---")
	
	var task_manager = get_node_or_null("/root/TaskManager")
	if not task_manager:
		print("错误: TaskManager未找到")
		return
	
	var ui_manager = get_node_or_null("/root/UIManager")
	if not ui_manager:
		print("错误: UIManager未找到")
		return
	
	print("TaskManager和UIManager都已找到")
	
	# 检查任务管理器的关键方法
	var task_methods = ["activate_task", "complete_task_by_object"]
	for method in task_methods:
		if task_manager.has_method(method):
			print("TaskManager具有方法: ", method)
		else:
			print("警告: TaskManager缺少方法: ", method)
	
	# 检查UI管理器的关键方法
	var ui_methods = ["add_task", "show_task_hint", "hide_task_hint"]
	for method in ui_methods:
		if ui_manager.has_method(method):
			print("UIManager具有方法: ", method)
		else:
			print("警告: UIManager缺少方法: ", method)