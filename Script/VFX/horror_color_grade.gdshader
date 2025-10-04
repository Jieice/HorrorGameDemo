shader_type canvas_item;

// 恐怖游戏色调滤镜
// 参考：寂静岭、生化危机、层层恐惧等经典恐怖游戏

// Godot 4.5 必须先声明 SCREEN_TEXTURE
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float saturation : hint_range(0.0, 2.0) = 0.75; // 饱和度降低
uniform float contrast : hint_range(0.0, 2.0) = 1.15; // 对比度提高
uniform float brightness : hint_range(0.0, 2.0) = 0.92; // 亮度降低
uniform vec3 tint_color : source_color = vec3(0.88, 0.9, 0.96); // 偏冷蓝灰色调

// 暗角（Vignette）
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35; // 暗角强度
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.6; // 暗角平滑度

// 颗粒噪点（Film Grain）
uniform float grain_intensity : hint_range(0.0, 0.2) = 0.04; // 噪点强度

// 随机函数（用于颗粒噪点）
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// 1. 降低饱和度（去色，营造压抑感）
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(gray), color.rgb, saturation);
	
	// 2. 调整对比度（暗部更暗，亮部更亮）
	color.rgb = (color.rgb - 0.5) * contrast + 0.5;
	
	// 3. 调整亮度（整体偏暗）
	color.rgb *= brightness;
	
	// 4. 色调偏移（偏冷/偏暖）
	color.rgb *= tint_color;
	
	// 5. 暗角效果（边缘变暗）
	vec2 uv = UV - 0.5; // 中心为(0,0)
	float dist = length(uv) * 2.0; // 归一化距离
	float vignette = smoothstep(vignette_intensity, vignette_intensity + vignette_smoothness, dist);
	vignette = 1.0 - vignette; // 反转（中心亮，边缘暗）
	color.rgb *= mix(1.0, vignette, vignette_intensity); // 应用暗角
	
	// 6. 颗粒噪点（老电影/录像带效果）
	float grain = random(UV + vec2(TIME * 0.1, 0.0)) * grain_intensity;
	color.rgb += grain - grain_intensity * 0.5; // 噪点（0附近）
	
	// 7. 确保不超出范围
	color.rgb = clamp(color.rgb, 0.0, 1.0);
	
	COLOR = color;
}
