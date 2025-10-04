extends CharacterBody3D

@export var speed := 2.0 # 正常移动速度（恐怖游戏应该慢一点）
@export var run_multiplier := 1.5 # 奔跑速度倍率
@export var mouse_sensitivity := 0.002 # 鼠标灵敏度

@export var stand_capsule_height := 2.0
@export var crouch_capsule_height := 1.0
@export var stand_eye_height := 1.6
@export var crouch_eye_height := 1.0
@export var crouch_speed := 0.1 # 蹲起过渡速度

@onready var ray: RayCast3D = $Pivot/Camera3D/RayCast3D
@onready var cam: Camera3D = $Pivot/Camera3D
@onready var pivot: Node3D = $Pivot
@onready var interact_hint_label: Label = $InteractHint
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var is_crouching := false
var can_interact := false
var current_interactable: Interactable = null
var dialogue_active := false

# 脚步声系统
var footstep_timer := 0.0
var footstep_interval := 0.55 # 脚步声间隔（秒）
var is_moving := false

func set_dialogue_active(active: bool):
	dialogue_active = active
	interact_hint_label.visible = not active
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		velocity = Vector3.ZERO
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # 游戏开始时捕获鼠标
	self.add_to_group("Player") # 将玩家添加到Player组

func _input(event: InputEvent) -> void:
	# === 测试热键（开发用，发布前删除） ===
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			# F1: 增加心率
			var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
			if heart_rate_sys:
				heart_rate_sys.increase_heart_rate(30.0)
				print("[测试] 按F1增加心率+30")
		elif event.keycode == KEY_F2:
			# F2: 大幅增加心率到危险水平
			var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
			if heart_rate_sys:
				heart_rate_sys.increase_heart_rate(60.0)
				print("[测试] 按F2增加心率+60（危险！）")
		elif event.keycode == KEY_F3:
			# F3: 重置心率
			var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
			if heart_rate_sys:
				heart_rate_sys.reset()
				print("[测试] 按F3重置心率")
	# === 测试热键结束 ===
	
	if dialogue_active:
		return # 禁用所有输入，包括空格、E、ESC等
	# 处理鼠标移动
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative
		rotate_y(-mouse_delta.x * mouse_sensitivity)
		pivot.rotate_x(-mouse_delta.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI / 2, PI / 3)
	
	# ESC键切换鼠标模式和弹出ESC菜单
	if event.is_action_pressed("esc"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			# 弹出ESC菜单
			if not get_tree().current_scene.has_node("ESCMenu"):
				var esc_menu_scene = preload("res://Scene/ESC.tscn")
				var esc_menu = esc_menu_scene.instantiate()
				get_tree().current_scene.add_child(esc_menu)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# E键互动
	if event.is_action_pressed("interact") and can_interact and current_interactable != null:
		current_interactable.interact()
	# 空格等其它输入也会被 dialogue_active 拦截

func _physics_process(_delta: float) -> void:
	if dialogue_active:
		velocity = Vector3.ZERO
		return # 禁用所有移动
	
	# 获取心率系统（整个函数只声明一次）
	var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
	
	# 深呼吸系统（长按空格）
	if heart_rate_sys:
		if Input.is_action_pressed("space"):
			heart_rate_sys.start_breathing()
		else:
			heart_rate_sys.stop_breathing()
	
	# 蹲伏系统
	update_crouch(_delta)
	
	# 移动逻辑
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_down"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x

	if dir != Vector3.ZERO:
		dir = dir.normalized()
		var current_speed = speed

		# 奔跑
		if Input.is_action_pressed("run") and not is_crouching:
			current_speed *= run_multiplier

		# 蹲伏减速
		if is_crouching:
			current_speed *= 0.5
		
		# 心率影响移动速度
		if heart_rate_sys:
			current_speed *= heart_rate_sys.get_movement_multiplier()

		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	# 脚步声系统
	update_footsteps(_delta, dir != Vector3.ZERO)
	
	# 交互检测
	update_interaction()

func update_interaction() -> void:
	# 射线检测交互对象
	var ray_result = ray.get_collider()
	if ray.is_colliding() and ray_result is Interactable:
		can_interact = true
		current_interactable = ray_result
		interact_hint_label.text = ray_result.interact_hint
		interact_hint_label.visible = true
	else:
		can_interact = false
		current_interactable = null
		interact_hint_label.visible = false

# 脚步声系统
func update_footsteps(delta: float, moving: bool):
	# 暂时移除 is_on_floor 判断，只要移动就播放脚步
	if moving:
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			play_footstep()
			footstep_timer = 0.0
			# 根据移动速度调整脚步间隔
			if Input.is_action_pressed("run"):
				footstep_interval = 0.4 # 跑步时脚步更快
			elif Input.is_action_pressed("ctrl"):
				footstep_interval = 0.9 # 蹲伏时脚步更慢
			else:
				footstep_interval = 0.55 # 正常行走
	else:
		footstep_timer = 0.0

func play_footstep():
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		# 蹲伏时脚步声更小、更闷
		if is_crouching:
			audio_mgr.play_sfx("footstep", -12.0) # 蹲伏：音量降低
		else:
			audio_mgr.play_sfx("footstep", -8.0) # 正常：标准音量

# 蹲伏系统
func update_crouch(delta: float):
	if Input.is_action_pressed("ctrl"):
		is_crouching = true
	else:
		is_crouching = false
	
	# 只调整 pivot（摄像头父节点）的高度，不动碰撞体
	var target_height = crouch_eye_height if is_crouching else stand_eye_height
	pivot.position.y = lerp(pivot.position.y, target_height, crouch_speed)
