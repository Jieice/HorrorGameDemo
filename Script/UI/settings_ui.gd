extends Control

# 音频设置
var sound_effect_volume: float = 1.0
var bgm_volume: float = 1.0

# 显示设置
var show_fps: bool = false
var fullscreen: bool = false

# 配置文件路径
const CONFIG_FILE_PATH = "user://settings.cfg"

# 音频总线索引
const SOUND_EFFECT_BUS_IDX = 1  # 音效总线索引
const BGM_BUS_IDX = 2  # 背景音乐总线索引

# 初始化
func _ready():
	# 加载设置
	load_settings()
	
	# 更新UI
	update_ui_from_settings()
	
	# 设置初始值
	apply_settings()

# 加载设置
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	
	if err == OK:
		# 音频设置
		sound_effect_volume = config.get_value("audio", "sound_effect_volume", 1.0)
		bgm_volume = config.get_value("audio", "bgm_volume", 1.0)
		
		# 显示设置
		show_fps = config.get_value("display", "show_fps", false)
		fullscreen = config.get_value("display", "fullscreen", false)
	else:
		# 使用默认设置
		sound_effect_volume = 1.0
		bgm_volume = 1.0
		show_fps = false
		fullscreen = false

# 保存设置
func save_settings():
	var config = ConfigFile.new()
	
	# 音频设置
	config.set_value("audio", "sound_effect_volume", sound_effect_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	
	# 显示设置
	config.set_value("display", "show_fps", show_fps)
	config.set_value("display", "fullscreen", fullscreen)
	
	# 保存到文件
	config.save(CONFIG_FILE_PATH)

# 应用设置
func apply_settings():
	# 应用音频设置
	if SOUND_EFFECT_BUS_IDX < AudioServer.bus_count:
		AudioServer.set_bus_volume_db(SOUND_EFFECT_BUS_IDX, linear_to_db(sound_effect_volume))
	
	if BGM_BUS_IDX < AudioServer.bus_count:
		AudioServer.set_bus_volume_db(BGM_BUS_IDX, linear_to_db(bgm_volume))
	
	# 应用显示设置
	var fps_display = Engine.get_singleton("FPS")
	if fps_display:
		fps_display.set_fps_visibility(show_fps)
	else:
		# 如果FPS单例不存在，尝试在场景树中查找
		fps_display = get_node_or_null("/root/FPS")
		if fps_display:
			fps_display.visible = show_fps
	
	# 应用全屏设置
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# 从设置更新UI
func update_ui_from_settings():
	# 更新音频滑块
	%SoundEffectSlider.value = sound_effect_volume
	%BGMSlider.value = bgm_volume
	
	# 更新音量显示
	%SoundEffectValue.text = str(int(sound_effect_volume * 100)) + "%"
	%BGMValue.text = str(int(bgm_volume * 100)) + "%"
	
	# 更新复选框
	%FPSCheckBox.button_pressed = show_fps
	%FullscreenCheckBox.button_pressed = fullscreen

# 音效滑块值变化
func _on_sound_effect_slider_value_changed(value):
	sound_effect_volume = value
	%SoundEffectValue.text = str(int(value * 100)) + "%"

# 背景音乐滑块值变化
func _on_bgm_slider_value_changed(value):
	bgm_volume = value
	%BGMValue.text = str(int(value * 100)) + "%"

# FPS复选框状态变化
func _on_fps_check_box_toggled(button_pressed):
	show_fps = button_pressed

# 全屏复选框状态变化
func _on_fullscreen_check_box_toggled(button_pressed):
	fullscreen = button_pressed

# 保存按钮点击
func _on_save_button_pressed():
	# 保存设置并应用
	save_settings()
	apply_settings()
	
	# 只在游戏场景中设置鼠标为捕捉模式，主菜单中保持可见
	if get_tree().current_scene.name != "MainMenu":
		# 检查是否存在对话框，如果存在则恢复对话框状态
		var dialogue_box = get_tree().get_first_node_in_group("DialogueBox")
		if dialogue_box and dialogue_box.visible:
			# 如果对话框正在显示，保持暂停状态并保持对话框可见
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			# 否则恢复正常游戏状态
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# 恢复游戏运行状态
			get_tree().paused = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 立即隐藏界面并移除
	hide()
	queue_free()

# 取消按钮点击
func _on_cancel_button_pressed():
	# 确保焦点不在其他控件上
	release_focus()
	# 重新加载设置并更新UI
	load_settings()
	update_ui_from_settings()
	# 立即隐藏界面
	hide()
	# 延迟一帧后从场景树中移除自身
	call_deferred("queue_free")
