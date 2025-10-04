extends Node

## 心率/压力系统
## 管理玩家的心理压力，影响视觉和音效
## 作者：AI Assistant
## 日期：2025-10-04

# 心率参数
var heart_rate: float = 60.0 # 当前心率
var base_heart_rate: float = 60.0 # 基础心率
var max_heart_rate: float = 140.0 # 最大心率

# 恢复速率
var natural_recovery_rate: float = 3.0 # 自然恢复速率（每秒）
var breath_recovery_rate: float = 5.0 # 深呼吸恢复速率（每秒）

# 状态
var is_breathing: bool = false # 是否正在深呼吸
var breathing_timer: float = 0.0 # 深呼吸计时器

# 心率阈值
const THRESHOLD_NORMAL = 100.0
const THRESHOLD_STRESSED = 120.0
const THRESHOLD_PANIC = 130.0

# 信号
signal heart_rate_changed(new_rate: float)
signal stress_level_changed(level: String) # "normal", "stressed", "panic"

func _ready():
	print("[HeartRateSystem] 心率系统已初始化")

func _process(delta: float):
	# 深呼吸恢复
	if is_breathing:
		breathing_timer += delta
		decrease_heart_rate(breath_recovery_rate * delta)
	else:
		# 自然恢复
		if heart_rate > base_heart_rate:
			decrease_heart_rate(natural_recovery_rate * delta)
	
	# 检查是否需要触发压力等级变化
	_check_stress_level()

## 增加心率
func increase_heart_rate(amount: float):
	var old_rate = heart_rate
	heart_rate = min(heart_rate + amount, max_heart_rate)
	
	if heart_rate != old_rate:
		heart_rate_changed.emit(heart_rate)
		print("[HeartRateSystem] 心率上升: %.1f -> %.1f (+%.1f)" % [old_rate, heart_rate, amount])

## 减少心率
func decrease_heart_rate(amount: float):
	var old_rate = heart_rate
	heart_rate = max(heart_rate - amount, base_heart_rate)
	
	if heart_rate != old_rate:
		heart_rate_changed.emit(heart_rate)

## 开始深呼吸
func start_breathing():
	if not is_breathing:
		is_breathing = true
		breathing_timer = 0.0
		print("[HeartRateSystem] 开始深呼吸")

## 停止深呼吸
func stop_breathing():
	if is_breathing:
		is_breathing = false
		print("[HeartRateSystem] 停止深呼吸（持续%.1f秒）" % breathing_timer)

## 重置心率
func reset():
	heart_rate = base_heart_rate
	is_breathing = false
	breathing_timer = 0.0
	heart_rate_changed.emit(heart_rate)
	print("[HeartRateSystem] 心率已重置")

## 获取当前压力等级
func get_stress_level() -> String:
	if heart_rate >= THRESHOLD_PANIC:
		return "panic"
	elif heart_rate >= THRESHOLD_STRESSED:
		return "stressed"
	elif heart_rate >= THRESHOLD_NORMAL:
		return "elevated"
	else:
		return "normal"

## 获取归一化心率（0.0-1.0）
func get_normalized_heart_rate() -> float:
	return (heart_rate - base_heart_rate) / (max_heart_rate - base_heart_rate)

## 检查压力等级变化
var _last_stress_level: String = "normal"
func _check_stress_level():
	var current_level = get_stress_level()
	if current_level != _last_stress_level:
		stress_level_changed.emit(current_level)
		print("[HeartRateSystem] 压力等级变化: %s -> %s" % [_last_stress_level, current_level])
		_last_stress_level = current_level

## 获取视觉效果强度（用于后处理）
func get_vignette_intensity() -> float:
	# 心率>100开始出现暗角，心率越高越强
	if heart_rate < THRESHOLD_NORMAL:
		return 0.0
	else:
		var normalized = (heart_rate - THRESHOLD_NORMAL) / (max_heart_rate - THRESHOLD_NORMAL)
		return clamp(normalized * 0.6, 0.0, 0.6) # 最大0.6强度

## 获取屏幕晃动强度
func get_shake_intensity() -> float:
	# 心率>130才开始晃动
	if heart_rate < THRESHOLD_PANIC:
		return 0.0
	else:
		var normalized = (heart_rate - THRESHOLD_PANIC) / (max_heart_rate - THRESHOLD_PANIC)
		return clamp(normalized * 0.02, 0.0, 0.02) # 轻微晃动

## 是否应该降低移动速度
func should_slow_movement() -> bool:
	return heart_rate >= THRESHOLD_STRESSED

## 获取移动速度倍率
func get_movement_multiplier() -> float:
	if heart_rate < THRESHOLD_STRESSED:
		return 1.0
	else:
		# 心率>120时，速度降低10%
		return 0.9
