extends Node

signal state_changed(old_state, new_state)
signal mouse_mode_changed(old_mode, new_mode)

enum PlayerState {
	NORMAL = 0,      # 正常游戏状态
	DIALOGUE = 1,    # 对话状态
	PAUSED = 2,      # 暂停状态
	MENU = 3,        # 在菜单中
	CUTSCENE = 4     # 过场动画状态
}

var current_state: PlayerState = PlayerState.NORMAL
var current_mouse_mode: int = Input.MOUSE_MODE_CAPTURED
var player_node: Node = null
var dialogue_box: Node = null
var pause_menu: Node = null
var ui_manager: Node = null
var task_manager: Node = null
var current_scene: String = ""

func _ready() -> void:
	print("PlayerController初始化完成")
	
	# 检查当前场景
	var root = get_tree().get_current_scene()
	if root:
		current_scene = root.name
		print("当前场景: ", current_scene)
		
		# 只在游戏场景中启用，主菜单中不工作
		if current_scene == "MainMenu":
			print("主菜单场景，PlayerController不启用")
			return
	
	# 初始化节点引用
	# 延迟获取玩家节点，确保玩家已经初始化
	await get_tree().process_frame
	await get_tree().process_frame  # 等待两帧确保所有节点都初始化完成
	
	# 额外等待，确保SpawnPoint完成玩家生成
	var max_retries = 10
	var retry_count = 0
	while retry_count < max_retries and not player_node:
		await get_tree().process_frame
		retry_count += 1
	
	# 尝试多种方式找到玩家节点
	player_node = get_tree().get_first_node_in_group("Player")
	if player_node:
		print("通过Player组找到玩家节点: ", player_node.get_path())
	else:
		player_node = get_node_or_null("/root/Player")
		if player_node:
			print("通过路径找到玩家节点: /root/Player")
	
	if not player_node:
		print("警告：无法找到玩家节点！PlayerController可能无法正常工作")
	
	pause_menu = get_node_or_null("/root/PauseMenu")
	ui_manager = get_node_or_null("/root/UIManager")
	task_manager = get_node_or_null("/root/TaskManager")
	
	# 延迟获取DialogueBox，等待world.gd实例化它
	await get_tree().process_frame
	dialogue_box = get_tree().get_first_node_in_group("DialogueBox")
	if dialogue_box:
		print("通过分组找到DialogueBox: ", dialogue_box.get_path())
	else:
		# 如果通过分组找不到，尝试从父节点查找
		if get_parent() and get_parent().has_node("DialogueBox"):
			dialogue_box = get_parent().get_node("DialogueBox")
			print("从父节点找到DialogueBox: ", dialogue_box.get_path())
		else:
			print("警告：无法找到DialogueBox节点")
	
	# 将控制器添加到组中以便其他脚本可以找到它
	add_to_group("PlayerController")
	
	# PlayerController只在游戏场景中工作，默认捕获鼠标
	set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("PlayerController: 初始化完成，鼠标模式设置为CAPTURED")
	
	# 确保游戏未暂停
	if get_tree().paused:
		get_tree().paused = false
	
	# 恢复玩家移动
	if player_node and player_node.has_method("set_movement_enabled"):
		player_node.set_movement_enabled(true)
	
	print("对话状态退出完成，鼠标模式: ", Input.get_mouse_mode())
	
	# 初始状态设置为NORMAL
	_set_state(PlayerState.NORMAL)
	
	# 监听场景变化
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed() -> void:
	var root = get_tree().get_current_scene()
	if root:
		current_scene = root.name
		print("场景变化: ", current_scene)
		
		# 只在游戏场景中工作
		if current_scene == "MainMenu":
			print("切换到主菜单，PlayerController不工作")
			return
		else:
			# 切换到游戏场景时重新初始化
			_initialize_in_game_scene()

func _initialize_in_game_scene() -> void:
	# 在游戏场景中重新初始化
	set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("游戏场景初始化完成，PlayerController启用")
	_set_state(PlayerState.NORMAL)

func set_mouse_mode(mode: int) -> void:
	if current_mouse_mode == mode:
		return
	
	var old_mode = current_mouse_mode
	current_mouse_mode = mode
	Input.mouse_mode = mode
	emit_signal("mouse_mode_changed", old_mode, mode)
	print("鼠标模式变化: ", old_mode, " -> ", mode)

