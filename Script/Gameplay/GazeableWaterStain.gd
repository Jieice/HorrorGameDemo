extends MeshInstance3D

## 可注视的水渍
## 盯着看3秒后逐渐形成眼睛的形状
## 作者：AI Assistant
## 日期：2025-10-04

@export var eye_texture: Texture2D # 眼睛纹理（需要准备）
@export var morph_duration: float = 2.0 # 变形持续时间

var is_morphing: bool = false
var morph_progress: float = 0.0
var has_triggered: bool = false
var original_material: Material

func _ready():
	# 自动注册为可注视对象
	add_to_group("gazeable")
	
	# 保存原始材质
	if get_surface_override_material_count() > 0:
		original_material = get_surface_override_material(0)
	
	print("[GazeableWaterStain] 水渍已准备好，等待玩家注视...")

func _process(delta: float):
	# 如果正在变形，逐渐改变材质
	if is_morphing:
		morph_progress += delta / morph_duration
		morph_progress = min(morph_progress, 1.0)
		
		# 更新材质透明度或混合参数
		_update_material_morph(morph_progress)

## 当玩家注视3秒后触发
func _on_gaze_triggered():
	if has_triggered:
		return
	
	has_triggered = true
	print("[GazeableWaterStain] 玩家注视触发！水渍开始变形...")
	
	# 开始变形
	is_morphing = true
	morph_progress = 0.0
	
	# 播放水滴回音声
	if AudioManager:
		AudioManager.play_sfx("water_drip_echo", -12.0)
	
	# 增加心率
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(15.0)
	
	# 等待变形完成
	await get_tree().create_timer(morph_duration).timeout
	
	print("[GazeableWaterStain] 变形完成！形成眼睛形状")
	
	# 再次增加心率
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(10.0)

## 更新材质变形效果
func _update_material_morph(progress: float):
	# 这里需要根据实际材质类型来实现
	# 简单示例：改变材质的颜色或透明度
	if get_surface_override_material_count() > 0:
		var mat = get_surface_override_material(0)
		if mat is StandardMaterial3D:
			# 逐渐显示眼睛纹理或改变颜色
			var color = Color.WHITE
			color.a = progress
			mat.albedo_color = color

## 重置状态
func reset():
	is_morphing = false
	morph_progress = 0.0
	has_triggered = false
	
	# 恢复原始材质
	if original_material:
		set_surface_override_material(0, original_material)
	
	print("[GazeableWaterStain] 已重置")
