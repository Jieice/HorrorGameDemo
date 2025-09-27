extends Node

func _ready():
	# 确保在主菜单中鼠标可见
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("MouseController: 强制设置鼠标为可见状态")

func _process(_delta):
	# 持续确保鼠标可见
	if get_tree().current_scene.name == "MainMenu" and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("MouseController: 重置鼠标为可见状态")