func _input(event: InputEvent) -> void:
	match current_state:
		PlayerState.NORMAL:
			_handle_normal_input(event)
		PlayerState.DIALOGUE:
			_handle_dialogue_input(event)
		PlayerState.PAUSED:
			_handle_paused_input(event)
		PlayerState.MENU:
			_handle_menu_input(event)
		PlayerState.CUTSCENE:
			_handle_cutscene_input(event)

func _handle_normal_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		handle_interact()
	elif event.is_action_pressed("pause"):
		pause_game()

func _handle_dialogue_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # 使用空格键或回车键
		_on_dialogue_space_pressed()
	elif event.is_action_pressed("ui_cancel"):  # 使用ESC键
		_on_dialogue_space_pressed() # 跳过对话也使用相同处理

func _handle_paused_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		resume_game()

func _handle_menu_input(event: InputEvent) -> void:
	# 菜单状态下的输入处理
	pass

func _handle_cutscene_input(event: InputEvent) -> void:
	# 过场动画状态下的输入处理
	pass

func handle_interact() -> void:
	# 交互逻辑
	print("交互！")
	
	# 使用射线检测获取玩家面前的NPC
	if not player_node:
		print("错误：无法获取玩家节点")
		# 尝试重新获取玩家节点
		player_node = get_tree().get_first_node_in_group("Player")
		if not player_node:
			print("错误：无法找到玩家节点")
			return
	
	# 尝试多种路径获取相机
	var player_camera = null
	
	# 尝试方法1：直接获取Camera3D
	player_camera = player_node.get_node_or_null("Camera3D")
	
	# 尝试方法2：通过Pivot获取Camera3D
	if not player_camera:
		player_camera = player_node.get_node_or_null("Pivot/Camera3D")
	
	# 尝试方法3：查找任何Camera3D子节点
	if not player_camera:
		var cameras = player_node.find_children("*", "Camera3D", true, false)
		if cameras.size() > 0:
			player_camera = cameras[0]
	
	if not player_camera:
		print("错误：无法获取玩家相机")
		# 尝试直接与玩家节点交互
		if player_node.is_in_group("interactable") or player_node.has_method("interact"):
			print("玩家交互: ", player_node.get_class())
			if player_node.has_method("interact"):
				player_node.interact()
		return
	
	var raycast = player_camera.get_node_or_null("RayCast3D")
	if not raycast:
		# 尝试在玩家节点上查找RayCast3D
		raycast = player_node.find_child("RayCast3D", true, false)
		
	if not raycast:
		print("错误：无法获取射线检测器")
		return
	
	# 启用射线检测
	raycast.enabled = true
	raycast.force_raycast_update()
	
	print("射线检测状态 - 是否碰撞: ", raycast.is_colliding())
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		print("碰撞到的对象: ", collider)
		print("碰撞对象类型: ", collider.get_class() if collider else "无")
		
		if collider and collider.has_method("interact"):
			print("找到可交互对象，调用interact方法")
			collider.interact()
		else:
			print("碰撞对象没有interact方法，尝试直接开始对话")
		# 简化：如果是NPC组的成员，直接开始对话
		if collider and collider.is_in_group("NPC"):
			start_dialogue(collider)
		else:
			print("碰撞对象不是NPC，无法对话")
	else:
		print("射线没有检测到任何对象")
		# 如果没有检测到对象，尝试查找附近的NPC
		var nearby_npcs = get_tree().get_nodes_in_group("NPC")
		print("附近NPC数量: ", nearby_npcs.size())
		
		if nearby_npcs.size() > 0:
			# 找到最近的NPC
			var closest_npc = null
			var closest_distance = INF
			
			for npc in nearby_npcs:
				var distance = player_node.global_position.distance_to(npc.global_position)
				print("NPC: ", npc.name, " 距离: ", distance)
				if distance < closest_distance and distance < 3.0:  # 3米范围内
					closest_distance = distance
					closest_npc = npc
			
			if closest_npc:
				print("找到最近的NPC: ", closest_npc.name, " 距离: ", closest_distance)
				closest_npc.interact()
			else:
				print("没有NPC在交互范围内")
		else:
			print("场景中没有NPC")

func _set_state(new_state: PlayerState) -> void:
	var old_state = current_state
	current_state = new_state
	emit_signal("state_changed", old_state, new_state)
	
	# 根据新状态执行进入逻辑
	match new_state:
		PlayerState.NORMAL:
			_on_normal_state_entered()
		PlayerState.DIALOGUE:
			_on_dialogue_state_entered()
		PlayerState.PAUSED:
			_on_paused_state_entered()
		PlayerState.MENU:
			_on_menu_state_entered()
		PlayerState.CUTSCENE:
			_on_cutscene_state_entered()

