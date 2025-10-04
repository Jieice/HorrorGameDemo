extends Node

# 统一的剧情节点数组
var story_nodes = [
	{
		"id": "prologue_clock",
		"type": "item",
		"title": "序章·陌生人",
		"desc": "调查破旧的挂钟",
		"monologue": "这钟……早就停了吧？怎么好像还能听到微弱的滴答声……是我的错觉吗？还是说，在这里，连时间都会骗人。\n（幻觉：耳边响起童年时被呵斥的声音：'哭个不停，碍事！'）",
		"vfx": "vfx_hallucination", # 第一次幻觉，中度冲击
		"next": "prologue_luggage"
	},
	{
		"id": "prologue_luggage",
		"type": "item",
		"title": "序章·陌生人",
		"desc": "翻找角落的旧行李",
		"monologue": "一张……全家福？不，只是一半的全家福。被撕掉的另一半……是被谁，还是被我……亲手毁掉了？我记不清了……或者说，我不敢记起。",
		"vfx": "vfx_medium", # 心理压迫，中度
		"next": "prologue_ticket"
	},
	{
		"id": "prologue_ticket",
		"type": "item",
		"title": "序章·陌生人",
		"desc": "查看地上的旧票据",
		"monologue": "这不是回忆……这是我的票。目的地被水晕开了，看不清楚……也好，去哪里都一样。反正……这场旅途，不是过去，就是现在。我终究是……逃不掉的。",
		"vfx": "vfx_subtle", # 轻度暗角，压抑感
		"next": "prologue_stranger"
	},
	{
		"id": "prologue_stranger",
		"type": "npc",
		"title": "序章·陌生人",
		"desc": "与候车室的陌生人对话",
		"npc_name": "陌生人",
		"dialogue": [
			"……夜色真长，不是吗？",
			"长得足够让一个人……忘记自己本来的样子。",
			"看你的表情，是在等一趟……回家的车？",
			"回家啊……有时候，比流浪还冷。因为流浪是身冷，回家……是心冷。你觉得呢？",
			{"choices": [
				{"text": "疑惑：你到底是谁？", "next": 5, "mask_delta": 10}
			]},
			"我？我是卸下包袱的你，是学会闭嘴的你，是你……未来要学的那张脸。",
			"记住，石头因为太硬，所以只能被踩在脚下。人若想活下去，就要变得像水一样……就要戴上面具。"
		],
		"vfx": "vfx_horror_reveal", # 陌生人揭示真相，最强冲击
		"env_effect": "lights_dim", # 灯光变暗
		"next": null
	}
]

var current_index: int = 0
var current_node = null
var dialogue_box = null
var current_dialogue_line := 0
var is_initialized := false

func _ready():
	# 监听场景切换
	get_tree().node_added.connect(_on_scene_changed)
	# 初始场景检查
	_check_and_initialize()

func _on_scene_changed(node):
	# 当根节点变化时，检查是否是游戏场景
	if node == get_tree().current_scene:
		_check_and_initialize()

func _check_and_initialize():
	await get_tree().process_frame
	var scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	if scene_name == "Main" or scene_name.begins_with("Main-"):
		initialize()

func initialize():
	if is_initialized:
		return
	is_initialized = true
	current_index = 0
	current_node = story_nodes[current_index]
	call_deferred("update_interactables")
	# 播放恐怖环境BGM
	call_deferred("start_ambient_audio")
	# 启动持续的灯光闪烁效果
	call_deferred("start_ambient_lighting")

# 只激活当前剧情节点的互动对象
func update_interactables():
	var root = get_tree().current_scene
	if not root:
		return
	var all_nodes = root.get_tree().get_nodes_in_group("Interactable")
	for node in all_nodes:
		if "story_node_id" in node and "interactable" in node:
			node.interactable = node.story_node_id == current_node["id"]

