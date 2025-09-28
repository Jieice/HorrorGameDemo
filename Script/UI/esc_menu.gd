extends Control

# 设置UI场景路径
const SETTINGS_UI_SCENE = preload("res://Scene/UI/SettingsUI.tscn")
var settings_ui = null

# 初始化
func _ready():
	# 默认隐藏菜单
	hide()
	


# 输入处理
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC键
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true
		get_viewport().set_input_as_handled()

# 继续游戏按钮
func _on_resume_button_pressed():
	hide()
	get_tree().paused = false

# 设置按钮
func _on_settings_button_pressed():
	print("设置按钮被点击 - _on_settings_button_pressed() 方法被调用")
	
	# 预加载设置UI
	if not settings_ui or not is_instance_valid(settings_ui):
		print("创建新的SettingsUI实例")
		settings_ui = SETTINGS_UI_SCENE.instantiate()
		add_child(settings_ui)
		settings_ui.z_index = 100
		
		# 确保设置UI在暂停时仍能处理输入
		settings_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# 确保设置UI可以接收鼠标输入
		if settings_ui is Control:
			settings_ui.mouse_filter = Control.MOUSE_FILTER_STOP
			
		# 连接关闭信号
		if settings_ui.has_signal("closed"):
			print("连接SettingsUI的closed信号")
			settings_ui.closed.connect(_on_settings_closed)
		else:
			print("警告：SettingsUI没有closed信号！")
	else:
		print("使用现有的SettingsUI实例")
	
	# 显示设置UI
	print("显示SettingsUI")
	if settings_ui:
		print("SettingsUI实例有效：", is_instance_valid(settings_ui))
		settings_ui.show()
	else:
		print("错误：SettingsUI实例无效！")
	
	# 确保鼠标可见
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("鼠标模式设置为可见")
	
	# 调试信息
	print("当前场景树中的SettingsUI节点：")
	for child in get_children():
		if child.name.begins_with("SettingsUI"):
			print("  - ", child.name, "(有效：", is_instance_valid(child), ")")

# 主菜单按钮
func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

# 退出游戏按钮
func _on_quit_button_pressed():
	get_tree().quit()
	
# 处理设置UI关闭
func _on_settings_closed():
	if settings_ui and is_instance_valid(settings_ui):
		settings_ui.hide()
