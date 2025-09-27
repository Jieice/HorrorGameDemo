# res://scripts/UIManager.gd
extends Node
# 全局 UI 管理器（风格 + 打字机）
# 把这个文件加入 Project Settings -> AutoLoad （名字 UIManager）

var default_font: Font = null

# 打字机状态
var _typing := false
var _typing_label: Node = null
var _typing_text: String = ""
var _typing_index: int = 0
var _typing_timer: Timer = null

# 任务提示系统
var task_manager: Node = null
var task_hint_ui: Node = null

# 玩家控制器
var player_controller: Node = null

# 面具完整度UI相关
var mask_integrity_bar: ProgressBar = null
var mask_integrity_label: Label = null
var mask_integrity_value: int = 50
var mask_texture_rect: TextureRect = null

# 面具图片路径常量
const MASK_IMAGE_100_PATH = "res://Assets/Textures/Masks/mask_100.png"  # 完整面具 (90-100%)
const MASK_IMAGE_75_PATH = "res://Assets/Textures/Masks/mask_75.png"    # 轻微损坏面具 (70-89%)
const MASK_IMAGE_50_PATH = "res://Assets/Textures/Masks/mask_50.png"    # 中度损坏面具 (40-69%)
const MASK_IMAGE_25_PATH = "res://Assets/Textures/Masks/mask_25.png"    # 严重损坏面具 (10-39%)
const MASK_IMAGE_0_PATH = "res://Assets/Textures/Masks/mask_0.png"      # 破碎面具 (0-9%)

# 面具图片资源缓存
var mask_image_100: Texture2D = null
var mask_image_75: Texture2D = null
var mask_image_50: Texture2D = null
var mask_image_25: Texture2D = null
var mask_image_0: Texture2D = null

func _ready() -> void:
	# 如有默认字体，可以在这里加载（可选）
	# default_font = load("res://fonts/NotoSansSC-VariableFont_wght.ttf")
	
	# 将UIManager添加到组中，以便其他脚本可以找到它
	add_to_group("UIManager")
	
	# 获取PlayerController
	player_controller = get_parent().get_node_or_null("PlayerController")
	if not player_controller:
		# 如果在父节点中找不到，尝试从根节点获取（向后兼容）
		player_controller = get_node_or_null("/root/PlayerController")
	
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)
	
	# 加载面具图片资源
	_load_mask_images()
	
	# 初始化面具完整度UI
	_initialize_mask_integrity_ui()
	
	# 初始化任务系统
	_initialize_task_system()

# ----------------------
# 恐怖风格按钮（可复用）
# ----------------------
func apply_horror_style(button: Button) -> void:
	# 最小样式：保留原来按钮外观的同时提供统一覆盖（你可以调整数值）
	button.custom_minimum_size = Vector2(220, 56)
	button.add_theme_font_size_override("font_size", 24)
	if default_font:
		button.add_theme_font_override("font", default_font)
	button.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1, 0.2, 0.2))
	# 背景相关（如果你的按钮使用 Panel 风格，这些会生效）
	button.add_theme_color_override("bg_color", Color(0.06, 0.06, 0.06))
	button.add_theme_color_override("bg_hover_color", Color(0.18, 0.06, 0.06))

func shake_button(button: Button) -> void:
	var t = button.create_tween()
	var ox = button.position.x
	t.tween_property(button, "position:x", ox + 8, 0.06).set_trans(Tween.TRANS_SINE)
	t.tween_property(button, "position:x", ox - 8, 0.06).set_trans(Tween.TRANS_SINE)
	t.tween_property(button, "position:x", ox, 0.06).set_trans(Tween.TRANS_SINE)

func click_bounce(button: Button) -> void:
	var t = button.create_tween()
	var os = button.scale
	t.tween_property(button, "scale", os * 0.95, 0.04)
	t.tween_property(button, "scale", os, 0.06)

