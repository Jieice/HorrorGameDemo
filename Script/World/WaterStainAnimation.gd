extends Node3D

## 水渍扩散动画
## 当玩家调查物品时，水渍开始扩散
## 作者：AI Assistant
## 日期：2025-10-04

@export var spread_speed: float = 0.5 # 扩散速度
@export var max_scale: float = 3.0 # 最大扩散倍数

var is_spreading: bool = false
var original_scale: Vector3
var target_scale: Vector3
var spread_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	print("[WaterStainAnimation] 水渍动画已准备好")

	# 保存原始缩放
	if mesh_instance:
		original_scale = mesh_instance.scale

	# 设置目标缩放
	target_scale = original_scale * max_scale

func _process(delta: float):
	if not is_spreading:
		return

	spread_timer += delta

	# 平滑扩散动画
	var progress = min(spread_timer / 2.0, 1.0) # 2秒扩散完成
	var new_scale = original_scale.lerp(target_scale, progress)

	if mesh_instance:
		mesh_instance.scale = new_scale

	# 当扩散完成时，停止扩散
	if progress >= 1.0:
		is_spreading = false
		print("[WaterStainAnimation] 水渍扩散完成")

## 开始扩散动画
func start_spreading():
	if is_spreading:
		return

	print("[WaterStainAnimation] 开始水渍扩散动画")
	is_spreading = true
	spread_timer = 0.0

	# 播放扩散音效
	if AudioManager:
		AudioManager.play_sfx("water_drip_echo")

## 重置动画
func reset():
	is_spreading = false
	spread_timer = 0.0

	if mesh_instance:
		mesh_instance.scale = original_scale

	print("[WaterStainAnimation] 水渍动画已重置")
