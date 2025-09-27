extends CharacterBody3D

@export var speed := 3.0                 # 正常移动速度
@export var run_multiplier := 1.5        # 奔跑速度倍率
@export var mouse_sensitivity := 0.002   # 鼠标灵敏度

@export var stand_capsule_height := 2.0
@export var crouch_capsule_height := 1.0
@export var stand_eye_height := 1.6
@export var crouch_eye_height := 1.0
@export var crouch_speed := 0.1          # 蹲起过渡速度

@onready var ray: RayCast3D = $Pivot/Camera3D/RayCast3D
@onready var cam: Camera3D = $Pivot/Camera3D
@onready var pivot: Node3D = $Pivot
@onready var interact_hint: Label = $"InteractHint"
var is_crouching := false
var game_active := true

func _ready() -> void:
	self.add_to_group("Player")  # 将玩家添加到Player组
	
	# 玩家脚本现在独立工作，不依赖PlayerController
	# PlayerController将在游戏场景中自动处理玩家状态
func _input(event: InputEvent) -> void:
	# 处理鼠标移动（游戏场景中默认捕获鼠标）
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative
		rotate_y(-mouse_delta.x * mouse_sensitivity)
		pivot.rotate_x(-mouse_delta.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2, PI/3)

func _physics_process(_delta: float) -> void:
	# 基础移动逻辑，不依赖外部状态控制
	
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

		# 蹲伏（这里只是速度减半，占位用）
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
	if ray.is_colliding():  # 如果射线碰到物体
		var obj = ray.get_collider()  # 获取碰撞物体
		if obj.is_in_group("interactable"):  # 检查物体是否在交互分组
			interact_hint.text = "按 E 互动"
			interact_hint.visible = true  # 显示提示框
		else:
			interact_hint.visible = false
	else:
		interact_hint.visible = false

	# 基础交互逻辑
	if Input.is_action_just_pressed("interact") and ray.is_colliding():
		var obj = ray.get_collider()
		if obj.is_in_group("interactable"):
			# 直接处理交互，不依赖PlayerController
			print("玩家交互: ", obj.name)
				
# 玩家脚本现在独立运行，PlayerController将在游戏场景中处理状态管理
