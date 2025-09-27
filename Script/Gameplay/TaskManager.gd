extends Node

signal task_updated(task_id, status)
signal task_completed(task_id)
signal new_task_added(task_id)
signal mask_integrity_changed(old_value: int, new_value: int)
signal mask_emotional_state_changed(old_state: String, new_state: String)
signal mask_hallucination_triggered(intensity: float, type: String)
signal inner_monologue_triggered(text: String, priority: String)
signal choice_presented(options: Array, context: String)
signal ending_triggered(ending_type: String)
signal environment_effect_changed(effect_name: String, value: float)

# 面具完整度系统
class MaskIntegrity:
	var current_value: int = 50  # 初始面具完整度
	var max_value: int = 100
	var min_value: int = 0
	var degradation_rate: float = 0.05  # 每秒自然衰减率
	var emotional_state: String = "neutral"  # 情绪状态: angry, fearful, confused, numb, cold
	var hallucination_intensity: float = 0.0  # 幻觉强度
	var last_change_time: float = 0.0  # 上次变化时间
	var environment_effects: Dictionary = {
		"sound_distortion": 0.0,  # 声音失真程度
		"visual_distortion": 0.0,  # 视觉失真程度
		"stranger_frequency": 0.0  # 陌生人出现频率
	}
	
	func _init():
		current_value = 50
		last_change_time = Time.get_unix_time_from_system()
		_update_derived_values()
	
	func modify_value(amount: int) -> int:
		var old_value = current_value
		current_value = clamp(current_value + amount, min_value, max_value)
		last_change_time = Time.get_unix_time_from_system()
		_update_derived_values()
		return old_value
	
	func get_percentage() -> float:
		return float(current_value) / max_value
	
	func get_level() -> String:
		var percentage = get_percentage()
		if percentage >= 0.8:
			return "完整"
		elif percentage >= 0.6:
			return "轻微破损"
		elif percentage >= 0.4:
			return "中度破损"
		elif percentage >= 0.2:
			return "严重破损"
		else:
			return "破碎"
	
	# 更新派生值（情绪状态、幻觉强度等）
	func _update_derived_values() -> void:
		var percentage = get_percentage()
		
		# 更新情绪状态
		if percentage < 0.2:
			emotional_state = "angry"  # 愤怒
		elif percentage < 0.4:
			emotional_state = "fearful"  # 恐惧
		elif percentage < 0.6:
			emotional_state = "confused"  # 困惑
		elif percentage < 0.8:
			emotional_state = "numb"  # 麻木
		else:
			emotional_state = "cold"  # 冷漠
		
		# 更新幻觉强度 - 低完整度时更强
		hallucination_intensity = 1.0 - percentage
		
		# 更新环境效果
		environment_effects["sound_distortion"] = 0.8 - percentage * 0.6  # 低完整度时声音更失真
		environment_effects["visual_distortion"] = 0.7 - percentage * 0.5  # 低完整度时视觉更失真
		environment_effects["stranger_frequency"] = percentage * 0.8  # 高完整度时陌生人出现更频繁
	
	# 获取当前情绪状态
	func get_emotional_state() -> String:
		return emotional_state
	
	# 获取幻觉强度
	func get_hallucination_intensity() -> float:
		return hallucination_intensity
	
	# 获取环境效果
	func get_environment_effects() -> Dictionary:
		return environment_effects
	
	# 获取面具完整度变化后的时间（秒）
	func get_time_since_last_change() -> float:
		return Time.get_unix_time_from_system() - last_change_time

class Task:
	var id: String
	var title: String
	var description: String
	var completed: bool = false
	var active: bool = false
	var hint_text: String = ""
	var mask_impact: int = 0  # 任务完成对面具完整度的影响
	var choice_options: Array = []  # 任务相关的选择选项
	var inner_monologue: String = ""  # 任务相关的内心独白
	var trigger_conditions: Dictionary = {}  # 触发条件
	var ending_trigger: String = ""  # 任务完成可能触发的结局
	
	func _init(p_id: String, p_title: String, p_description: String, p_hint_text: String = "", 
				p_mask_impact: int = 0, p_choice_options: Array = [], p_inner_monologue: String = ""):
		id = p_id
		title = p_title
		description = p_description
		hint_text = p_hint_text
		mask_impact = p_mask_impact
		choice_options = p_choice_options
		inner_monologue = p_inner_monologue

