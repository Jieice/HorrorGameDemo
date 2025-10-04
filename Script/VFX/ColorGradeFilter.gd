extends CanvasLayer

# 恐怖游戏色调滤镜控制脚本

@onready var color_rect: ColorRect = $ColorRect

func _ready():
	# 只在游戏场景显示
	color_rect.visible = false
	get_tree().node_added.connect(_on_scene_changed)
	_check_scene()

func _on_scene_changed(node):
	if node == get_tree().current_scene:
		_check_scene()

func _check_scene():
	await get_tree().process_frame
	var scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	if scene_name == "Main" or scene_name.begins_with("Main-"):
		color_rect.visible = true
	else:
		color_rect.visible = false