# 物品互动：显示心理独白
func on_item_interact(story_node_id: String):
	if story_node_id == current_node["id"] and current_node.has("monologue"):
		# 播放音效（如果配置了）
		if current_node.has("sfx"):
			for sfx_name in current_node["sfx"]:
				play_sound(sfx_name)
		# 触发屏幕特效（如果配置了）
		if current_node.has("vfx"):
			trigger_screen_effect(current_node["vfx"])
		show_monologue(current_node["monologue"])
		advance_story()

# NPC互动：弹出对话框
func on_npc_interact(story_node_id: String):
	if story_node_id == current_node["id"] and current_node.has("dialogue"):
		print("[StoryManager] NPC互动，当前节点:", story_node_id)
		# 触发环境效果（如果配置了）
		if current_node.has("env_effect"):
			print("[StoryManager] 触发环境效果:", current_node["env_effect"])
			trigger_env_effect(current_node["env_effect"])
		# 触发屏幕特效（如果配置了）
		if current_node.has("vfx"):
			trigger_screen_effect(current_node["vfx"])
		start_dialogue()

# 显示心理独白（物品互动）
func show_monologue(text: String):
	var DialogueBoxScene = preload("res://Scene/DialogueBox.tscn")
	var dlg_box = DialogueBoxScene.instantiate()
	get_tree().current_scene.add_child(dlg_box)
	dlg_box.show_monologue(text)
	dlg_box.dialogue_closed.connect(_on_monologue_closed)
	set_player_dialogue_active(true)

func _on_monologue_closed():
	set_player_dialogue_active(false)

# 开始NPC对话
func start_dialogue():
	if dialogue_box == null or not is_instance_valid(dialogue_box):
		var DialogueBoxScene = preload("res://Scene/DialogueBox.tscn")
		dialogue_box = DialogueBoxScene.instantiate()
		get_tree().current_scene.add_child(dialogue_box)
		dialogue_box.dialogue_advanced.connect(_on_dialogue_advanced)
		dialogue_box.choice_selected.connect(_on_choice_selected)
		current_dialogue_line = 0
		set_player_dialogue_active(true)
		# 对话开始时，摄像机FOV轻微收窄
		trigger_dialogue_camera_effect(true)
	show_next_dialogue_line()

# 推进对话
func show_next_dialogue_line():
	if not current_node.has("dialogue"):
		return
	var dialogue = current_node["dialogue"]
	if current_dialogue_line < dialogue.size():
		var line = dialogue[current_dialogue_line]
		if typeof(line) == TYPE_STRING:
			dialogue_box.show_dialogue(current_node.get("npc_name", "???"), line, [])
			current_dialogue_line += 1
		elif typeof(line) == TYPE_DICTIONARY and line.has("choices"):
			dialogue_box.show_dialogue(current_node.get("npc_name", "???"), "请选择：", line["choices"])
	else:
		end_dialogue()

func _on_dialogue_advanced():
	show_next_dialogue_line()

func _on_choice_selected(index: int):
	var dialogue = current_node["dialogue"]
	var line = dialogue[current_dialogue_line]
	var choice = line["choices"][index]
	# 处理面具完整度变化
	if choice.has("mask_delta"):
		change_mask_integrity(choice["mask_delta"])
	# 跳转到指定对话行
	if choice.has("next"):
		current_dialogue_line = choice["next"]
	else:
		current_dialogue_line += 1
	show_next_dialogue_line()

func end_dialogue():
	if dialogue_box and is_instance_valid(dialogue_box):
		dialogue_box.queue_free()
		dialogue_box = null
	current_dialogue_line = 0
	# 对话结束演出（序章特殊：灯光熄灭 + 汽笛声）
	if current_node["id"] == "prologue_stranger":
		trigger_ending_sequence()
	else:
		set_player_dialogue_active(false)
		trigger_dialogue_camera_effect(false)
		advance_story()

# 推进剧情到下一个节点
func advance_story():
	if current_node["next"] == null:
		# 剧情已结束或章节切换
		return
	# 查找下一个节点索引
	for i in range(story_nodes.size()):
		if story_nodes[i]["id"] == current_node["next"]:
			current_index = i
			current_node = story_nodes[current_index]
			update_interactables()
			show_task_hint() # 推进到下一个节点后显示新任务
			return