var tasks: Dictionary = {}  # 存储所有任务
var active_tasks: Array = []  # 当前活跃的任务
var completed_tasks: Array = []  # 已完成的任务
var mask_integrity: MaskIntegrity  # 面具完整度实例

# 节点引用
@onready var player_controller: Node = get_parent().get_node_or_null("PlayerController")
@onready var ui_manager: Node = get_node_or_null("/root/UIManager")

func _ready():
	# 如果在父节点中找不到PlayerController，尝试从根节点获取（向后兼容）
	if not player_controller:
		player_controller = get_node_or_null("/root/PlayerController")
	# 将任务管理器添加到自动加载
	add_to_group("TaskManager")
	
	# 初始化面具完整度系统
	mask_integrity = MaskIntegrity.new()
	print("面具完整度系统初始化完成，当前值: ", mask_integrity.current_value)
	
	# 连接PlayerController的信号
	if player_controller:
		player_controller.connect("state_changed", _on_player_state_changed)
	
	# 启动面具完整度自然衰减
	var decay_timer = Timer.new()
	decay_timer.wait_time = 1.0
	decay_timer.timeout.connect(_on_mask_decay)
	add_child(decay_timer)
	decay_timer.start()
	
	# 添加测试任务
	_add_test_tasks()

# 添加新任务 - 增强版本，支持面具完整度系统
func add_task(task_id: String, title: String, description: String, hint_text: String = "", 
			  mask_impact: int = 0, choice_options: Array = [], inner_monologue: String = "", ending_trigger: String = ""):
	if not tasks.has(task_id):
		var new_task = Task.new(task_id, title, description, hint_text, mask_impact, choice_options, inner_monologue)
		new_task.ending_trigger = ending_trigger
		tasks[task_id] = new_task
		# 自动激活新任务
		activate_task(task_id)
		emit_signal("new_task_added", task_id)
		print("任务已添加: ", title, " (面具影响: ", mask_impact, ")")
		return true
	else:
		# 如果任务已存在但未激活，则激活它
		if not tasks[task_id].active:
			activate_task(task_id)
		return false

# 激活任务
func activate_task(task_id: String):
	if tasks.has(task_id):
		var task = tasks[task_id]
		if not task.active and not task.completed:
			task.active = true
			active_tasks.append(task_id)
			emit_signal("task_updated", task_id, "activated")
			print("任务已激活: ", task.title)
			return true
		elif task.active:
			print("任务 ", task.title, " 已经激活了")
		elif task.completed:
			print("任务 ", task.title, " 已经完成，无法再次激活")
	return false

# 完成任务
func complete_task(task_id: String):
	return _mark_task_completed(task_id)

# 获取任务
func get_task(task_id: String):
	if tasks.has(task_id):
		return tasks[task_id]
	return null

# 获取所有活跃任务
func get_active_tasks():
	var active_task_objects = []
	for task_id in active_tasks:
		active_task_objects.append(tasks[task_id])
	return active_task_objects

# 获取所有已完成任务
func get_completed_tasks():
	var completed_task_objects = []
	for task_id in completed_tasks:
		completed_task_objects.append(tasks[task_id])
	return completed_task_objects

# 检查任务是否完成
func is_task_completed(task_id: String):
	if tasks.has(task_id):
		return tasks[task_id].completed
	return false

# 检查任务是否活跃
func is_task_active(task_id: String):
	if tasks.has(task_id):
		return tasks[task_id].active
	return false

# 获取任务提示文本
func get_task_hint(task_id: String):
	if tasks.has(task_id):
		var task = tasks[task_id]
		if task.active and not task.completed:
			return task.hint_text
	return ""
	
# 获取任务标题
func get_task_title(task_id: String):
	if tasks.has(task_id):
		return tasks[task_id].title
	return "未知任务"

# 获取所有活跃任务的提示文本
func get_all_active_hints():
	var hints = []
	for task_id in active_tasks:
		var task = tasks[task_id]
		if task.active and not task.completed:
			# 如果有提示文本，使用提示文本，否则使用任务描述
			if not task.hint_text.is_empty():
				hints.append(task.hint_text)
			else:
				hints.append(task.description)
	print("当前活跃任务提示: ", hints)
	return hints

