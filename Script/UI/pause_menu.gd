extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer
@onready var ui_manager: Node = get_node_or_null("/root/UIManager")
@onready var settings_button: Button = $VBoxContainer/MainMenuButton

const SETTINGS_UI_SCENE = preload("res://Scene/UI/SettingsUI.tscn")

func _ready() -> void:
	# 初始设置
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 设置按钮文本
	resume_button.text = "继续游戏"
	settings_button.text = "设置"
	quit_button.text = "退出游戏"
	
	# 使用 UIManager 应用风格 + 动画
	if ui_manager:
		# 使用UIManager的方法同时应用风格和连接信号
		if ui_manager.has_method("apply_horror_effects"):
			ui_manager.apply_horror_effects(resume_button, Callable(self, "_on_resume_pressed"))
			ui_manager.apply_horror_effects(settings_button, Callable(self, "_on_settings_pressed"))
			ui_manager.apply_horror_effects(quit_button, Callable(self, "_on_quit_pressed"))

func _unhandled_input(event: InputEvent) -> void:
	# 只处理ESC键按下事件
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled() # 立即标记事件已处理
		
		if visible:
			hide_menu()
		else:
			show_menu()

func show_menu() -> void:
	# 暂停游戏
	get_tree().paused = true
	
	# 显示鼠标
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 显示菜单
	modulate = Color(1, 1, 1, 0)
	visible = true
	
	# 播放心跳声
	if heartbeat_player:
		heartbeat_player.play()
	
	# 动画效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	
	# 设置焦点
	resume_button.grab_focus()

func hide_menu() -> void:
	# 停止心跳声
	if heartbeat_player and heartbeat_player.playing:
		heartbeat_player.stop()
	
	# 立即隐藏菜单（不使用动画）
	modulate = Color(1, 1, 1, 0)
	visible = false
	
	# 解除游戏暂停
	get_tree().paused = false
	
	# 捕获鼠标
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- 按钮回调 ---
func _on_resume_pressed() -> void:
	hide_menu()

func _on_settings_pressed() -> void:
	# 检查是否已存在设置UI实例
	var existing_settings = get_tree().root.get_node_or_null("SettingsUI")
	if existing_settings:
		# 如果已存在，则先移除旧实例
		existing_settings.queue_free()
		
	# 创建新的设置UI实例
	var settings_ui = SETTINGS_UI_SCENE.instantiate()
	settings_ui.name = "SettingsUI" # 设置唯一名称以便检查
	# 设置处理模式为ALWAYS，确保在游戏暂停时仍能交互
	settings_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	# 设置鼠标过滤模式，确保能接收所有输入
	settings_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 添加到场景树并确保所有控件都正确初始化
	get_tree().root.add_child(settings_ui)
	
	# 确保所有按钮信号正确连接
	if settings_ui.has_method("_connect_signals"):
		settings_ui.call("_connect_signals")
	
	# 确保设置界面获得焦点
	if settings_ui.has_method("grab_focus"):
		settings_ui.grab_focus()
		
	# 隐藏暂停菜单
	visible = false
	
	# 设置UI显示在暂停菜单上方
	settings_ui.show()
	
	# 确保鼠标可见
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_quit_pressed() -> void:
	# 确保游戏未暂停
	get_tree().paused = false
	# 退出游戏
	get_tree().quit()
