extends CanvasLayer

signal dialogue_advanced
signal choice_selected(index)
signal dialogue_closed

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var choices_container: VBoxContainer = $Panel/ChoicesContainer

var choices = []
var is_monologue := false
var is_typing := false
var full_text := ""
var current_char := 0
var typewriter_speed := 0.05 # 打字速度（秒/字符）

# 显示对话（NPC对话）
func show_dialogue(npc_name: String, text: String, choices_array := []):
	is_monologue = false
	name_label.text = npc_name
	name_label.modulate = Color(0.85, 0.75, 0.7, 1) # NPC对话：暖白色
	full_text = text
	choices = choices_array
	start_typewriter()
	# 清空旧的选项按钮
	for child in choices_container.get_children():
		child.queue_free()
	if choices.size() > 0:
		# 有选项，显示选项按钮
		choices_container.visible = true
		for i in choices.size():
			var btn = create_styled_button(choices[i]["text"])
			btn.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(btn)
	else:
		# 无选项，添加"继续"按钮
		choices_container.visible = true
		var continue_btn = create_styled_button("继续 >")
		continue_btn.pressed.connect(_on_continue_pressed)
		choices_container.add_child(continue_btn)

# 显示心理独白（物品互动）
func show_monologue(text: String):
	is_monologue = true
	name_label.text = "● 内心独白 ●"
	name_label.modulate = Color(0.85, 0.25, 0.3, 1) # 心理独白：暗红色
	full_text = "[i]" + text + "[/i]" # 斜体
	choices = []
	start_typewriter(0.04) # 心理独白打字稍慢，增强压迫感
	# 清空旧的选项按钮
	for child in choices_container.get_children():
		child.queue_free()
	# 添加"继续"按钮
	choices_container.visible = true
	var continue_btn = create_styled_button("继续 >")
	continue_btn.pressed.connect(_on_monologue_close_pressed)
	choices_container.add_child(continue_btn)

# 创建恐怖风格按钮
func create_styled_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(280, 45)
	# 应用按钮样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.35, 0.1, 0.15, 0.8)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.35, 0.12, 0.16, 1)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.7, 0.2, 0.25, 1)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.9, 1))
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _on_choice_pressed(index):
	# 选择分支时，如果还在打字，先跳过动画
	if is_typing:
		skip_typewriter()
		return
	emit_signal("choice_selected", index)

func _on_continue_pressed():
	# 如果还在打字，先跳过动画显示全部文字
	if is_typing:
		skip_typewriter()
		return
	# 文字已完整显示，推进对话
	emit_signal("dialogue_advanced")

func _on_monologue_close_pressed():
	# 如果还在打字，先跳过动画显示全部文字
	if is_typing:
		skip_typewriter()
		return
	# 文字已完整显示，关闭对话框
	emit_signal("dialogue_closed")
	queue_free()

# 开始打字机效果
func start_typewriter(speed: float = 0.05):
	typewriter_speed = speed
	current_char = 0
	is_typing = true
	text_label.visible_characters = 0
	text_label.text = full_text
	_typewriter_step()

# 打字机逐字显示
func _typewriter_step():
	if not is_typing:
		return
	if current_char < full_text.length():
		current_char += 1
		text_label.visible_characters = current_char
		# 占位：播放打字音效
		# play_typing_sound()
		# 继续下一个字符
		await get_tree().create_timer(typewriter_speed).timeout
		_typewriter_step()
	else:
		# 打字完成
		is_typing = false
		text_label.visible_characters = -1 # 显示全部

# 跳过打字动画（点击时）
func skip_typewriter():
	if is_typing:
		is_typing = false
		current_char = full_text.length()
		text_label.visible_characters = -1
		text_label.text = full_text

# 占位：播放打字音效
func play_typing_sound():
	# 后续可接入 AudioManager
	pass

func _input(event):
	# 点击任意键跳过打字动画
	if is_typing and event is InputEventMouseButton and event.pressed:
		skip_typewriter()
