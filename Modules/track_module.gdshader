shader_type canvas_item;
uniform vec2 CursorPos = vec2(0,0);
uniform vec2 EditINOUT = vec2(0,0);
uniform bool EditShow = false;
void vertex() {
	// Called for every vertex the material is visible on
}

void fragment() {
	COLOR = vec4(0,0,0,1);
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
