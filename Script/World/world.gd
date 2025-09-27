extends Node

# 世界场景脚本
# 负责管理游戏世界的整体状态和场景切换

@onready var pause_menu: Control = $PauseMenu
# 引用其他管理器
var task_manager
var ui_manager
var audio_manager
var player_controller: Node = null
var dialogue_box: Node = null
var interaction_hint: Node = null

func _ready():
	# 添加到World组，便于其他节点查找
	add_to_group("World")
	print("World: 已添加到World组")
	
	# 实例化DialogueBox（因为autoload可能无法正确加载）
	var dialogue_scene = preload("res://Scene/DialogueBox.tscn")
	dialogue_box = dialogue_scene.instantiate()
	add_child(dialogue_box)
	print("World: 已实例化DialogueBox")
	
	# 创建交互提示UI
	_create_interaction_hint()
	
	# 延迟实例化PlayerController，确保玩家节点已经存在
	call_deferred("_initialize_player_controller")

# 创建交互提示UI
func _create_interaction_hint():
	# 创建交互提示UI（添加到一个CanvasLayer，保证始终在屏幕中心）
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	
	var hint = Label.new()
	hint.name = "InteractionHint"
	hint.text = "按E键互动"
	hint.visible = true
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1))
	hint.add_theme_font_size_override("font_size", 24)
	
	hint.anchor_left = 0.0
	hint.anchor_top = 0.0
	hint.anchor_right = 1.0
	hint.anchor_bottom = 1.0
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BOTH
	hint.position = Vector2.ZERO
	hint.set_anchors_preset(Control.PRESET_CENTER)
	hint.position = Vector2(-80, 20)
	
	# 添加到UI层
	canvas.add_child(hint)
	interaction_hint = hint
	print("World: 已创建交互提示UI并放入CanvasLayer/UI")

func _initialize_player_controller() -> void:
	# 等待一帧确保玩家节点已经生成
	await get_tree().process_frame
	
	# 实例化PlayerController
	var player_controller_script = preload("res://Script/Gameplay/PlayerController.gd")
	player_controller = player_controller_script.new()
	add_child(player_controller)
	print("World: 已实例化PlayerController")
	
	# 连接PlayerController的信号
	player_controller.connect("state_changed", _on_player_state_changed)

func _unhandled_input(_event: InputEvent) -> void:
	# ESC键已由PlayerController统一处理，这里不再处理
	pass

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state):
	print("World检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	# 根据玩家状态控制世界场景
	match new_state:
		0: # NORMAL
			# 玩家恢复正常状态，世界场景正常运行
			pass
		1: # DIALOGUE
			# 玩家进入对话状态，可以调整世界场景
			pass
		2: # PAUSED
			# 游戏暂停，世界场景暂停更新
			pass
		3: # MENU
			# 玩家在菜单中，世界场景暂停更新
			pass
		4: # CUTSCENE
			# 玩家在过场动画中，世界场景暂停更新
			pass
		_:
			# 未知状态
			pass
