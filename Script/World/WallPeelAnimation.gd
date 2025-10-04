extends Node3D

## 墙皮脱落动画
## 当玩家调查更多物品时，墙皮开始剥落
## 作者：AI Assistant
## 日期：2025-10-04

@export var peel_speed: float = 0.3 # 剥落速度
@export var peel_angle: float = 45.0 # 剥落角度（度）

var is_peeling: bool = false
var original_rotation: Vector3
var target_rotation: Vector3
var peel_timer: float = 0.0

@onready var wall_mesh: MeshInstance3D = $WallMesh

func _ready():
	print("[WallPeelAnimation] 墙皮剥落动画已准备好")

	# 保存原始旋转
	if wall_mesh:
		original_rotation = wall_mesh.rotation_degrees

	# 设置目标旋转（向外剥落）
	target_rotation = original_rotation + Vector3(peel_angle, 0, 0)

func _process(delta: float):
	if not is_peeling:
		return

	peel_timer += delta

	# 平滑剥落动画
	var progress = min(peel_timer / 3.0, 1.0) # 3秒剥落完成
	var new_rotation = original_rotation.lerp(target_rotation, progress)

	if wall_mesh:
		wall_mesh.rotation_degrees = new_rotation

	# 当剥落完成时，停止剥落
	if progress >= 1.0:
		is_peeling = false
		print("[WallPeelAnimation] 墙皮剥落完成")

## 开始剥落动画
func start_peeling():
	if is_peeling:
		return

	print("[WallPeelAnimation] 开始墙皮剥落动画")
	is_peeling = true
	peel_timer = 0.0

	# 播放剥落音效
	if AudioManager:
		AudioManager.play_sfx("wall_crack")

## 重置动画
func reset():
	is_peeling = false
	peel_timer = 0.0

	if wall_mesh:
		wall_mesh.rotation_degrees = original_rotation

	print("[WallPeelAnimation] 墙皮剥落动画已重置")
