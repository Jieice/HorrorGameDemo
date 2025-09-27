extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if animation_player.get_animation_list().size() > 0:
		var anim_name = animation_player.get_animation_list()[0] # 取第一个动画
		var animation: Animation = animation_player.get_animation(anim_name)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR
			animation_player.play(anim_name)
