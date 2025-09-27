extends CanvasLayer

signal fps_visibility_changed(is_visible: bool)

@onready var label: Label = $Label
var show_fps: bool = false

func _ready() -> void:
	# 设置FPS显示在左上角
	if label:
		# 设置锚点为左上角
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		# 设置边距
		label.position = Vector2(10, 10)
	
	# 加载设置
	load_settings()
	
	# 初始隐藏
	visible = show_fps
	
	# 添加自身到自动加载单例
	if not Engine.has_singleton("FPS"):
		Engine.register_singleton("FPS", self)

func _process(_delta: float) -> void:
	if label:
		label.text = "FPS: " + str(Engine.get_frames_per_second())

# 加载设置
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		show_fps = config.get_value("display", "show_fps", false)
	else:
		show_fps = false
	
	# 应用设置
	set_fps_visibility(show_fps)

# 设置FPS可见性
func set_fps_visibility(is_visible: bool) -> void:
	show_fps = is_visible
	visible = show_fps
	fps_visibility_changed.emit(show_fps)
