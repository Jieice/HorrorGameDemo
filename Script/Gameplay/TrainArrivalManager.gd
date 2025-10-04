extends Node

## 列车到站管理器
## 控制序章结尾的列车到站高潮序列
## 作者：AI Assistant
## 日期：2025-10-04

# 列车到站阶段枚举
enum TrainStage {
	IDLE,           # 等待开始
	APPROACHING,    # 列车接近（远处汽笛+灯光闪烁）
	LIGHTS_FLICKER, # 灯光剧烈闪烁
	SCREEN_SHAKE,   # 画面剧烈震动
	TRAIN_PASSING,  # 列车呼啸而过（白光+音效）
	AFTERGLOW       # 余光渐暗，进入下一场景
}

# 当前阶段
var current_stage: TrainStage = TrainStage.IDLE
var stage_timer: float = 0.0

# 阶段持续时间（秒）
@export var stage_durations: Array[float] = [
	0.0,   # IDLE
	3.0,   # APPROACHING
	2.0,   # LIGHTS_FLICKER
	1.5,   # SCREEN_SHAKE
	2.0,   # TRAIN_PASSING
	3.0    # AFTERGLOW
]

# 信号
signal stage_changed(new_stage: TrainStage)
signal sequence_started()
signal sequence_ended()

# 引用
var camera: Camera3D
var lighting_controller: Node
var audio_manager: Node
var screen_effects: Node

func _ready():
	print("[TrainArrivalManager] 列车到站管理器已初始化")

func _process(delta: float):
	if current_stage == TrainStage.IDLE:
		return

	stage_timer += delta

	# 检查是否需要进入下一阶段
	var current_duration = stage_durations[current_stage]
	if stage_timer >= current_duration:
		_next_stage()

	# 根据当前阶段执行效果
	_update_stage_effects(delta)

## 开始列车到站序列
func start_sequence():
	if current_stage != TrainStage.IDLE:
		return

	print("[TrainArrivalManager] ===== 列车到站序列开始 =====")
	current_stage = TrainStage.APPROACHING
	stage_timer = 0.0

	# 获取引用
	camera = get_viewport().get_camera_3d()
	lighting_controller = get_node_or_null("/root/LightingController")
	audio_manager = get_node_or_null("/root/AudioManager")
	screen_effects = get_node_or_null("/root/ScreenEffects")

	sequence_started.emit()
	stage_changed.emit(current_stage)

## 跳过序列（用于测试）
func skip_sequence():
	print("[TrainArrivalManager] 跳过列车到站序列")
	_end_sequence()

## 进入下一阶段
func _next_stage():
	var old_stage = current_stage
	current_stage = (current_stage + 1) as TrainStage

	if current_stage >= TrainStage.size():
		_end_sequence()
		return

	stage_timer = 0.0
	print("[TrainArrivalManager] 进入阶段: %s" % TrainStage.keys()[current_stage])
	stage_changed.emit(current_stage)

	# 执行阶段切换效果
	_execute_stage_transition(old_stage, current_stage)

## 更新当前阶段效果
func _update_stage_effects(delta: float):
	match current_stage:
		TrainStage.APPROACHING:
			_update_approaching(delta)
		TrainStage.LIGHTS_FLICKER:
			_update_lights_flicker(delta)
		TrainStage.SCREEN_SHAKE:
			_update_screen_shake(delta)
		TrainStage.TRAIN_PASSING:
			_update_train_passing(delta)
		TrainStage.AFTERGLOW:
			_update_afterglow(delta)

## 列车接近阶段
func _update_approaching(delta: float):
	# 远处汽笛声渐强
	if audio_manager:
		# 这里可以播放渐强的汽笛声
		pass

	# 灯光开始轻微闪烁
	if lighting_controller:
		lighting_controller.trigger_event("flicker", 0.5)

## 灯光闪烁阶段
func _update_lights_flicker(delta: float):
	# 灯光剧烈闪烁
	if lighting_controller:
		lighting_controller.trigger_event("flicker_rapid", 0.3)

	# 心率急剧上升
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(8.0)

## 画面震动阶段
func _update_screen_shake(delta: float):
	# 剧烈画面震动
	if camera:
		var shake_intensity = 0.5 + (stage_timer / stage_durations[current_stage]) * 0.5
		camera.position += Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			0
		)

	# 心率进一步上升
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(10.0)

## 列车经过阶段
func _update_train_passing(delta: float):
	# 白光效果（列车灯光）
	if screen_effects:
		screen_effects.apply_brightness(2.0)

	# 巨大噪音
	if audio_manager:
		audio_manager.play_sfx("train_horn_distant", 5.0)

	# 最大心率
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(15.0)

## 余光阶段
func _update_afterglow(delta: float):
	# 余光渐暗
	if screen_effects:
		var brightness = 1.0 - (stage_timer / stage_durations[current_stage])
		screen_effects.apply_brightness(brightness)

	# 心率开始下降
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.decrease_heart_rate(5.0)

## 执行阶段切换效果
func _execute_stage_transition(from_stage: TrainStage, to_stage: TrainStage):
	match to_stage:
		TrainStage.LIGHTS_FLICKER:
			if audio_manager:
				audio_manager.play_sfx("train_horn_distant", -5.0)
		TrainStage.SCREEN_SHAKE:
			if audio_manager:
				audio_manager.play_sfx("wall_knock", -5.0)
		TrainStage.TRAIN_PASSING:
			if audio_manager:
				audio_manager.play_sfx("chaos_soundwall", 0.0)

## 结束序列
func _end_sequence():
	print("[TrainArrivalManager] ===== 列车到站序列结束 =====")
	current_stage = TrainStage.IDLE
	stage_timer = 0.0

	# 恢复正常状态
	if camera:
		camera.position = Vector3.ZERO

	if lighting_controller:
		lighting_controller.reset_lights()

	sequence_ended.emit()

## 获取当前阶段
func get_current_stage() -> TrainStage:
	return current_stage

## 获取阶段进度（0.0-1.0）
func get_stage_progress() -> float:
	if current_stage == TrainStage.IDLE:
		return 0.0
	return stage_timer / stage_durations[current_stage]
