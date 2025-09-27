extends Control

# 面具UI控制脚本
# 根据面具完整度显示不同的面具图片

# 面具图片引用
@export var mask_image_100: Texture2D  # 完整面具 (90-100%)
@export var mask_image_75: Texture2D   # 轻微损坏面具 (70-89%)
@export var mask_image_50: Texture2D   # 中度损坏面具 (40-69%)
@export var mask_image_25: Texture2D   # 严重损坏面具 (10-39%)
@export var mask_image_0: Texture2D    # 破碎面具 (0-9%)

# UI组件
@onready var mask_texture_rect: TextureRect = $MaskTextureRect

# 任务管理器引用
var task_manager = null

func _ready():
	# 获取任务管理器引用
	task_manager = get_node_or_null("/root/TaskManager")
	if task_manager:
		# 连接面具完整度变化信号
		task_manager.connect("mask_integrity_changed", Callable(self, "_on_mask_integrity_changed"))
		print("MaskUI: 成功连接到TaskManager的面具完整度信号")
		
		# 初始化面具图片
		var initial_integrity = task_manager.get_mask_integrity()
		_update_mask_image(initial_integrity)
	else:
		print("MaskUI: 警告 - 无法连接到TaskManager")

# 处理面具完整度变化
func _on_mask_integrity_changed(old_value: int, new_value: int) -> void:
	_update_mask_image(new_value)

# 根据完整度更新面具图片
func _update_mask_image(integrity_value: int) -> void:
	if not mask_texture_rect:
		print("MaskUI: 错误 - 找不到MaskTextureRect节点")
		return
		
	var texture = null
	
	# 根据完整度选择对应的面具图片
	if integrity_value >= 90:
		texture = mask_image_100
	elif integrity_value >= 70:
		texture = mask_image_75
	elif integrity_value >= 40:
		texture = mask_image_50
	elif integrity_value >= 10:
		texture = mask_image_25
	else:
		texture = mask_image_0
	
	# 如果没有设置图片资源，使用占位图像
	if texture == null:
		print("MaskUI: 警告 - 面具图片资源未设置，使用占位图像")
		# 创建一个简单的占位图像
		var placeholder = _create_placeholder_texture(integrity_value)
		mask_texture_rect.texture = placeholder
	else:
		mask_texture_rect.texture = texture

# 创建占位图像（当没有设置实际图像资源时使用）
func _create_placeholder_texture(integrity_value: int) -> ImageTexture:
	var image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	
	# 根据完整度选择颜色
	var color = Color.WHITE
	if integrity_value >= 90:
		color = Color(0, 1, 0, 1)  # 绿色
	elif integrity_value >= 70:
		color = Color(0.5, 1, 0, 1)  # 黄绿色
	elif integrity_value >= 40:
		color = Color(1, 1, 0, 1)  # 黄色
	elif integrity_value >= 10:
		color = Color(1, 0.5, 0, 1)  # 橙色
	else:
		color = Color(1, 0, 0, 1)  # 红色
	
	# 填充图像
	image.fill(color)
	
	# 创建纹理
	var texture = ImageTexture.create_from_image(image)
	return texture
