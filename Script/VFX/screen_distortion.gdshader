shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float time_scale : hint_range(0.0, 10.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	
	// 波纹扭曲
	float wave = sin(uv.y * 10.0 + TIME * time_scale) * distortion_strength;
	uv.x += wave;
	
	COLOR = texture(TEXTURE, uv);
}



