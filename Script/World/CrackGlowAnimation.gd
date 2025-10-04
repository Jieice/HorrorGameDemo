extends Node3D

## 裂痕发光动画
## 当环境崩解时，裂痕开始发光
## 作者：AI Assistant
## 日期：2025-10-04

@export var glow_intensity: float = 2.0 # 发光强度
@export var pulse_speed: float = 1.0 # 脉动速度

var is_glowing: bool = false
var glow_timer: float = 0.0
var light_component: OmniLight3D

func _ready():
	print("[CrackGlowAnimation] 裂痕发光动画已准备好")

	# 查找灯光组件
	light_component = find_child("CrackLight", true, false)

	if not light_component:
		print("[CrackGlowAnimation] 警告：未找到裂痕灯光组件")

func _process(delta: float):
	if not is_glowing:
		return

	glow_timer += delta

	# 脉动发光效果
	var pulse = (sin(glow_timer * pulse_speed) + 1.0) * 0.5 # 0.0-1.0范围
	var current_intensity = glow_intensity * (0.5 + pulse * 0.5)

	if light_component:
		light_component.light_energy = current_intensity
		light_component.omni_range = 3.0 + pulse * 2.0 # 范围也随之变化

		# 颜色从橙色到红色变化
		var color_progress = pulse
		var light_color = Color(1.0, 0.3 + color_progress * 0.7, 0.0) # 橙红色
		light_component.light_color = light_color

## 开始发光动画
func start_glow_animation():
	if is_glowing:
		return

	print("[CrackGlowAnimation] 开始裂痕发光动画")
	is_glowing = true
	glow_timer = 0.0

	if light_component:
		light_component.visible = true
		light_component.light_energy = 0.0 # 从无光开始

	# 播放崩解音效
	if AudioManager:
		AudioManager.play_sfx("chaos_soundwall")

## 停止发光动画
func stop_glow_animation():
	is_glowing = false

	if light_component:
		light_component.visible = false

	print("[CrackGlowAnimation] 裂痕发光动画已停止")

## 重置动画
func reset():
	is_glowing = false
	glow_timer = 0.0

	if light_component:
		light_component.visible = false
		light_component.light_energy = 0.0

	print("[CrackGlowAnimation] 裂痕发光动画已重置")
