extends Node

signal state_changed(old_state, new_state)
signal mouse_mode_changed(old_mode, new_mode)

enum PlayerState {
	NORMAL = 0, # 正常游戏状态
	DIALOGUE = 1, # 对话状态
	PAUSED = 2, # 暂停状态
	MENU = 3, # 在菜单中
	CUTSCENE = 4 # 过场动画状态
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
	# 使用更高效的方式获取玩家节点
	call_deferred("_initialize_player_node")
	# 初始化射线检测（延迟一帧，容错玩家节点未就绪）
	call_deferred("_initialize_raycast")

func _initialize_player_node() -> void:
	# 通过组查找玩家节点
	player_node = get_tree().get_first_node_in_group("Player")
	if not player_node:
		# 尝试其他方法获取玩家节点
		player_node = get_node_or_null("/root/Player")
		if not player_node:
			# 尝试在当前场景中查找
			var current_scene = get_tree().get_current_scene()
			if current_scene:
				player_node = current_scene.get_node_or_null("Player")
				if not player_node:
					# 尝试查找所有可能的路径
					var possible_paths = [
						"Player",
						"World/Player",
						"GameWorld/Player",
						"Level/Player",
						"YSort/Player"
					]
					for path in possible_paths:
						player_node = current_scene.get_node_or_null(path)
						if player_node:
							print("在路径找到玩家节点: ", path)
							break
			
			if not player_node:
				print("错误：无法获取玩家节点")
				return
	
	print("成功初始化玩家节点: ", player_node.name)
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
	if event.is_action_pressed("ui_accept"): # 使用空格键或回车键
		_on_dialogue_space_pressed()
	elif event.is_action_pressed("ui_cancel"): # 使用ESC键
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
	
	# 使用射线检测获取玩家前面的NPC
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
	
	# 直接使用player.gd中的射线检测
	if not player_node:
		print("错误：玩家节点未初始化")
		return
		
	# 尝试多种可能的射线检测器路径
	var raycast = null
	var possible_paths = [
		"Head/Camera3D/RayCast3D",
		"Camera3D/RayCast3D",
		"Pivot/Camera3D/RayCast3D",
		"RayCast3D"
	]
	
	for path in possible_paths:
		raycast = player_node.get_node_or_null(path)
		if raycast:
			print("在路径找到射线检测器: ", path)
			break
		
	if not raycast:
		print("错误：无法获取玩家射线检测器")
		return
	
	# 启用射线检测
	raycast.enabled = true
	raycast.force_raycast_update()
	
	# 获取交互提示UI - 尝试多种可能的路径
	var interaction_hint = get_node_or_null("/root/GameWorld/UI/InteractionHint")
	if not interaction_hint:
		interaction_hint = get_node_or_null("/root/world/UI/InteractionHint")
	if not interaction_hint:
		interaction_hint = get_node_or_null("../../UI/InteractionHint")
	if not interaction_hint:
		interaction_hint = get_node_or_null("/root/UI/InteractionHint")
	if not interaction_hint:
		interaction_hint = get_node_or_null("/root/InteractionHint")
	
	print("射线检测状态 - 是否碰撞: ", raycast.is_colliding())
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		print("碰撞到的对象: ", collider)
		print("碰撞对象类型: ", collider.get_class() if collider else "无")
		
		# 显示交互提示
		if interaction_hint and (collider.is_in_group("interactable") or collider.is_in_group("NPC") or collider.has_method("interact")):
			interaction_hint.visible = true
			interaction_hint.text = "按 E 互动"
			print("显示交互提示: 按 E 互动")
		
		if collider and collider.has_method("interact"):
			print("找到可交互对象，调用interact方法")
			collider.interact()
		
		# 如果是NPC组的成员，直接开始对话
		if collider and collider.is_in_group("NPC"):
			start_dialogue(collider)
		else:
			print("碰撞对象不是NPC，无法对话")
	else:
		# 隐藏交互提示
		if interaction_hint:
			interaction_hint.visible = false
		print("射线没有检测到任何对象")

# 这些函数已在文件前面定义，此处删除重复定义

# 这些函数已在文件前面定义，此处删除重复定义
# 请参考文件前面的函数定义（298-526行）

# 射线检测相关
var raycast: RayCast3D
var raycast_enabled: bool = true

func _initialize_raycast() -> void:
	if not player_node:
		print("警告：_initialize_raycast时player_node为空")
		return
	
	# 优先使用玩家场景中已有的RayCast3D
	raycast = _get_existing_raycast()
	if raycast:
		raycast.enabled = true
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		print("射线检测采用现有节点: ", raycast.get_path())
		return
	
