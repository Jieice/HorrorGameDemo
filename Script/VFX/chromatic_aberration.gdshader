shader_type canvas_item;

uniform float aberration_strength : hint_range(0.0, 0.05) = 0.01;

void fragment() {
	vec2 uv = UV;
	
	// RGB 通道分离
	float r = texture(TEXTURE, uv + vec2(aberration_strength, 0.0)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - vec2(aberration_strength, 0.0)).b;
	
	COLOR = vec4(r, g, b, 1.0);
}



