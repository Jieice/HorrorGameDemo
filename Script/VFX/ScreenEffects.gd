extends CanvasLayer

# 根据恐怖游戏设计原则：
# 1. 环境和音效优先于视觉特效
# 2. "少即是多"，克制使用
# 3. 细微的持续压迫感，而不是强烈冲击

# 恐怖氛围主要通过：昏暗灯光、环境音、对话、剧情来营造

@onready var brightness_overlay: ColorRect = $BrightnessOverlay

func _ready():
	# 确保亮度遮罩初始化为透明
	if brightness_overlay:
		brightness_overlay.color = Color(1, 1, 1, 0)
		brightness_overlay.visible = true

# 应用亮度效果（用于列车白光等）
func apply_brightness(brightness: float, duration: float = 0.0):
	if not brightness_overlay:
		return
	
	# brightness: 0.0 = 无效果，1.0 = 正常，2.0+ = 增亮（白光效果）
	var alpha = clamp((brightness - 1.0), 0.0, 1.0)
	
	if duration > 0:
		var tween = create_tween()
		tween.tween_property(brightness_overlay, "color:a", alpha, duration)
	else:
		brightness_overlay.color.a = alpha

# 重置亮度效果
func reset_brightness(duration: float = 0.5):
	apply_brightness(1.0, duration)

# 预留接口，后续根据需要逐步添加
func vfx_subtle():
	pass

func vfx_medium():
	pass

func vfx_hallucination():
	pass

func vfx_horror_reveal():
	pass
