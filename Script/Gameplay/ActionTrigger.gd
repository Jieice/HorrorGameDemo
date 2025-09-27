extends Node

# 动作类型枚举
enum ActionType {
	SEARCH_TRASHCAN = 0,  # 搜索垃圾桶
	OPEN_DOOR = 1,        # 开门
	PICKUP_ITEM = 2,      # 拾取物品
	TALK_TO_NPC = 3,      # 与NPC对话
	USE_OBJECT = 4        # 使用物体
}

@export var action_type: ActionType = ActionType.SEARCH_TRASHCAN
@export var custom_action_name: String = "custom_action"  # 自定义动作名称
@export var action_prompt: String = "按 E 键执行动作"  # 动作提示文本
@export var trigger_task_id: String = ""  # 触发的任务ID
@export var trigger_task_objective: String = ""  # 触发的任务目标
@export var complete_task_id: String = ""  # 完成的任务ID
@export var complete_task_objective: String = ""  # 完成的任务目标
@export var task_description: String = ""  # 任务描述，用于触发新任务

# 优化：统一动作提示变量命名和结构，增加注释
var is_player_nearby: bool = false
var action_ui: Label = null
var action_area: Area3D = null
var player_controller: Node = null
var is_action_executed: bool = false

func _ready():
	# 获取PlayerController
	player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		player_controller = get_node_or_null("/root/PlayerController")
	# 创建动作区域（如果不存在）
	if not has_node("ActionArea"):
		action_area = Area3D.new()
		action_area.name = "ActionArea"
		add_child(action_area)
		# 添加碰撞形状
		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(2.0, 2.0, 2.0)  # 交互范围
		collision_shape.shape = shape
		action_area.add_child(collision_shape)
	else:
		action_area = get_node("ActionArea")
	# 连接动作区域信号
	action_area.body_entered.connect(_on_action_area_body_entered)
	action_area.body_exited.connect(_on_action_area_body_exited)
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)
	# 创建动作提示UI
	action_ui = Label.new()
	action_ui.text = get_prompt_text()
	action_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_ui.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_ui.set("theme_override_font_sizes/font_size", 16)
	action_ui.set("theme_override_colors/font_color", Color.WHITE)
	action_ui.visible = false
	# 将UI添加到CanvasLayer
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	canvas_layer.add_child(action_ui)

func _process(delta):
	# 检查玩家是否在附近并按下动作键
	if is_player_nearby and Input.is_action_just_pressed("interact"):  # 使用E键交互
		# 检查玩家状态是否允许交互
		if player_controller and player_controller.current_state != player_controller.PlayerState.NORMAL:
			print("玩家当前状态不允许交互")
			return
		execute_action()

# 执行动作
func execute_action():
	# 防止重复执行
	if is_action_executed:
		return
	
	is_action_executed = true
	var action_name = get_action_name()
	print("执行动作: ", action_name, " (类型: ", action_type, ")")
	
	# 处理任务相关逻辑
	_handle_task_interaction()
	
	# 这里可以添加特定的动作逻辑
	# 例如：播放动画、显示效果等
	match action_type:
		ActionType.SEARCH_TRASHCAN:
			print("搜索垃圾桶...")
			# 添加搜索垃圾桶的逻辑
		ActionType.OPEN_DOOR:
			print("开门...")
			# 添加开门的逻辑
		ActionType.PICKUP_ITEM:
			print("拾取物品...")
			# 添加拾取物品的逻辑
		ActionType.USE_OBJECT:
			print("使用物体...")
			# 添加使用物体的逻辑
		ActionType.TALK_TO_NPC:
			print("与NPC对话...")
			# 添加与NPC对话的逻辑

# 根据动作类型返回动作名称
func get_action_name() -> String:
	match action_type:
		ActionType.SEARCH_TRASHCAN:
			return "search_trashcan"
		ActionType.OPEN_DOOR:
			return "open_door"
		ActionType.PICKUP_ITEM:
			return "pickup_item"
		ActionType.TALK_TO_NPC:
			return "talk_to_npc"
		ActionType.USE_OBJECT:
			return "use_object"
		_:
			return "unknown_action"

# 根据动作类型返回提示文本
func get_prompt_text() -> String:
	if action_prompt != "":
		return action_prompt
	
	match action_type:
		ActionType.SEARCH_TRASHCAN:
			return "按 E 搜索垃圾桶"
		ActionType.OPEN_DOOR:
			return "按 E 开门"
		ActionType.PICKUP_ITEM:
			return "按 E 拾取物品"
		ActionType.TALK_TO_NPC:
			return "按 E 对话"
		ActionType.USE_OBJECT:
			return "按 E 使用物体"
		_:
			return "按 E 互动"

# 当玩家进入动作范围时
func _on_action_area_body_entered(body):
	if body.is_in_group("Player"):
		is_player_nearby = true
		if player_controller and player_controller.current_state == player_controller.PlayerState.NORMAL:
			action_ui.visible = true

# 当玩家离开动作范围时
func _on_action_area_body_exited(body):
	if body.is_in_group("Player"):
		is_player_nearby = false
		action_ui.visible = false

# 处理任务交互逻辑
func _handle_task_interaction():
	# 获取UI管理器
	var ui_manager = get_node_or_null("/root/UIManager")
	if not ui_manager:
		print("错误: 无法找到UIManager节点")
		return
	
	# 如果有触发任务ID，添加新任务
	if not trigger_task_id.is_empty() and not task_description.is_empty():
		# 使用UIManager的add_task函数，传递ID、标题、描述和是否为主任务
		ui_manager.add_task(trigger_task_id, get_action_name(), task_description, true)
		print("触发任务: ", trigger_task_id)
	
	# 如果有完成任务ID，完成任务
	if not complete_task_id.is_empty():
		# 获取任务管理器
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			# 使用简化版的complete_task_by_object函数，通过物体名称完成任务
			task_manager.complete_task_by_object(get_action_name())
			print("完成任务: ", complete_task_id)
	
	# 如果有触发任务目标ID，添加任务目标
	if not trigger_task_id.is_empty() and not trigger_task_objective.is_empty():
		# 获取任务管理器
		var task_manager = get_node_or_null("/root/TaskManager")
		if task_manager:
			# 简化版中，任务目标直接通过名称匹配完成
			# 这里我们直接完成任务，因为与物体交互本身就是目标
			task_manager.complete_task_by_object(get_action_name())
			print("添加任务目标: ", trigger_task_objective)

# 玩家状态变化处理函数
func _on_player_state_changed(old_state: int, new_state: int):
	print("ActionTrigger检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	# 根据玩家状态更新UI可见性
	if is_player_nearby:
		action_ui.visible = (new_state == 0)  # 0 = NORMAL状态