# 通过关键字完成任务
func _complete_task_by_keyword(keyword: String):
	for task_id in active_tasks:
		var task = tasks[task_id]
		# 检查任务描述或提示文本中是否包含关键字
		if task.description.find(keyword) != -1 or task.hint_text.find(keyword) != -1:
			_mark_task_completed(task_id)
			return true
	return false

# 通过位置名称完成任务（到达某地）
func complete_task_by_location(location_name: String):
	return _complete_task_by_keyword(location_name)

# 通过NPC名称完成任务（与某人聊天）
func complete_task_by_npc(npc_name: String):
	return _complete_task_by_keyword(npc_name)

# 通过物体名称完成任务（获得物品或与物体互动）
func complete_task_by_object(object_name: String):
	return _complete_task_by_keyword(object_name)

# 内部函数：标记任务为已完成
func _mark_task_completed(task_id: String):
	if tasks.has(task_id):
		var task = tasks[task_id]
		if not task.completed:
			task.completed = true
			task.active = false
			active_tasks.erase(task_id)
			completed_tasks.append(task_id)
			
			# 播放任务完成音效
			_play_task_complete_sound()
			
			# 更新面具完整度
			if task.mask_impact != 0:
				var old_mask_value = mask_integrity.modify_value(task.mask_impact)
				emit_signal("mask_integrity_changed", old_mask_value, mask_integrity.current_value)
				print("面具完整度变化: ", old_mask_value, " -> ", mask_integrity.current_value, 
					  " (等级: ", mask_integrity.get_level(), ")")
			
			# 触发内心独白
			if not task.inner_monologue.is_empty():
				emit_signal("inner_monologue_triggered", task.inner_monologue, "task_completion")
			
			# 触发结局
			if not task.ending_trigger.is_empty():
				emit_signal("ending_triggered", task.ending_trigger)
			
			emit_signal("task_completed", task_id)
			emit_signal("task_updated", task_id, "completed")
			print("任务已完成: ", task.title, " (面具影响: ", task.mask_impact, ")")
			return true
	return false

# 播放任务完成音效
func _play_task_complete_sound():
	# 直接使用AudioManager播放音效，不再自己处理
	if AudioManager and AudioManager.has_method("play_sound"):
		AudioManager.play_sound("task_complete")
	else:
		print("警告: 无法加载任务完成音效")



# 获取所有任务
func get_all_tasks():
	var all_task_objects = []
	for task_id in tasks:
		all_task_objects.append(tasks[task_id])
	return all_task_objects

# 面具完整度系统相关函数
func get_mask_integrity() -> int:
	return mask_integrity.current_value

func get_mask_integrity_percentage() -> float:
	return mask_integrity.get_percentage()

func get_mask_integrity_level() -> String:
	return mask_integrity.get_level()

func modify_mask_integrity(amount: int) -> void:
	var old_value = mask_integrity.current_value
	var old_emotional_state = mask_integrity.get_emotional_state()
	
	# 修改面具完整度值
	mask_integrity.modify_value(amount)
	
	# 发送面具完整度变化信号
	emit_signal("mask_integrity_changed", old_value, mask_integrity.current_value)
	
	# 播放面具完整度变化音效
	_play_mask_change_sound(amount)
	
	# 检查情绪状态是否变化
	var new_emotional_state = mask_integrity.get_emotional_state()
	if old_emotional_state != new_emotional_state:
		emit_signal("mask_emotional_state_changed", old_emotional_state, new_emotional_state)
		print("情绪状态变化: ", old_emotional_state, " -> ", new_emotional_state)
		
		# 根据情绪状态触发不同的内心独白
		var monologue = _get_emotional_state_monologue(new_emotional_state)
		if not monologue.is_empty():
			emit_signal("inner_monologue_triggered", monologue, "emotional_change")
	
	# 获取环境效果并发送信号
	var effects = mask_integrity.get_environment_effects()
	for effect_name in effects:
		emit_signal("environment_effect_changed", effect_name, effects[effect_name])
	
	# 根据幻觉强度触发幻觉
	var hallucination_intensity = mask_integrity.get_hallucination_intensity()
	if hallucination_intensity > 0.6 and randf() < hallucination_intensity * 0.3:
		var hallucination_type = _get_random_hallucination_type(hallucination_intensity)
		emit_signal("mask_hallucination_triggered", hallucination_intensity, hallucination_type)
		print("触发幻觉: ", hallucination_type, " (强度: ", hallucination_intensity, ")")
	
	print("面具完整度修改: ", old_value, " -> ", mask_integrity.current_value, 
		  " (等级: ", mask_integrity.get_level(), ")")

