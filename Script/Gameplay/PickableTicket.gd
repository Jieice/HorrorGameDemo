extends Area3D

## 可拾取的票据
## 拾取后触发黑暗事件
## 作者：AI Assistant
## 日期：2025-10-04

@export var ticket_text: String = "目的地被水晕开了..." # 票据描述
@export var stranger_node_path: NodePath # 陌生人节点路径
@export var stranger_new_position: Vector3 = Vector3.ZERO # 陌生人新位置

var can_pickup: bool = true
var is_in_range: bool = false
var player_in_area: Node3D = null

func _ready():
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("[PickableTicket] 票据已准备好，等待玩家拾取...")

func _process(_delta: float):
	# 检测拾取输入
	if can_pickup and is_in_range and Input.is_action_just_pressed("interact"):
		_pickup_ticket()

## 玩家进入范围
func _on_body_entered(body: Node3D):
	if body.is_in_group("Player"):
		is_in_range = true
		player_in_area = body
		print("[PickableTicket] 玩家进入拾取范围")
		
		# 显示提示
		if TaskHintUI:
			TaskHintUI.show_hint("按 [E] 拾取票据", 0.0)

## 玩家离开范围
func _on_body_exited(body: Node3D):
	if body.is_in_group("Player"):
		is_in_range = false
		player_in_area = null
		print("[PickableTicket] 玩家离开拾取范围")
		
		# 隐藏提示
		if TaskHintUI:
			TaskHintUI.hide_hint()

## 拾取票据
func _pickup_ticket():
	if not can_pickup:
		return
	
	can_pickup = false
	print("[PickableTicket] ===== 票据被拾取！触发黑暗事件 =====")
	
	# 隐藏提示
	if TaskHintUI:
		TaskHintUI.hide_hint()
	
	# 显示票据文字（可选）
	if DialogueManager and DialogueManager.has_method("show_text"):
		DialogueManager.show_text(ticket_text)
	
	# 增加心率（拾取瞬间的紧张）
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(10.0)
	
	# 触发黑暗事件
	await get_tree().create_timer(0.5).timeout # 稍微延迟，让玩家读完文字
	
	var darkness_mgr = get_node_or_null("/root/DarknessEventManager")
	if darkness_mgr:
		# 获取陌生人节点
		var stranger = null
		if stranger_node_path != NodePath():
			stranger = get_node_or_null(stranger_node_path)
		
		# 触发黑暗
		darkness_mgr.trigger_darkness(stranger, stranger_new_position)
	else:
		print("[PickableTicket] 警告：DarknessEventManager未找到！")
	
	# 通知环境进度系统
	var env_progress = get_node_or_null("/root/EnvironmentProgressSystem")
	if env_progress:
		env_progress.on_item_investigated()
	
	# 隐藏或删除票据模型
	visible = false
	
	# 可选：完全删除
	# queue_free()

## 重置（用于测试）
func reset():
	can_pickup = true
	visible = true
	print("[PickableTicket] 已重置")
