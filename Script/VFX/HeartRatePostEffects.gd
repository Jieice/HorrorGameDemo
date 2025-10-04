extends Node

## 心率后处理效果管理器
## 根据心率水平应用视觉效果（暗角、色差、晃动等）
## 作者：AI Assistant
## 日期：2025-10-04

# 心率阈值
@export var normal_threshold: float = 100.0
@export var elevated_threshold: float = 120.0
@export var stressed_threshold: float = 130.0
@export var panic_threshold: float = 140.0

# 效果强度（0.0-1.0）
var vignette_intensity: float = 0.0
var chromatic_aberration: float = 0.0
var shake_intensity: float = 0.0
var desaturation: float = 0.0

# 相机引用
var camera: Camera3D
var post_process_material: ShaderMaterial

# 平滑过渡
var target_vignette: float = 0.0
var target_chromatic: float = 0.0
var target_shake: float = 0.0
var target_desaturation: float = 0.0

# 过渡速度
@export var transition_speed: float = 2.0

func _ready():
	print("[HeartRatePostEffects] 心率后处理效果管理器已初始化")

	# 延迟获取相机引用，因为相机可能在场景加载后才创建
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	if not camera:
		print("[HeartRatePostEffects] 警告：未找到相机节点")
	else:
		# 创建后处理材质
		_create_post_process_material()

	# 连接心率系统信号
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.heart_rate_changed.connect(_on_heart_rate_changed)
		heart_rate_sys.stress_level_changed.connect(_on_stress_level_changed)

func _process(delta: float):
	# 平滑过渡效果强度
	vignette_intensity = lerp(vignette_intensity, target_vignette, delta * transition_speed)
	chromatic_aberration = lerp(chromatic_aberration, target_chromatic, delta * transition_speed)
	shake_intensity = lerp(shake_intensity, target_shake, delta * transition_speed)
	desaturation = lerp(desaturation, target_desaturation, delta * transition_speed)

	# 应用效果
	_apply_effects()

	# 应用相机晃动
	_apply_camera_shake(delta)

## 创建后处理材质
func _create_post_process_material():
	if not camera:
		return

	# 创建ColorRect作为后处理层
	var post_process_rect = ColorRect.new()
	post_process_rect.name = "HeartRatePostEffects"
	post_process_rect.anchor_right = 1.0
	post_process_rect.anchor_bottom = 1.0
	post_process_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建着色器材质
	var shader_code = """
	shader_type canvas_item;

	uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
	uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
	uniform float chromatic_aberration : hint_range(0.0, 0.1) = 0.0;
	uniform float desaturation : hint_range(0.0, 1.0) = 0.0;

	void fragment() {
		vec2 uv = SCREEN_UV;

		// 暗角效果
		float vignette = 1.0 - vignette_intensity * (1.0 - length(uv - 0.5));
		COLOR.rgb *= vignette;

		// 色差效果
		if (chromatic_aberration > 0.0) {
			float aberration = chromatic_aberration * (length(uv - 0.5) * 2.0);
			COLOR.r = texture(SCREEN_TEXTURE, uv + vec2(aberration, 0.0)).r;
			COLOR.g = texture(SCREEN_TEXTURE, uv).g;
			COLOR.b = texture(SCREEN_TEXTURE, uv - vec2(aberration, 0.0)).b;
		}

		// 去饱和效果
		if (desaturation > 0.0) {
			float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
			COLOR.rgb = mix(COLOR.rgb, vec3(gray), desaturation);
		}
	}
	"""

	var shader = Shader.new()
	shader.code = shader_code

	post_process_material = ShaderMaterial.new()
	post_process_material.shader = shader

	post_process_rect.material = post_process_material

	# 添加到相机
	camera.add_child(post_process_rect)
	print("[HeartRatePostEffects] 后处理材质已创建并应用")

## 应用效果到材质
func _apply_effects():
	if not post_process_material:
		return

	post_process_material.set_shader_parameter("vignette_intensity", vignette_intensity)
	post_process_material.set_shader_parameter("chromatic_aberration", chromatic_aberration)
	post_process_material.set_shader_parameter("desaturation", desaturation)

## 应用相机晃动
func _apply_camera_shake(delta: float):
	if not camera or shake_intensity <= 0.0:
		return

	# 生成随机晃动偏移
	var shake_offset = Vector3(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity),
		0
	)

	camera.position += shake_offset

## 心率变化回调
func _on_heart_rate_changed(new_rate: float):
	_update_effects_based_on_heart_rate(new_rate)

## 压力等级变化回调
func _on_stress_level_changed(level: String):
	print("[HeartRatePostEffects] 压力等级变化: %s" % level)

## 根据心率更新效果
func _update_effects_based_on_heart_rate(heart_rate: float):
	var normalized_rate = clamp(heart_rate / panic_threshold, 0.0, 1.0)

	if heart_rate <= normal_threshold:
		# 正常状态：无效果
		target_vignette = 0.0
		target_chromatic = 0.0
		target_shake = 0.0
		target_desaturation = 0.0

	elif heart_rate <= elevated_threshold:
		# 轻度紧张：轻微暗角和去饱和
		target_vignette = normalized_rate * 0.2
		target_chromatic = 0.0
		target_shake = 0.0
		target_desaturation = normalized_rate * 0.1

	elif heart_rate <= stressed_threshold:
		# 压力状态：中等暗角、轻微色差和小晃动
		target_vignette = 0.2 + normalized_rate * 0.3
		target_chromatic = normalized_rate * 0.02
		target_shake = normalized_rate * 0.05
		target_desaturation = 0.1 + normalized_rate * 0.2

	else:
		# 恐慌状态：强烈效果
		target_vignette = 0.5 + normalized_rate * 0.3
		target_chromatic = 0.02 + normalized_rate * 0.03
		target_shake = 0.05 + normalized_rate * 0.1
		target_desaturation = 0.3 + normalized_rate * 0.3

	print("[HeartRatePostEffects] 心率 %.1f -> 暗角: %.2f, 色差: %.3f, 晃动: %.3f, 去饱和: %.2f" %
		[heart_rate, target_vignette, target_chromatic, target_shake, target_desaturation])

## 重置所有效果
func reset_effects():
	target_vignette = 0.0
	target_chromatic = 0.0
	target_shake = 0.0
	target_desaturation = 0.0

	print("[HeartRatePostEffects] 所有效果已重置")

## 获取当前效果强度
func get_effect_intensities() -> Dictionary:
	return {
		"vignette": vignette_intensity,
		"chromatic_aberration": chromatic_aberration,
		"shake": shake_intensity,
		"desaturation": desaturation
	}