	# 查找玩家相机（多种可能路径）
	var cam = player_node.get_node_or_null("Camera3D")
	if not cam:
		cam = player_node.get_node_or_null("Pivot/Camera3D")
	if not cam:
		var cams = player_node.find_children("*", "Camera3D", true, false)
		if cams.size() > 0:
			cam = cams[0]
	
	if cam:
		# 创建新的RayCast3D并挂载到相机
		raycast = RayCast3D.new()
		raycast.enabled = true
		raycast.collide_with_bodies = true
		raycast.collide_with_areas = true
		# 增加检测距离，避免过近导致无法命中
		raycast.target_position = Vector3(0, 0, -4)
		raycast.collision_mask = 0xFFFFFFFF # 兼容所有层，避免因层不一致而检测失败
		cam.add_child(raycast)
		print("射线检测已初始化并挂载到: ", cam.get_path())
	else:
		print("警告：无法初始化射线检测，找不到Camera3D节点")

func _get_existing_raycast() -> RayCast3D:
	if not player_node:
		return null
	var possible_paths = [
		"Head/Camera3D/RayCast3D",
		"Camera3D/RayCast3D",
		"Pivot/Camera3D/RayCast3D",
		"RayCast3D"
	]
	for path in possible_paths:
		var rc = player_node.get_node_or_null(path)
		if rc:
			return rc
	return null

func _process(delta):
	# 只在NORMAL状态下处理交互检测
	if current_state != PlayerState.NORMAL:
		# 非NORMAL状态下隐藏交互提示
		var hint = _find_interaction_hint()
		if hint:
			hint.visible = false
		return
		
	# 若raycast尚未就位，尝试获取或初始化
	if not raycast:
		raycast = _get_existing_raycast()
		if not raycast:
			_initialize_raycast()
		else:
			raycast.enabled = true
			
	if not raycast:
		return  # 如果射线仍然不可用，直接返回

	# 确保射线启用
	raycast.enabled = true
	
	# 强制更新一次，避免首次不检测
	raycast.force_raycast_update()
	
	# 获取交互提示UI
	var hint = _find_interaction_hint()
	if not hint:
		return  # 如果找不到提示UI，直接返回
		
	# 默认隐藏提示
	var should_show_hint = false
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# 检查碰撞对象是否可交互
		if collider:
			# 直接检查碰撞对象
			if collider.is_in_group("interactable") or collider.has_method("interact"):
				should_show_hint = true
			# 检查父对象（处理碰撞体是子节点的情况）
			elif collider.get_parent() and (collider.get_parent().is_in_group("interactable") or collider.get_parent().has_method("interact")):
				should_show_hint = true
	
	# 根据检测结果设置提示可见性
	hint.visible = should_show_hint
	if should_show_hint:
		hint.text = "按 E 互动"

# 查找交互提示UI节点
func _find_interaction_hint():
	var hint = null
	
	# 尝试多种可能的路径
	var possible_paths = [
		"/root/world/UI/InteractionHint",
		"/root/GameWorld/UI/InteractionHint",
		"UI/InteractionHint",
		"/root/UIManager/InteractionHint",
		"/root/InteractionHint"
	]
	
	# 尝试从路径获取
	for path in possible_paths:
		hint = get_node_or_null(path)
		if hint:
			return hint
	
	# 尝试从当前场景查找
	var world = get_tree().current_scene
	if world:
		hint = world.get_node_or_null("InteractionHint")
		if not hint:
			hint = world.get_node_or_null("UI/InteractionHint")
		if not hint:
			hint = world.find_child("InteractionHint", true, false)
	
	return hint

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
	
	# 连接NPC的信号到对话框（避免重复连接）
	if dialogue_box.has_signal("dialogue_completed") and npc_node.has_method("_on_dialogue_completed"):
		if not dialogue_box.is_connected("dialogue_completed", Callable(npc_node, "_on_dialogue_completed")):
			dialogue_box.connect("dialogue_completed", Callable(npc_node, "_on_dialogue_completed"))
	
	if dialogue_box.has_signal("dialogue_closed") and npc_node.has_method("_on_dialogue_closed"):
		if not dialogue_box.is_connected("dialogue_closed", Callable(npc_node, "_on_dialogue_closed")):
			dialogue_box.connect("dialogue_closed", Callable(npc_node, "_on_dialogue_closed"))
	
	if dialogue_box.has_signal("option_selected") and npc_node.has_method("_on_option_selected"):
		if not dialogue_box.is_connected("option_selected", Callable(npc_node, "_on_option_selected")):
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
	
	# 播放恢复游戏音效
	if AudioManager and AudioManager.has_method("play_sound"):
		AudioManager.play_sound("ui_unpause", -5.0)
	
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
				print("直接恢复游戏状态，未找到暂停菜单")


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
	if dialogue_box and dialogue_box.has_method("process_space_key"):
		dialogue_box.process_space_key()
