extends Node

# 音效管理器 - 统一管理所有音效和背景音乐

# 音频播放器节点
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var ambient_player: AudioStreamPlayer = $AmbientPlayer

# 音效资源字典
var sfx_library = {
	"heartbeat": "res://Assets/Audio/SFX/heartbeat.mp3",
	"glass_shatter": "res://Assets/Audio/SFX/glass-bottle-shatter-13847.mp3",
	"whisper": "res://Assets/Audio/SFX/norameld__horror-whisper-voice-needy.aiff",
	"footstep": "res://Assets/Audio/SFX/yoyodaman234__concrete-footstep-2.wav",
	"door_creak": "res://Assets/Audio/SFX/glass-bottle-shatter-13847.mp3", # 临时替代，需要在Godot中导入flac文件
	"mask_change": "res://Assets/Audio/SFX/mask_change.mp3",
	"task_complete": "res://Assets/Audio/SFX/task_complete.mp3",
	# 黑暗事件音效
	"breathing_heavy": "res://Assets/Audio/SFX/heartbeat.mp3", # 用心跳音效代替沉重呼吸
	"low_frequency_hum": "res://Assets/Audio/SFX/heartbeat.mp3", # 用心跳音效代替低频嗡鸣
	"wall_knock": "res://Assets/Audio/SFX/glass-bottle-shatter-13847.mp3", # 临时用玻璃破碎声代替墙内敲击
	"light_buzz_electric": "res://Assets/Audio/SFX/heartbeat.mp3", # 临时用心跳音效代替电灯嗡鸣
	"train_horn_distant": "res://Assets/Audio/SFX/mugwumb__metro-leaving-the-station.wav",
	# 列车到站音效
	"chaos_soundwall": "res://Assets/Audio/SFX/mugwumb__metro-leaving-the-station.wav",
	# 时钟音效
	"clock_reverse": "res://Assets/Audio/SFX/glass-bottle-shatter-13847.mp3" # 临时用玻璃破碎声
}

# BGM资源
var bgm_library = {
	"horror_ambient": "res://Assets/Audio/BGM/headphaze__horror_ambience_atmos-06.wav"
}

# 播放BGM
func play_bgm(bgm_name: String, fade_in_duration: float = 2.0):
	print("[AudioManager] play_bgm called:", bgm_name)
	if not bgm_library.has(bgm_name):
		print("[AudioManager] BGM不存在：", bgm_name)
		print("[AudioManager] 可用BGM：", bgm_library.keys())
		return
	var bgm = load(bgm_library[bgm_name])
	if not bgm:
		print("[AudioManager] BGM加载失败：", bgm_library[bgm_name])
		return
	bgm_player.stream = bgm
	bgm_player.volume_db = -80
	bgm_player.play()
	print("[AudioManager] BGM开始播放，淡入中...")
	# 淡入
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -10, fade_in_duration)

# 停止BGM
func stop_bgm(fade_out_duration: float = 2.0):
	if bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80, fade_out_duration)
		await tween.finished
		bgm_player.stop()

# 播放音效
func play_sfx(sfx_name: String, volume_db: float = 0.0):
	if not sfx_library.has(sfx_name):
		print("[AudioManager] 音效不存在：", sfx_name)
		return
	var sfx = load(sfx_library[sfx_name])
	if not sfx:
		print("[AudioManager] 音效加载失败：", sfx_library[sfx_name])
		return
	sfx_player.stream = sfx
	sfx_player.volume_db = volume_db
	sfx_player.play()

# 播放环境音效（循环）
func play_ambient(sfx_name: String, volume_db: float = -15.0, fade_in: float = 1.0):
	if not sfx_library.has(sfx_name):
		print("[AudioManager] 环境音效不存在：", sfx_name)
		return
	var sfx = load(sfx_library[sfx_name])
	ambient_player.stream = sfx
	ambient_player.volume_db = -80
	ambient_player.play()
	# 淡入
	var tween = create_tween()
	tween.tween_property(ambient_player, "volume_db", volume_db, fade_in)

# 停止环境音
func stop_ambient(fade_out: float = 1.0):
	if ambient_player.playing:
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", -80, fade_out)
		await tween.finished
		ambient_player.stop()
