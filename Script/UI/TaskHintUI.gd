extends CanvasLayer

signal hint_displayed(hint_text)
signal hint_hidden

@onready var hint_container = $MarginContainer
@onready var hint_label = $MarginContainer/VBoxContainer/HintLabel
@onready var task_list_container = $MarginContainer/VBoxContainer/TaskListContainer
@onready var task_item_template = $MarginContainer/VBoxContainer/TaskListContainer/TaskItem

var task_manager: Node
var player_controller: Node
var is_visible: bool = false
var current_hints: Array = []

func _ready():
	# 隐藏模板
	if task_item_template:
		task_item_template.visible = false
	
	# 初始隐藏UI
	hide_hints()
	
	# 调整任务提示位置，避免与FPS重叠
	if hint_container:
		# 设置位置为左上角，但在FPS下方（假设FPS高度约30像素）
		hint_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hint_container.position = Vector2(10, 50)  # FPS下方40像素处
		hint_container.size = Vector2(300, 200)  # 设置合适的大小

func _process(delta):
	# 检查是否应该显示提示（例如，当玩家按下某个键时）
	if Input.is_action_just_pressed("toggle_tasks"):
		# 只有在正常状态下才能切换任务提示显示
		if player_controller and player_controller.current_state == player_controller.PlayerState.NORMAL:
			toggle_hint_display()
		elif is_visible:
			# 如果当前显示提示但玩家不在正常状态，则隐藏提示
			hide_hints()

# 切换提示显示状态
func toggle_hint_display():
	if is_visible:
		hide_hints()
	else:
		show_hints()

# 显示提示
func show_hints():
	if task_manager:
		current_hints = task_manager.get_all_active_hints()
		update_hint_display()
	
	if hint_container:
		hint_container.visible = true
		is_visible = true
		emit_signal("hint_displayed", "")

# 隐藏提示
func hide_hints():
	if hint_container:
		hint_container.visible = false
		is_visible = false
		emit_signal("hint_hidden")

# 更新提示显示
func update_hint_display():
	# 确保task_list_container和task_item_template存在
	if not task_list_container:
		print("错误: task_list_container 为空")
		return
	
	if not task_item_template:
		print("错误: task_item_template 为空")
		return
	
	# 清除现有任务项
	for child in task_list_container.get_children():
		if child != task_item_template:
			child.queue_free()
	
	# 如果没有提示，显示默认文本
	if current_hints.is_empty():
		hint_label.text = "当前没有活跃任务"
		return
	
	# 更新主提示文本
	if current_hints.size() > 0 and hint_label:
		hint_label.text = current_hints[0]
	
	# 添加所有任务项
	for i in range(current_hints.size()):
		var task_item = task_item_template.duplicate()
		task_item.text = current_hints[i]
		task_item.visible = true
		task_list_container.add_child(task_item)

# 当任务更新时调用
func _on_task_updated(task_id: String, status: String):
	if task_manager:
		current_hints = task_manager.get_all_active_hints()
		if is_visible:
			update_hint_display()

# 当新任务添加时调用
func _on_new_task_added(task_id: String):
	if task_manager:
		var task = task_manager.get_task(task_id)
		if task and task.active:
			current_hints = task_manager.get_all_active_hints()
			if is_visible:
				update_hint_display()
			
			# 可以在这里添加新任务通知效果
			show_new_task_notification(task.title)

# 当任务完成时调用
func _on_task_completed(task_id: String):
	if task_manager:
		current_hints = task_manager.get_all_active_hints()
		if is_visible:
			update_hint_display()
		
		# 可以在这里添加任务完成通知效果
		var task = task_manager.get_task(task_id)
		if task:
			show_task_completed_notification(task.title)

