extends Node

## 黑暗事件管理器
## 控制灯光熄灭、恐怖音效、陌生人移动等
## 作者：AI Assistant
## 日期：2025-10-04

# 黑暗持续时间
@export var darkness_duration: float = 3.0

# 状态
var is_darkness_active: bool = false
var darkness_timer: float = 0.0

# 灯光引用（需要在场景中设置）
var scene_lights: Array[Node3D] = []
var original_light_states: Array[bool] = []

# 信号
signal darkness_started()
signal darkness_ended()
signal heart_rate_pulse() # 每0.5秒发送一次，用于持续增加心率

func _ready():
	print("[DarknessEventManager] 黑暗事件管理器已初始化")

func _process(delta: float):
	if is_darkness_active:
		darkness_timer += delta
		
		# 每0.5秒增加一次心率
		if int(darkness_timer * 2) > int((darkness_timer - delta) * 2):
			heart_rate_pulse.emit()
			var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
			if heart_rate_sys:
				heart_rate_sys.increase_heart_rate(5.0)
		
		# 检查是否到达结束时间
		if darkness_timer >= darkness_duration:
			_end_darkness()

## 触发黑暗事件
func trigger_darkness(stranger_node: Node3D = null, new_position: Vector3 = Vector3.ZERO):
	if is_darkness_active:
		return # 已经在黑暗中了
	
	print("[DarknessEventManager] ===== 黑暗事件开始 =====")
	is_darkness_active = true
	darkness_timer = 0.0
	
	# 发送开始信号
	darkness_started.emit()
	
	# 1. 熄灭所有灯光
	_turn_off_all_lights()
	
	# 2. 播放黑暗音效
	_play_darkness_sounds()
	
	# 3. 移动陌生人（如果提供了）
	if stranger_node and new_position != Vector3.ZERO:
		await get_tree().create_timer(1.5).timeout # 黑暗中途移动
		stranger_node.global_position = new_position
		print("[DarknessEventManager] 陌生人已移动到新位置")
	
	# 等待黑暗结束（_process会处理）

## 结束黑暗
func _end_darkness():
	print("[DarknessEventManager] ===== 黑暗事件结束 =====")
	is_darkness_active = false
	
	# 1. 恢复所有灯光（突然亮起）
	_turn_on_all_lights()
	
	# 2. 播放灯光恢复音效
	if AudioManager:
		AudioManager.play_sfx("light_buzz_electric", -10.0)
	
	# 3. 大幅增加心率（发现陌生人移动了）
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(25.0)
	
	# 发送结束信号
	darkness_ended.emit()

## 熄灭所有灯光
func _turn_off_all_lights():
	print("[DarknessEventManager] 熄灭所有灯光...")
	
	# 保存当前灯光状态
	original_light_states.clear()
	
	# 查找场景中的所有灯光
	_find_all_lights(get_tree().current_scene)
	
	# 熄灭所有灯光
	for light in scene_lights:
		if light is Light3D:
			original_light_states.append(light.visible)
			light.visible = false

## 恢复所有灯光
func _turn_on_all_lights():
	print("[DarknessEventManager] 恢复所有灯光...")
	
	for i in range(scene_lights.size()):
		if i < original_light_states.size():
			var light = scene_lights[i]
			if light is Light3D:
				light.visible = original_light_states[i]

## 递归查找所有灯光
func _find_all_lights(node: Node):
	if node is Light3D:
		scene_lights.append(node)
	
	for child in node.get_children():
		_find_all_lights(child)

## 播放黑暗中的音效
func _play_darkness_sounds():
	print("[DarknessEventManager] 播放黑暗音效...")
	
	if AudioManager:
		# 立即播放的音效
		AudioManager.play_sfx("breathing_heavy", -12.0)
		AudioManager.play_sfx("low_frequency_hum", -15.0)
		
		# 延迟播放的音效
		await get_tree().create_timer(0.8).timeout
		AudioManager.play_sfx("wall_knock", -10.0)
		
		await get_tree().create_timer(0.7).timeout
		AudioManager.play_sfx("breathing_heavy", -12.0)
		
		await get_tree().create_timer(0.5).timeout
		AudioManager.play_sfx("wall_knock", -10.0)

## 注册灯光（手动添加特定灯光）
func register_light(light: Light3D):
	if light not in scene_lights:
		scene_lights.append(light)
		print("[DarknessEventManager] 注册灯光: %s" % light.name)

## 清除灯光列表
func clear_lights():
	scene_lights.clear()
	original_light_states.clear()
	print("[DarknessEventManager] 已清除灯光列表")

## 重置状态
func reset():
	is_darkness_active = false
	darkness_timer = 0.0
	_turn_on_all_lights()
	print("[DarknessEventManager] 已重置")







