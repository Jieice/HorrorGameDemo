extends Node3D

signal dialogue_closed  # 对话关闭信号

@export var npc_name: String = "NPC的名字"  # NPC 名称
@export var dialogue_lines: Array = []  # 对话内容，支持多行文本
var can_interact: bool = true  # 是否可以交互，防止重复触发
var is_interacting: bool = false  # 添加缺失的变量
var dialogue_box = null  # 添加缺失的变量

# 选项文本
@export var choice_texts: Array = [
	"友好询问",
	"直接追问",
	"礼貌道别"
]

# 每个选项对应的对话内容
@export var choice_dialogues: Array = [
	["这很有趣。"],
	["我理解你的想法。"],
	["这是个不错的选择。"]
]

# 任务相关导出变量
@export var trigger_task_id: String = ""  # 触发的任务ID
@export var trigger_task_objective: String = ""  # 触发的任务目标
@export var complete_task_id: String = ""  # 完成的任务ID
@export var complete_task_objective: String = ""  # 完成的任务目标
@export var task_description: String = ""  # 任务描述，用于触发新任务

func _ready() -> void:
	self.add_to_group("interactable")
	# 连接NPC的dialogue_closed信号到player的_on_global_dialogue_closed函数
	var player = get_tree().get_first_node_in_group("Player")  # 修正组名大小写
	if player:
		self.connect("dialogue_closed", Callable(player, "_on_global_dialogue_closed"))
	
	# 获取PlayerController并连接其信号
	var player_controller = _find_player_controller()
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)

# 辅助函数：查找PlayerController
func _find_player_controller() -> Node:
	# 方法1：通过组查找PlayerController
	var player_controllers = get_tree().get_nodes_in_group("PlayerController")
	if player_controllers.size() > 0:
		return player_controllers[0]
	
	# 方法2：如果组查找失败，尝试从World节点获取子节点
	var world_node = get_tree().get_first_node_in_group("World")
	if world_node:
		# 遍历World节点的所有子节点，查找PlayerController
		for child in world_node.get_children():
			if child.is_in_group("PlayerController"):
				return child
	
	# 方法3：如果仍然找不到，尝试从当前场景的根节点查找
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		# 遍历当前场景的所有子节点，查找PlayerController
		for child in current_scene.get_children():
			if child.is_in_group("PlayerController"):
				return child
	
	return null

func interact() -> void:
	if not can_interact:
		return
	
	print("=== NPC interact方法被调用 ===")
	print("NPC名称: ", npc_name)
	print("对话行数: ", dialogue_lines.size())
	print("对话内容: ", dialogue_lines)
	
	# 统一使用PlayerController处理对话
	var player_controller = _find_player_controller()
	if not player_controller:
		print("错误：找不到PlayerController")
		return
	
	print("找到PlayerController: ", player_controller != null)
	
	# 如果已经在对话中，不重复触发
	if player_controller.get_current_state() == player_controller.PlayerState.DIALOGUE:
		print("玩家已经在对话中，不重复触发")
		return
	
	# 设置为不可交互，防止重复触发
	can_interact = false
	
	# 调用PlayerController的start_dialogue方法
	print("调用PlayerController.start_dialogue，传入NPC: ", self)
	player_controller.start_dialogue(self)

# 显示选择项
func show_choices() -> void:
	print("=== NPC.show_choices被调用 ===")
	print("选择项数量: ", choice_texts.size())
	
	# 获取对话框节点
	var dialogue_box_node = get_tree().get_first_node_in_group("DialogueBox")
	if not dialogue_box_node:
		dialogue_box_node = get_node_or_null("/root/DialogueBox")
	
	if dialogue_box_node and dialogue_box_node.has_method("show_choices"):
		# 确保对话框连接了option_selected信号
		if not dialogue_box_node.is_connected("option_selected", Callable(self, "_on_option_selected")):
			dialogue_box_node.connect("option_selected", Callable(self, "_on_option_selected"))
		
		# 调用对话框的show_choices方法显示选择项
		print("调用对话框的show_choices方法，选择项: ", choice_texts)
		dialogue_box_node.show_choices(choice_texts)
	else:
		print("错误：找不到对话框节点或对话框没有show_choices方法")
		# 如果找不到对话框，结束对话
		var player_controller = _find_player_controller()
		if player_controller and player_controller.has_method("end_dialogue"):
			player_controller.end_dialogue()

