extends Control

@onready var master_slider = $VBoxContainer/MasterVolume/HSlider
@onready var music_slider = $VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider = $VBoxContainer/SFXVolume/HSlider
@onready var ambient_slider = $VBoxContainer/AmbientVolume/HSlider
@onready var voice_slider = $VBoxContainer/VoiceVolume/HSlider
@onready var ui_slider = $VBoxContainer/UIVolume/HSlider
@onready var mute_button = $VBoxContainer/MuteButton

func _ready():
	# 连接信号
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	mute_button.toggled.connect(_on_mute_toggled)
	
	# 设置初始值
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	ambient_slider.value = AudioManager.ambient_volume
	voice_slider.value = AudioManager.voice_volume
	ui_slider.value = AudioManager.ui_volume
	mute_button.button_pressed = AudioManager.is_muted

func _on_master_volume_changed(value):
	AudioManager.set_master_volume(value)
	# 播放测试音效
	AudioManager.play_sound("button_click")

func _on_music_volume_changed(value):
	AudioManager.set_music_volume(value)
	# 播放测试音乐
	if !AudioManager.music_player.playing:
		AudioManager.play_music("main_theme")

func _on_sfx_volume_changed(value):
	AudioManager.set_sfx_volume(value)
	# 播放测试音效
	AudioManager.play_sound("button_click")

func _on_ambient_volume_changed(value):
	AudioManager.set_ambient_volume(value)
	# 播放测试环境音效
	if !AudioManager.ambient_player.playing:
		AudioManager.play_ambient("ambient_rain")

func _on_voice_volume_changed(value):
	AudioManager.set_voice_volume(value)
	# 播放测试语音
	AudioManager.play_sound("button_click")

func _on_ui_volume_changed(value):
	AudioManager.set_ui_volume(value)
	# 播放测试UI音效
	AudioManager.play_sound("button_click")

func _on_mute_toggled(button_pressed):
	AudioManager.set_mute(button_pressed)

func _on_close_button_pressed():
	self.visible = false

func _on_test_heartbeat_pressed():
	AudioManager.play_sound("ambient_rain", -5.0, 1.0)

func _on_test_footstep_pressed():
	AudioManager.play_sound("footstep", 0.0, 1.2)

func _on_test_door_pressed():
	AudioManager.play_sound("door_open")