extends CanvasLayer

@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var name_label: Label = $Panel/NameLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var continue_label: Label = $ContinueLabel
@onready var interact_hint: Label = $InteractHint
@onready var ui_manager: Node = get_node_or_null("/root/UIManager")
var player_controller: Node = null

@export var text_speed: float = 0.03  # 打字速度
var lines: Array = []          # 对话内容
var current_line: int = 0              # 当前行
var typing: bool = false
var choices: Array = []  # 选择项
var choice_callbacks: Dictionary = {}  # 选择对应的回调函数
signal dialogue_closed
signal option_selected(index: int)  # 选择项被选中的信号
signal handle_space  # 添加空格键处理信号

# 预留的选择处理函数，供外部覆盖
func on_option_selected(index: int) -> void:
	# 此函数可被外部脚本覆盖以自定义选择处理逻辑
	pass

func _ready() -> void:
	# 添加到DialogueBox分组，便于PlayerController查找
	add_to_group("DialogueBox")
	
	# 从父节点查找PlayerController
	player_controller = get_parent().get_node_or_null("PlayerController")
	
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)
	
	visible = false
	continue_label.text = "[空格] 继续"  # 设置空格继续提示

# 对话内容数组
func start_dialogue(dialogue_lines: Array, speaker_name: String = "") -> void:
	# 重置选择相关变量
	_clear_choices()
	
	# 确保对话框可见
	visible = true
	$Panel.show()
	$Panel/NameLabel.show()
	$Panel/TextLabel.show()
	$ContinueLabel.show()
	
	name_label.text = speaker_name
	lines = dialogue_lines
	current_line = 0
	typing = true
	text_label.text = ""
	continue_label.visible = false
	
	if lines.size() > 0:
		_type_text(lines[0])
	else:
		close_dialogue()

# 添加选择对话框功能
func show_choices(options: Array, callbacks: Dictionary = {}) -> void:
	print("显示选择项，数量: ", options.size())
	
	# 清除现有选择项
	_clear_choices()
	choices = options
	choice_callbacks = callbacks  # 使用统一的choice_callbacks变量
	
	# 隐藏继续提示，显示选择项
	continue_label.visible = false
	
	# 创建选择按钮
	for i in range(options.size()):
		var button = Button.new()
		button.text = options[i]
		# 使用call_method连接按钮按下信号，避免lambda函数问题
		button.connect("pressed", Callable(self, "_on_choice_button_pressed").bind(i))
		print("创建按钮: ", i, " 文本: ", options[i])
		# 设置按钮样式，使其更美观
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_color_hover", Color(0.9, 0.9, 1.0))
		button.add_theme_color_override("font_color_pressed", Color(0.8, 0.8, 0.9))
		button.add_theme_stylebox_override("normal", _create_button_style(Color(0.2, 0.2, 0.3, 0.8)))
		button.add_theme_stylebox_override("hover", _create_button_style(Color(0.3, 0.3, 0.4, 0.9)))
		button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.25, 0.25, 0.35, 1.0)))
		
		# 增大按钮尺寸
		button.custom_minimum_size = Vector2(300, 50)  # 设置最小尺寸为300x50
		button.add_theme_font_size_override("font_size", 20)  # 增大字体大小
		
		choices_container.add_child(button)
	
	# 显示选择容器
	choices_container.visible = true
	print("选择容器已设置为可见")

# 清除所有选择项
func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	choices = []
	choice_callbacks = {}