# 当对话完成时调用（初始对话结束后显示选择项）
func _on_dialogue_completed() -> void:
	print("NPC _on_dialogue_completed方法被调用，NPC名称: ", npc_name)
	
	# 检查是否有选择项
	if choice_texts.size() > 0:
		print("显示选择项，数量: ", choice_texts.size())
		# 显示选择项
		show_choices()
	else:
		print("没有选择项，结束对话")
		# 没有选择项，结束对话
		var dialogue_box_node = get_node_or_null("/root/DialogueBox")
		if dialogue_box_node:
			if dialogue_box_node.has_method("close_dialogue"):
				dialogue_box_node.close_dialogue()
			else:
				dialogue_box_node.visible = false
		
		# 通知PlayerController结束对话
		var player_controller = _find_player_controller()
		if player_controller and player_controller.has_method("end_dialogue"):
			player_controller.end_dialogue()

# 当对话关闭时调用
func _on_dialogue_closed() -> void:
	print("NPC _on_dialogue_closed方法被调用，NPC名称: ", npc_name)
	
	var dialogue_box_node = get_node_or_null("/root/DialogueBox")
	if dialogue_box_node:
		# 断开所有信号连接，避免多次连接
		if dialogue_box_node.is_connected("dialogue_closed", Callable(self, "_on_dialogue_closed")):
			dialogue_box_node.disconnect("dialogue_closed", Callable(self, "_on_dialogue_closed"))
		if dialogue_box_node.is_connected("option_selected", Callable(self, "_on_option_selected")):
			dialogue_box_node.disconnect("option_selected", Callable(self, "_on_option_selected"))
		if dialogue_box_node.is_connected("dialogue_completed", Callable(self, "_on_dialogue_completed")):
			dialogue_box_node.disconnect("dialogue_completed", Callable(self, "_on_dialogue_completed"))
		
		# 使用dialogue_box的close_dialogue方法关闭对话框并恢复玩家移动
		dialogue_box_node.close_dialogue()
		
		# 处理任务相关逻辑
		_handle_task_interaction()
		
		# 通知PlayerController结束对话
		var player_controller = _find_player_controller()
		if player_controller and player_controller.has_method("end_dialogue"):
			print("通知PlayerController结束对话")
			player_controller.end_dialogue()
		
		# 对话已结束
		print("对话已结束")
		
		# 重置可交互状态
		can_interact = true

# 当玩家做出选择时调用
func _on_option_selected(index: int) -> void:
	print("选项被选择，索引: ", index)
	
	var dialogue_box_node = get_node_or_null("/root/DialogueBox")
	if dialogue_box_node and index >= 0 and index < choice_texts.size() and index < choice_dialogues.size():
		print("启动选择对应的对话，索引: ", index)
		
		# 断开dialogue_completed信号，避免选择后的对话再次显示选择项
		if dialogue_box_node.is_connected("dialogue_completed", Callable(self, "_on_dialogue_completed")):
			dialogue_box_node.disconnect("dialogue_completed", Callable(self, "_on_dialogue_completed"))
		
		# 重新连接dialogue_completed信号，但这次用于选择后的对话结束
		dialogue_box_node.connect("dialogue_completed", Callable(self, "_on_choice_dialogue_completed"))
		
		# 启动选择对应的对话
		dialogue_box_node.start_dialogue(choice_dialogues[index], npc_name)
	else:
		print("错误：无效的选择索引或找不到DialogueBox节点，索引: ", index)

# 当选择后的对话完成时调用
func _on_choice_dialogue_completed() -> void:
	print("NPC _on_choice_dialogue_completed方法被调用，NPC名称: ", npc_name)
	
	var dialogue_box_node = get_node_or_null("/root/DialogueBox")
	if dialogue_box_node:
		# 断开dialogue_completed信号连接
		if dialogue_box_node.is_connected("dialogue_completed", Callable(self, "_on_choice_dialogue_completed")):
			dialogue_box_node.disconnect("dialogue_completed", Callable(self, "_on_choice_dialogue_completed"))
			print("已断开dialogue_completed信号连接")
		
		# 使用dialogue_box的close_dialogue方法关闭对话框并恢复玩家移动
		dialogue_box_node.close_dialogue()
		print("对话框已关闭")
		
		# 发出对话关闭信号，通知玩家对话已结束
		emit_signal("dialogue_closed")
		print("已发出dialogue_closed信号")
		
		# 处理任务相关逻辑
		_handle_task_interaction()
		print("任务交互逻辑已处理")
		
		# 通知PlayerController结束对话
		var player_controller = _find_player_controller()
		if player_controller and player_controller.has_method("end_dialogue"):
			print("通知PlayerController结束对话")
			player_controller.end_dialogue()
	else:
		print("错误：无法找到DialogueBox节点")
	
	# 重置可交互状态
	can_interact = true

