extends Node

## 序章环境管理器
## 注册环境渐变对象和初始化序章特有系统
## 作者：AI Assistant
## 日期：2025-10-04

# 环境对象引用
var water_stain: Node3D
var wall_peel: Node3D
var ceiling: Node3D
var crack_light: Node3D

func _ready():
	print("[PrologueEnvironment] 初始化序章环境...")
	
	# 等待场景完全加载
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 查找环境对象
	find_environment_objects()
	
	# 注册到环境进度系统
	register_environment_objects()
	
	# 设置总物品数量（用于计算进度）
	var env_sys = get_node_or_null("/root/EnvironmentProgressSystem")
	if env_sys:
		env_sys.total_items = 7 # 挂钟、行李、票据 + 4个新物品
		print("[PrologueEnvironment] 设置总物品数：7")

func find_environment_objects():
	var root = get_tree().current_scene
	if not root:
		print("[PrologueEnvironment] 警告：当前场景不存在")
		return
	
	# 查找环境效果节点
	water_stain = root.get_node_or_null("EnvironmentEffects/WaterStain")
	wall_peel = root.get_node_or_null("EnvironmentEffects/WallPeel")
	ceiling = root.get_node_or_null("EnvironmentEffects/Ceiling")
	crack_light = root.get_node_or_null("EnvironmentEffects/CrackLight")
	
	# 输出找到的对象
	print("[PrologueEnvironment] 水渍: ", "找到" if water_stain else "未找到")
	print("[PrologueEnvironment] 墙皮: ", "找到" if wall_peel else "未找到")
	print("[PrologueEnvironment] 天花板: ", "找到" if ceiling else "未找到")
	print("[PrologueEnvironment] 裂缝光: ", "找到" if crack_light else "未找到")

func register_environment_objects():
	var env_sys = get_node_or_null("/root/EnvironmentProgressSystem")
	if not env_sys:
		print("[PrologueEnvironment] 警告：EnvironmentProgressSystem 未找到")
		return
	
	# 注册环境对象
	if water_stain:
		env_sys.register_water_stain(water_stain)
	if wall_peel:
		env_sys.register_wall_peel(wall_peel)
	if ceiling:
		env_sys.register_ceiling(ceiling)
	if crack_light:
		env_sys.register_crack_light(crack_light)
	
	print("[PrologueEnvironment] 环境对象注册完成")

# 手动触发测试（用于调试）
func _input(event):
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F4:
			# F4: 测试环境渐变
			var env_sys = get_node_or_null("/root/EnvironmentProgressSystem")
			if env_sys:
				env_sys.on_item_investigated()
				print("[PrologueEnvironment] [测试] 手动触发环境进度")
