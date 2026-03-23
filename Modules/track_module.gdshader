shader_type canvas_item;
uniform vec2 CursorPos = vec2(0,0);
uniform vec2 EditINOUT = vec2(0,0);
uniform bool EditShow = false;
uniform float frame_input = 0;
uniform int max_layers = 112;
uniform usampler2DArray WaveForms;
void vertex() {
	
	// Called for every vertex the material is visible on
}
vec3 pos_texture(vec2 uv, float count, float frame){
	float x = uv.x * count + frame;   // 연속 좌표
	float local_x = fract(x);         // 현재 레이어 안에서의 x
	int layer = int(floor(x));        // 실제 레이어 번호

	layer = clamp(layer, 0, max_layers - 1);
	return vec3(local_x, uv.y, float(layer));
}
void fragment() {
	
	//COLOR = vec4(0,0,0,1);
	//float count = (sin(TIME * 1.0) + 1.0) * 56.0;
	uvec4 v = texture(WaveForms, pos_texture(UV, 1, frame_input));
	
	COLOR = vec4(vec3(v.rgb) / 255.0 , 1.0);
	
	if (EditShow &&
	    FRAGCOORD.x >= min(EditINOUT.x, EditINOUT.y) &&
	    FRAGCOORD.x <= max(EditINOUT.x, EditINOUT.y)) {
	    COLOR.g += 1.0;
	}
	if(FRAGCOORD.x - CursorPos.x > 0.0 && FRAGCOORD.y - CursorPos.y > 0.0 ){
		COLOR += vec4(1,0,0,1);
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
