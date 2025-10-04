extends Area3D

## 测试黑暗事件按钮
## 用于测试黑暗事件功能
## 作者：AI Assistant
## 日期：2025-10-04

var can_trigger: bool = true
var is_in_range: bool = false
var player_in_area: Node3D = null

func _ready():
	print("[TestDarknessButton] 测试按钮已准备好，按E触发黑暗事件")

func _process(_delta: float):
	# 检测交互输入
	if can_trigger and is_in_range and Input.is_action_just_pressed("interact"):
		_trigger_darkness()

## 玩家进入范围
func _on_body_entered(body: Node3D):
	if body.is_in_group("Player"):
		is_in_range = true
		player_in_area = body
		print("[TestDarknessButton] 玩家进入范围")
		if TaskHintUI:
			TaskHintUI.show_hint("按 [E] 测试黑暗事件", 0.0)

## 玩家离开范围
func _on_body_exited(body: Node3D):
	if body.is_in_group("Player"):
		is_in_range = false
		player_in_area = null
		print("[TestDarknessButton] 玩家离开范围")
		if TaskHintUI:
			TaskHintUI.hide_hint()

## 触发黑暗事件
func _trigger_darkness():
	if not can_trigger:
		return

	can_trigger = false
	print("[TestDarknessButton] ===== 测试黑暗事件触发！ =====")

	# 隐藏提示
	if TaskHintUI:
		TaskHintUI.hide_hint()

	# 获取黑暗管理器
	var darkness_mgr = get_node_or_null("/root/DarknessEventManager")
	if darkness_mgr:
		# 获取陌生人节点
		var stranger = get_node_or_null("../StrangerNPC")

		# 触发黑暗事件
		darkness_mgr.trigger_darkness(stranger, Vector3(1.5, 0, -2.5))
	else:
		print("[TestDarknessButton] 警告：DarknessEventManager未找到！")

	# 短暂延迟后重新启用
	await get_tree().create_timer(1.0).timeout
	can_trigger = true
	print("[TestDarknessButton] 测试按钮已重新启用")
