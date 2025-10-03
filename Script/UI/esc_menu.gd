extends Control

var just_opened := true

func _ready():
	set_process_unhandled_input(true)
	just_opened = true
	await get_tree().process_frame
	just_opened = false

func _unhandled_input(event):
	if just_opened:
		return
	if event.is_action_pressed("esc") or event.is_action_pressed("ui_cancel"):
		queue_free()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	print("继续游戏")
	queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_settings_button_pressed():
	print("打开设置")
	if not has_node("SettingsUI"):
		var settings_scene = preload("res://Scene/UI/SettingsUI.tscn")
		var settings_ui = settings_scene.instantiate()
		add_child(settings_ui)

func _on_main_menu_button_pressed():
	print("返回主菜单")
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func _on_quit_button_pressed():
	print("退出游戏")
	get_tree().quit()
