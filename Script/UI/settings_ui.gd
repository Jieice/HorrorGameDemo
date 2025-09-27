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
	# 确保处理模式设置正确
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 确保鼠标过滤模式正确
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 加载设置
	load_settings()
	
	# 更新UI
	update_ui_from_settings()
	
	# 设置初始值
	apply_settings()
	
	# 确保所有按钮可点击
	_connect_signals()

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
	
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if dir == null:
		print("错误：无法访问用户目录")
		return
	
	# 保存到文件
	var err = config.save(CONFIG_FILE_PATH)
	if err != OK:
		print("错误：无法保存设置文件，错误代码：", err)
	else:
		print("设置已成功保存到：", CONFIG_FILE_PATH)

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
	release_focus()
	# 保存设置并应用
	save_settings()
	apply_settings()
	# 确保不会显示ESC菜单
	get_viewport().set_input_as_handled()
	# 隐藏并释放
	hide()
	call_deferred("queue_free")
	# 通知父节点我们已关闭
	if get_parent().has_method("_on_settings_closed"):
		get_parent()._on_settings_closed()
	else:
		# 兼容旧代码，尝试显示暂停菜单
		var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.show()

# 取消按钮点击
func _on_cancel_button_pressed():
	release_focus()
	# 重新加载设置并更新UI
	load_settings()
	update_ui_from_settings()
	# 确保不会显示ESC菜单
	get_viewport().set_input_as_handled()
	# 隐藏并释放
	hide()
	call_deferred("queue_free")
	# 通知父节点我们已关闭
	if get_parent().has_method("_on_settings_closed"):
		get_parent()._on_settings_closed()
	else:
		# 兼容旧代码，尝试显示暂停菜单
		var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.show()

# 确保所有按钮信号正确连接
func _connect_signals():
	# 连接滑块信号
	var sound_slider = get_node_or_null("%SoundEffectSlider")
	if sound_slider:
		if not sound_slider.value_changed.is_connected(_on_sound_effect_slider_value_changed):
			sound_slider.value_changed.connect(_on_sound_effect_slider_value_changed)
	
	var bgm_slider = get_node_or_null("%BGMSlider")
	if bgm_slider:
		if not bgm_slider.value_changed.is_connected(_on_bgm_slider_value_changed):
			bgm_slider.value_changed.connect(_on_bgm_slider_value_changed)
	
	# 连接复选框信号
	var fps_checkbox = get_node_or_null("%FPSCheckBox")
	if fps_checkbox:
		if not fps_checkbox.toggled.is_connected(_on_fps_check_box_toggled):
			fps_checkbox.toggled.connect(_on_fps_check_box_toggled)
	
	var fullscreen_checkbox = get_node_or_null("%FullscreenCheckBox")
	if fullscreen_checkbox:
		if not fullscreen_checkbox.toggled.is_connected(_on_fullscreen_check_box_toggled):
			fullscreen_checkbox.toggled.connect(_on_fullscreen_check_box_toggled)
	
	# 连接按钮信号 - 使用直接路径而不是%
	var save_button = get_node_or_null("VBoxContainer/Buttons/SaveButton")
	if not save_button:
		save_button = get_node_or_null("%SaveButton")
	if save_button:
		save_button.mouse_filter = Control.MOUSE_FILTER_STOP
		if not save_button.pressed.is_connected(_on_save_button_pressed):
			save_button.pressed.connect(_on_save_button_pressed)
	
	var cancel_button = get_node_or_null("VBoxContainer/Buttons/CancelButton")
	if not cancel_button:
		cancel_button = get_node_or_null("%CancelButton")
	if cancel_button:
		cancel_button.mouse_filter = Control.MOUSE_FILTER_STOP
		if not cancel_button.pressed.is_connected(_on_cancel_button_pressed):
			cancel_button.pressed.connect(_on_cancel_button_pressed)
