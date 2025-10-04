extends CanvasLayer

# 面具完整度UI - 显示在屏幕右上角

@onready var container: MarginContainer = $Container
@onready var mask_icon: TextureRect = $Container/VBoxContainer/MaskIcon
@onready var percentage_label: Label = $Container/VBoxContainer/PercentageLabel

func _ready():
	# 只在游戏场景显示
	container.visible = false
	get_tree().node_added.connect(_on_scene_changed)
	_check_scene()

func _on_scene_changed(node):
	if node == get_tree().current_scene:
		_check_scene()

func _check_scene():
	await get_tree().process_frame
	var scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	if scene_name == "Main" or scene_name.begins_with("Main-"):
		container.visible = true
		update_mask(0, "res://Assets/Textures/Masks/mask_0.png")
	else:
		container.visible = false

# 更新面具显示
func update_mask(integrity: int, icon_path: String):
	# 更新图标
	var texture = load(icon_path)
	if texture:
		mask_icon.texture = texture
	# 更新百分比
	percentage_label.text = str(integrity) + "%"
	# 根据完整度改变文字颜色
	if integrity < 30:
		percentage_label.modulate = Color(0.9, 0.85, 0.8, 1) # 低完整度：暖白色（真实自我）
	elif integrity < 70:
		percentage_label.modulate = Color(0.85, 0.75, 0.7, 1) # 中完整度：偏暗
	else:
		percentage_label.modulate = Color(0.7, 0.75, 0.8, 1) # 高完整度：冷白色（面具）
