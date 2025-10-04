extends CanvasLayer

@onready var title_label: Label = $Panel/TitleLabel
@onready var desc_label: Label = $Panel/DescLabel
@onready var panel: Panel = $Panel

var display_time := 5.0
var is_showing := false
var current_tween: Tween = null

func _ready():
	panel.visible = false

func show_task(title: String, desc: String):
	# 先取消旧的 Tween，立即隐藏旧任务
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	panel.visible = false
	await get_tree().process_frame
	# 显示新任务
	title_label.text = title
	desc_label.text = desc
	panel.visible = true
	panel.modulate.a = 1.0
	is_showing = true
	current_tween = create_tween()
	current_tween.tween_property(panel, "modulate:a", 0.0, 1.0).set_delay(display_time)
	await current_tween.finished
	panel.visible = false
	is_showing = false
	current_tween = null

func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"): # Tab键，随时可查看
		# 先取消旧的 Tween
		if current_tween and current_tween.is_valid():
			current_tween.kill()
		panel.visible = true
		panel.modulate.a = 1.0
		is_showing = true
		current_tween = create_tween()
		current_tween.tween_property(panel, "modulate:a", 0.0, 1.0).set_delay(display_time)
		await current_tween.finished
		panel.visible = false
		is_showing = false
		current_tween = null
