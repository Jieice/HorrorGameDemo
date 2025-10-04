extends CanvasLayer

# 场景淡入淡出过渡效果

@onready var fade_rect: ColorRect = $FadeRect

signal transition_finished

# 淡出（变黑）
func fade_out(duration: float = 1.0, color: Color = Color.BLACK):
	fade_rect.color = color
	fade_rect.modulate.a = 0.0
	fade_rect.visible = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

# 淡入（变亮）
func fade_in(duration: float = 1.0):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	fade_rect.visible = false
	emit_signal("transition_finished")

# 场景切换（淡出 → 切换 → 淡入）
func change_scene(scene_path: String, fade_out_time: float = 1.0, fade_in_time: float = 1.5):
	# 淡出
	await fade_out(fade_out_time)
	# 切换场景
	get_tree().change_scene_to_file(scene_path)
	# 等待场景加载
	await get_tree().process_frame
	await get_tree().process_frame
	# 淡入
	await fade_in(fade_in_time)