# 选择被点击时的回调函数
func _on_choice_selected(index: int) -> void:
	print("选择被点击，索引: ", index)
	
	# 这个函数会在选择按钮被点击时通过回调调用
	# 直接处理选择逻辑，避免递归调用
	var dialogue_box_node = get_node_or_null("/root/DialogueBox")
	if not dialogue_box_node:
		print("警告：无法找到DialogueBox节点")
		return
		
	if dialogue_box_node and index >= 0 and index < choice_texts.size() and index < choice_dialogues.size():
		print("启动选择对应的对话，索引: ", index)
		
		# 断开dialogue_completed信号，避免选择后的对话再次显示选择项
		if dialogue_box_node.is_connected("dialogue_completed", Callable(self, "_on_dialogue_completed")):
			dialogue_box_node.disconnect("dialogue_completed", Callable(self, "_on_dialogue_completed"))
		
		# 重新连接dialogue_completed信号，但这次用于选择后的对话结束
		dialogue_box_node.connect("dialogue_completed", Callable(self, "_on_choice_dialogue_completed"))
		
		# 启动选择对应的对话
		dialogue_box_node.start_dialogue(choice_dialogues[index], npc_name)
	else:
		print("错误：无效的选择索引或找不到DialogueBox节点，索引: ", index)

# 处理任务交互逻辑
func _handle_task_interaction() -> void:
	# 获取任务管理器
	var task_manager = get_node_or_null("/root/TaskManager")
	if not task_manager:
		# 尝试在场景中查找TaskManager
		task_manager = get_tree().get_first_node_in_group("TaskManager")
	
	if task_manager:
		# 如果有触发任务ID，添加新任务
		if not trigger_task_id.is_empty() and not task_description.is_empty():
			# 使用简化版的add_task函数，只需要ID、标题和描述
			task_manager.add_task(trigger_task_id, npc_name, task_description)
			print("触发任务: ", trigger_task_id)
		
		# 如果有完成任务ID，完成任务
		if not complete_task_id.is_empty():
			# 使用简化版的complete_task_by_npc函数，通过NPC名称完成任务
			task_manager.complete_task_by_npc(npc_name)
			print("完成任务: ", complete_task_id)
		
		# 如果有触发任务目标，添加任务目标
		if not trigger_task_id.is_empty() and not trigger_task_objective.is_empty():
			# 简化版中，任务目标直接通过名称匹配完成
			# 这里我们直接完成任务，因为与NPC对话本身就是目标
			task_manager.complete_task_by_npc(npc_name)
			print("添加任务目标: ", trigger_task_objective)
	else:
		print("错误: 未找到TaskManager节点")

# 获取对话行
func get_dialogue_lines() -> Array:
	print("NPC get_dialogue_lines方法被调用，NPC名称: ", npc_name, " 对话行数: ", dialogue_lines.size())
	return dialogue_lines

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state):
	print("NPC检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	
	# 如果玩家状态不是对话状态，重置NPC状态
	if new_state != 1:  # 1 是 DIALOGUE 状态
		is_interacting = false
		var player_controller = _find_player_controller()
		if player_controller and player_controller.is_connected("state_changed", _on_player_state_changed):
			player_controller.disconnect("state_changed", _on_player_state_changed)

	# 根据玩家状态控制NPC行为
	match new_state:
		0: # NORMAL
			# 玩家恢复正常状态，NPC可以交互
			pass
		1: # DIALOGUE
			# 玩家进入对话状态，NPC正在对话中
			pass
		2: # PAUSED
			# 游戏暂停，NPC暂停更新
			pass
		3: # IN_MENU
			# 玩家在菜单中，NPC暂停更新
			pass
		4: # IN_CUTSCENE
			# 玩家在过场动画中，NPC暂停更新
			pass
		_:
			# 未知状态
			pass

func show_choice_dialogue(options: Array, callbacks: Dictionary):
	print("显示选择对话，选项数量: ", options.size())
	
	# 连接PlayerController的状态变化信号
	var player_controller = _find_player_controller()
	if player_controller and not player_controller.is_connected("state_changed", _on_player_state_changed):
		player_controller.connect("state_changed", _on_player_state_changed)
	
	# 获取对话框并显示选择
	dialogue_box = get_node_or_null("/root/DialogueBox")
	if dialogue_box:
		# 连接选择完成信号
		if not dialogue_box.is_connected("option_selected", _on_option_selected):
			dialogue_box.connect("option_selected", _on_option_selected)
		
		# 显示选择项
		dialogue_box.show_choices(options, callbacks)
	else:
		print("错误：无法找到DialogueBox")

func trigger_task(task_id: String):
	print("NPC触发任务: ", task_id)
	var task_manager = get_node_or_null("/root/TaskManager")
	if task_manager:
		task_manager.activate_task(task_id)
	else:
		print("错误：无法找到TaskManager")
