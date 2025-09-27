extends TextureButton

# 预加载设置UI场景
const SETTINGS_UI_SCENE = preload("res://Scene/UI/SettingsUI.tscn")
var settings_ui = null

func _ready():
	# 检查当前场景是否为主菜单
	var current_scene = get_tree().current_scene
	if current_scene.name == "main_menu" or current_scene.scene_file_path == "res://Scene/main_menu.tscn":
		# 如果是主菜单，则隐藏设置按钮
		hide()
	else:
		# 如果不是主菜单，则显示设置按钮
		show()
	
	# 预加载设置UI
	settings_ui = SETTINGS_UI_SCENE.instantiate()
	get_tree().root.add_child(settings_ui)
	settings_ui.z_index = 100
	settings_ui.hide()
	
	# 连接按钮信号
	pressed.connect(_on_settings_button_pressed)

# 设置按钮点击事件
func _on_settings_button_pressed():
	settings_ui.show()
