layout(location=0) in vec3 pos;
layout(location=1) in vec2 atexcoord;

out vec2 texcoord; 
out vec4 offset; 


void main() 
{ 
	texcoord = atexcoord;
    offset = fma(SMAA_RT_METRICS.xyxy, vec4( 1.0, 0.0, 0.0, 1.0), texcoord.xyxy);
	
	gl_Position = vec4(pos, 1.0);
	
} 