func _on_normal_state_entered() -> void:
	print("进入正常状态")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 启用玩家移动
	if player_node and player_node.has_method("set_movement_enabled"):
		player_node.set_movement_enabled(true)
	
	print("正常状态进入完成，鼠标模式: ", Input.get_mouse_mode())

func _on_dialogue_state_entered() -> void:
	print("进入对话状态")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 禁用玩家移动
	if player_node and player_node.has_method("set_movement_enabled"):
		player_node.set_movement_enabled(false)
	
	print("对话状态进入完成，鼠标模式: ", Input.get_mouse_mode())

func _on_paused_state_entered() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 游戏暂停由pause_menu处理

func _on_menu_state_entered() -> void:
	set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 确保游戏未暂停
	if get_tree().paused:
		get_tree().paused = false

func _on_cutscene_state_entered() -> void:
	set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# 禁用玩家移动
	if player_node and player_node.has_method("set_movement_enabled"):
		player_node.set_movement_enabled(false)

# 辅助函数：获取状态名称
func _get_state_name(state: PlayerState) -> String:
	match state:
		PlayerState.NORMAL:
			return "NORMAL"
		PlayerState.DIALOGUE:
			return "DIALOGUE"
		PlayerState.PAUSED:
			return "PAUSED"
		PlayerState.MENU:
			return "MENU"
		PlayerState.CUTSCENE:
			return "CUTSCENE"
		_:
			return "UNKNOWN"

# 清理对话连接
func _clear_dialogue_connections() -> void:
	# 断开旧的NPC信号连接
	if dialogue_box:
		# 尝试断开可能存在的所有NPC连接
		for node in get_tree().get_nodes_in_group("NPC"):
			if dialogue_box.is_connected("dialogue_completed", Callable(node, "_on_dialogue_completed")):
				dialogue_box.disconnect("dialogue_completed", Callable(node, "_on_dialogue_completed"))
			if dialogue_box.is_connected("dialogue_closed", Callable(node, "_on_dialogue_closed")):
				dialogue_box.disconnect("dialogue_closed", Callable(node, "_on_dialogue_closed"))
			if dialogue_box.is_connected("option_selected", Callable(node, "_on_option_selected")):
				dialogue_box.disconnect("option_selected", Callable(node, "_on_option_selected"))

# 公共接口：开始对话
func start_dialogue(npc_node: Node = null) -> void:
	print("=== PlayerController.start_dialogue被调用 ===")
	print("开始对话 - 当前状态: ", _get_state_name(current_state))
	if current_state != PlayerState.NORMAL:
		print("警告：只有在NORMAL状态才能开始对话")
		return
	
	# 清理任何可能存在的旧连接
	_clear_dialogue_connections()
	
	# 检查NPC节点
	if not npc_node:
		print("错误：NPC节点为空")
		return
		
	print("NPC节点名称: ", npc_node.name)
	
	# 检查是否为NPC组成员
	if not npc_node.is_in_group("NPC"):
		print("警告：节点不是NPC组成员")
		return
	
	# 获取对话框节点
	if not dialogue_box:
		dialogue_box = get_tree().get_first_node_in_group("DialogueBox")
		if not dialogue_box:
			print("错误：找不到对话框节点")
			return
	
	# 设置状态为对话状态
	_set_state(PlayerState.DIALOGUE)
	print("设置状态为对话状态")
	
	# 确保对话框可见
	dialogue_box.visible = true
	
	# 获取NPC名称和对话内容
	var dialogue_lines = []
	var npc_name = ""
	
	if npc_node.has_method("get_dialogue_lines"):
		dialogue_lines = npc_node.get_dialogue_lines()
	else:
		# 直接尝试访问属性
		dialogue_lines = npc_node.dialogue_lines if "dialogue_lines" in npc_node else ["对话内容加载失败"]
		if "dialogue_lines" not in npc_node:
			print("无法获取对话内容，使用默认内容")
	
	# 直接尝试访问npc_name属性
	npc_name = npc_node.npc_name if "npc_name" in npc_node else npc_node.name
	
	print("对话内容: ", dialogue_lines)
	print("NPC名称: ", npc_name)
	
	# 调用对话框的start_dialogue方法
	dialogue_box.start_dialogue(dialogue_lines, npc_name)
	
	# 连接NPC的信号到对话框
	if dialogue_box.has_signal("dialogue_completed") and npc_node.has_method("_on_dialogue_completed"):
		dialogue_box.connect("dialogue_completed", Callable(npc_node, "_on_dialogue_completed"))
	
	if dialogue_box.has_signal("dialogue_closed") and npc_node.has_method("_on_dialogue_closed"):
		dialogue_box.connect("dialogue_closed", Callable(npc_node, "_on_dialogue_closed"))
	
	if dialogue_box.has_signal("option_selected") and npc_node.has_method("_on_option_selected"):
		dialogue_box.connect("option_selected", Callable(npc_node, "_on_option_selected"))

