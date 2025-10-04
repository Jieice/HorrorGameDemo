extends Node

# 面具完整度管理器
# 初始状态：0%（代表主角的真实自我）
# 增长机制：每当玩家选择逃避、沉默或顺从，面具完整度上升
# 影响：低完整度=痛苦/愤怒，高完整度=麻木/冷酷
# 结局判定：超过80%强制进入"完全蜕变"结局

signal mask_changed(new_value: int)

var mask_integrity: int = 0 # 当前面具完整度 (0-100)

# 改变面具完整度
func change_integrity(delta: int):
	var old_value = mask_integrity
	mask_integrity = clamp(mask_integrity + delta, 0, 100)
	if mask_integrity != old_value:
		emit_signal("mask_changed", mask_integrity)
		# 播放面具变化音效
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.play_sfx("mask_change", -5.0)
		# 更新UI
		update_ui()

# 获取当前面具完整度
func get_integrity() -> int:
	return mask_integrity

# 获取当前面具阶段（0-4）
func get_mask_stage() -> int:
	if mask_integrity < 25:
		return 0
	elif mask_integrity < 50:
		return 1
	elif mask_integrity < 75:
		return 2
	elif mask_integrity < 100:
		return 3
	else:
		return 4

# 获取当前面具图标路径
func get_mask_icon() -> String:
	var stage = get_mask_stage()
	match stage:
		0: return "res://Assets/Textures/Masks/mask_0.png"
		1: return "res://Assets/Textures/Masks/mask_25.png"
		2: return "res://Assets/Textures/Masks/mask_50.png"
		3: return "res://Assets/Textures/Masks/mask_75.png"
		4: return "res://Assets/Textures/Masks/mask_100.png"
		_: return "res://Assets/Textures/Masks/mask_0.png"

# 更新UI
func update_ui():
	var ui = get_node_or_null("/root/MaskUI")
	if ui:
		ui.update_mask(mask_integrity, get_mask_icon())
