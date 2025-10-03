extends CharacterBody3D

@export var speed := 3.0 # 正常移动速度
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
@onready var interact_hint: Label = $"InteractHint"
var is_crouching := false
var can_interact := false
var current_interactable: Node = null

func _ready() -> void:
	print("Player ready!")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # 游戏开始时捕获鼠标
	self.add_to_group("Player") # 将玩家添加到Player组

func _input(event: InputEvent) -> void:
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
		print("与对象交互: ", current_interactable.name)
		# 这里可以添加具体的交互逻辑

func _physics_process(_delta: float) -> void:
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
		if Input.is_action_pressed("run"):
			current_speed *= run_multiplier

		# 蹲伏
		if Input.is_action_pressed("ctrl"):
			is_crouching = true
			current_speed *= 0.5
		else:
			is_crouching = false

		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	# 交互检测
	update_interaction()

func update_interaction() -> void:
	# 射线检测交互对象
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_method("interact"):
			can_interact = true
			current_interactable = collider
			interact_hint.text = "按 E 与 " + collider.name + " 交互"
			interact_hint.visible = true
		else:
			can_interact = false
			current_interactable = null
			interact_hint.visible = false
	else:
		can_interact = false
		current_interactable = null
		interact_hint.visible = false
