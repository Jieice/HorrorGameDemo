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
var _typing_speed: float = 0.03  # 默认打字速度

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
	
# 打字机效果实现
func typewriter(label: Node, text: String, speed: float = -1) -> void:
	print("=== UIManager.typewriter被调用 ===")
	print("要显示的文本: ", text)
	
	# 如果已经在打字，先停止
	if _typing and _typing_timer and _typing_timer.is_inside_tree():
		_typing_timer.stop()
		_typing_timer.queue_free()
		_typing = false
	
	# 设置打字速度
	var typing_speed = speed if speed > 0 else _typing_speed
	
	# 初始化打字机状态
	_typing = true
	_typing_label = label
	_typing_text = text
	_typing_index = 0
	
	# 清空标签文本
	if label is RichTextLabel or label is Label:
		label.text = ""
	
	# 创建定时器
	_typing_timer = Timer.new()
	_typing_timer.wait_time = typing_speed
	_typing_timer.one_shot = false
	add_child(_typing_timer)
	_typing_timer.connect("timeout", _on_typing_timer_timeout)
	_typing_timer.start()
	
# 打字机定时器回调
func _on_typing_timer_timeout() -> void:
	if not _typing or not _typing_label or not _typing_label.is_inside_tree():
		if _typing_timer:
			_typing_timer.stop()
			_typing_timer.queue_free()
		_typing = false
		return
	
	# 添加下一个字符
	if _typing_index < _typing_text.length():
		if _typing_label is RichTextLabel or _typing_label is Label:
			_typing_label.text += _typing_text[_typing_index]
		_typing_index += 1
	else:
		# 打字完成
		_typing = false
		if _typing_timer:
			_typing_timer.stop()
			_typing_timer.queue_free()
			
# 立即完成打字
func complete_typing() -> void:
	if _typing and _typing_label and _typing_label.is_inside_tree():
		if _typing_label is RichTextLabel or _typing_label is Label:
			_typing_label.text = _typing_text
		
		_typing = false
		if _typing_timer:
			_typing_timer.stop()
			_typing_timer.queue_free()
