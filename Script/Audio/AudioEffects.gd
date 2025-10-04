extends Node

# 音效后处理效果管理器

# 为 AudioStreamPlayer 添加低通滤波（让声音变闷）
func add_lowpass_filter(player: AudioStreamPlayer, cutoff_hz: float = 2000.0):
	if not player:
		return
	var bus_idx = AudioServer.get_bus_index(player.bus)
	if bus_idx == -1:
		return
	# 检查是否已有低通滤波
	var has_filter = false
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectLowPassFilter:
			has_filter = true
			var effect = AudioServer.get_bus_effect(bus_idx, i) as AudioEffectLowPassFilter
			effect.cutoff_hz = cutoff_hz
			break
	if not has_filter:
		var lowpass = AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = cutoff_hz
		AudioServer.add_bus_effect(bus_idx, lowpass)

# 移除低通滤波
func remove_lowpass_filter(player: AudioStreamPlayer):
	if not player:
		return
	var bus_idx = AudioServer.get_bus_index(player.bus)
	if bus_idx == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(bus_idx, i)
			break
