extends Node

# 音效管理器
# 负责管理游戏中的所有音效和音乐

# 音效类型枚举
enum SoundType {
	AMBIENT,    # 环境音效
	SFX,        # 特效音效
	VOICE,      # 语音/对话
	UI,         # UI音效
	MUSIC       # 背景音乐
}

# 预加载音效
var sounds = {
	# 环境音效
	"ambient_rain": preload("res://Assets/Audio/heartbeat.mp3"),  # 暂时使用心跳声代替
	
	# 特效音效
	"footstep": preload("res://Assets/Audio/heartbeat.mp3"),      # 暂时使用心跳声代替
	"door_open": preload("res://Assets/Audio/heartbeat.mp3"),     # 暂时使用心跳声代替
	"door_close": preload("res://Assets/Audio/heartbeat.mp3"),    # 暂时使用心跳声代替
	
	# UI音效
	"task_complete": preload("res://Assets/Audio/SFX/task_complete.mp3"),
	"mask_change": preload("res://Assets/Audio/SFX/mask_change.mp3"),
	"button_click": preload("res://Assets/Audio/heartbeat.mp3"),  # 暂时使用心跳声代替
	"ui_unpause": preload("res://Assets/Audio/heartbeat.mp3"),   # 暂时使用心跳声代替
	
	# 背景音乐
	"main_theme": preload("res://Assets/Audio/heartbeat.mp3"),    # 暂时使用心跳声代替
}

# 音频播放器节点
var audio_players = {}
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# 音量设置
var master_volume: float = 0.7  # 降低主音量
var music_volume: float = 0.5   # 降低音乐音量
var sfx_volume: float = 0.5     # 降低音效音量
var ambient_volume: float = 0.4 # 降低环境音量
var voice_volume: float = 0.7   # 降低语音音量
var ui_volume: float = 0.3      # 降低UI音量

# 是否静音
var is_muted: bool = false

func _ready():
	# 创建音乐播放器
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# 创建环境音效播放器
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# 初始化音频播放器池
	for i in range(10):  # 创建10个音频播放器用于SFX
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.name = "SFXPlayer_" + str(i)
		add_child(player)
		audio_players[player.name] = {"player": player, "in_use": false}
	
	# 应用初始音量设置
	apply_volume_settings()

# 应用音量设置
func apply_volume_settings():
	# 设置主音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	# 设置各个音频总线的音量
	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	
	if AudioServer.get_bus_index("Ambient") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), linear_to_db(ambient_volume))
	
	if AudioServer.get_bus_index("Voice") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voice_volume))
	
	if AudioServer.get_bus_index("UI") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(ui_volume))
	
	# 应用静音设置
	for i in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(i, is_muted)

# 播放音效
func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sounds.has(sound_name):
		print("错误: 找不到音效 ", sound_name)
		return null
	
	# 获取一个可用的音频播放器
	var player = get_available_player()
	if player:
		player.stream = sounds[sound_name]
		# 使用正常音量，不做特殊处理
		player.volume_db = volume_db
		# 使用传入的音调参数
		player.pitch_scale = pitch_scale
		player.play()
		return player
	
	print("警告: 没有可用的音频播放器")
	return null

# 播放音乐
func play_music(music_name: String, fade_in: float = 0.0):
	if not sounds.has(music_name):
		print("错误: 找不到音乐 ", music_name)
		return
	
	# 如果需要淡入
	if fade_in > 0:
		music_player.stream = sounds[music_name]
		music_player.volume_db = -80.0  # 开始时音量很低
		music_player.play()
		
		# 创建淡入效果
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0.0, fade_in)
	else:
		music_player.stream = sounds[music_name]
		music_player.volume_db = 0.0
		music_player.play()

# 停止音乐
func stop_music(fade_out: float = 0.0):
	if fade_out > 0:
		# 创建淡出效果
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

# 播放环境音效
func play_ambient(ambient_name: String, fade_in: float = 0.0):
	if not sounds.has(ambient_name):
		print("错误: 找不到环境音效 ", ambient_name)
		return
	
	# 确保ambient_player已初始化
	if not is_instance_valid(ambient_player):
		ambient_player = AudioStreamPlayer.new()
		ambient_player.bus = "Ambient"
		add_child(ambient_player)
		print("AudioManager: 重新初始化ambient_player")
	
	# 如果需要淡入
	if fade_in > 0:
		ambient_player.stream = sounds[ambient_name]
		ambient_player.volume_db = -80.0  # 开始时音量很低
		ambient_player.play()
		
		# 创建淡入效果
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", 0.0, fade_in)
	else:
		ambient_player.stream = sounds[ambient_name]
		ambient_player.play()

# 停止环境音效
func stop_ambient(fade_out: float = 0.0):
	if fade_out > 0:
		# 创建淡出效果
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(ambient_player.stop)
	else:
		ambient_player.stop()

# 获取一个可用的音频播放器
func get_available_player() -> AudioStreamPlayer:
	for key in audio_players:
		var player_data = audio_players[key]
		if not player_data.in_use or not player_data.player.playing:
			player_data.in_use = true
			return player_data.player
	
	return null

# 设置主音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 设置音乐音量
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 设置音效音量
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 设置环境音效音量
func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 设置语音音量
func set_voice_volume(volume: float):
	voice_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 设置UI音效音量
func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

# 切换静音状态
func toggle_mute():
	is_muted = !is_muted
	apply_volume_settings()
	return is_muted

# 设置静音状态
func set_mute(mute: bool):
	is_muted = mute
	apply_volume_settings()
