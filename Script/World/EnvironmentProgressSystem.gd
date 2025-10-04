extends Node

## 环境进度系统
## 根据玩家调查物品数量，触发环境渐变效果
## 作者：AI Assistant
## 日期：2025-10-04

# 进度阶段
enum ProgressStage {
	NORMAL, # 0个物品：正常
	STAGE_1, # 1个物品：水渍扩散
	STAGE_2, # 2个物品：墙皮脱落
	STAGE_3, # 3个物品：天花板扭曲
	COLLAPSE # 全部完成：空间崩解
}

# 当前状态
var current_stage: ProgressStage = ProgressStage.NORMAL
var items_investigated: int = 0
var total_items: int = 3 # 序章有3个主要物品

# 环境对象引用（需要在场景中设置）
var water_stain_objects: Array[Node3D] = []
var wall_peel_objects: Array[Node3D] = []
var ceiling_objects: Array[Node3D] = []
var crack_lights: Array[Node3D] = []

# 信号
signal stage_changed(new_stage: ProgressStage)
signal item_investigated(count: int, total: int)

func _ready():
	print("[EnvironmentProgressSystem] 环境进度系统已初始化")

	# 注册环境动画对象
	_register_environment_objects()

## 注册环境动画对象
func _register_environment_objects():
	# 水渍对象注册
	var water_stain = find_child("WaterStain", true, false)
	if water_stain:
		register_water_stain(water_stain)

	# 墙皮对象注册
	var wall_peel = find_child("WallPeel", true, false)
	if wall_peel:
		register_wall_peel(wall_peel)

	# 天花板对象注册
	var ceiling = find_child("CeilingDistortion", true, false)
	if ceiling:
		register_ceiling(ceiling)

	# 裂痕光对象注册
	var crack_light = find_child("CrackLight", true, false)
	if crack_light:
		register_crack_light(crack_light)

	print("[EnvironmentProgressSystem] 已注册 %d 个水渍对象，%d 个墙皮对象，%d 个天花板对象，%d 个裂痕光对象" %
		[water_stain_objects.size(), wall_peel_objects.size(), ceiling_objects.size(), crack_lights.size()])

## 物品调查完成
func on_item_investigated():
	items_investigated += 1
	item_investigated.emit(items_investigated, total_items)
	print("[EnvironmentProgressSystem] 物品调查进度: %d/%d" % [items_investigated, total_items])
	
	# 更新阶段
	_update_stage()

## 更新环境阶段
func _update_stage():
	var new_stage: ProgressStage
	
	match items_investigated:
		0:
			new_stage = ProgressStage.NORMAL
		1:
			new_stage = ProgressStage.STAGE_1
		2:
			new_stage = ProgressStage.STAGE_2
		3:
			new_stage = ProgressStage.STAGE_3
		_:
			if items_investigated >= total_items:
				new_stage = ProgressStage.COLLAPSE
			else:
				return
	
	if new_stage != current_stage:
		current_stage = new_stage
		stage_changed.emit(new_stage)
		print("[EnvironmentProgressSystem] 阶段变化: %s" % _get_stage_name(new_stage))
		
		# 触发环境变化
		_apply_stage_effects()

## 应用阶段效果
func _apply_stage_effects():
	match current_stage:
		ProgressStage.NORMAL:
			_apply_normal_effects()
		ProgressStage.STAGE_1:
			_apply_stage1_effects()
		ProgressStage.STAGE_2:
			_apply_stage2_effects()
		ProgressStage.STAGE_3:
			_apply_stage3_effects()
		ProgressStage.COLLAPSE:
			_apply_collapse_effects()

## 阶段0：正常
func _apply_normal_effects():
	print("[EnvironmentProgressSystem] 应用效果：正常状态")

## 阶段1：水渍扩散
func _apply_stage1_effects():
	print("[EnvironmentProgressSystem] 应用效果：水渍扩散")
	
	# 显示/动画化水渍
	for obj in water_stain_objects:
		if obj and obj.has_method("start_spreading"):
			obj.start_spreading()
	
	# 播放环境音效
	if AudioManager:
		AudioManager.play_sfx("water_drip_echo")

## 阶段2：墙皮脱落
func _apply_stage2_effects():
	print("[EnvironmentProgressSystem] 应用效果：墙皮脱落")
	
	# 显示墙皮脱落效果
	for obj in wall_peel_objects:
		if obj and obj.has_method("start_peeling"):
			obj.start_peeling()
	
	# 播放音效
	if AudioManager:
		AudioManager.play_sfx("wall_crack")
	
	# 增加灯光闪烁
	if LightingController:
		LightingController.set_flicker_intensity(0.3)

## 阶段3：天花板扭曲
func _apply_stage3_effects():
	print("[EnvironmentProgressSystem] 应用效果：天花板扭曲")
	
	# 天花板效果
	for obj in ceiling_objects:
		if obj and obj.has_method("start_distortion"):
			obj.start_distortion()
	
	# 播放音效
	if AudioManager:
		AudioManager.play_sfx("wall_knock")
		AudioManager.play_sfx("low_frequency_hum", 0.3) # 低音量循环
	
	# 更强的灯光不稳定
	if LightingController:
		LightingController.set_flicker_intensity(0.5)

## 阶段4：空间崩解
func _apply_collapse_effects():
	print("[EnvironmentProgressSystem] 应用效果：空间崩解")
	
	# 裂痕发光
	for light in crack_lights:
		if light:
			light.visible = true
			if light.has_method("start_glow_animation"):
				light.start_glow_animation()
	
	# 播放崩解音效
	if AudioManager:
		AudioManager.play_sfx("wall_crack")
	
	# 最大灯光不稳定
	if LightingController:
		LightingController.set_flicker_intensity(0.8)

## 注册环境对象
func register_water_stain(object: Node3D):
	if object not in water_stain_objects:
		water_stain_objects.append(object)

func register_wall_peel(object: Node3D):
	if object not in wall_peel_objects:
		wall_peel_objects.append(object)

func register_ceiling(object: Node3D):
	if object not in ceiling_objects:
		ceiling_objects.append(object)

func register_crack_light(object: Node3D):
	if object not in crack_lights:
		crack_lights.append(object)

## 重置系统
func reset():
	items_investigated = 0
	current_stage = ProgressStage.NORMAL
	print("[EnvironmentProgressSystem] 已重置")

## 获取阶段名称
func _get_stage_name(stage: ProgressStage) -> String:
	match stage:
		ProgressStage.NORMAL:
			return "正常"
		ProgressStage.STAGE_1:
			return "水渍扩散"
		ProgressStage.STAGE_2:
			return "墙皮脱落"
		ProgressStage.STAGE_3:
			return "天花板扭曲"
		ProgressStage.COLLAPSE:
			return "空间崩解"
		_:
			return "未知"

## 获取当前进度百分比
func get_progress_percentage() -> float:
	return float(items_investigated) / float(total_items) * 100.0
