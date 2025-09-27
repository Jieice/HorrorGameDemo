# res://scripts/UIManager.gd
extends Node
# 全局 UI 管理器（风格 + 打字机）
# 把这个文件加入 Project Settings -> AutoLoad （名字 UIManager）

var default_font: Font = null

# 打字机状态
var _typing := false
var _typing_label: Node = null
var _typing_text: String = ""
var _typing_index: int = 0
var _typing_timer: Timer = null

# 任务提示系统
var task_manager: Node = null
var task_hint_ui: Node = null

# 玩家控制器
var player_controller: Node = null

# 音效设置UI
var audio_settings_ui: Node = null


func _ready() -> void:
	add_to_group("UIManager")
	
	# 获取PlayerController
	player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		# 如果在父节点中找不到，尝试从根节点获取（向后兼容）
		player_controller = get_node_or_null("/root/PlayerController")
	
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)

# 玩家状态变化处理（已移除面具相关逻辑，仅保留打印和扩展接口）
func _on_player_state_changed(old_state, new_state):
	print("UIManager检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	# 可在此扩展其它UI逻辑
