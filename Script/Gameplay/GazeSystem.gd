extends Node

## 注视系统
## 检测玩家盯着特定物体看，触发异常事件
## 作者：AI Assistant
## 日期：2025-10-04

# 参数
var gaze_threshold: float = 3.0 # 触发注视事件的时间（秒）
var raycast_distance: float = 10.0 # Raycast检测距离

# 状态
var current_gaze_object: Node3D = null
var gaze_timer: float = 0.0
var is_gazing: bool = false

# 已触发的注视事件（避免重复触发）
var triggered_objects: Dictionary = {}

# 信号
signal gaze_started(object: Node3D)
signal gaze_progress(object: Node3D, progress: float) # progress: 0.0-1.0
signal gaze_triggered(object: Node3D)
signal gaze_ended(object: Node3D)

func _ready():
	print("[GazeSystem] 注视系统已初始化")

func _process(delta: float):
	# 获取玩家摄像机
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# 检查对话状态，对话中不检测注视
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("get") and player.get("dialogue_active"):
		_reset_gaze()
		return
	
	# 发射Raycast
	var space_state = camera.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * raycast_distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		
		# 检查是否是可注视对象
		if _is_gazeable(hit_object):
			_handle_gaze(hit_object, delta)
		else:
			_reset_gaze()
	else:
		_reset_gaze()

## 处理注视
func _handle_gaze(object: Node3D, delta: float):
	# 如果是新对象
	if object != current_gaze_object:
		_reset_gaze()
		current_gaze_object = object
		is_gazing = true
		gaze_started.emit(object)
		print("[GazeSystem] 开始注视: %s" % object.name)
	
	# 累计时间
	gaze_timer += delta
	var progress = min(gaze_timer / gaze_threshold, 1.0)
	gaze_progress.emit(object, progress)
	
	# 检查是否达到触发阈值
	if gaze_timer >= gaze_threshold and not _is_triggered(object):
		_trigger_gaze_event(object)

## 触发注视事件
func _trigger_gaze_event(object: Node3D):
	triggered_objects[object.get_instance_id()] = true
	gaze_triggered.emit(object)
	print("[GazeSystem] 注视事件触发: %s" % object.name)
	
	# 调用对象的注视回调（如果存在）
	if object.has_method("_on_gaze_triggered"):
		object._on_gaze_triggered()
	
	# 增加心率
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(15.0)

## 重置注视状态
func _reset_gaze():
	if current_gaze_object and is_gazing:
		gaze_ended.emit(current_gaze_object)
		print("[GazeSystem] 停止注视: %s (持续%.1f秒)" % [current_gaze_object.name, gaze_timer])
	
	current_gaze_object = null
	gaze_timer = 0.0
	is_gazing = false

## 检查对象是否可被注视
func _is_gazeable(object: Node3D) -> bool:
	# 检查对象是否在"gazeable"组
	if object.is_in_group("gazeable"):
		return true
	
	# 或者检查对象是否有gazeable元数据
	if object.has_meta("gazeable"):
		return object.get_meta("gazeable")
	
	return false

## 检查对象是否已触发过
func _is_triggered(object: Node3D) -> bool:
	return triggered_objects.has(object.get_instance_id())

## 清除已触发记录（用于重置场景）
func clear_triggered():
	triggered_objects.clear()
	print("[GazeSystem] 已清除触发记录")

## 重置所有状态
func reset():
	_reset_gaze()
	clear_triggered()
	print("[GazeSystem] 已重置")

## 获取当前注视进度
func get_gaze_progress() -> float:
	if is_gazing:
		return min(gaze_timer / gaze_threshold, 1.0)
	return 0.0

## 手动标记对象为可注视
func register_gazeable_object(object: Node3D):
	if not object.is_in_group("gazeable"):
		object.add_to_group("gazeable")
		print("[GazeSystem] 注册可注视对象: %s" % object.name)

## 取消注册可注视对象
func unregister_gazeable_object(object: Node3D):
	if object.is_in_group("gazeable"):
		object.remove_from_group("gazeable")
		print("[GazeSystem] 取消注册: %s" % object.name)