# 创建按钮样式
func _create_button_style(bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.8, 0.8, 0.8, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

# 选择按钮被按下的处理函数
func _on_choice_button_pressed(index: int) -> void:
	print("选择按钮被按下，索引: ", index)
	
	# 发出选择信号
	emit_signal("option_selected", index)
	
	# 调用回调函数（如果存在）
	if choice_callbacks.has(index):
		var callback = choice_callbacks[index]
		if callback is Callable:
			print("调用回调函数，索引: ", index)
			callback.call(index)
		else:
			print("警告：回调函数不是Callable类型，索引: ", index)
	else:
		print("警告：未找到索引为 ", index, " 的回调函数")
	
	# 清除选择项
	_clear_choices()
	
	# 不立即关闭对话框，等待选择后的对话内容显示完毕
	# 对话关闭信号将在NPC.gd的_on_choice_dialogue_completed函数中发出
	
	# 标记输入已处理，防止其他节点处理
	get_viewport().set_input_as_handled()

func show_hint() -> void:
	interact_hint.visible = true
	get_tree().create_timer(2.0).timeout.connect(_hide_hint)

# 隐藏关闭提示
func _hide_hint() -> void:
	interact_hint.visible = false
	
	
signal dialogue_completed

func _type_text(text: String, emotion: String = "normal") -> void:
	print("=== _type_text开始执行 ===")
	print("要显示的文本: ", text)
	print("text_label是否存在: ", text_label != null)
	
	typing = true
	text_label.text = ""
	continue_label.visible = false
	
	# 根据情绪设置文本样式
	_apply_emotion_style(emotion)
	
	if ui_manager and ui_manager.has_method("typewriter"):
		print("使用UIManager的打字机效果")
		# 调用UIManager的打字机效果
		ui_manager.typewriter(text_label, text, text_speed)

		# 安全等待打字机效果完成
		if ui_manager._typing_timer and is_instance_valid(ui_manager._typing_timer):
			await ui_manager._typing_timer.tree_exited
		else:
			# 如果_typing_timer不可用，使用定时器代替
			await get_tree().create_timer(text.length() * text_speed).timeout
			
		typing = false
		continue_label.visible = true
		print("打字机效果完成，显示继续标签")
	else:
		# 如果UIManager不可用，使用内置的打字机效果
		print("UIManager不可用，使用内置的打字机效果")
		for i in range(text.length()):
			if not typing:
				break
			text_label.text += text[i]
			await get_tree().create_timer(text_speed).timeout
		typing = false
		continue_label.visible = true
		print("打字机效果完成，显示继续标签")
		
# 根据情绪设置文本样式
func _apply_emotion_style(emotion: String) -> void:
	var base_font_size = 24  # 增大基础字体大小
	
	# 重置样式
	text_label.add_theme_font_size_override("normal_font_size", base_font_size)
	text_label.add_theme_color_override("default_color", Color(1, 1, 1))
	
	# 根据情绪应用不同样式
	match emotion:
		"angry":
			text_label.add_theme_font_size_override("normal_font_size", base_font_size + 4)
			text_label.add_theme_color_override("default_color", Color(0.9, 0.3, 0.3))
		"sad":
			text_label.add_theme_font_size_override("normal_font_size", base_font_size - 2)
			text_label.add_theme_color_override("default_color", Color(0.5, 0.7, 0.9))
		"happy":
			text_label.add_theme_color_override("default_color", Color(1.0, 0.9, 0.4))
		"scared":
			# 添加轻微抖动效果
			var tween = create_tween().set_loops()
			tween.tween_property(text_label, "position:x", text_label.position.x + 2, 0.1)
			tween.tween_property(text_label, "position:x", text_label.position.x, 0.1)
			text_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.9))
		"confused":
			text_label.add_theme_color_override("default_color", Color(0.7, 0.5, 0.9))
		_:  # 默认样式
			pass

# 处理空格键输入，用于继续对话或跳过打字动画
func process_space_key() -> void:
	print("=== 对话框处理空格键输入 ===")
	print("当前行: ", current_line, ", 总行数: ", lines.size(), ", 是否正在打字: ", typing)
	print("对话框可见: ", visible, ", 选择容器可见: ", choices_container.visible if choices_container else "N/A")
	
	# 发射空格键处理信号
	emit_signal("handle_space")
	
	# 如果正在显示选择项，不处理空格键
	if choices_container and choices_container.visible and choices_container.get_child_count() > 0:
		print("正在显示选择项，不处理空格键")
		return
	
	# 如果正在打字，跳过打字动画
	if typing:
		print("跳过打字动画")
		typing = false
		# 立即显示完整文本
		if current_line < lines.size():
			text_label.text = lines[current_line]
		continue_label.visible = true
		print("打字动画已跳过，显示完整文本")
		return
	
	# 如果打字已完成，显示下一行或关闭对话
	if not typing and current_line < lines.size() - 1:
		# 显示下一行对话
		current_line += 1
		typing = true
		continue_label.visible = false
		print("显示下一行对话: ", current_line, " - 内容: ", lines[current_line])
		_type_text(lines[current_line])
	elif not typing and current_line == lines.size() - 1:
		# 当前是最后一行且打字完成，发射对话完成信号
		print("对话已结束，发射dialogue_completed信号")
		emit_signal("dialogue_completed")
		# 不立即关闭对话框，等待NPC处理选项
	else:
		print("未处理空格键，条件不满足 - typing: ", typing, ", current_line: ", current_line, ", lines.size(): ", lines.size())

# # 关闭对话框
func close_dialogue() -> void:
	visible = false
	if player_controller and player_controller.has_method("end_dialogue"):
		player_controller.end_dialogue()
	emit_signal("dialogue_closed")

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state) -> void:
	print("对话框检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	
	# 如果玩家状态不是对话状态，隐藏对话框
	if new_state != 1 and visible:  # 1 是 DIALOGUE 状态
		hide_dialogue()

# 隐藏对话框
func hide_dialogue() -> void:
	print("隐藏对话框")
	visible = false
	$Panel.hide()
	$Panel/NameLabel.hide()
	$Panel/TextLabel.hide()
	$ChoicesContainer.hide()
	$ContinueLabel.hide()
	
	# 隐藏所有选择按钮
	for button in $ChoicesContainer.get_children():
		button.hide()
	
	# 发出对话关闭信号
	emit_signal("dialogue_closed")
