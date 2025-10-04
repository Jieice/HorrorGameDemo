extends StaticBody3D

## 可注视的挂钟
## 盯着看3秒后指针开始逆转，发出扭曲的滴答声
## 作者：AI Assistant
## 日期：2025-10-04

@export var clock_hand: Node3D # 时钟指针（可选，如果模型有的话）
@export var reverse_speed: float = 0.5 # 逆转速度

var is_reversing: bool = false
var original_rotation: float = 0.0
var has_triggered: bool = false # 是否已经触发过

func _ready():
	# 自动注册为可注视对象
	add_to_group("gazeable")

	# 自动查找时钟指针
	if not clock_hand:
		clock_hand = find_child("ClockHand", true, false)

	# 保存初始旋转
	if clock_hand:
		original_rotation = clock_hand.rotation.z

	print("[GazeableClock] 挂钟已准备好，等待玩家注视...")

func _process(delta: float):
	# 如果正在逆转，持续旋转指针
	if is_reversing and clock_hand:
		clock_hand.rotation.z -= reverse_speed * delta

## 当玩家注视3秒后触发
func _on_gaze_triggered():
	if has_triggered:
		return # 已经触发过了，不重复触发
	
	has_triggered = true
	print("[GazeableClock] 玩家注视触发！指针开始逆转...")
	
	# 开始逆转
	is_reversing = true
	
	# 播放扭曲的滴答声
	if AudioManager:
		AudioManager.play_sfx("clock_reverse", -8.0)
	
	# 增加心率（GazeSystem会自动增加15，这里再加5）
	if HeartRateSystem:
		HeartRateSystem.increase_heart_rate(5.0)
	
	# 5秒后停止逆转
	await get_tree().create_timer(5.0).timeout
	is_reversing = false
	print("[GazeableClock] 指针停止逆转")

## 重置状态（用于测试或重新开始）
func reset():
	is_reversing = false
	has_triggered = false
	if clock_hand:
		clock_hand.rotation.z = original_rotation
	print("[GazeableClock] 已重置")
