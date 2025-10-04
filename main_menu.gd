extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# 设置UI场景路径
const SETTINGS_UI_SCENE = preload("res://Scene/UI/SettingsUI.tscn")
var settings_ui = null

# 设置为高优先级，确保在主菜单中不响应ESC键
func _unhandled_input(event: InputEvent) -> void:
	# 拦截ESC键，防止暂停菜单在主菜单中显示
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# 如果设置界面正在显示，则隐藏它
		if settings_ui and settings_ui.visible:
			settings_ui.hide()

func _ready() -> void:
	start_button.text = "开始游戏"
	settings_button.text = "设置"
	quit_button.text = "退出游戏"

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 预加载设置UI
	settings_ui = SETTINGS_UI_SCENE.instantiate()
	add_child(settings_ui)
	settings_ui.hide()
	
	# 确保设置UI在最上层显示
	settings_ui.z_index = 100
	
	# 主菜单只需要鼠标可见，不需要其他复杂逻辑
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_start_pressed() -> void:
	# 使用淡入淡出过渡切换到游戏场景
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		transition.change_scene("res://Scene/Level/level1/Main-Prologue_Subway.tscn", 1.0, 2.0)
	else:
		get_tree().change_scene_to_file("res://Scene/Level/level1/Main-Prologue_Subway.tscn")

func _on_settings_pressed() -> void:
	# 显示设置界面
	if not settings_ui or not is_instance_valid(settings_ui):
		settings_ui = SETTINGS_UI_SCENE.instantiate()
		add_child(settings_ui)
		settings_ui.z_index = 100
	
	settings_ui.show()
	
func _on_settings_closed() -> void:
	# 设置UI关闭后的回调
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