func apply_horror_effects(button: Button, on_click: Callable) -> void:
	apply_horror_style(button)
	button.mouse_entered.connect(func() -> void:
		shake_button(button))
	button.pressed.connect(func() -> void:
		click_bounce(button)
		if on_click:
			on_click.call())

# ----------------------
# 打字机（支持 Label / RichTextLabel）
# ----------------------
func typewriter(label: Node, text: String, speed: float = 0.04) -> void:
	# 安全关闭之前的定时器
	if _typing_timer and _typing_timer.is_inside_tree():
		_typing_timer.stop()
		_typing_timer.queue_free()

	_typing_label = label
	_typing_text = text
	_typing_index = 0
	_typing = true

	# 设置完整文本并初始化可见字符数
	if _typing_label is RichTextLabel:
		_typing_label.text = _typing_text
		_typing_label.visible_characters = 0
	else:
		_typing_label.text = _typing_text
		_typing_label.visible_characters = 0

	_typing_timer = Timer.new()
	_typing_timer.wait_time = speed
	_typing_timer.one_shot = false
	add_child(_typing_timer)
	_typing_timer.timeout.connect(_on_type_tick)
	_typing_timer.start()

func _on_type_tick() -> void:
	if not _typing_label or not is_instance_valid(_typing_label):
		_stop_typing_timer()
		_typing = false
		return

	if _typing_index < _typing_text.length():
		# 增加可见字符数
		_typing_label.visible_characters += 1
		_typing_index += 1
	else:
		_stop_typing_timer()
		_typing = false
		# 确保显示所有字符
		_typing_label.visible_characters = -1
		# 通知父节点（常见是 DialogueBox）打字结束（如果父节点实现了 _on_typewriter_finished）
		if _typing_label.get_parent() and _typing_label.get_parent().has_method("_on_typewriter_finished"):
			_typing_label.get_parent()._on_typewriter_finished()

func _stop_typing_timer() -> void:
	if _typing_timer and _typing_timer.is_inside_tree():
		_typing_timer.stop()
		_typing_timer.queue_free()
	_typing_timer = null

func is_typing() -> bool:
	return _typing

func skip_typewriter(label: Node, text: String) -> void:
	# 立即完成当前打字并调用完成回调
	_stop_typing_timer()
	if label:
		if label is RichTextLabel:
			label.clear()
			label.append_text(text)
		else:
			label.text = text
	_typing = false
	if label.get_parent() and label.get_parent().has_method("_on_typewriter_finished"):
		label.get_parent()._on_typewriter_finished()

# ----------------------
# 任务提示系统
# ----------------------
func _initialize_task_system() -> void:
	# 获取自动加载的任务管理器
	task_manager = get_node_or_null("/root/TaskManager")
	if not task_manager:
		print("警告: 无法找到自动加载的TaskManager，将在稍后重试")
		# 使用定时器延迟初始化
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.timeout.connect(_delayed_task_system_init)
		add_child(timer)
		timer.start()
		return
	
	# 初始化任务系统UI
	_setup_task_system_ui()

# 延迟初始化任务系统
func _delayed_task_system_init() -> void:
	task_manager = get_node_or_null("/root/TaskManager")
	if not task_manager:
		print("错误: 仍然无法找到自动加载的TaskManager")
		return
	
	# 初始化任务系统UI
	_setup_task_system_ui()
	print("任务系统延迟初始化成功")

# 设置任务系统UI（复用代码）
func _setup_task_system_ui() -> void:
	# 创建任务提示UI - 直接使用场景文件
	task_hint_ui = load("res://Scene/UI/TaskHintUI.tscn").instantiate()
	add_child(task_hint_ui)
	
	# 连接信号
	task_manager.connect("task_updated", Callable(task_hint_ui, "_on_task_updated"))
	task_manager.connect("new_task_added", Callable(task_hint_ui, "_on_new_task_added"))
	task_manager.connect("task_completed", Callable(task_hint_ui, "_on_task_completed"))
	
	# 连接PlayerController的state_changed信号到TaskHintUI的处理函数
	if player_controller:
		player_controller.connect("state_changed", Callable(task_hint_ui, "_on_player_state_changed"))
	
	# 初始化任务提示UI
	task_hint_ui.task_manager = task_manager
	task_hint_ui.player_controller = player_controller
	task_hint_ui._ready()

