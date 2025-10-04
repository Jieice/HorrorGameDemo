extends Node3D

## 陌生人注视效果
## 当玩家盯着陌生人看时触发特殊效果
## 作者：AI Assistant
## 日期：2025-10-04

@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var mesh = $MeshInstance3D if has_node("MeshInstance3D") else null

var is_being_gazed := false
var original_position := Vector3.ZERO

func _ready():
	original_position = position
	
	# 注册为可注视对象
	var gaze_sys = get_node_or_null("/root/GazeSystem")
	if gaze_sys:
		gaze_sys.register_gazeable_object(self)
		gaze_sys.gaze_started.connect(_on_gaze_started)
		gaze_sys.gaze_ended.connect(_on_gaze_ended)
	
	print("[GazeableStranger] 陌生人注视系统已初始化")

func _on_gaze_started(object):
	if object != self:
		return
	
	is_being_gazed = true
	print("[GazeableStranger] 玩家开始盯着陌生人看...")
	
	# 播放缓慢抬头动画（如果有）
	if animation_player and animation_player.has_animation("look_up"):
		animation_player.play("look_up")

func _on_gaze_ended(object):
	if object != self:
		return
	
	is_being_gazed = false
	print("[GazeableStranger] 玩家移开视线")
	
	# 恢复原状（如果有动画）
	if animation_player and animation_player.has_animation("look_up"):
		animation_player.play_backwards("look_up")

func _on_gaze_triggered():
	print("[GazeableStranger] 对视触发！恐怖效果...")
	
	# 增加心率
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	if heart_rate_sys:
		heart_rate_sys.increase_heart_rate(20.0)
	
	# 播放低频嗡鸣
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_sfx("low_frequency_hum", -8.0)
	
	# 画面轻微扭曲
	var cam_effects = get_node_or_null("/root/CameraEffects")
	if cam_effects and cam_effects.has_method("apply_distortion"):
		cam_effects.apply_distortion(0.1, 0.5)
	
	# 灯光闪烁
	var lighting = get_node_or_null("/root/LightingController")
	if lighting:
		lighting.trigger_event("flicker", 0.3)
