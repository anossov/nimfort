layout(location=0) in vec3 pos;
layout(location=1) in vec2 atexcoord;

out vec2 texcoord; 
out vec4 offset[3]; 

void main() 
{ 
	texcoord = atexcoord;
	
    offset[0] = fma(SMAA_RT_METRICS.xyxy, vec4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = fma(SMAA_RT_METRICS.xyxy, vec4( 1.0, 0.0, 0.0, 1.0), texcoord.xyxy);
    offset[2] = fma(SMAA_RT_METRICS.xyxy, vec4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);

	gl_Position = vec4(pos, 1.0);
}