# 公共接口：结束对话
func end_dialogue() -> void:
	print("结束对话 - 当前状态: ", _get_state_name(current_state))
	if current_state != PlayerState.DIALOGUE:
		print("警告：只有在DIALOGUE状态才能结束对话")
		# 强制恢复NORMAL状态防止卡死
		_set_state(PlayerState.NORMAL)
		return
	
	# 清理信号连接
	_clear_dialogue_connections()
	
	_set_state(PlayerState.NORMAL)
	print("设置状态为正常状态")
	
	# 确保对话框节点存在
	if not dialogue_box:
		dialogue_box = get_node_or_null("/root/DialogueBox")
		if not dialogue_box:
			dialogue_box = get_tree().get_first_node_in_group("DialogueBox")
	
	# 隐藏对话框
	if dialogue_box:
		print("隐藏对话框")
		if dialogue_box.has_method("hide_dialogue"):
			dialogue_box.hide_dialogue()
		elif dialogue_box.has_method("close_dialogue"):
			dialogue_box.close_dialogue()
		else:
			dialogue_box.visible = false
		
		# 清理对话框内部状态
		if dialogue_box.has_method("clear_dialogue"):
			dialogue_box.clear_dialogue()
	else:
		print("警告：结束对话时找不到对话框节点")

# 公共接口：暂停游戏
func pause_game() -> void:
	if current_state == PlayerState.PAUSED or current_state == PlayerState.MENU:
		return
	
	_set_state(PlayerState.PAUSED)
	
	# 游戏暂停由pause_menu处理
	get_tree().paused = true
	
	# 显示暂停菜单
	if pause_menu and pause_menu.has_method("pause_game"):
		pause_menu.pause_game()
	else:
		# 尝试通过场景路径直接获取
		pause_menu = get_node_or_null("/root/PauseMenu")
		if pause_menu and pause_menu.has_method("pause_game"):
			pause_menu.pause_game()
		else:
			# 尝试通过节点组获取
			pause_menu = get_tree().get_first_node_in_group("PauseMenu")
			if pause_menu and pause_menu.has_method("pause_game"):
				pause_menu.pause_game()

# 公共接口：恢复游戏
func resume_game() -> void:
	if current_state != PlayerState.PAUSED:
		return
	
	_set_state(PlayerState.NORMAL)
	
	# 确保鼠标被捕获
	set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 隐藏暂停菜单
	if pause_menu and pause_menu.has_method("resume_game"):
		pause_menu.resume_game()
	else:
		# 尝试通过场景路径直接获取
		pause_menu = get_node_or_null("/root/PauseMenu")
		if pause_menu and pause_menu.has_method("resume_game"):
			pause_menu.resume_game()
		else:
			# 尝试通过节点组获取
			pause_menu = get_tree().get_first_node_in_group("PauseMenu")
			if pause_menu and pause_menu.has_method("resume_game"):
				pause_menu.resume_game()
			else:
				# 如果找不到暂停菜单，直接恢复游戏状态
				get_tree().paused = false



# 公共接口：开始过场动画
func start_cutscene() -> void:
	_set_state(PlayerState.CUTSCENE)

# 公共接口：结束过场动画
func end_cutscene() -> void:
	if current_state != PlayerState.CUTSCENE:
		return
	
	_set_state(PlayerState.NORMAL)

# 获取当前状态
func get_current_state() -> PlayerState:
	return current_state

# 检查是否在特定状态
func is_in_state(state: PlayerState) -> bool:
	return current_state == state

# 检查是否允许移动
func is_movement_allowed() -> bool:
	return current_state == PlayerState.NORMAL

# 检查是否允许交互
func is_interaction_allowed() -> bool:
	return current_state == PlayerState.NORMAL or current_state == PlayerState.CUTSCENE

func _on_dialogue_box_closed() -> void:
	# 对话框关闭后，恢复正常状态
	_set_state(PlayerState.NORMAL)
	# 延迟设置鼠标模式，确保场景加载完成
	await get_tree().create_timer(0.5).timeout
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_dialogue_space_pressed() -> void:
	if dialogue_box and dialogue_box.has_method("handle_space"):
		dialogue_box.handle_space()
