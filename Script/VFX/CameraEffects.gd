extends Node

# 摄像机特效
# 根据恐怖游戏设计原则：细微、克制、关键时刻才用

# FOV轻微收窄（对话时营造压迫感）
func fov_dialogue_start(camera: Camera3D, intensity: float = 3.0, duration: float = 1.5):
	if not camera:
		return
	var original_fov = camera.fov
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	# 视野轻微收窄
	tween.tween_property(camera, "fov", original_fov - intensity, duration)

# FOV恢复（对话结束）
func fov_dialogue_end(camera: Camera3D, original_fov: float, duration: float = 1.5):
	if not camera:
		return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "fov", original_fov, duration)

# FOV呼吸（心理压迫）
func fov_breathe(camera: Camera3D, intensity: float = 5.0, duration: float = 2.0):
	if not camera:
		return
	var original_fov = camera.fov
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	# 视野收窄
	tween.tween_property(camera, "fov", original_fov - intensity, duration * 0.5)
	# 恢复
	tween.tween_property(camera, "fov", original_fov, duration * 0.5)

# FOV冲击（幻觉）
func fov_impact(camera: Camera3D, intensity: float = 8.0, duration: float = 0.4):
	if not camera:
		return
	var original_fov = camera.fov
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	# 快速扩大
	tween.tween_property(camera, "fov", original_fov + intensity, duration * 0.3)
	# 恢复
	tween.tween_property(camera, "fov", original_fov, duration * 0.7)

# 幻觉冲击组合
func hallucination_impact(camera: Camera3D, camera_parent: Node3D):
	fov_impact(camera, 6.0, 0.3)

# 摄像机倾斜
func tilt(camera_parent: Node3D, angle: float = 2.0, duration: float = 1.0):
	if not camera_parent:
		return
	var original_rot = camera_parent.rotation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_parent, "rotation:z", deg_to_rad(angle), duration * 0.5)
	tween.tween_property(camera_parent, "rotation:z", original_rot.z, duration * 0.5)
