shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 uv = UV - 0.5; // 中心为(0,0)
	float dist = length(uv) * 2.0; // 归一化距离
	
	// vignette_intensity 越小，暗角越强
	// 1.0 = 无暗角，0.0 = 全黑
	float vignette = smoothstep(vignette_intensity - vignette_smoothness, vignette_intensity, dist);
	
	// 中心透明，边缘黑色
	COLOR = vec4(0.0, 0.0, 0.0, vignette);
}