# 显示新任务通知
func show_new_task_notification(task_title: String):
	# 创建一个漂亮的新任务通知面板
	var notification_panel = Panel.new()
	notification_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_panel.position.y = 20
	notification_panel.size.y = 60
	notification_panel.size.x = 400
	notification_panel.position.x = (get_viewport().get_visible_rect().size.x - notification_panel.size.x) / 2
	
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_box.border_width_bottom = 2
	style_box.border_width_top = 2
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_color = Color(1, 0.8, 0, 1)  # 金色边框
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	notification_panel.add_theme_stylebox_override("panel", style_box)
	
	# 创建一个HBoxContainer来放置图标和文本
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 5
	hbox.offset_bottom = -5
	notification_panel.add_child(hbox)
	
	# 添加新任务图标（使用RichTextLabel显示一个!符号）
	var icon = RichTextLabel.new()
	icon.bbcode_enabled = true
	icon.text = "[font_size=24][color=yellow]![/color][/font_size]"
	icon.fit_content = true
	icon.size.x = 30
	icon.size.y = 30
	icon.custom_minimum_size = Vector2(30, 30)
	hbox.add_child(icon)
	
	# 添加新任务文本
	var text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.text = "[font_size=18][color=yellow]新任务:[/color][/font_size] [font_size=16]" + task_title + "[/font_size]"
	text.fit_content = true
	text.size.y = 50
	text.custom_minimum_size = Vector2(0, 50)
	hbox.add_child(text)
	
	# 添加到场景
	add_child(notification_panel)
	
	# 添加动画效果
	var tween = create_tween()
	notification_panel.modulate.a = 0
	tween.tween_property(notification_panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 0.5)
	
	# 动画完成后移除通知
	await tween.finished
	if is_instance_valid(notification_panel):
		notification_panel.queue_free()
	
	print("新任务: ", task_title)

# 显示任务完成通知
func show_task_completed_notification(task_title: String):
	# 创建一个漂亮的任务完成通知面板
	var notification_panel = Panel.new()
	notification_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_panel.position.y = 20
	notification_panel.size.y = 60
	notification_panel.size.x = 400
	notification_panel.position.x = (get_viewport().get_visible_rect().size.x - notification_panel.size.x) / 2
	
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_box.border_width_bottom = 2
	style_box.border_width_top = 2
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_color = Color(0, 0.8, 0, 1)
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	notification_panel.add_theme_stylebox_override("panel", style_box)
	
	# 创建一个HBoxContainer来放置图标和文本
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 5
	hbox.offset_bottom = -5
	notification_panel.add_child(hbox)
	
	# 添加任务完成图标（使用RichTextLabel显示一个✓符号）
	var icon = RichTextLabel.new()
	icon.bbcode_enabled = true
	icon.text = "[font_size=24][color=lime]✓[/color][/font_size]"
	icon.fit_content = true
	icon.size.x = 30
	icon.size.y = 30
	icon.custom_minimum_size = Vector2(30, 30)
	hbox.add_child(icon)
	
	# 添加任务完成文本
	var text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.text = "[font_size=18][color=lime]任务完成:[/color][/font_size] [font_size=16]" + task_title + "[/font_size]"
	text.fit_content = true
	text.size.y = 50
	text.custom_minimum_size = Vector2(0, 50)
	hbox.add_child(text)
	
	# 添加到场景
	add_child(notification_panel)
	
	# 添加动画效果
	var tween = create_tween()
	notification_panel.modulate.a = 0
	tween.tween_property(notification_panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 0.5)
	
	# 动画完成后移除通知
	await tween.finished
	if is_instance_valid(notification_panel):
		notification_panel.queue_free()
	
	print("任务完成: ", task_title)

# 设置自定义提示文本（临时显示）
func show_custom_hint(text: String, duration: float = 3.0):
	var original_hints = current_hints
	current_hints = [text]
	update_hint_display()
	
	if not is_visible:
		show_hints()
	
	# 指定时间后恢复原始提示
	await get_tree().create_timer(duration).timeout
	current_hints = original_hints
	if is_visible:
		update_hint_display()
	else:
		hide_hints()

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state):
	# 根据玩家状态控制任务提示显示
	print("任务提示UI检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	match new_state:
		0: # NORMAL
			# 玩家恢复正常状态，可以显示任务提示
			pass
		1: # DIALOGUE
			# 玩家进入对话状态，隐藏任务提示
			if is_visible:
				hide_hints()
		2: # PAUSED
			# 游戏暂停，隐藏任务提示
			if is_visible:
				hide_hints()
		3: # IN_MENU
			# 玩家在菜单中，隐藏任务提示
			if is_visible:
				hide_hints()
		4: # IN_CUTSCENE
			# 玩家在过场动画中，隐藏任务提示
			if is_visible:
				hide_hints()
		_:
			# 未知状态，隐藏任务提示
			if is_visible:
				hide_hints()