# 播放面具完整度变化音效
func _play_mask_change_sound(amount: int):
	# 在编辑器中不播放音效
	if Engine.is_editor_hint():
		return
		
	# 直接使用AudioManager播放音效，不再自己处理
	if AudioManager and AudioManager.has_method("play_sound"):
		AudioManager.play_sound("mask_change")
		print("警告: 无法加载面具变化音效")

# 根据情绪状态获取对应的内心独白
func _get_emotional_state_monologue(state: String) -> String:
	var monologues = {
		"angry": "为什么他们要这样对我？我无法忍受这种感觉...",
		"fearful": "我感到害怕...这一切太可怕了...",
		"confused": "我不明白发生了什么...一切都很混乱...",
		"numb": "我什么都感觉不到了...这样也许更好...",
		"cold": "这是正确的选择...忍耐是唯一的出路..."
	}
	
	if monologues.has(state):
		return monologues[state]
	return ""

# 获取随机幻觉类型
func _get_random_hallucination_type(intensity: float) -> String:
	var types = []
	
	# 低完整度（高幻觉强度）时，幻觉更具攻击性
	if intensity > 0.7:
		types = ["hostile_whispers", "mocking_laughter", "threatening_shadows"]
	# 高完整度（低幻觉强度）时，幻觉更具诱导性
	else:
		types = ["approving_stranger", "comforting_voice", "guiding_shadow"]
	
	return types[randi() % types.size()]

# 面具完整度自然衰减
func _on_mask_decay() -> void:
	if player_controller and player_controller.current_state == player_controller.PlayerState.NORMAL:
		# 应用自然衰减
		var decay_amount = -int(mask_integrity.degradation_rate)
		if decay_amount != 0:
			modify_mask_integrity(decay_amount)
		
		# 定期检查是否需要触发幻觉
		var hallucination_intensity = mask_integrity.get_hallucination_intensity()
		if randf() < hallucination_intensity * 0.1:
			var hallucination_type = _get_random_hallucination_type(hallucination_intensity)
			emit_signal("mask_hallucination_triggered", hallucination_intensity, hallucination_type)
		
		# 应用环境效果
		_apply_environment_effects()

# 应用环境效果到游戏世界
func _apply_environment_effects() -> void:
	# 在编辑器中不应用音频效果
	if Engine.is_editor_hint():
		return
		
	var effects = mask_integrity.get_environment_effects()
	
	# 应用声音失真效果
	# 确保AudioServer已初始化并可用
	if not Engine.is_editor_hint() and AudioServer != null:
		# 安全检查：确保AudioServer已初始化
		if not is_instance_valid(AudioServer):
			return
			
		# 检查总线是否存在
		if AudioServer.get_bus_count() <= 0 or AudioServer.get_bus_index("Master") == -1:
			return
			
		var master_bus_idx = AudioServer.get_bus_index("Master")
		
		# 检查是否已有失真效果器
		var has_distortion = false
		for i in range(AudioServer.get_bus_effect_count(master_bus_idx)):
			if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectDistortion:
				has_distortion = true
				var distortion = AudioServer.get_bus_effect(master_bus_idx, i)
				distortion.drive = effects["sound_distortion"]
				break
		
		# 如果没有失真效果器，添加一个
		if not has_distortion and effects["sound_distortion"] > 0.1:
			var distortion = AudioEffectDistortion.new()
			distortion.drive = effects["sound_distortion"]
			AudioServer.add_bus_effect(master_bus_idx, distortion)
	
	# 发送环境效果变化信号，让其他系统响应
	for effect_name in effects:
		emit_signal("environment_effect_changed", effect_name, effects[effect_name])
	
	# 根据陌生人出现频率决定是否生成陌生人
	if randf() < effects["stranger_frequency"] * 0.05:
		_spawn_stranger()