# 获取任务提示UI的引用（供外部访问）
func get_task_hint_ui() -> Node:
	return task_hint_ui

# 切换任务提示显示
func toggle_task_hint() -> void:
	if task_hint_ui:
		task_hint_ui.toggle_hint_display()

# 显示任务提示
func show_task_hint() -> void:
	if task_hint_ui:
		task_hint_ui.show_hints()

# 隐藏任务提示
func hide_task_hint() -> void:
	if task_hint_ui:
		task_hint_ui.hide_hints()

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state):
	print("UIManager检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	# 根据玩家状态控制UI显示
	match new_state:
		0: # NORMAL
			# 玩家恢复正常状态，UI系统正常运行
			if mask_integrity_bar:
				mask_integrity_bar.visible = true
		1: # DIALOGUE
			# 玩家进入对话状态，可以调整UI显示
			if mask_integrity_bar:
				mask_integrity_bar.visible = true
		2: # PAUSED
			# 游戏暂停，UI系统暂停更新
			if mask_integrity_bar:
				mask_integrity_bar.visible = false
		3: # IN_MENU
			# 玩家在菜单中，UI系统暂停更新
			if mask_integrity_bar:
				mask_integrity_bar.visible = false
		4: # IN_CUTSCENE
			# 玩家在过场动画中，UI系统暂停更新
			if mask_integrity_bar:
				mask_integrity_bar.visible = false
		_:
			# 未知状态
			pass

# ----------------------
# 面具完整度系统UI
# ----------------------
func _initialize_mask_integrity_ui() -> void:
	# 创建面具完整度UI容器
	var mask_container = MarginContainer.new()
	mask_container.name = "MaskIntegrityContainer"
	mask_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mask_container.add_theme_constant_override("margin_left", 20)
	mask_container.add_theme_constant_override("margin_top", 20)
	mask_container.add_theme_constant_override("margin_right", 20)
	mask_container.add_theme_constant_override("margin_bottom", 20)
	add_child(mask_container)
	
	# 创建面具图片显示
	mask_texture_rect = TextureRect.new()
	mask_texture_rect.name = "MaskTextureRect"
	mask_texture_rect.custom_minimum_size = Vector2(225, 225)  # 增大到原来的2.25倍（150 * 1.5 = 225）
	mask_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	mask_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mask_container.add_child(mask_texture_rect)
	
	# 不再创建标签和进度条
	
	# 连接到TaskManager的面具完整度信号
	task_manager = get_node_or_null("/root/TaskManager")
	if task_manager:
		task_manager.connect("mask_integrity_changed", Callable(self, "_on_mask_integrity_changed"))
		task_manager.connect("inner_monologue_triggered", Callable(self, "_on_inner_monologue_triggered"))
		task_manager.connect("choice_presented", Callable(self, "_on_choice_presented"))
		print("UIManager: 成功连接到TaskManager的面具完整度信号")
	else:
		print("UIManager: 警告 - 无法连接到TaskManager")

# 创建恐怖风格的样式框
func _create_horror_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.05, 0.05, 0.8)  # 深红色背景
	style.border_color = Color(0.8, 0.1, 0.1, 1.0)  # 红色边框
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

# 面具完整度变化处理
func _on_mask_integrity_changed(old_value: int, new_value: int) -> void:
	mask_integrity_value = new_value
	
	# 只更新面具图片
	_update_mask_image(new_value)
	
	print("UIManager: 面具完整度更新 - ", old_value, " -> ", new_value)

