extends Node

# 灯光控制器 - 统一控制场景内所有灯光

# 获取场景内所有 OmniLight3D
func get_all_lights() -> Array:
	# 直接从场景根节点查找所有 OmniLight3D
	var all_lights = get_tree().current_scene.find_children("*", "OmniLight3D", true, false)
	return all_lights

# 设置所有灯光的能量（亮度）
func set_all_lights_energy(energy: float, duration: float = 0.0):
	var lights = get_all_lights()
	for light in lights:
		if duration > 0:
			var tween = create_tween()
			tween.tween_property(light, "light_energy", energy, duration)
		else:
			light.light_energy = energy

# 调整所有灯光亮度（相对）
func adjust_all_lights(multiplier: float, duration: float = 1.0):
	var lights = get_all_lights()
	for light in lights:
		var target_energy = light.light_energy * multiplier
		if duration > 0:
			var tween = create_tween()
			tween.tween_property(light, "light_energy", target_energy, duration)
		else:
			light.light_energy = target_energy

# 灯光闪烁（恐怖游戏风格：随机不规律闪烁）
func flicker_lights(times: int = 3, interval: float = 0.1):
	var lights = get_all_lights()
	if lights.size() == 0:
		print("[LightingController] 没有找到灯光")
		return
	# 保存原始亮度
	var original_energies = {}
	for light in lights:
		original_energies[light] = light.light_energy
	# 随机闪烁
	for i in range(times):
		# 随机选择部分灯光熄灭
		for light in lights:
			if randf() < 0.7: # 70%概率熄灭
				light.light_energy = original_energies[light] * randf_range(0.1, 0.3)
		await get_tree().create_timer(interval * randf_range(0.5, 1.0)).timeout
		# 恢复
		for light in lights:
			light.light_energy = original_energies[light]
		await get_tree().create_timer(interval * randf_range(1.0, 2.0)).timeout

# 持续不规律闪烁（环境效果）
func ambient_flicker(duration: float = 5.0):
	var elapsed = 0.0
	while elapsed < duration:
		# 每次循环重新获取灯光，避免访问已释放的节点
		var lights = get_all_lights()
		if lights.size() == 0:
			await get_tree().create_timer(1.0).timeout
			elapsed += 1.0
			continue
		# 随机选择1-2个灯光闪烁
		var num_flicker = randi() % 2 + 1
		for i in range(num_flicker):
			if lights.size() > 0:
				var random_light = lights[randi() % lights.size()]
				if is_instance_valid(random_light):
					var original_energy = random_light.light_energy
					random_light.light_energy = original_energy * randf_range(0.2, 0.5)
					await get_tree().create_timer(randf_range(0.05, 0.12)).timeout
					if is_instance_valid(random_light):
						random_light.light_energy = original_energy
		var wait_time = randf_range(1.0, 3.0)
		await get_tree().create_timer(wait_time).timeout
		elapsed += wait_time

# 灯光逐渐变暗
func dim_lights(target_multiplier: float = 0.4, duration: float = 1.5):
	adjust_all_lights(target_multiplier, duration)

# 灯光逐渐变亮
func brighten_lights(target_multiplier: float = 1.5, duration: float = 1.5):
	adjust_all_lights(target_multiplier, duration)

# 恢复灯光到默认亮度（需要提前保存）
var original_light_energies = {}

func save_original_light_energies():
	var lights = get_all_lights()
	for light in lights:
		original_light_energies[light] = light.light_energy

func restore_lights(duration: float = 1.0):
	for light in original_light_energies:
		if is_instance_valid(light):
			var tween = create_tween()
			tween.tween_property(light, "light_energy", original_light_energies[light], duration)

# 重置所有灯光到默认状态
func reset_lights(duration: float = 1.0):
	var lights = get_all_lights()
	for light in lights:
		if is_instance_valid(light):
			# 重置到默认亮度（1.0）
			if duration > 0:
				var tween = create_tween()
				tween.tween_property(light, "light_energy", 1.0, duration)
			else:
				light.light_energy = 1.0

# 统一的事件触发接口
func trigger_event(event_name: String, param: float = 1.0):
	match event_name:
		"flicker":
			# 闪烁，param 为持续时间（秒）
			var times = int(param * 10) # 0.5秒 = 5次闪烁
			flicker_lights(times, 0.1)
		
		"flicker_rapid":
			# 快速闪烁，param 为持续时间（秒）
			var times = int(param * 20) # 0.3秒 = 6次快速闪烁
			flicker_lights(times, 0.05)
		
		"dim":
			# 变暗，param 为目标亮度倍数
			dim_lights(param, 1.5)
		
		"dim_briefly":
			# 短暂变暗后恢复
			dim_lights(0.5, param)
			await get_tree().create_timer(2.0).timeout
			brighten_lights(2.0, param)
		
		"brighten":
			# 变亮，param 为目标亮度倍数
			brighten_lights(param, 1.5)
		
		"off":
			# 熄灭，param 为过渡时间
			set_all_lights_energy(0.0, param)
		
		"on":
			# 开启，param 为目标亮度
			set_all_lights_energy(param, 1.0)
		
		_:
			push_warning("[LightingController] 未知的灯光事件: %s" % event_name)
