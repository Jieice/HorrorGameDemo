extends CanvasLayer

## 心率UI显示
## 在屏幕左下角显示心率波形和数值
## 作者：AI Assistant
## 日期：2025-10-04

@onready var heart_rate_label: Label = $Control/MarginContainer/VBoxContainer/HeartRateLabel
@onready var waveform: Line2D = $Control/MarginContainer/VBoxContainer/Waveform
@onready var stress_indicator: ColorRect = $Control/MarginContainer/VBoxContainer/StressIndicator

# 波形参数
var waveform_points: Array[float] = []
var max_points: int = 50
var point_spacing: float = 4.0
var time_accumulator: float = 0.0
var update_interval: float = 0.05 # 每0.05秒更新一次

# 心跳周期
var heartbeat_timer: float = 0.0
var heartbeat_interval: float = 1.0 # 默认60 BPM

# 颜色
var color_normal: Color = Color(0.2, 0.8, 0.3) # 绿色
var color_elevated: Color = Color(0.8, 0.8, 0.2) # 黄色
var color_stressed: Color = Color(0.9, 0.5, 0.1) # 橙色
var color_panic: Color = Color(0.9, 0.2, 0.2) # 红色

func _ready():
	print("[HeartRateUI] ===== 开始初始化 =====")
	
	# 强制显示
	visible = true
	print("[HeartRateUI] visible设置为true")
	
	# 检查节点是否存在
	if heart_rate_label:
		print("[HeartRateUI] heart_rate_label找到")
		heart_rate_label.text = "测试 60 BPM"
	else:
		print("[HeartRateUI] 错误：heart_rate_label未找到！")
	
	if waveform:
		print("[HeartRateUI] waveform找到")
	else:
		print("[HeartRateUI] 错误：waveform未找到！")
	
	if stress_indicator:
		print("[HeartRateUI] stress_indicator找到")
	else:
		print("[HeartRateUI] 错误：stress_indicator未找到！")
	
	# 初始化波形点
	for i in range(max_points):
		waveform_points.append(0.0)
	print("[HeartRateUI] 波形点已初始化")
	
	# 连接心率系统信号
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.heart_rate_changed.connect(_on_heart_rate_changed)
		heart_rate_sys.stress_level_changed.connect(_on_stress_level_changed)
		print("[HeartRateUI] 已连接到HeartRateSystem")
	else:
		print("[HeartRateUI] 警告：HeartRateSystem未找到")
	
	# 初始显示
	_update_display(60.0)
	
	print("[HeartRateUI] ===== 初始化完成 =====")

func _process(delta: float):
	if not visible:
		return
	
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if not heart_rate_sys:
		return
	
	# 更新心跳周期
	var current_bpm = heart_rate_sys.heart_rate
	heartbeat_interval = 60.0 / current_bpm if current_bpm > 0 else 1.0
	
	# 更新波形
	time_accumulator += delta
	heartbeat_timer += delta
	
	if time_accumulator >= update_interval:
		time_accumulator = 0.0
		_update_waveform()

## 检测是否是游戏场景
func _is_game_scene() -> bool:
	var scene_name = get_tree().current_scene.name
	return scene_name.contains("Subway") or scene_name.contains("Level") or scene_name.contains("Prologue")

## 心率变化回调
func _on_heart_rate_changed(new_rate: float):
	_update_display(new_rate)

## 压力等级变化回调
func _on_stress_level_changed(level: String):
	_update_color(level)

## 更新显示
func _update_display(rate: float):
	if heart_rate_label:
		heart_rate_label.text = "%d BPM" % int(rate)
	
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	_update_color(heart_rate_sys.get_stress_level() if heart_rate_sys else "normal")

## 更新颜色
func _update_color(stress_level: String):
	var target_color: Color
	
	match stress_level:
		"normal":
			target_color = color_normal
		"elevated":
			target_color = color_elevated
		"stressed":
			target_color = color_stressed
		"panic":
			target_color = color_panic
		_:
			target_color = color_normal
	
	if heart_rate_label:
		heart_rate_label.add_theme_color_override("font_color", target_color)
	
	if waveform:
		waveform.default_color = target_color
	
	if stress_indicator:
		stress_indicator.color = target_color

## 更新波形
func _update_waveform():
	if not waveform:
		return
	
	# 生成心跳波形（ECG样式）
	var new_value: float = 0.0
	
	# 计算在心跳周期中的位置
	var cycle_position = fmod(heartbeat_timer, heartbeat_interval) / heartbeat_interval
	
	# ECG波形模拟
	if cycle_position < 0.1:
		# P波（小峰）
		new_value = sin(cycle_position * PI / 0.1) * 0.3
	elif cycle_position < 0.15:
		# 基线
		new_value = 0.0
	elif cycle_position < 0.25:
		# QRS复合波（主峰）
		var qrs_pos = (cycle_position - 0.15) / 0.1
		if qrs_pos < 0.3:
			# Q波（下降）
			new_value = - qrs_pos * 0.3
		elif qrs_pos < 0.6:
			# R波（急升）
			new_value = (qrs_pos - 0.3) * 3.0
		else:
			# S波（下降）
			new_value = (1.0 - qrs_pos) * 2.0 - 0.2
	elif cycle_position < 0.35:
		# ST段（平稳）
		new_value = 0.0
	elif cycle_position < 0.5:
		# T波（圆润峰）
		var t_pos = (cycle_position - 0.35) / 0.15
		new_value = sin(t_pos * PI) * 0.4
	else:
		# 基线
		new_value = 0.0
	
	# 添加轻微噪声
	new_value += randf_range(-0.05, 0.05)
	
	# 更新点数组
	waveform_points.pop_front()
	waveform_points.append(new_value)
	
	# 更新Line2D
	waveform.clear_points()
	for i in range(waveform_points.size()):
		var x = i * point_spacing
		var y = 30.0 - waveform_points[i] * 20.0 # 中心在30，振幅20
		waveform.add_point(Vector2(x, y))

## 显示/隐藏UI
func set_ui_visible(should_show: bool):
	visible = should_show