# 生成陌生人
func _spawn_stranger() -> void:
	# 这里只是发送信号，实际生成逻辑由其他系统处理
	print("陌生人出现...")
	# 如果有专门的系统处理陌生人生成，可以发送信号
	# emit_signal("stranger_spawn_requested", player_controller.global_position)

# 触发选择对话框
func present_task_choice(task_id: String, choice_context: String = "") -> void:
	if tasks.has(task_id):
		var task = tasks[task_id]
		if task.choice_options.size() > 0:
			emit_signal("choice_presented", task.choice_options, choice_context)

# 处理选择结果
func handle_choice_result(choice_index: int, task_id: String = "") -> void:
	if task_id.is_empty():
		# 全局选择处理
		match choice_index:
			0:  # 选择沉默
				modify_mask_integrity(-5)
				emit_signal("inner_monologue_triggered", "我选择了沉默...也许这是最好的选择", "choice")
			1:  # 选择反抗
				modify_mask_integrity(-10)
				emit_signal("inner_monologue_triggered", "我必须反抗！不能就这样屈服！", "choice")
			2:  # 选择妥协
				modify_mask_integrity(-3)
				emit_signal("inner_monologue_triggered", "有时候妥协是必要的...", "choice")
	else:
		# 特定任务选择处理
		if tasks.has(task_id):
			var task = tasks[task_id]
			if choice_index < task.choice_options.size():
				var choice = task.choice_options[choice_index]
				if choice.has("mask_impact"):
					modify_mask_integrity(choice.mask_impact)
				if choice.has("inner_monologue"):
					emit_signal("inner_monologue_triggered", choice.inner_monologue, "task_choice")

# 玩家状态变化处理
func _on_player_state_changed(old_state, new_state):
	# 根据玩家状态控制任务更新
	print("任务系统检测到玩家状态变化: 从 ", old_state, " 到 ", new_state)
	match new_state:
		0: # NORMAL
			print("玩家状态变为正常，任务系统正常运行")
		1: # DIALOGUE
			print("玩家进入对话状态，任务系统继续运行")
		2: # PAUSED
			print("游戏暂停，任务系统暂停更新")
		3: # IN_MENU
			print("玩家在菜单中，任务系统暂停更新")
		4: # IN_CUTSCENE
			print("玩家在过场动画中，任务系统暂停更新")
		_:
			print("未知玩家状态: ", new_state)

# 添加测试任务
func _add_test_tasks() -> void:
	# 基础任务（无面具影响）
	add_task("find_key", "找到钥匙", "在房间里找到一把古老的钥匙", "搜索房间的每个角落")
	
	# 面具影响任务
	add_task("face_fear", "面对恐惧", "我必须面对内心的恐惧", 
			 "倾听内心的声音，做出选择", -10, 
			 [
				 {"text": "选择沉默", "mask_impact": -5, "inner_monologue": "沉默是金，但代价是什么？"},
				 {"text": "大声反抗", "mask_impact": -15, "inner_monologue": "我必须发声，即使代价是破碎！"},
				 {"text": "寻求妥协", "mask_impact": -3, "inner_monologue": "平衡是智慧的选择"}
			 ],
			 "内心的恐惧正在侵蚀我的面具...")
	
	add_task("help_stranger", "帮助陌生人", "一个神秘的陌生人需要帮助",
			 "决定是否要帮助这个陌生人", 5,
			 [
				 {"text": "提供帮助", "mask_impact": 5, "inner_monologue": "善良会让面具更加坚固"},
				 {"text": "拒绝帮助", "mask_impact": -8, "inner_monologue": "冷漠也是一种选择，但会让面具出现裂痕"},
				 {"text": "询问更多信息", "mask_impact": 0, "inner_monologue": "谨慎是明智的"}
			 ],
			 "陌生人的眼神让我感到不安...")
	
	add_task("confront_truth", "面对真相", "真相总是残酷的，但必须面对",
			 "准备好面对残酷的真相了吗？", -20,
			 [],
			 "真相会让我自由，还是会让我彻底破碎？",
			 "truth_ending")
	
	print("测试任务添加完成，共添加 ", tasks.size(), " 个任务")
