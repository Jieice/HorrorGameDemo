extends Node3D

## 天花板扭曲动画
## 当玩家调查全部物品时，天花板开始扭曲变形
## 作者：AI Assistant
## 日期：2025-10-04

@export var distortion_speed: float = 0.2 # 扭曲速度
@export var max_distortion: float = 0.5 # 最大扭曲程度

var is_distorting: bool = false
var original_position: Vector3
var distortion_timer: float = 0.0
var distortion_direction: int = 1 # 1表示向下扭曲，-1表示向上扭曲

@onready var ceiling_mesh: MeshInstance3D = $CeilingMesh

func _ready():
	print("[CeilingDistortionAnimation] 天花板扭曲动画已准备好")

	# 保存原始位置
	if ceiling_mesh:
		original_position = ceiling_mesh.position

func _process(delta: float):
	if not is_distorting:
		return

	distortion_timer += delta

	# 正弦波扭曲动画
	var distortion_amount = sin(distortion_timer * distortion_speed) * max_distortion * distortion_direction

	if ceiling_mesh:
		ceiling_mesh.position.y = original_position.y + distortion_amount

		# 同时轻微扭曲旋转
		var rotation_amount = sin(distortion_timer * distortion_speed * 0.5) * 2.0
		ceiling_mesh.rotation_degrees.z = rotation_amount

	# 扭曲持续10秒后停止
	if distortion_timer >= 10.0:
		is_distorting = false
		print("[CeilingDistortionAnimation] 天花板扭曲完成")

## 开始扭曲动画
func start_distortion():
	if is_distorting:
		return

	print("[CeilingDistortionAnimation] 开始天花板扭曲动画")
	is_distorting = true
	distortion_timer = 0.0

	# 播放扭曲音效
	if AudioManager:
		AudioManager.play_sfx("wall_knock")
		AudioManager.play_sfx("low_frequency_hum", 0.3) # 低音量循环

## 重置动画
func reset():
	is_distorting = false
	distortion_timer = 0.0

	if ceiling_mesh:
		ceiling_mesh.position = original_position
		ceiling_mesh.rotation_degrees.z = 0

	print("[CeilingDistortionAnimation] 天花板扭曲动画已重置")
