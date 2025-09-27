extends Node3D

@export var object_name: String = "default_object" # 对象名称，用于任务系统识别
@export var interaction_prompt: String = "按 E 键交互" # 交互提示文本
@export var trigger_task_id: String = ""  # 触发的任务ID
@export var trigger_task_objective: String = ""  # 触发的任务目标
@export var complete_task_id: String = ""  # 完成的任务ID
@export var complete_task_objective: String = ""  # 完成的任务目标
@export var task_description: String = ""  # 任务描述，用于触发新任务
@export var has_choices: bool = false  # 是否有选择选项
@export var choice_prompt: String = "你面临一个选择..." # 选择提示文本
@export var choice_options: Array[String] = []  # 选择选项数组
@export var choice_mask_impacts: Array[int] = []  # 每个选项对应的面具完整性影响
@export var choice_descriptions: Array[String] = []  # 每个选项的描述
@export var inner_monologue: String = ""  # 交互时的内心独白
@export var mask_impact_on_interact: int = 0  # 交互时面具完整性影响

var is_player_nearby: bool = false
var interaction_ui: Label = null
var interaction_area: Area3D = null
var player_controller: Node = null

func _ready():
	# 获取PlayerController
	player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		# 如果在父节点中找不到，尝试从根节点获取（向后兼容）
		player_controller = get_node_or_null("/root/PlayerController")
	
	# 创建交互区域（如果不存在）
	if not has_node("InteractionArea"):
		interaction_area = Area3D.new()
		interaction_area.name = "InteractionArea"
		add_child(interaction_area)
		
		# 添加碰撞形状
		var collision_shape = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 2.0  # 交互范围
		collision_shape.shape = shape
		interaction_area.add_child(collision_shape)
	else:
		interaction_area = get_node("InteractionArea")
	
	# 连接交互区域信号
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)
	
	# 创建交互提示UI
	interaction_ui = Label.new()
	interaction_ui.text = interaction_prompt
	interaction_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_ui.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_ui.set("theme_override_font_sizes/font_size", 16)
	interaction_ui.set("theme_override_colors/font_color", Color.WHITE)
	interaction_ui.visible = false
	
	# 将UI添加到CanvasLayer
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	canvas_layer.add_child(interaction_ui)

func _process(_delta):
	# 检查玩家是否在附近并按下交互键
	if is_player_nearby and Input.is_action_just_pressed("interact"):
		# 检查玩家状态是否允许交互
		if player_controller and player_controller.current_state != player_controller.PlayerState.NORMAL:
			print("玩家当前状态不允许交互")
			return
		interact()

func interact():
	print("玩家与对象交互: ", object_name)
	
	# 触发内心独白
	if not inner_monologue.is_empty():
		_trigger_inner_monologue()
	
	# 处理面具完整性影响
	if mask_impact_on_interact != 0:
		_apply_mask_impact(mask_impact_on_interact)
	
	# 如果有选择选项，显示选择对话框
	if has_choices and choice_options.size() > 0:
		_show_choice_dialog()
	else:
		# 处理任务相关逻辑
		_handle_task_interaction()
	
	# 这里可以添加特定的交互逻辑
	# 例如：播放动画、显示对话框等

func _handle_task_interaction():
	# 处理任务交互逻辑
	var task_manager = get_node_or_null("/root/TaskManager")
	if not task_manager:
		# 尝试在场景中查找TaskManager
		task_manager = get_tree().get_first_node_in_group("TaskManager")
	
	if task_manager:
		# 触发新任务
		if not trigger_task_id.is_empty() and not task_description.is_empty():
			# 使用简化版的add_task函数，只需要ID、标题和描述
			task_manager.add_task(trigger_task_id, object_name, task_description)
			print("触发新任务: ", trigger_task_id)
		
		# 触发任务目标
		if not trigger_task_id.is_empty() and not trigger_task_objective.is_empty():
			# 简化版中，任务目标直接通过名称匹配完成
			task_manager.complete_task_by_object(object_name)
			print("触发任务目标: ", trigger_task_objective)
		
		# 完成任务目标
		if not complete_task_id.is_empty() and not complete_task_objective.is_empty():
			# 简化版中，任务目标直接通过名称匹配完成
			task_manager.complete_task_by_object(object_name)
			print("完成任务目标: ", complete_task_objective)
		
		# 完成任务
		if not complete_task_id.is_empty() and complete_task_objective.is_empty():
			# 使用简化版的complete_task_by_object函数，通过物体名称完成任务
			task_manager.complete_task_by_object(object_name)
			print("完成任务: ", complete_task_id)
	else:
		print("错误: 未找到TaskManager节点")

# 触发内心独白
func _trigger_inner_monologue():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("show_inner_monologue"):
		ui_manager.show_inner_monologue(inner_monologue)
		print("触发内心独白: ", inner_monologue)

# 应用面具完整性影响
func _apply_mask_impact(impact: int):
	var task_manager = get_node_or_null("/root/TaskManager")
	if task_manager and task_manager.has_method("modify_mask_integrity"):
		task_manager.modify_mask_integrity(impact)
		print("应用面具完整性影响: ", impact)

# 显示选择对话框
func _show_choice_dialog():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("show_choice_dialog"):
		# 构建选择数据
		var choice_data = {
			"prompt": choice_prompt,
			"options": choice_options,
			"descriptions": choice_descriptions,
			"mask_impacts": choice_mask_impacts,
			"object_name": object_name,
			"callback": Callable(self, "_on_choice_made")
		}
		ui_manager.show_choice_dialog(choice_data)
		print("显示选择对话框: ", choice_prompt)

# 选择结果回调
func _on_choice_made(choice_index: int):
	print("玩家选择了选项: ", choice_index)
	
	# 应用选择的面具完整性影响
	if choice_index >= 0 and choice_index < choice_mask_impacts.size():
		var impact = choice_mask_impacts[choice_index]
		_apply_mask_impact(impact)
		
		# 触发选择的内心独白（如果有）
		if choice_index < choice_descriptions.size() and not choice_descriptions[choice_index].is_empty():
			inner_monologue = choice_descriptions[choice_index]
			_trigger_inner_monologue()
	
	# 处理任务逻辑
	_handle_task_interaction()

# 玩家状态变化处理函数
func _on_player_state_changed(old_state: int, new_state: int):
	print("InteractableObject检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	# 根据玩家状态更新UI可见性
	if is_player_nearby:
		interaction_ui.visible = (new_state == 0)  # 0 = NORMAL状态

# 当玩家进入交互范围时
func _on_interaction_area_body_entered(body):
	if body.is_in_group("Player"):
		is_player_nearby = true
		# 只有在玩家状态为NORMAL时才显示交互提示
		if player_controller and player_controller.current_state == player_controller.PlayerState.NORMAL:
			interaction_ui.visible = true

# 当玩家离开交互范围时
func _on_interaction_area_body_exited(body):
	if body.is_in_group("Player"):
		is_player_nearby = false
		interaction_ui.visible = false