# 获取面具完整度等级文本
func _get_mask_integrity_level_text(value: int) -> String:
	var percentage = float(value) / 100.0
	if percentage >= 0.8:
		return "完整"
	elif percentage >= 0.6:
		return "轻微破损"
	elif percentage >= 0.4:
		return "中度破损"
	elif percentage >= 0.2:
		return "严重破损"
	else:
		return "破碎"

# 获取面具完整度颜色
func _get_mask_integrity_color(value: int) -> Color:
	var percentage = float(value) / 100.0
	if percentage >= 0.8:
		return Color(0.0, 1.0, 0.0, 0.8)  # 绿色
	elif percentage >= 0.6:
		return Color(0.8, 1.0, 0.0, 0.8)  # 黄绿色
	elif percentage >= 0.4:
		return Color(1.0, 1.0, 0.0, 0.8)  # 黄色
	elif percentage >= 0.2:
		return Color(1.0, 0.5, 0.0, 0.8)  # 橙色
	else:
		return Color(1.0, 0.0, 0.0, 0.8)  # 红色

# 根据完整度更新面具图片
func _update_mask_image(integrity_value: int) -> void:
	if not mask_texture_rect:
		print("UIManager: 错误 - 找不到MaskTextureRect节点")
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
	
	# 检查是否需要更新图片（只有当图片变化时才应用过渡效果）
	var current_texture = mask_texture_rect.texture
	if current_texture != texture:
		# 如果没有设置图片资源，使用占位图像
		if texture == null:
			print("UIManager: 警告 - 面具图片资源未设置，使用占位图像")
			# 创建一个简单的占位图像
			var placeholder = _create_placeholder_texture(integrity_value)
			_apply_transition_effect(placeholder)
		else:
			_apply_transition_effect(texture)
		
# 应用过渡效果
func _apply_transition_effect(new_texture: Texture2D) -> void:
	# 创建一个补间动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# 先淡出当前图片
	tween.tween_property(mask_texture_rect, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# 在淡出完成后更换图片并淡入
	tween.tween_callback(func(): mask_texture_rect.texture = new_texture)
	tween.tween_property(mask_texture_rect, "modulate", Color(1, 1, 1, 1), 0.3)

# 加载面具图片资源
func _load_mask_images() -> void:
	# 尝试加载面具图片资源
	mask_image_100 = _load_texture_safe(MASK_IMAGE_100_PATH)
	mask_image_75 = _load_texture_safe(MASK_IMAGE_75_PATH)
	mask_image_50 = _load_texture_safe(MASK_IMAGE_50_PATH)
	mask_image_25 = _load_texture_safe(MASK_IMAGE_25_PATH)
	mask_image_0 = _load_texture_safe(MASK_IMAGE_0_PATH)
	
	print("UIManager: 面具图片资源加载完成")

# 安全加载纹理（如果文件不存在则返回null）
func _load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	else:
		print("UIManager: 警告 - 无法加载纹理: ", path)
		return null

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

# 创建彩色样式框
func _create_colored_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	return style

# 内心独白触发处理
func _on_inner_monologue_triggered(text: String, priority: String) -> void:
	print("UIManager: 内心独白触发 - ", text, " (优先级: ", priority, ")")
	show_inner_monologue(text)

# 选择呈现处理
func _on_choice_presented(options: Array, context: String) -> void:
	print("UIManager: 选择对话框 - ", context)
	for i in range(options.size()):
		var option = options[i]
		print("选项 ", i + 1, ": ", option.text if option.has("text") else "未知选项")
	# 这里我们不需要处理通用的选择呈现，因为InteractableObject会直接调用show_choice_dialog

# ----------------------
# 内心独白系统
# ----------------------
func show_inner_monologue(text: String) -> void:
	print("显示内心独白: ", text)
	# 创建内心独白UI
	_create_inner_monologue_ui(text)

func _create_inner_monologue_ui(text: String) -> void:
	# 创建内心独白容器
	var monologue_container = MarginContainer.new()
	monologue_container.name = "InnerMonologueContainer"
	monologue_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	monologue_container.add_theme_constant_override("margin_left", 50)
	monologue_container.add_theme_constant_override("margin_bottom", 100)
	add_child(monologue_container)
	
	# 创建背景面板
	var panel = Panel.new()
	panel.name = "InnerMonologuePanel"
	panel.custom_minimum_size = Vector2(400, 80)
	monologue_container.add_child(panel)
	
	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
	panel_style.border_color = Color(0.5, 0.1, 0.1, 1.0)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# 创建标签显示文本
	var label = Label.new()
	label.name = "InnerMonologueLabel"
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	# 使用打字机效果显示文本
	typewriter(label, text, 0.05)
	
	# 3秒后自动移除
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		if monologue_container and monologue_container.is_inside_tree():
			monologue_container.queue_free()
	)
	add_child(timer)
	timer.start()