# 显示任务提示
func show_task_hint():
	var ui = get_node_or_null("/root/TaskHintUI")
	if ui and current_node.has("title") and current_node.has("desc"):
		ui.show_task(current_node["title"], current_node["desc"])

# 统一管理玩家对话状态
func set_player_dialogue_active(active: bool):
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0:
		player[0].set_dialogue_active(active)

# 面具完整度变化
func change_mask_integrity(delta: int):
	var mask_mgr = get_node_or_null("/root/MaskManager")
	if mask_mgr:
		mask_mgr.change_integrity(delta)

# 触发屏幕特效
func trigger_screen_effect(effect_name: String):
	var screen_effects = get_node_or_null("/root/ScreenEffects")
	if screen_effects and screen_effects.has_method(effect_name):
		screen_effects.call(effect_name)

# 触发环境效果（灯光变化等）
func trigger_env_effect(effect_name: String):
	match effect_name:
		"lights_flicker":
			flicker_lights()
		"lights_dim":
			dim_lights()

# 灯光闪烁
func flicker_lights():
	var lighting = get_node_or_null("/root/LightingController")
	if lighting:
		lighting.flicker_lights()

# 灯光变暗
func dim_lights():
	print("[StoryManager] dim_lights called")
	var lighting = get_node_or_null("/root/LightingController")
	if lighting:
		print("[StoryManager] LightingController 找到，调用 dim_lights")
		lighting.dim_lights(0.4, 1.5)
	else:
		print("[StoryManager] LightingController 未找到")

# 启动环境音效
func start_ambient_audio():
	print("[StoryManager] start_ambient_audio called")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		print("[StoryManager] AudioManager 找到，播放 BGM")
		# 播放恐怖环境BGM
		audio_mgr.play_bgm("horror_ambient", 3.0)
	else:
		print("[StoryManager] AudioManager 未找到")

# 播放音效
func play_sound(sfx_name: String, volume_offset: float = 0.0):
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		# 心跳声音量稍微提升
		if sfx_name == "heartbeat":
			audio_mgr.play_sfx(sfx_name, 3.0 + volume_offset)
		else:
			audio_mgr.play_sfx(sfx_name, volume_offset)

# 启动环境灯光效果
func start_ambient_lighting():
	var lighting = get_node_or_null("/root/LightingController")
	if lighting:
		# 持续不规律闪烁，营造恐怖氛围
		lighting.ambient_flicker(999.0) # 持续闪烁

# 对话时摄像机效果
var original_fov: float = 75.0 # 默认FOV

func trigger_dialogue_camera_effect(start: bool):
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0:
		var cam = player[0].get_node_or_null("Pivot/Camera3D")
		if cam:
			var cam_effects = get_node_or_null("/root/CameraEffects")
			if cam_effects:
				if start:
					# 保存原始FOV
					original_fov = cam.fov
					# 对话开始：FOV极轻微收窄（2度，3秒渐变，让玩家几乎察觉不到）
					cam_effects.fov_dialogue_start(cam, 2.0, 3.0)
				else:
					# 对话结束：FOV恢复（3秒渐变）
					cam_effects.fov_dialogue_end(cam, original_fov, 3.0)

# 序章结尾演出（陌生人对话结束）
func trigger_ending_sequence():
	print("[StoryManager] 开始序章结尾列车到站序列...")

	# 启动列车到站序列
	var train_mgr = get_node_or_null("/root/TrainArrivalManager")
	if train_mgr:
		train_mgr.start_sequence()

		# 等待列车到站序列完成
		await train_mgr.sequence_ended

	# 恢复玩家控制
	set_player_dialogue_active(false)
	trigger_dialogue_camera_effect(false)

	# 章节切换（暂时只推进剧情）
	advance_story()
	print("[StoryManager] 【序章完成】列车到站序列执行完毕")
