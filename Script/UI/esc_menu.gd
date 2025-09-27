extends Control

# 设置UI场景路径
const SETTINGS_UI_SCENE = preload("res://Scene/UI/SettingsUI.tscn")
var settings_ui = null

# 初始化
func _ready():
	# 默认隐藏菜单
	hide()
	
	# 预加载设置UI
	settings_ui = SETTINGS_UI_SCENE.instantiate()
	add_child(settings_ui)
	settings_ui.z_index = 100
	settings_ui.hide()

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
	settings_ui.show()

# 主菜单按钮
func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

# 退出游戏按钮
func _on_quit_button_pressed():
	get_tree().quit()