# ----------------------
# 选择对话框系统
# ----------------------
func show_choice_dialog(choice_data: Dictionary) -> void:
	print("显示选择对话框: ", choice_data.get("prompt", ""))
	_create_choice_dialog_ui(choice_data)

func _create_choice_dialog_ui(choice_data: Dictionary) -> void:
	var prompt = choice_data.get("prompt", "你面临一个选择...")
	var options = choice_data.get("options", [])
	var descriptions = choice_data.get("descriptions", [])
	var mask_impacts = choice_data.get("mask_impacts", [])
	var callback = choice_data.get("callback", Callable())
	
	if options.size() == 0:
		print("错误: 没有选择选项")
		return
	
	# 创建选择对话框容器
	var dialog_container = MarginContainer.new()
	dialog_container.name = "ChoiceDialogContainer"
	dialog_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(dialog_container)
	
	# 创建背景面板
	var panel = Panel.new()
	panel.name = "ChoiceDialogPanel"
	panel.custom_minimum_size = Vector2(500, 300)
	dialog_container.add_child(panel)
	
	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	panel_style.border_color = Color(0.8, 0.1, 0.1, 1.0)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# 创建VBox容器
	var vbox = VBoxContainer.new()
	vbox.name = "ChoiceDialogVBox"
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# 创建提示标签
	var prompt_label = Label.new()
	prompt_label.name = "ChoicePromptLabel"
	prompt_label.text = prompt
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(prompt_label)
	
	# 创建选项按钮容器
	var button_container = VBoxContainer.new()
	button_container.name = "ChoiceButtonContainer"
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	# 创建选项按钮
	for i in range(options.size()):
		var option_text = options[i]
		var description = ""
		if i < descriptions.size():
			description = descriptions[i]
		
		var impact_text = ""
		if i < mask_impacts.size() and mask_impacts[i] != 0:
			var impact = mask_impacts[i]
			if impact > 0:
				impact_text = " [面具+%d]" % impact
			else:
				impact_text = " [面具%d]" % impact
		
		var button_text = option_text + impact_text
		if not description.is_empty():
			button_text += "\n" + "    " + description
		
		var button = Button.new()
		button.name = "ChoiceButton_" + str(i)
		button.text = button_text
		button.custom_minimum_size = Vector2(400, 60)
		
		# 应用恐怖风格
		apply_horror_style(button)
		button.add_theme_font_size_override("font_size", 16)
		
		# 连接按钮按下信号
		var choice_index = i
		button.pressed.connect(func() -> void:
			print("玩家选择了选项: ", choice_index)
			if dialog_container and dialog_container.is_inside_tree():
				dialog_container.queue_free()
			if callback.is_valid():
				callback.call(choice_index)
		)
		
		button_container.add_child(button)
	
	# 暂停游戏（可选）
	if player_controller:
		player_controller.set_state(player_controller.PlayerState.DIALOGUE)
	
	print("选择对话框创建完成，选项数量: ", options.size())
